import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/domain/ai/core/ai_training_pipeline.dart';
import 'package:scrumflow/domain/ai/core/explainer.dart';
import 'package:scrumflow/domain/ai/core/feature_spec.dart';
import 'package:scrumflow/domain/ai/core/sprint_forecast_engine.dart';
import 'package:scrumflow/domain/ai/core/synthetic_history_generator.dart';

/// Kiểm thử bất biến ngẫu nhiên có seed (`ai_invariants_test.dart` — mục 4.13 MASTER_PROMPT).
///
/// Chạy ≥ 500 kịch bản ngẫu nhiên có seed (in rõ `seed` khi thất bại):
/// 1. Xác suất dự đoán luôn thuộc `[0.0, 1.0]`, không bao giờ `NaN` hay `Infinite`.
/// 2. Đầu vào cực đoan (`±1e9`, `NaN`, `Infinity`) không gây crash hay `NaN`.
/// 3. Tính đơn điệu (Monotonicity): khi tăng đặc trưng thứ `j` theo chiều dấu trọng số `w_j`,
///    xác suất dự đoán không bao giờ giảm.
/// 4. Bất biến giải thích: `sum(w_j * z_j) + bias == logit`.
/// 5. Bất biến Monte Carlo (`SprintForecastEngine`): xác suất `∈ [0, 1]`, `p10 <= p50 <= p90`,
///    đơn điệu theo khối lượng còn lại và số ngày còn lại.
void main() {
  late final TrainedRiskModelArtifact trainedArtifact;

  setUpAll(() {
    const gen = SyntheticHistoryGenerator();
    final trainDs = gen.generate(count: 400, rng: Random(42));
    final testDs = gen.generate(count: 100, rng: Random(2026));
    trainedArtifact = AiTrainingPipeline.trainAndEvaluate(
      trainPool: trainDs,
      holdoutTest: testDs,
      rng: Random(42),
      epochs: 60,
    );
  });

  test(
    '600 kịch bản ngẫu nhiên có seed: xác suất hợp lệ, đơn điệu theo trọng số, không NaN/crash',
    () {
      const int numScenarios = 600;
      final model = trainedArtifact.model;
      final std = trainedArtifact.standardizer;
      final weights = model.weights;

      for (int scenario = 0; scenario < numScenarios; scenario++) {
        final seed = 100000 + scenario;
        final rng = Random(seed);

        // Sinh vector đặc trưng ngẫu nhiên (xen kẽ cả giá trị bình thường và giá trị biên cực đoan)
        final rawFeatures = List<double>.generate(
          TaskFeatureSpec.featureCount,
          (j) {
            if (scenario % 25 == 0 &&
                j == scenario % TaskFeatureSpec.featureCount) {
              // Chèn các giá trị cực đoan định kỳ để kiểm tra độ bền
              const extremes = [
                1e9,
                -1e9,
                0.0,
                double.nan,
                double.infinity,
                double.negativeInfinity,
              ];
              return extremes[rng.nextInt(extremes.length)];
            }
            final def = TaskFeatureSpec.definitions[j];
            final span = def.maxValue - def.minValue;
            return def.minValue - 0.5 * span + rng.nextDouble() * (2.0 * span);
          },
        );

        final z = std.transform(rawFeatures);
        final prob = model.predictProba(z);

        expect(
          prob.isNaN || prob.isInfinite,
          isFalse,
          reason: 'Seed $seed: xác suất bị NaN/Infinite ($prob)',
        );
        expect(
          prob,
          inInclusiveRange(0.0, 1.0),
          reason: 'Seed $seed: xác suất nằm ngoài [0, 1] ($prob)',
        );

        // Kiểm tra bất biến Explainer: sum(contributions) + bias == logit
        final explanation = Explainer.explain(
          model: model,
          standardizer: std,
          rawFeatures: rawFeatures,
        );
        final sumContrib = explanation.contributions.fold<double>(
          0.0,
          (acc, c) => acc + c.contribution,
        );
        expect(
          (sumContrib + explanation.bias).clamp(-500.0, 500.0),
          closeTo(explanation.logit, 1e-8),
          reason: 'Seed $seed: tổng đóng góp + bias không khớp logit',
        );

        // Kiểm tra tính đơn điệu theo dấu trọng số trên các đặc trưng hữu hạn không bị kẹp biên
        final cleanFeatures = List<double>.generate(
          TaskFeatureSpec.featureCount,
          (j) => std.means[j] + (rng.nextDouble() - 0.5) * std.stds[j],
        );
        final baseZ = std.transform(cleanFeatures);
        final baseProb = model.predictProba(baseZ);

        final featureIdx = scenario % TaskFeatureSpec.featureCount;
        final wj = weights[featureIdx];
        if (wj.abs() > 1e-6 && std.stds[featureIdx] > 1e-6) {
          final shiftedFeatures = List<double>.from(cleanFeatures);
          final direction = wj > 0 ? 1.0 : -1.0;
          shiftedFeatures[featureIdx] += direction * std.stds[featureIdx] * 0.5;
          final shiftedProb = model.predictProba(
            std.transform(shiftedFeatures),
          );

          expect(
            shiftedProb + 1e-12,
            greaterThanOrEqualTo(baseProb),
            reason:
                'Seed $seed: vi phạm tính đơn điệu tại feature #$featureIdx (w=$wj)',
          );
        }
      }
    },
  );

  test(
    '100 kịch bản ngẫu nhiên có seed cho SprintForecastEngine (Monte Carlo invariants)',
    () {
      const engine = SprintForecastEngine();

      for (int i = 0; i < 100; i++) {
        final seed = 500000 + i;
        final rng = Random(seed);

        final remaining = (rng.nextInt(40) + 1).toDouble();
        final daysLeft = rng.nextInt(15) + 1;
        final pool = List<double>.generate(
          5,
          (_) => 0.5 + rng.nextDouble() * 3.0,
        );

        final resBase = engine.simulate(
          remainingPoints: remaining,
          daysLeft: daysLeft,
          historicalDailyThroughputs: pool,
          numSimulations: 200,
          rng: Random(seed),
        );

        expect(
          resBase.completionProbability,
          inInclusiveRange(0.0, 1.0),
          reason: 'Seed $seed: xác suất ngoài [0, 1]',
        );
        expect(
          resBase.daysToCompleteP10,
          lessThanOrEqualTo(resBase.daysToCompleteP50),
          reason: 'Seed $seed: p10 > p50',
        );
        expect(
          resBase.daysToCompleteP50,
          lessThanOrEqualTo(resBase.daysToCompleteP90),
          reason: 'Seed $seed: p50 > p90',
        );

        // Cùng seed -> kết quả nhiều việc hơn không bao giờ có xác suất hoàn thành cao hơn
        final resMoreWork = engine.simulate(
          remainingPoints: remaining + 10.0,
          daysLeft: daysLeft,
          historicalDailyThroughputs: pool,
          numSimulations: 200,
          rng: Random(seed),
        );
        expect(
          resMoreWork.completionProbability,
          lessThanOrEqualTo(resBase.completionProbability + 1e-9),
          reason: 'Seed $seed: thêm việc nhưng xác suất hoàn thành lại tăng',
        );

        // Cùng seed -> nhiều ngày hơn không bao giờ có xác suất hoàn thành thấp hơn
        final resMoreDays = engine.simulate(
          remainingPoints: remaining,
          daysLeft: daysLeft + 5,
          historicalDailyThroughputs: pool,
          numSimulations: 200,
          rng: Random(seed),
        );
        expect(
          resMoreDays.completionProbability + 1e-9,
          greaterThanOrEqualTo(resBase.completionProbability),
          reason: 'Seed $seed: thêm ngày nhưng xác suất hoàn thành lại giảm',
        );
      }
    },
  );
}
