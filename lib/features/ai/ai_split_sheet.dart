import 'package:flutter/material.dart';
import 'ai_split_service.dart';

/// Mở bottom sheet gợi ý task. Trả về số task đã thêm (null nếu đóng sheet).
Future<int?> showAiSplitSheet(
  BuildContext context, {
  required AiSplitService service,
  required String storyTitle,
  required String storyDescription,
  required Future<void> Function(AiTaskSuggestion task) onCreateTask,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AiSplitSheet(
      service: service,
      storyTitle: storyTitle,
      storyDescription: storyDescription,
      onCreateTask: onCreateTask,
    ),
  );
}

class _AiSplitSheet extends StatefulWidget {
  const _AiSplitSheet({
    required this.service,
    required this.storyTitle,
    required this.storyDescription,
    required this.onCreateTask,
  });

  final AiSplitService service;
  final String storyTitle;
  final String storyDescription;
  final Future<void> Function(AiTaskSuggestion task) onCreateTask;

  @override
  State<_AiSplitSheet> createState() => _AiSplitSheetState();
}

class _AiSplitSheetState extends State<_AiSplitSheet> {
  AiSplitResult? _result;
  String? _error;
  bool _loading = true;
  bool _saving = false;
  final List<TextEditingController> _titleCtrls = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _titleCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.service.splitStory(
        title: widget.storyTitle,
        description: widget.storyDescription,
      );
      if (!mounted) return;
      for (final c in _titleCtrls) {
        c.dispose();
      }
      _titleCtrls
        ..clear()
        ..addAll(r.tasks.map((t) => TextEditingController(text: t.title)));
      setState(() {
        _result = r;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể lấy gợi ý. Kiểm tra kết nối mạng và thử lại.';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final r = _result;
    if (r == null) return;
    setState(() => _saving = true);
    var added = 0;
    try {
      for (var i = 0; i < r.tasks.length; i++) {
        final t = r.tasks[i];
        if (!t.selected) continue;
        t.title = _titleCtrls[i].text.trim();
        if (t.title.isEmpty) continue;
        await widget.onCreateTask(t);
        t.selected = false; // tránh tạo trùng nếu phải thử lại
        added++;
      }
      if (mounted) Navigator.of(context).pop(added);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm $added task, có lỗi ở các task còn lại. Bấm lại để thử tiếp.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.8;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI gợi ý tách task',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.storyTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Divider(),
            Expanded(child: _buildBody(context)),
            if (_result != null && !_loading) _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('AI đang phân tích User Story...'),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final r = _result!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        if (r.isFallback)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              'Gợi ý mẫu (AI tạm thời không khả dụng)',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        for (var i = 0; i < r.tasks.length; i++) _taskTile(context, r.tasks[i], i),
      ],
    );
  }

  Widget _taskTile(BuildContext context, AiTaskSuggestion t, int i) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: t.selected,
              onChanged: _saving ? null : (v) => setState(() => t.selected = v ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleCtrls[i],
                    enabled: !_saving,
                    maxLines: null,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Tiêu đề task',
                    ),
                  ),
                  if (t.description.isNotEmpty)
                    Text(t.description, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Chip(
                        label: Text(t.role),
                        visualDensity: VisualDensity.compact,
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _saving || t.estimateHours <= 1
                            ? null
                            : () => setState(() => t.estimateHours--),
                      ),
                      Text('${t.estimateHours}h'),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _saving || t.estimateHours >= 16
                            ? null
                            : () => setState(() => t.estimateHours++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final count = _result!.tasks.where((t) => t.selected).length;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _saving || count == 0 ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.playlist_add),
              label: Text('Thêm $count task vào Board'),
            ),
          ],
        ),
      ),
    );
  }
}