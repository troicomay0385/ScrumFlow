import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:scrumflow/domain/ai/core/ai_training_pipeline.dart';
import 'package:scrumflow/domain/ai/core/dataset.dart';
import 'package:scrumflow/domain/ai/core/explainer.dart';
import 'package:scrumflow/domain/ai/core/feature_spec.dart';
import 'package:scrumflow/domain/ai/core/logistic_regression.dart';
import 'package:scrumflow/domain/ai/core/metrics.dart';
import 'package:scrumflow/domain/ai/core/standardizer.dart';
import 'package:scrumflow/domain/ai/core/synthetic_history_generator.dart';

/// CLI đánh giá độc lập mô hình AI Sprint Risk Radar (chạy bằng `dart run tool/ai_eval.dart`).
///
/// Chỉ sử dụng lõi thuần Dart trong `package:scrumflow/domain/ai/core/...`.
/// Xuất báo cáo ra console, `docs/ai/EVAL_REPORT.md` và `docs/ai/eval.json`.
void main() {
  const int trainSeed = 42;
  const int holdoutTestSeed =
      2026; // Seed tập test tách biệt hoàn toàn với seed huấn luyện
  const int shiftTestSeed = 9001;
  const List<int> multiSeeds = [42, 101, 202, 303, 404];

  const generator = SyntheticHistoryGenerator();

  // 1. Sinh tập huấn luyện (800 mẫu, seed 42) và tập kiểm thử giữ riêng (300 mẫu, seed 2026)
  final trainPool = generator.generate(count: 800, rng: Random(trainSeed));
  final holdoutTest = generator.generate(
    count: 300,
    rng: Random(holdoutTestSeed),
  );

  final primaryArtifact = AiTrainingPipeline.trainAndEvaluate(
    trainPool: trainPool,
    holdoutTest: holdoutTest,
    rng: Random(trainSeed),
    trainedAtIso: '2026-10-22T00:00:00.000Z',
  );

  // 2. Đánh giá qua 5 seed huấn luyện độc lập trên cùng tập holdout test
  final seedAccs = <double>[];
  final seedF1s = <double>[];
  final seedAucs = <double>[];

  for (final s in multiSeeds) {
    final dsTrain = generator.generate(count: 800, rng: Random(s));
    final art = AiTrainingPipeline.trainAndEvaluate(
      trainPool: dsTrain,
      holdoutTest: holdoutTest,
      rng: Random(s),
      trainedAtIso: '2026-10-22T00:00:00.000Z',
    );
    seedAccs.add(art.testMetrics.accuracy);
    seedF1s.add(art.testMetrics.f1);
    seedAucs.add(art.testMetrics.rocAuc);
  }

  final meanAcc = _mean(seedAccs);
  final stdAcc = _std(seedAccs);
  final meanF1 = _mean(seedF1s);
  final stdF1 = _std(seedF1s);
  final meanAuc = _mean(seedAucs);
  final stdAuc = _std(seedAucs);

  // 3. Kiểm chứng chéo 5-Fold (Stratified 5-Fold Cross-Validation) trên tập 800 mẫu
  final folds = trainPool.stratifiedKFold(k: 5, rng: Random(trainSeed));
  final cvAccs = <double>[];
  final cvF1s = <double>[];
  final cvAucs = <double>[];

  for (int i = 0; i < folds.length; i++) {
    final (foldTrain, foldVal) = folds[i];
    final std = Standardizer.fit(foldTrain.featureMatrix);
    final lr = LogisticRegression.initialized(
      dimension: std.dimension,
      rng: Random(trainSeed + i),
    );
    lr.fit(
      trainX: std.transformAll(foldTrain.featureMatrix),
      trainY: foldTrain.labels,
      rng: Random(trainSeed + i),
    );
    final probs = std
        .transformAll(foldVal.featureMatrix)
        .map(lr.predictProba)
        .toList();
    final m = MetricsCalculator.evaluate(
      labels: foldVal.labels,
      probabilities: probs,
    );
    cvAccs.add(m.accuracy);
    cvF1s.add(m.f1);
    cvAucs.add(m.rocAuc);
  }

  // 4. Thí nghiệm Ablation (bỏ từng nhóm đặc trưng)
  final ablationResults = AiTrainingPipeline.runAblationStudy(
    trainPool: trainPool,
    holdoutTest: holdoutTest,
    fullModelMetrics: primaryArtifact.testMetrics,
    baseSeed: trainSeed,
  );

  // 5. Đánh giá dưới điều kiện Distribution Shift (áp lực cao, hạn ngắn, tải cao)
  final shiftedTest = generator.generate(
    count: 300,
    rng: Random(shiftTestSeed),
    shift: DistributionShiftConfig.highPressureShift,
  );
  final shiftedXNorm = primaryArtifact.standardizer.transformAll(
    shiftedTest.featureMatrix,
  );
  final shiftedProbs = shiftedXNorm
      .map(primaryArtifact.model.predictProba)
      .toList();
  final shiftedMetrics = MetricsCalculator.evaluate(
    labels: shiftedTest.labels,
    probabilities: shiftedProbs,
  );

  // 6. Kiểm tra ví dụ giải thích (Explainer)
  final sampleExplanation = Explainer.explain(
    model: primaryArtifact.model,
    standardizer: primaryArtifact.standardizer,
    rawFeatures: holdoutTest.samples.first.features,
  );

  // 7. Kiểm tra các ngưỡng chấp nhận (Mục 5 MASTER_PROMPT)
  final mTest = primaryArtifact.testMetrics;
  final mBaseA = primaryArtifact.majorityBaselineMetrics;
  final mBaseB = primaryArtifact.formulaBaselineMetrics;

  final passRocAuc = mTest.rocAuc >= 0.75;
  final passAccVsBaseA = mTest.accuracy >= (mBaseA.accuracy + 0.05);
  final passVsBaseB = (mTest.rocAuc > mBaseB.rocAuc) || (mTest.f1 > mBaseB.f1);
  final passStdAuc = stdAuc <= 0.03;
  final passNotOverlyEasy = mTest.accuracy < 0.97;

  final allThresholdsPassed =
      passRocAuc &&
      passAccVsBaseA &&
      passVsBaseB &&
      passStdAuc &&
      passNotOverlyEasy;

  // Chuẩn bị dữ liệu JSON
  final evalJson = <String, dynamic>{
    'dataset': {
      'trainSeed': trainSeed,
      'holdoutTestSeed': holdoutTestSeed,
      'trainSize': trainPool.length,
      'trainPositiveCount': trainPool.positiveCount,
      'trainPositiveRatio': trainPool.positiveRatio,
      'holdoutTestSize': holdoutTest.length,
      'holdoutPositiveCount': holdoutTest.positiveCount,
      'holdoutPositiveRatio': holdoutTest.positiveRatio,
      'source': SampleSource.synthetic.name,
    },
    'training': {
      'epochsRun': primaryArtifact.history.epochsRun,
      'bestEpoch': primaryArtifact.history.bestEpoch,
      'stoppedEarly': primaryArtifact.history.stoppedEarly,
      'initialLoss': primaryArtifact.history.initialLoss,
      'finalLoss': primaryArtifact.history.finalLoss,
      'bestValLoss': primaryArtifact.history.bestValLoss,
      'weights': primaryArtifact.model.weights,
      'bias': primaryArtifact.model.bias,
      'featureKeys': TaskFeatureSpec.keys,
    },
    'holdoutComparison': {
      'logisticRegression': mTest.toJson(),
      'baselineMajority': mBaseA.toJson(),
      'baselineUs058Formula': mBaseB.toJson(),
    },
    'multiSeed5': {
      'seeds': multiSeeds,
      'accuracyMean': meanAcc,
      'accuracyStd': stdAcc,
      'f1Mean': meanF1,
      'f1Std': stdF1,
      'rocAucMean': meanAuc,
      'rocAucStd': stdAuc,
    },
    'crossValidation5Fold': {
      'accuracyMean': _mean(cvAccs),
      'accuracyStd': _std(cvAccs),
      'f1Mean': _mean(cvF1s),
      'f1Std': _std(cvF1s),
      'rocAucMean': _mean(cvAucs),
      'rocAucStd': _std(cvAucs),
    },
    'ablation': ablationResults.map((a) => a.toJson()).toList(),
    'distributionShift': {
      'testSize': shiftedTest.length,
      'positiveRatio': shiftedTest.positiveRatio,
      'metrics': shiftedMetrics.toJson(),
    },
    'acceptanceGates': {
      'rocAucGe075': passRocAuc,
      'accGeBaseAPlus5Pct': passAccVsBaseA,
      'aucOrF1GtBaseB': passVsBaseB,
      'aucStdLe003': passStdAuc,
      'accLt097Realistic': passNotOverlyEasy,
      'allPassed': allThresholdsPassed,
    },
  };

  final markdownReport = _buildMarkdownReport(
    trainPool: trainPool,
    holdoutTest: holdoutTest,
    artifact: primaryArtifact,
    multiSeeds: multiSeeds,
    meanAcc: meanAcc,
    stdAcc: stdAcc,
    meanF1: meanF1,
    stdF1: stdF1,
    meanAuc: meanAuc,
    stdAuc: stdAuc,
    cvAccMean: _mean(cvAccs),
    cvAccStd: _std(cvAccs),
    cvF1Mean: _mean(cvF1s),
    cvF1Std: _std(cvF1s),
    cvAucMean: _mean(cvAucs),
    cvAucStd: _std(cvAucs),
    ablationResults: ablationResults,
    shiftedTest: shiftedTest,
    shiftedMetrics: shiftedMetrics,
    sampleExplanation: sampleExplanation,
    passRocAuc: passRocAuc,
    passAccVsBaseA: passAccVsBaseA,
    passVsBaseB: passVsBaseB,
    passStdAuc: passStdAuc,
    passNotOverlyEasy: passNotOverlyEasy,
    allThresholdsPassed: allThresholdsPassed,
  );

  final docsDir = Directory('docs/ai');
  if (!docsDir.existsSync()) {
    docsDir.createSync(recursive: true);
  }
  File(
    'docs/ai/eval.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(evalJson));
  File('docs/ai/EVAL_REPORT.md').writeAsStringSync(markdownReport);

  stdout.writeln('==========================================================');
  stdout.writeln('  SCRUMFLOW AI SPRINT RISK RADAR — EVALUATION SUMMARY');
  stdout.writeln('==========================================================');
  stdout.writeln(
    'Train Pool: ${trainPool.length} samples (pos=${_pct(trainPool.positiveRatio)}) | '
    'Holdout Test: ${holdoutTest.length} samples (pos=${_pct(holdoutTest.positiveRatio)})',
  );
  stdout.writeln(
    'Loss: ${_fmt4(primaryArtifact.history.initialLoss)} -> '
    '${_fmt4(primaryArtifact.history.finalLoss)} '
    '(${primaryArtifact.history.epochsRun} epochs, bestEpoch=${primaryArtifact.history.bestEpoch})',
  );
  stdout.writeln('----------------------------------------------------------');
  stdout.writeln(
    'Model (Logistic Regression) : '
    'Acc=${_pct(mTest.accuracy)} | F1=${_fmt4(mTest.f1)} | AUC=${_fmt4(mTest.rocAuc)} | Brier=${_fmt4(mTest.brierScore)}',
  );
  stdout.writeln(
    'Baseline (a) Majority Class : '
    'Acc=${_pct(mBaseA.accuracy)} | F1=${_fmt4(mBaseA.f1)} | AUC=${_fmt4(mBaseA.rocAuc)} | Brier=${_fmt4(mBaseA.brierScore)}',
  );
  stdout.writeln(
    'Baseline (b) US-058 Formula : '
    'Acc=${_pct(mBaseB.accuracy)} | F1=${_fmt4(mBaseB.f1)} | AUC=${_fmt4(mBaseB.rocAuc)} | Brier=${_fmt4(mBaseB.brierScore)}',
  );
  stdout.writeln('----------------------------------------------------------');
  stdout.writeln(
    '5-Seed Holdout : Acc=${_pct(meanAcc)}±${_pct(stdAcc)} | '
    'F1=${_fmt4(meanF1)}±${_fmt4(stdF1)} | AUC=${_fmt4(meanAuc)}±${_fmt4(stdAuc)}',
  );
  stdout.writeln(
    '5-Fold CV      : Acc=${_pct(_mean(cvAccs))}±${_pct(_std(cvAccs))} | '
    'F1=${_fmt4(_mean(cvF1s))}±${_fmt4(_std(cvF1s))} | AUC=${_fmt4(_mean(cvAucs))}±${_fmt4(_std(cvAucs))}',
  );
  stdout.writeln(
    'Dist. Shift    : Acc=${_pct(shiftedMetrics.accuracy)} | '
    'F1=${_fmt4(shiftedMetrics.f1)} | AUC=${_fmt4(shiftedMetrics.rocAuc)}',
  );
  stdout.writeln('----------------------------------------------------------');
  stdout.writeln('OVERALL GATE   : ${allThresholdsPassed ? "PASS" : "FAIL"}');
  stdout.writeln('==========================================================');

  if (!allThresholdsPassed) {
    exitCode = 1;
  }
}

String _buildMarkdownReport({
  required Dataset trainPool,
  required Dataset holdoutTest,
  required TrainedRiskModelArtifact artifact,
  required List<int> multiSeeds,
  required double meanAcc,
  required double stdAcc,
  required double meanF1,
  required double stdF1,
  required double meanAuc,
  required double stdAuc,
  required double cvAccMean,
  required double cvAccStd,
  required double cvF1Mean,
  required double cvF1Std,
  required double cvAucMean,
  required double cvAucStd,
  required List<AblationResult> ablationResults,
  required Dataset shiftedTest,
  required EvaluationMetrics shiftedMetrics,
  required PredictionExplanation sampleExplanation,
  required bool passRocAuc,
  required bool passAccVsBaseA,
  required bool passVsBaseB,
  required bool passStdAuc,
  required bool passNotOverlyEasy,
  required bool allThresholdsPassed,
}) {
  final mTest = artifact.testMetrics;
  final mBaseA = artifact.majorityBaselineMetrics;
  final mBaseB = artifact.formulaBaselineMetrics;
  final cm = mTest.confusionMatrix;

  final sb = StringBuffer();
  sb.writeln('# BÁO CÁO ĐÁNH GIÁ MÔ HÌNH HỌC MÁY (EVAL_REPORT.md)');
  sb.writeln();
  sb.writeln(
    '> Sinh tự động từ lệnh thực thi thật: `dart run tool/ai_eval.dart`. Toàn bộ dữ liệu khởi tạo mang nhãn `source = synthetic` (có nhiễu thực tế và tương tác phi tuyến).',
  );
  sb.writeln();
  sb.writeln('## 1. Dữ liệu & Huấn luyện');
  sb.writeln(
    '- **Tập huấn luyện (Bootstrap Train Pool, seed `42`):** `${trainPool.length}` mẫu (`${trainPool.positiveCount}` trễ hạn = `${_pct(trainPool.positiveRatio)}`, `${trainPool.negativeCount}` đúng hạn) — tự động chia phân tầng `85% Train / 15% Validation` cho Early Stopping.',
  );
  sb.writeln(
    '- **Tập kiểm thử độc lập (Holdout Test, seed `2026`):** `${holdoutTest.length}` mẫu (`${holdoutTest.positiveCount}` trễ hạn = `${_pct(holdoutTest.positiveRatio)}`, `${holdoutTest.negativeCount}` đúng hạn).',
  );
  sb.writeln(
    '- **Quá trình hội tụ:** Chạy `${artifact.history.epochsRun}` epochs (best epoch = `${artifact.history.bestEpoch}`, dừng sớm = `${artifact.history.stoppedEarly}`).',
  );
  sb.writeln(
    '- **Hàm mất mát (BCE + L2):** Loss đầu = `${_fmt4(artifact.history.initialLoss)}` → Loss cuối = `${_fmt4(artifact.history.finalLoss)}` (Best Val Loss = `${_fmt4(artifact.history.bestValLoss)}`).',
  );
  sb.writeln();

  sb.writeln('## 2. So sánh trên Tập Holdout Test (Seed 2026)');
  sb.writeln();
  sb.writeln(
    '| Mô hình | Accuracy | Precision | Recall | F1-Score | ROC-AUC | Brier Score | ECE |',
  );
  sb.writeln('|---|---:|---:|---:|---:|---:|---:|---:|');
  sb.writeln(
    '| **Baseline (a): Đa số (Majority Class)** | ${_pct(mBaseA.accuracy)} | ${_pct(mBaseA.precision)} | ${_pct(mBaseA.recall)} | ${_fmt4(mBaseA.f1)} | ${_fmt4(mBaseA.rocAuc)} | ${_fmt4(mBaseA.brierScore)} | ${_fmt4(mBaseA.expectedCalibrationError)} |',
  );
  sb.writeln(
    '| **Baseline (b): Công thức cứng US-057/058** | ${_pct(mBaseB.accuracy)} | ${_pct(mBaseB.precision)} | ${_pct(mBaseB.recall)} | ${_fmt4(mBaseB.f1)} | ${_fmt4(mBaseB.rocAuc)} | ${_fmt4(mBaseB.brierScore)} | ${_fmt4(mBaseB.expectedCalibrationError)} |',
  );
  sb.writeln(
    '| **Mô hình học từ dữ liệu (Logistic Regression)** | **${_pct(mTest.accuracy)}** | **${_pct(mTest.precision)}** | **${_pct(mTest.recall)}** | **${_fmt4(mTest.f1)}** | **${_fmt4(mTest.rocAuc)}** | **${_fmt4(mTest.brierScore)}** | **${_fmt4(mTest.expectedCalibrationError)}** |',
  );
  sb.writeln();

  sb.writeln(
    '### Ma trận nhầm lẫn 2×2 (Confusion Matrix — Tập Test, N = ${cm.total})',
  );
  sb.writeln();
  sb.writeln(
    '| Thực tế \\ Dự đoán | Dự đoán Đúng hạn (0) | Dự đoán Trễ hạn (1) |',
  );
  sb.writeln('|---|---:|---:|');
  sb.writeln(
    '| **Thực tế Đúng hạn (0)** | TN = `${cm.tn}` | FP = `${cm.fp}` |',
  );
  sb.writeln('| **Thực tế Trễ hạn (1)** | FN = `${cm.fn}` | TP = `${cm.tp}` |');
  sb.writeln();

  sb.writeln('## 3. Độ ổn định qua 5 Seed & Kiểm chứng chéo 5-Fold CV');
  sb.writeln();
  sb.writeln(
    '| Phương pháp kiểm định | Accuracy (Mean ± Std) | F1-Score (Mean ± Std) | ROC-AUC (Mean ± Std) |',
  );
  sb.writeln('|---|---:|---:|---:|');
  sb.writeln(
    '| **5 Seeds độc lập (`${multiSeeds.join(", ")}`)** | `${_pct(meanAcc)} ± ${_pct(stdAcc)}` | `${_fmt4(meanF1)} ± ${_fmt4(stdF1)}` | `${_fmt4(meanAuc)} ± ${_fmt4(stdAuc)}` |',
  );
  sb.writeln(
    '| **5-Fold Stratified CV (`N = 800`)** | `${_pct(cvAccMean)} ± ${_pct(cvAccStd)}` | `${_fmt4(cvF1Mean)} ± ${_fmt4(cvF1Std)}` | `${_fmt4(cvAucMean)} ± ${_fmt4(cvAucStd)}` |',
  );
  sb.writeln();

  sb.writeln('## 4. Trọng số đã học (Learned Standardized Weights)');
  sb.writeln();
  sb.writeln(
    r'| # | Mã đặc trưng | Nhãn tiếng Việt | Trọng số chuẩn hoá $w_j$ | Tác động |',
  );
  sb.writeln('|---:|---|---|---:|---|');
  for (int j = 0; j < TaskFeatureSpec.definitions.length; j++) {
    final def = TaskFeatureSpec.definitions[j];
    final w = artifact.model.weights[j];
    final effect = w >= 0 ? '↑ Tăng rủi ro trễ' : '↓ Giảm rủi ro trễ';
    sb.writeln(
      '| ${j + 1} | `${def.key}` | ${def.labelVi} | `${w >= 0 ? "+" : ""}${_fmt4(w)}` | $effect |',
    );
  }
  sb.writeln(
    '| - | `bias` | Hệ số chệch (Bias b) | `${_fmt4(artifact.model.bias)}` | - |',
  );
  sb.writeln();

  sb.writeln('## 5. Thí nghiệm Ablation (Loại bỏ từng nhóm đặc trưng)');
  sb.writeln();
  sb.writeln(
    r'| Nhóm đặc trưng bị loại bỏ | Accuracy | F1-Score | ROC-AUC | Mức tụt AUC ($\Delta$AUC) |',
  );
  sb.writeln('|---|---:|---:|---:|---:|');
  for (final ab in ablationResults) {
    sb.writeln(
      '| ${ab.groupName} | ${_pct(ab.metrics.accuracy)} | ${_fmt4(ab.metrics.f1)} | ${_fmt4(ab.metrics.rocAuc)} | `-${_fmt4(ab.aucDrop)}` |',
    );
  }
  sb.writeln();

  sb.writeln('## 6. Bảng Hiệu chỉnh Xác suất 10 Bin (Calibration Table)');
  sb.writeln();
  sb.writeln(
    r'| Bin | Khoảng xác suất | Số mẫu | Xác suất dự đoán TB | Tỷ lệ trễ thực tế | Độ lệch $|\bar{p} - \bar{y}|$ |',
  );
  sb.writeln('|---:|---|---:|---:|---:|---:|');
  for (final bin in mTest.calibrationBins) {
    sb.writeln(
      '| ${bin.binIndex + 1} | `[${bin.lowerBound.toStringAsFixed(1)}, ${bin.upperBound.toStringAsFixed(1)})` | ${bin.count} | ${_pct(bin.meanPredicted)} | ${_pct(bin.fractionPositive)} | ${_pct(bin.calibrationGap)} |',
    );
  }
  sb.writeln();

  sb.writeln('## 7. Đánh giá dưới Distribution Shift (Kịch bản Áp lực cao)');
  sb.writeln(
    '- **Kịch bản lệch phân phối (seed `9001`, N = `${shiftedTest.length}`):** Tải thành viên tăng `+0.25`, thời gian đến deadline co ngắn còn `75%`, tỷ lệ chưa gán `28%` (tỷ lệ trễ thực tế tăng lên `${_pct(shiftedTest.positiveRatio)}`).',
  );
  sb.writeln(
    '- **Kết quả mô hình (không huấn luyện lại):** Accuracy = `${_pct(shiftedMetrics.accuracy)}`, F1 = `${_fmt4(shiftedMetrics.f1)}`, ROC-AUC = `${_fmt4(shiftedMetrics.rocAuc)}`, Brier = `${_fmt4(shiftedMetrics.brierScore)}`.',
  );
  sb.writeln();

  sb.writeln('## 8. Ví dụ Giải thích Dự đoán (Explainer Sample)');
  sb.writeln(
    '- **Xác suất dự đoán:** `${sampleExplanation.percentage}%` (`logit = ${_fmt4(sampleExplanation.logit)}`, `bias = ${_fmt4(sampleExplanation.bias)}`).',
  );
  for (final c in sampleExplanation.topContributors) {
    sb.writeln(
      '  - `${c.featureKey}` (${c.labelVi}): giá trị = `${_fmt4(c.rawValue)}`, đóng góp w_j*z_j = `${c.contribution >= 0 ? "+" : ""}${_fmt4(c.contribution)}`.',
    );
  }
  sb.writeln();

  sb.writeln('## 9. Cổng Kiểm tra Ngưỡng Chấp nhận (Mục 5 MASTER_PROMPT)');
  sb.writeln();
  sb.writeln('| Tiêu chí | Yêu cầu | Kết quả đo thật | Trạng thái |');
  sb.writeln('|---|---|---|---|');
  sb.writeln(
    '| ROC-AUC trên tập test riêng | `>= 0.7500` | `${_fmt4(mTest.rocAuc)}` | ${passRocAuc ? "PASS" : "FAIL"} |',
  );
  sb.writeln(
    '| Accuracy vượt Baseline (a) >= 5% | `>= ${_pct(mBaseA.accuracy + 0.05)}` | `${_pct(mTest.accuracy)}` | ${passAccVsBaseA ? "PASS" : "FAIL"} |',
  );
  sb.writeln(
    '| AUC hoặc F1 vượt Baseline (b) US-058 | `> ${_fmt4(mBaseB.rocAuc)} (AUC)` | `${_fmt4(mTest.rocAuc)} (AUC) / ${_fmt4(mTest.f1)} (F1)` | ${passVsBaseB ? "PASS" : "FAIL"} |',
  );
  sb.writeln(
    '| Độ lệch chuẩn AUC qua 5 seed | `<= 0.0300` | `${_fmt4(stdAuc)}` | ${passStdAuc ? "PASS" : "FAIL"} |',
  );
  sb.writeln(
    '| Độ chính xác thực tế (< 97%) | `< 97.0%` | `${_pct(mTest.accuracy)}` | ${passNotOverlyEasy ? "PASS" : "FAIL"} |',
  );
  sb.writeln();
  sb.writeln(
    '**KẾT LUẬN CỔNG KIỂM TRA:** **${allThresholdsPassed ? "ĐẠT TẤT CẢ TIÊU CHÍ (PASS)" : "KHÔNG ĐẠT (FAIL)"}**',
  );

  return sb.toString();
}

double _mean(List<double> values) {
  if (values.isEmpty) return 0.0;
  return values.fold<double>(0.0, (a, b) => a + b) / values.length;
}

double _std(List<double> values) {
  if (values.length <= 1) return 0.0;
  final m = _mean(values);
  double sumSq = 0.0;
  for (final v in values) {
    final d = v - m;
    sumSq += d * d;
  }
  return sqrt(sumSq / values.length);
}

String _fmt4(double v) => v.toStringAsFixed(4);
String _pct(double v) => '${(v * 100.0).toStringAsFixed(2)}%';
