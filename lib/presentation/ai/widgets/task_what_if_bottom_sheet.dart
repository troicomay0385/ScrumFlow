import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/utils/date_formatter.dart';
import '../../../data/models/performance_score_model.dart';
import '../bloc/task_risk_cubit.dart';
import '../bloc/task_risk_state.dart';
import 'risk_badge.dart';

/// Hiển thị Bottom Sheet giả lập điều chỉnh (What-if) cho một Task (US-069).
Future<void> showTaskWhatIfBottomSheet({
  required BuildContext context,
  required TaskRiskCubit cubit,
  bool canApplyChanges = true,
  Future<void> Function(String? newAssigneeId, DateTime? newDeadline)? onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AiThemeTokens.cardSurface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => BlocProvider.value(
      value: cubit,
      child: TaskWhatIfBottomSheet(
        canApplyChanges: canApplyChanges,
        onApply: onApply,
      ),
    ),
  );
}

class TaskWhatIfBottomSheet extends StatelessWidget {
  final bool canApplyChanges;
  final Future<void> Function(String? newAssigneeId, DateTime? newDeadline)?
  onApply;

  const TaskWhatIfBottomSheet({
    super.key,
    this.canApplyChanges = true,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: bottomInset + 16,
          ),
          child: BlocBuilder<TaskRiskCubit, TaskRiskState>(
            builder: (context, state) {
              final prediction = state.prediction;
              if (prediction == null || !prediction.isPredictable) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Không có dữ liệu dự báo để giả lập.'),
                  ),
                );
              }

              final sim = state.activeSimulation;
              final origPct = prediction.probabilityPercent;
              final newProb = sim?.newProbability ?? prediction.probability;
              final newPct = (newProb * 100).round();
              final deltaPct = origPct - newPct;

              final hasAdjustment =
                  (state.selectedAssigneeId != prediction.task.assigneeId) ||
                  (state.simulatedAddedDays > 0);

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AiThemeTokens.border(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.auto_graph_rounded,
                          color: AiThemeTokens.primary(context),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Giả lập điều chỉnh rủi ro (What-if)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AiThemeTokens.textPrimary(context),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Thẻ so sánh trước → sau
                    Container(
                      key: const Key('what_if_comparison_banner'),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AiThemeTokens.cardSubtleSurface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AiThemeTokens.border(context),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Hiện tại: $origPct%',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AiThemeTokens.textSecondary(context),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: AiThemeTokens.textSecondary(context),
                              ),
                              RiskBadge(
                                key: const Key('what_if_simulated_badge'),
                                probability: newProb,
                              ),
                              if (deltaPct != 0)
                                Text(
                                  deltaPct > 0
                                      ? '(-$deltaPct%)'
                                      : '(+${-deltaPct}%)',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: deltaPct > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                            ],
                          ),
                          if (sim != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              sim.subtitleVi,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AiThemeTokens.textPrimary(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. Chọn người phụ trách (tích hợp điểm hiệu suất US-057/058)
                    Text(
                      '1. Thử đổi người phụ trách (theo điểm US-057)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AiThemeTokens.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (prediction.memberScores.isEmpty)
                      Text(
                        'Chưa có danh sách thành viên dự án.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AiThemeTokens.textSecondary(context),
                        ),
                      )
                    else
                      ...prediction.memberScores.map(
                        (memberScore) => _MemberOptionTile(
                          score: memberScore,
                          isSelected:
                              state.selectedAssigneeId == memberScore.userId,
                          isCurrent:
                              prediction.task.assigneeId == memberScore.userId,
                          onSelect: () {
                            context.read<TaskRiskCubit>().simulateWhatIf(
                              assigneeId: memberScore.userId,
                              assigneeName: memberScore.userName,
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 2. Kéo thanh trượt gia hạn Deadline (+0..+5 ngày)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '2. Gia hạn thêm Deadline',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AiThemeTokens.textPrimary(context),
                            ),
                          ),
                        ),
                        Text(
                          '+${state.simulatedAddedDays} ngày',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AiThemeTokens.primary(context),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      key: const Key('what_if_deadline_slider'),
                      value: state.simulatedAddedDays.toDouble().clamp(0, 5),
                      min: 0,
                      max: 5,
                      divisions: 5,
                      activeColor: AiThemeTokens.primary(context),
                      label: '+${state.simulatedAddedDays} ngày',
                      onChanged: (val) {
                        context.read<TaskRiskCubit>().simulateWhatIf(
                          addedDays: val.round(),
                        );
                      },
                    ),
                    if (prediction.task.deadline != null &&
                        state.simulatedAddedDays > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Hạn mới dự kiến: ${formatDateVi(prediction.task.deadline!.add(Duration(days: state.simulatedAddedDays)))}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AiThemeTokens.textSecondary(context),
                          ),
                        ),
                      ),

                    // 3. Gợi ý tối ưu hàng đầu của AI
                    if (prediction.suggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Gợi ý giảm rủi ro tốt nhất từ AI:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AiThemeTokens.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...prediction.suggestions
                          .take(3)
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  context.read<TaskRiskCubit>().simulateWhatIf(
                                    assigneeId: s.targetAssigneeId,
                                    assigneeName: s.targetAssigneeName,
                                    addedDays: s.addedDays,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AiThemeTokens.border(context),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.tips_and_updates_outlined,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.titleVi,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    AiThemeTokens.textPrimary(
                                                      context,
                                                    ),
                                              ),
                                            ),
                                            Text(
                                              s.subtitleVi,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color:
                                                    AiThemeTokens.textSecondary(
                                                      context,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],

                    const SizedBox(height: 12),
                    if (canApplyChanges && onApply != null)
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          key: const Key('what_if_apply_button'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AiThemeTokens.primary(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: hasAdjustment
                              ? () async {
                                  final newAssignee =
                                      state.selectedAssigneeId !=
                                          prediction.task.assigneeId
                                      ? state.selectedAssigneeId
                                      : null;
                                  final newDeadline =
                                      state.simulatedAddedDays > 0 &&
                                          prediction.task.deadline != null
                                      ? prediction.task.deadline!.add(
                                          Duration(
                                            days: state.simulatedAddedDays,
                                          ),
                                        )
                                      : null;
                                  Navigator.of(context).pop();
                                  await onApply!(newAssignee, newDeadline);
                                }
                              : null,
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: Text(
                            'Áp dụng điều chỉnh này',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MemberOptionTile extends StatelessWidget {
  final MemberPerformanceScore score;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onSelect;

  const _MemberOptionTile({
    required this.score,
    required this.isSelected,
    required this.isCurrent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AiThemeTokens.primary(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        key: Key('what_if_member_${score.userId}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onSelect,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha: 0.1)
                : AiThemeTokens.cardSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primary : AiThemeTokens.border(context),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: isSelected
                    ? primary
                    : AiThemeTokens.textSecondary(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${score.userName}${isCurrent ? " (Hiện tại)" : ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AiThemeTokens.textPrimary(context),
                      ),
                    ),
                    Text(
                      score.recommendationReason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AiThemeTokens.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${score.scorePercentage}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
