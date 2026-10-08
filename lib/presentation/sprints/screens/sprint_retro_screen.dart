import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/models/sprint_retro_item_model.dart';
import '../../../data/repositories/sprint_retro_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

/// Màn hình Sprint Retrospective (US-024) theo mô hình chuẩn Scrum 3 cột.
class SprintRetroScreen extends StatefulWidget {
  final String projectId;
  final SprintModel sprint;
  final SprintRetroRepository repository;

  const SprintRetroScreen({
    super.key,
    required this.projectId,
    required this.sprint,
    required this.repository,
  });

  @override
  State<SprintRetroScreen> createState() => _SprintRetroScreenState();
}

class _SprintRetroScreenState extends State<SprintRetroScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddItemDialog(BuildContext context, {RetroColumnType initialColumn = RetroColumnType.wentWell}) {
    final textController = TextEditingController();
    RetroColumnType selectedCol = initialColumn;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: 20 + bottomInset,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Thêm ý kiến Retrospective',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 14),

                // Choice chips for 3 columns
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(
                          '🟢 Làm tốt',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        selected: selectedCol == RetroColumnType.wentWell,
                        selectedColor: const Color(0xFFDCFCE7),
                        onSelected: (_) => setModalState(() => selectedCol = RetroColumnType.wentWell),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(
                          '🟡 Cải thiện',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        selected: selectedCol == RetroColumnType.couldImprove,
                        selectedColor: const Color(0xFFFEF3C7),
                        onSelected: (_) => setModalState(() => selectedCol = RetroColumnType.couldImprove),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(
                          '🟣 Hành động',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        selected: selectedCol == RetroColumnType.actionItem,
                        selectedColor: const Color(0xFFEDE9FE),
                        onSelected: (_) => setModalState(() => selectedCol = RetroColumnType.actionItem),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: textController,
                  autofocus: true,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Nhập nội dung đóng góp ý kiến của bạn...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final text = textController.text.trim();
                    if (text.isEmpty) return;

                    final authState = context.read<AuthBloc>().state;
                    String uid = 'unknown';
                    String name = 'Thành viên';
                    if (authState is AuthAuthenticated) {
                      uid = authState.user.id;
                      name = authState.user.fullName;
                    }

                    await widget.repository.addRetroItem(
                      projectId: widget.projectId,
                      sprintId: widget.sprint.id,
                      column: selectedCol,
                      content: text,
                      authorId: uid,
                      authorName: name,
                    );

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Đăng ý kiến'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUid = authState is AuthAuthenticated ? authState.user.id : null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sprint Retrospective',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              widget.sprint.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '🟢 Làm tốt'),
            Tab(text: '🟡 Cải thiện'),
            Tab(text: '🟣 Hành động'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final cols = [
            RetroColumnType.wentWell,
            RetroColumnType.couldImprove,
            RetroColumnType.actionItem,
          ];
          _showAddItemDialog(context, initialColumn: cols[_tabController.index]);
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm ý kiến'),
      ),
      body: StreamBuilder<List<SprintRetroItemModel>>(
        stream: widget.repository.streamRetroItems(
          widget.projectId,
          widget.sprint.id,
        ),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];

          final wentWellItems = items
              .where((it) => it.column == RetroColumnType.wentWell)
              .toList();
          final couldImproveItems = items
              .where((it) => it.column == RetroColumnType.couldImprove)
              .toList();
          final actionItems = items
              .where((it) => it.column == RetroColumnType.actionItem)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildColumnList(
                wentWellItems,
                emptyMsg: 'Chưa có ý kiến "Điều làm tốt". Hãy chia sẻ thành công của nhóm!',
                cardBg: const Color(0xFFF0FDF4),
                accentColor: const Color(0xFF16A34A),
                currentUid: currentUid,
              ),
              _buildColumnList(
                couldImproveItems,
                emptyMsg: 'Chưa có ý kiến "Cần cải thiện". Hãy nêu những điểm vướng mắc!',
                cardBg: const Color(0xFFFFFBEB),
                accentColor: const Color(0xFFD97706),
                currentUid: currentUid,
              ),
              _buildColumnList(
                actionItems,
                emptyMsg: 'Chưa có cam kết "Kế hoạch hành động" cho Sprint tới.',
                cardBg: const Color(0xFFF5F3FF),
                accentColor: const Color(0xFF7C3AED),
                currentUid: currentUid,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColumnList(
    List<SprintRetroItemModel> items, {
    required String emptyMsg,
    required Color cardBg,
    required Color accentColor,
    String? currentUid,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forum_outlined, size: 48, color: accentColor.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                emptyMsg,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 14, left: 16, right: 16, bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final hasVoted = currentUid != null && item.voterIds.contains(currentUid);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: accentColor.withValues(alpha: 0.2),
                    child: Text(
                      item.authorName.isNotEmpty ? item.authorName[0].toUpperCase() : '?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.authorName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Vote Button
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: currentUid != null
                        ? () => widget.repository.toggleVote(
                              projectId: widget.projectId,
                              sprintId: widget.sprint.id,
                              itemId: item.id,
                              userId: currentUid,
                            )
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasVoted ? accentColor.withValues(alpha: 0.15) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasVoted ? accentColor : AppColors.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasVoted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 14,
                            color: hasVoted ? accentColor : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.votesCount}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: hasVoted ? accentColor : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (currentUid == item.authorId) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: AppColors.onSurfaceVariant,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => widget.repository.deleteRetroItem(
                        projectId: widget.projectId,
                        sprintId: widget.sprint.id,
                        itemId: item.id,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
