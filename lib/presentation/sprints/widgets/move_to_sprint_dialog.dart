import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/repositories/sprint_repository.dart';

/// Hộp thoại chọn Sprint đích để di chuyển hàng loạt User Story (US-053).
class MoveToSprintDialog extends StatefulWidget {
  final String projectId;
  final int selectedCount;
  final String? currentSprintId;

  const MoveToSprintDialog({
    super.key,
    required this.projectId,
    required this.selectedCount,
    this.currentSprintId,
  });

  static Future<String?> show({
    required BuildContext context,
    required String projectId,
    required int selectedCount,
    String? currentSprintId,
  }) {
    return showDialog<String?>(
      context: context,
      builder: (_) => MoveToSprintDialog(
        projectId: projectId,
        selectedCount: selectedCount,
        currentSprintId: currentSprintId,
      ),
    );
  }

  @override
  State<MoveToSprintDialog> createState() => _MoveToSprintDialogState();
}

class _MoveToSprintDialogState extends State<MoveToSprintDialog> {
  String? _selectedSprintId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.drive_file_move_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Di chuyển ${widget.selectedCount} User Story',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<List<SprintModel>>(
          stream: context.read<SprintRepository>().streamSprints(widget.projectId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final sprints = snapshot.data ?? const <SprintModel>[];

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chọn đích di chuyển:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option 1: Product Backlog (Nguồn tự do)
                  if (widget.currentSprintId != null)
                    InkWell(
                      onTap: () => setState(() => _selectedSprintId = '__BACKLOG__'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              _selectedSprintId == '__BACKLOG__'
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: _selectedSprintId == '__BACKLOG__'
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Product Backlog (Chưa gán Sprint)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Sprints list
                  if (sprints.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Chưa có Sprint nào trong dự án. Hãy tạo Sprint mới trước.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...sprints
                        .where((s) => s.id != widget.currentSprintId)
                        .map((sprint) {
                      final isSelected = _selectedSprintId == sprint.id;
                      return InkWell(
                        onTap: () => setState(() => _selectedSprintId = sprint.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sprint.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '${sprint.status} · ${sprint.storyIds.length} stories',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(
            'Hủy',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _selectedSprintId == null
              ? null
              : () => Navigator.pop(context, _selectedSprintId),
          child: Text(
            'Di chuyển',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
