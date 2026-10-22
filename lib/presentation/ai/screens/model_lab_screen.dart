import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/ai/risk_prediction_service.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/backlog_repository.dart';
import '../../../data/repositories/sprint_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../domain/ai/core/ai_training_pipeline.dart';
import '../../../domain/ai/core/feature_spec.dart';
import '../../../domain/ai/core/metrics.dart';
import '../bloc/model_lab_cubit.dart';
import '../bloc/model_lab_state.dart';
import '../widgets/risk_badge.dart';

T? _maybeRead<T>(BuildContext context) {
  try {
    return context.read<T>();
  } catch (_) {
    return null;
  }
}

/// Màn hình Phòng Thí Nghiệm Mô Hình AI (`ModelLabScreen` — US-071).
///
/// Chỉ dành cho PO và SM (`Permission.manageAiModel`).
/// Cho phép kiểm tra dữ liệu huấn luyện (`synthetic` vs `real`), huấn luyện lại
/// mô hình Logistic Regression ngay trên thiết bị, quan sát đường cong hàm mất mát
/// (Loss Curve), ma trận nhầm lẫn 2×2, so sánh với 2 Baseline và xem trọng số đặc trưng.
class ModelLabScreen extends StatelessWidget {
  final String projectId;
  final RiskPredictionService? predictionService;
  final List<TaskModel>? preloadedTasks;

  const ModelLabScreen({
    super.key,
    required this.projectId,
    this.predictionService,
    this.preloadedTasks,
  });

  @override
  Widget build(BuildContext context) {
    final existingCubit = _maybeRead<ModelLabCubit>(context);
    if (existingCubit != null) {
      return const _ModelLabView();
    }

    final aiService =
        predictionService ??
        _maybeRead<RiskPredictionService>(context) ??
        RiskPredictionService();

    return BlocProvider(
      create: (ctx) => ModelLabCubit(
        projectId: projectId,
        predictionService: aiService,
        taskRepository: _maybeRead<TaskRepository>(ctx),
        backlogRepository: _maybeRead<BacklogRepository>(ctx),
        sprintRepository: _maybeRead<SprintRepository>(ctx),
      )..loadModelInfo(preloadedTasks: preloadedTasks),
      child: _ModelLabView(preloadedTasks: preloadedTasks),
    );
  }
}

class _ModelLabView extends StatelessWidget {
  final List<TaskModel>? preloadedTasks;

  const _ModelLabView({this.preloadedTasks});

