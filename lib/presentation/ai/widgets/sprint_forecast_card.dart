import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../bloc/sprint_forecast_cubit.dart';
import '../bloc/sprint_forecast_state.dart';
import 'risk_badge.dart';

/// Card hiển thị dự báo tiến độ hoàn thành Sprint bằng Monte Carlo (US-070)
/// kèm gợi ý và bảng thử nghiệm What-if dời bớt User Story chưa hoàn thành.
class SprintForecastCard extends StatelessWidget {
  final VoidCallback? onRetry;

  const SprintForecastCard({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final onSurfaceColor = isDark
        ? AppColors.darkOnSurface
        : AppColors.onSurface;
    final subTextColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final lowContainerColor = isDark
        ? AppColors.darkSurfaceContainerLow
        : AppColors.surfaceContainerLow;

    return BlocBuilder<SprintForecastCubit, SprintForecastState>(
      builder: (context, state) {
        return Container(
          key: const Key('sprintForecastCard'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: isDark ? 0.25 : 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: switch (state) {
            SprintForecastInitial() ||
            SprintForecastLoading() => _buildLoading(onSurfaceColor),
            SprintForecastError(:final message) => _buildError(
              message,
              onSurfaceColor,
            ),
            SprintForecastLoaded() => _buildLoaded(
              context: context,
              state: state,
              isDark: isDark,
              onSurfaceColor: onSurfaceColor,
              subTextColor: subTextColor,
              lowContainerColor: lowContainerColor,
            ),
          },
        );
      },
    );
  }

  Widget _buildLoading(Color onSurfaceColor) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Đang chạy 1.000 kịch bản Monte Carlo dự báo Sprint...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onSurfaceColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message, Color onSurfaceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 12, color: onSurfaceColor),
              ),
            ),
          ],
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoaded({
    required BuildContext context,
    required SprintForecastLoaded state,
    required bool isDark,
    required Color onSurfaceColor,
    required Color subTextColor,
    required Color lowContainerColor,
  }) {
    final fc = state.activeForecast;
    final baseFc = state.baseForecast;
    final probPct = fc.completionPercent;
    final delayProb = (1.0 - fc.completionProbability).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_graph_rounded,
                size: 20,
                color: Color(0xFF0D9488),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dự báo Tiến độ Sprint (Monte Carlo)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: onSurfaceColor,
                    ),
                  ),
                  Text(
                    '${fc.simulationsRun} kịch bản · Nguồn: ${fc.sourceType.labelVi}',
                    style: GoogleFonts.inter(fontSize: 11, color: subTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            RiskBadge(probability: delayProb, compact: true),
          ],
        ),

        // 2. Cảnh báo độ tin cậy thấp khi ít dữ liệu lịch sử
        if (fc.isLowConfidence) ...[
          const SizedBox(height: 12),
          Container(
            key: const Key('sprintForecast_lowConfidenceBanner'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dự báo độ tin cậy thấp — dự án chưa có Sprint đã đóng, hệ thống dùng phân phối khởi tạo.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (state.hasWhatIfChanges) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.science_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chế độ What-if: Đang thử dời ${state.excludedStoryIds.length} Story (${baseFc.completionPercent}% → $probPct%)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.read<SprintForecastCubit>().resetWhatIf(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Hoàn tác'),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // 3. Xác suất hoàn thành đúng hạn & Phân vị ngày p10 / p50 / p90
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: lowContainerColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Xác suất hoàn thành đúng hạn:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subTextColor,
                    ),
                  ),
                  Text(
                    '$probPct%',
                    key: const Key('sprintForecast_probabilityText'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: probPct >= 70
                          ? AppColors.success
                          : (probPct >= 40
                                ? AppColors.warning
                                : AppColors.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: fc.completionProbability.clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: AppColors.outline.withValues(alpha: 0.2),
                  color: probPct >= 70
                      ? AppColors.success
                      : (probPct >= 40 ? AppColors.warning : AppColors.error),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPercentileCell(
                    label: 'Lạc quan (p10)',
                    value: '${fc.daysToCompleteP10} ngày',
                    onSurfaceColor: onSurfaceColor,
                    subTextColor: subTextColor,
                  ),
                  const SizedBox(width: 8),
                  _buildPercentileCell(
                    label: 'Trung vị (p50)',
                    value: '${fc.daysToCompleteP50} ngày',
                    onSurfaceColor: onSurfaceColor,
                    subTextColor: subTextColor,
                    highlight: true,
                  ),
                  const SizedBox(width: 8),
                  _buildPercentileCell(
                    label: 'Thận trọng (p90)',
                    value: '${fc.daysToCompleteP90} ngày',
                    onSurfaceColor: onSurfaceColor,
                    subTextColor: subTextColor,
                  ),
                ],
              ),
            ],
          ),
        ),

        // 4. Gợi ý What-if nhanh (Top suggestions)
        if (baseFc.whatIfSuggestions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Gợi ý giảm tải Sprint (What-if):',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: onSurfaceColor,
            ),
          ),
          const SizedBox(height: 6),
          ...baseFc.whatIfSuggestions
              .take(2)
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.tips_and_updates_outlined,
                        size: 15,
                        color: Color(0xFF0D9488),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Nếu dời ${s.story.storyKey} (${s.story.storyPoints} SP): xác suất hoàn thành ${s.basePercent}% → ${s.newPercent}%',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: onSurfaceColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],

        // 5. Nút mở Bottom Sheet thử bớt Story
        if (state.incompleteStories.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('sprintForecast_openWhatIfButton'),
              onPressed: () => _showWhatIfBottomSheet(context),
              icon: const Icon(Icons.tune_rounded, size: 17),
              label: const Text('Thử bớt Story (What-if)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D9488),
                side: BorderSide(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPercentileCell({
    required String label,
    required String value,
    required Color onSurfaceColor,
    required Color subTextColor,
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFF0D9488).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: subTextColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: highlight ? const Color(0xFF0D9488) : onSurfaceColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showWhatIfBottomSheet(BuildContext context) {
    final cubit = context.read<SprintForecastCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const SprintWhatIfBottomSheet(),
      ),
    );
  }
}

/// Bottom sheet tương tác cho phép PO / SM chọn thử các User Story chưa hoàn thành
/// để xem xác suất hoàn thành Sprint thay đổi tức thời (chỉ tính trên bộ nhớ).
class SprintWhatIfBottomSheet extends StatelessWidget {
  const SprintWhatIfBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final onSurfaceColor = isDark
        ? AppColors.darkOnSurface
        : AppColors.onSurface;
    final subTextColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          key: const Key('sprintWhatIfBottomSheet'),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: BlocBuilder<SprintForecastCubit, SprintForecastState>(
            builder: (context, state) {
              if (state is! SprintForecastLoaded) {
                return const SizedBox.shrink();
              }
              final basePct = state.baseForecast.completionPercent;
              final activePct = state.activeForecast.completionPercent;
              final delta = activePct - basePct;

              return Material(
                color: Colors.transparent,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Mô phỏng What-if: Dời bớt Story',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: onSurfaceColor,
                              ),
                            ),
                          ),
                          if (state.hasWhatIfChanges)
                            TextButton(
                              onPressed: () => context
                                  .read<SprintForecastCubit>()
                                  .resetWhatIf(),
                              child: const Text('Đặt lại'),
                            ),
                        ],
                      ),
                      Text(
                        'Thử dời các User Story chưa xong sang Sprint sau để xem xác suất hoàn thành đúng hạn thay đổi (không ghi vào cơ sở dữ liệu).',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: subTextColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            Text(
                              'Xác suất hoàn thành: $basePct% → $activePct%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: onSurfaceColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: delta > 0
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : AppColors.outline.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                delta >= 0 ? '+$delta%' : '$delta%',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: delta > 0
                                      ? AppColors.success
                                      : subTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...state.incompleteStories.map((story) {
                        final isExcluded = state.excludedStoryIds.contains(
                          story.id,
                        );
                        return CheckboxListTile(
                          key: Key('whatIfStoryTile_${story.id}'),
                          contentPadding: EdgeInsets.zero,
                          value: isExcluded,
                          activeColor: const Color(0xFF0D9488),
                          onChanged: (_) => context
                              .read<SprintForecastCubit>()
                              .toggleExcludedStory(story.id),
                          title: Text(
                            '${story.storyKey} · ${story.title}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: onSurfaceColor,
                              decoration: isExcluded
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${story.storyPoints} SP · ${story.priority} · ${story.status}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: subTextColor,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
