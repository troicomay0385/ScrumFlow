import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/utils/date_formatter.dart';
import '../../../data/ai/risk_prediction_service.dart';
import '../../tasks/screens/task_detail_screen.dart';
import '../bloc/sprint_risk_cubit.dart';
import '../bloc/sprint_risk_state.dart';
import 'risk_badge.dart';

/// Thẻ Bento "Cảnh báo Task có nguy cơ trễ cao (AI)" trong `SprintDetailScreen` (US-069).
///
/// Liệt kê các Task chưa hoàn thành trong Sprint theo thứ tự rủi ro giảm dần,
/// kèm lý do đóng góp lớn nhất và nút mở nhanh `TaskDetailScreen`.
class SprintHighRiskTasksCard extends StatelessWidget {
  final String projectId;
  final VoidCallback? onRetry;

  const SprintHighRiskTasksCard({
    super.key,
    required this.projectId,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('sprint_high_risk_tasks_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AiThemeTokens.cardSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiThemeTokens.border(context)),
      ),
      child: BlocBuilder<SprintRiskCubit, SprintRiskState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Radar Rủi ro Task trong Sprint (AI)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AiThemeTokens.textPrimary(context),
                          ),
                        ),
                        Text(
                          'Xếp hạng các Task có nguy cơ trễ hạn cao nhất',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AiThemeTokens.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.status == SprintRiskStatus.initial ||
                  state.status == SprintRiskStatus.loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AiThemeTokens.primary(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Đang quét rủi ro các Task trong Sprint...',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AiThemeTokens.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (state.status == SprintRiskStatus.error)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.errorMessage ?? 'Không thể tải dự báo rủi ro.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                    if (onRetry != null)
                      TextButton.icon(
                        key: const Key('sprint_risk_retry_button'),
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Thử lại'),
                      ),
                  ],
                )
              else if (state.actionableRiskTasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AiThemeTokens.cardSubtleSurface(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chưa có Task đang mở có đặt deadline hoặc tất cả Task đều đã hoàn thành.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AiThemeTokens.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...state.actionableRiskTasks
                    .take(5)
                    .map(
                      (prediction) => _SprintRiskTaskRow(
                        prediction: prediction,
                        projectId: projectId,
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _SprintRiskTaskRow extends StatelessWidget {
  final TaskRiskPrediction prediction;
  final String projectId;

  const _SprintRiskTaskRow({required this.prediction, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final task = prediction.task;
    final topReason = prediction.topReasons.isNotEmpty
        ? prediction.topReasons.first
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: Key('sprint_risk_task_row_${task.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TaskDetailScreen(task: task, projectId: projectId),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AiThemeTokens.cardSubtleSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AiThemeTokens.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AiThemeTokens.textPrimary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RiskBadge.fromPrediction(
                    prediction: prediction,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    '👤 ${task.assigneeName?.isNotEmpty == true ? task.assigneeName : "Chưa giao"}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AiThemeTokens.textSecondary(context),
                    ),
                  ),
                  if (task.deadline != null)
                    Text(
                      '📅 Hạn: ${formatDateVi(task.deadline!)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AiThemeTokens.textSecondary(context),
                      ),
                    ),
                ],
              ),
              if (topReason != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Yếu tố chính: ${topReason.labelVi} (${topReason.formattedPercentPoints})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AiThemeTokens.textSecondary(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