  @override
  Widget build(BuildContext context) {
    final isDark = AiThemeTokens.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'AI Model Lab (US-071)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AiThemeTokens.textPrimary(context),
          ),
        ),
      ),
      body: BlocConsumer<ModelLabCubit, ModelLabState>(
        listenWhen: (prev, curr) =>
            curr.infoBannerMessage != null &&
            prev.infoBannerMessage != curr.infoBannerMessage,
        listener: (context, state) {
          if (state.infoBannerMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.infoBannerMessage!),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        builder: (context, state) {
          if (state.status == ModelLabStatus.initial ||
              (state.status == ModelLabStatus.loading &&
                  state.artifact == null)) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state.status == ModelLabStatus.error && state.artifact == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage ?? 'Không thể tải AI Model Lab.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AiThemeTokens.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('model_lab_retry_button'),
                      onPressed: () => context
                          .read<ModelLabCubit>()
                          .loadModelInfo(preloadedTasks: preloadedTasks),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final artifact = state.artifact;
          if (artifact == null) {
            return const SizedBox.shrink();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Thẻ dữ liệu huấn luyện & Cảnh báo mẫu thật
                _DatasetSummaryCard(state: state, artifact: artifact),
                const SizedBox(height: 16),

                // 2. Nút Huấn luyện lại + Biểu đồ Loss Curve (Canvas)
                _TrainingAndLossCurveCard(
                  state: state,
                  artifact: artifact,
                  preloadedTasks: preloadedTasks,
                ),
                const SizedBox(height: 16),

                // 3. Metrics tập test & Confusion Matrix 2x2
                _MetricsAndConfusionCard(
                  metrics: artifact.testMetrics,
                  previousMetrics: state.previousMetricsBeforeRetrain,
                ),
                const SizedBox(height: 16),

                // 4. Bảng so sánh 3 mô hình (Baselines vs Logistic Regression)
                _BaselineComparisonCard(artifact: artifact),
                const SizedBox(height: 16),

                // 5. Feature Importance (Thanh ngang có dấu |w_i|)
                _FeatureImportanceCard(artifact: artifact),
                const SizedBox(height: 16),

                // 6. Tiện ích: Sao chép JSON & Đặt lại mặc định
                _UtilitiesCard(state: state),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DatasetSummaryCard extends StatelessWidget {
  final ModelLabState state;
  final TrainedRiskModelArtifact artifact;

  const _DatasetSummaryCard({required this.state, required this.artifact});

  @override
  Widget build(BuildContext context) {
    final posPct = (artifact.positiveLabelRatio * 100).toStringAsFixed(1);

    return Container(
      key: const Key('model_lab_dataset_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AiThemeTokens.cardSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiThemeTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage_rounded,
                size: 18,
                color: AiThemeTokens.primary(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '1. Nguồn Dữ Liệu Huấn Luyện (Synthetic & Real)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AiThemeTokens.textPrimary(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AiThemeTokens.cardSubtleSurface(context),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Schema v${artifact.schemaVersion}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AiThemeTokens.primary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _StatPill(
                label: 'Mẫu khởi tạo (synthetic)',
                value: '${artifact.syntheticSampleCount}',
              ),
              _StatPill(
                label: 'Mẫu thực tế đã gộp (real)',
                value: '${artifact.realSampleCount}',
              ),
              _StatPill(
                label: 'Task Done có hạn trong dự án',
                value: '${state.detectedRealTaskCount}',
              ),
              _StatPill(label: 'Tỷ lệ nhãn Trễ hạn (y=1)', value: '$posPct%'),
            ],
          ),
          const SizedBox(height: 10),
          if (state.hasLowRealDataWarning)
            Container(
              key: const Key('model_lab_low_real_data_warning'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AiThemeTokens.riskBackground(context, RiskLevel.medium),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AiThemeTokens.riskForeground(
                      context,
                      RiskLevel.medium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cảnh báo: Dữ liệu thật còn ít (${state.detectedRealTaskCount} < 10 task Done có deadline). Mô hình hiện chủ yếu dựa trên 800 mẫu lịch sử khởi tạo tổng hợp (synthetic bootstrap).',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AiThemeTokens.riskForeground(
                          context,
                          RiskLevel.medium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Chống rò rỉ nhãn (Anti-Label Leakage): Mẫu real chỉ lấy từ Task Done có deadline (nhãn y = updatedAt > deadline). Các đặc trưng động của mẫu real được cố định tại checkpoint giữa kỳ (elapsedRatio=0.5, statusProgress=0.5, loggedHoursPerDay=1.5) và tính leave-one-out cho tỷ lệ đúng hạn.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AiThemeTokens.textSecondary(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AiThemeTokens.cardSubtleSurface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AiThemeTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AiThemeTokens.textSecondary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AiThemeTokens.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingAndLossCurveCard extends StatelessWidget {
  final ModelLabState state;
  final TrainedRiskModelArtifact artifact;
  final List<TaskModel>? preloadedTasks;

  const _TrainingAndLossCurveCard({
    required this.state,
    required this.artifact,
    this.preloadedTasks,
  });

  @override
  Widget build(BuildContext context) {
    final isTraining = state.status == ModelLabStatus.training;
    final trainLosses = state.liveTrainLosses.isNotEmpty
        ? state.liveTrainLosses
        : artifact.history.trainLosses;
    final valLosses = state.liveValLosses.isNotEmpty
        ? state.liveValLosses
        : artifact.history.valLosses;

    return Container(
      key: const Key('model_lab_loss_curve_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AiThemeTokens.cardSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiThemeTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 18,
                color: AiThemeTokens.primary(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '2. Huấn Luyện & Đường Cong Mất Mát (Loss Curve)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AiThemeTokens.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Epochs: ${artifact.history.epochsRun}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AiThemeTokens.textSecondary(context),
                ),
              ),
              Text(
                'Train Loss: ${artifact.history.initialLoss.toStringAsFixed(3)} → ${artifact.history.finalLoss.toStringAsFixed(3)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AiThemeTokens.primary(context),
                ),
              ),
              Text(
                'Val Loss: ${artifact.history.bestValLoss.toStringAsFixed(3)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: CustomPaint(
              key: const Key('model_lab_loss_canvas'),
              painter: _LossCurvePainter(
                trainLosses: trainLosses,
                valLosses: valLosses,
                trainColor: AiThemeTokens.primary(context),
                valColor: AppColors.info,
                gridColor: AiThemeTokens.border(context),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              key: const Key('model_lab_retrain_button'),
              style: FilledButton.styleFrom(
                backgroundColor: AiThemeTokens.primary(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isTraining
                  ? null
                  : () => context.read<ModelLabCubit>().retrainWithProjectData(
                      preloadedTasks: preloadedTasks,
                    ),
              icon: isTraining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.model_training_rounded, size: 18),
              label: Text(
                isTraining
                    ? 'Đang huấn luyện (Epoch ${state.currentEpoch}/${state.totalEpochs})...'
                    : 'Huấn luyện lại (Gộp mẫu Real + Bootstrap)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LossCurvePainter extends CustomPainter {
  final List<double> trainLosses;
  final List<double> valLosses;
  final Color trainColor;
  final Color valColor;
  final Color gridColor;

  _LossCurvePainter({
    required this.trainLosses,
    required this.valLosses,
    required this.trainColor,
    required this.valColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (trainLosses.isEmpty) return;

    final allValues = <double>[...trainLosses, ...valLosses];
    final minLoss = allValues.reduce(min) * 0.92;
    final maxLoss = max(minLoss + 0.05, allValues.reduce(max) * 1.05);

    void drawCurve(List<double> values, Color color, {bool dashed = false}) {
      if (values.isEmpty) return;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      final path = Path();
      final count = values.length;
      for (int i = 0; i < count; i++) {
        final x = count == 1 ? size.width / 2 : (i / (count - 1)) * size.width;
        final ratio = ((values[i] - minLoss) / (maxLoss - minLoss)).clamp(
          0.0,
          1.0,
        );
        final y = size.height - ratio * (size.height - 12) - 6;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      if (!dashed) {
        canvas.drawPath(path, paint);
      } else {
        for (final metric in path.computeMetrics()) {
          double dist = 0.0;
          while (dist < metric.length) {
            final next = min(dist + 6.0, metric.length);
            canvas.drawPath(metric.extractPath(dist, next), paint);
            dist += 10.0;
          }
        }
      }
    }

    drawCurve(trainLosses, trainColor, dashed: false);
    drawCurve(valLosses, valColor, dashed: true);
  }

  @override
  bool shouldRepaint(covariant _LossCurvePainter oldDelegate) {
    return oldDelegate.trainLosses.length != trainLosses.length ||
        oldDelegate.valLosses.length != valLosses.length;
  }
}

class _MetricsAndConfusionCard extends StatelessWidget {
  final EvaluationMetrics metrics;
  final EvaluationMetrics? previousMetrics;

  const _MetricsAndConfusionCard({required this.metrics, this.previousMetrics});

  String _fmtPct(double v) => '${(v * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final cm = metrics.confusionMatrix;

    return Container(
      key: const Key('model_lab_metrics_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AiThemeTokens.cardSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiThemeTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '3. Đánh Giá Tập Test Độc Lập & Confusion Matrix 2×2',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AiThemeTokens.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(label: 'Accuracy', value: _fmtPct(metrics.accuracy)),
              _StatPill(label: 'Precision', value: _fmtPct(metrics.precision)),
              _StatPill(label: 'Recall', value: _fmtPct(metrics.recall)),
              _StatPill(
                label: 'F1-Score',
                value: metrics.f1.toStringAsFixed(3),
              ),
              _StatPill(
                label: 'ROC-AUC',
                value: metrics.rocAuc.toStringAsFixed(3),
              ),
              _StatPill(
                label: 'Brier Score',
                value: metrics.brierScore.toStringAsFixed(3),
              ),
            ],
          ),
          if (previousMetrics != null) ...[
            const SizedBox(height: 8),
            Text(
              'Trước khi Retrain: Accuracy ${_fmtPct(previousMetrics!.accuracy)} · F1 ${previousMetrics!.f1.toStringAsFixed(3)} · AUC ${previousMetrics!.rocAuc.toStringAsFixed(3)}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: AiThemeTokens.textSecondary(context),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Ma trận nhầm lẫn 2×2 (Confusion Matrix):',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AiThemeTokens.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Table(
            key: const Key('model_lab_confusion_matrix'),
            border: TableBorder.all(
              color: AiThemeTokens.border(context),
              borderRadius: BorderRadius.circular(8),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: AiThemeTokens.cardSubtleSurface(context),
                ),
                children: const [
                  _MatrixCell(text: 'Thực tế \\ Dự đoán', isHeader: true),
                  _MatrixCell(text: 'Đoán Trễ (1)', isHeader: true),
                  _MatrixCell(text: 'Đoán Đúng hạn (0)', isHeader: true),
                ],
              ),
              TableRow(
                children: [
                  const _MatrixCell(text: 'Thực tế Trễ (1)', isHeader: true),
                  _MatrixCell(text: 'TP = ${cm.tp}', isMono: true),
                  _MatrixCell(text: 'FN = ${cm.fn}', isMono: true),
                ],
              ),
              TableRow(
                children: [
                  const _MatrixCell(
                    text: 'Thực tế Đúng hạn (0)',
                    isHeader: true,
                  ),
                  _MatrixCell(text: 'FP = ${cm.fp}', isMono: true),
                  _MatrixCell(text: 'TN = ${cm.tn}', isMono: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatrixCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isMono;

  const _MatrixCell({
    required this.text,
    this.isHeader = false,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: isMono
            ? GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AiThemeTokens.textPrimary(context),
              )
            : GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
                color: AiThemeTokens.textPrimary(context),
              ),
      ),
    );
  }
}

class _BaselineComparisonCard extends StatelessWidget {
  final TrainedRiskModelArtifact artifact;

  const _BaselineComparisonCard({required this.artifact});

  String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final maj = artifact.majorityBaselineMetrics;
    final form = artifact.formulaBaselineMetrics;
    final lr = artifact.testMetrics;

    return Container(
      key: const Key('model_lab_baseline_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AiThemeTokens.cardSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiThemeTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '4. So Sánh Với Các Mô Hình Cơ Sở (Baselines)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AiThemeTokens.textPrimary(context),
            ),
          ),
          const SizedBox(height: 10),
          _BaselineRow(
            title: 'Luôn đoán đúng hạn (Majority Class)',
            acc: _pct(maj.accuracy),
            f1: maj.f1.toStringAsFixed(3),
            auc: maj.rocAuc.toStringAsFixed(3),
            highlight: false,
          ),
          const SizedBox(height: 8),
          _BaselineRow(
            title: 'Công thức cứng US-057 (0.5·OnTime + 0.3·Workload)',
            acc: _pct(form.accuracy),
            f1: form.f1.toStringAsFixed(3),
            auc: form.rocAuc.toStringAsFixed(3),
            highlight: false,
          ),
          const SizedBox(height: 8),
          _BaselineRow(
            title: 'Mô hình học từ dữ liệu (Logistic Regression)',
            acc: _pct(lr.accuracy),
            f1: lr.f1.toStringAsFixed(3),
            auc: lr.rocAuc.toStringAsFixed(3),
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _BaselineRow extends StatelessWidget {
  final String title;
  final String acc;
  final String f1;
  final String auc;
  final bool highlight;

  const _BaselineRow({
    required this.title,
    required this.acc,
    required this.f1,
    required this.auc,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AiThemeTokens.primary(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight
            ? primary.withValues(alpha: 0.08)
            : AiThemeTokens.cardSubtleSurface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? primary : AiThemeTokens.border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AiThemeTokens.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Acc: $acc',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: highlight
                      ? primary
                      : AiThemeTokens.textSecondary(context),
                ),
              ),
              Text(
                'F1: $f1',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: highlight
                      ? primary
                      : AiThemeTokens.textSecondary(context),
                ),
              ),
              Text(
                'ROC-AUC: $auc',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: highlight
                      ? primary
                      : AiThemeTokens.textSecondary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureImportanceCard extends StatelessWidget {
  final TrainedRiskModelArtifact artifact;

  const _FeatureImportanceCard({required this.artifact});

  @override
  Widget build(BuildContext context) {
    final weights = artifact.model.weights;
    final defs = TaskFeatureSpec.definitions;
    final maxAbsWeight = weights.isEmpty
        ? 1.0
        : max(0.01, weights.map((w) => w.abs()).reduce(max));

    final indexed = List<int>.generate(
      min(weights.length, defs.length),
      (i) => i,
    )..sort((a, b) => weights[b].abs().compareTo(weights[a].abs()));

    return Container(
      key: const Key('model_lab_feature_importance_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AiThemeTokens.cardSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiThemeTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '5. Độ Quan Trọng Đặc Trưng (|Trọng Số Chuẩn Hoá w_j|)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AiThemeTokens.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dấu (+) làm tăng xác suất trễ hạn · Dấu (−) làm giảm xác suất trễ hạn',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AiThemeTokens.textSecondary(context),
            ),
          ),
          const SizedBox(height: 12),
          ...indexed.map((idx) {
            final w = weights[idx];
            final def = defs[idx];
            final ratio = (w.abs() / maxAbsWeight).clamp(0.0, 1.0);
            final color = w >= 0 ? AppColors.error : AppColors.success;
            final signStr = w >= 0
                ? '+${w.toStringAsFixed(3)}'
                : w.toStringAsFixed(3);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          def.labelVi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AiThemeTokens.textPrimary(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        signStr,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: AiThemeTokens.cardSubtleSurface(context),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _UtilitiesCard extends StatelessWidget {
  final ModelLabState state;

  const _UtilitiesCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final isTraining = state.status == ModelLabStatus.training;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AiThemeTokens.cardSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiThemeTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '6. Tiện Ích Quản Trị Mô Hình',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AiThemeTokens.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                key: const Key('model_lab_copy_json_button'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final jsonStr = context
                      .read<ModelLabCubit>()
                      .exportWeightsJson();
                  await Clipboard.setData(ClipboardData(text: jsonStr));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã sao chép trọng số JSON của mô hình vào bộ nhớ tạm!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                  }
                },
                icon: const Icon(Icons.copy_all_rounded, size: 18),
                label: const Text('Copy Weights JSON'),
              ),
              OutlinedButton.icon(
                key: const Key('model_lab_reset_button'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isTraining
                    ? null
                    : () => context.read<ModelLabCubit>().resetToDefaultModel(),
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('Đặt lại mô hình mặc định'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
