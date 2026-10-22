import 'dart:math';

import 'feature_spec.dart';
import 'logistic_regression.dart';
import 'standardizer.dart';

/// Mức đóng góp của một đặc trưng đơn lẻ vào dự đoán rủi ro của Task:
/// $$\text{contribution}_j = w_j \cdot z_j$$
///
/// - Nếu $\text{contribution}_j > 0$: Đặc trưng này đang **đẩy rủi ro trễ hạn tăng lên**.
/// - Nếu $\text{contribution}_j < 0$: Đặc trưng này đang **giúp giảm rủi ro trễ hạn**.
class FeatureContribution {
  final int featureIndex;
  final String featureKey;
  final String labelVi;
  final double rawValue;
  final double standardizedValue;
  final double weight;
  final double contribution;

  const FeatureContribution({
    required this.featureIndex,
    required this.featureKey,
    required this.labelVi,
    required this.rawValue,
    required this.standardizedValue,
    required this.weight,
    required this.contribution,
  });

  /// `true` nếu yếu tố này làm tăng nguy cơ trễ hạn (`contribution > 0`).
  bool get isRiskIncreasing => contribution >= 0;

  /// Độ lớn tuyệt đối của đóng góp $|w_j \cdot z_j|$.
  double get magnitude => contribution.abs();
}

/// Kết quả giải thích chi tiết cho một dự đoán của mô hình [LogisticRegression].
///
/// Đảm bảo bất biến toán học:
/// $$\sum_{j=1}^{d} \text{contribution}_j + \text{bias} = \text{logit}$$
class PredictionExplanation {
  final double probability;
  final double logit;
  final double bias;
  final List<FeatureContribution> contributions;
  final List<FeatureContribution> topContributors;

  PredictionExplanation({
    required this.probability,
    required this.logit,
    required this.bias,
    required List<FeatureContribution> contributions,
    required List<FeatureContribution> topContributors,
  }) : contributions = List<FeatureContribution>.unmodifiable(contributions),
       topContributors = List<FeatureContribution>.unmodifiable(
         topContributors,
       );

  RiskLevel get riskLevel => RiskThresholds.classify(probability);
  int get percentage => (probability * 100).round();
}

/// Bộ giải thích dự đoán mô hình tuyến tính (`Explainer` — US-069).
///
/// Tính toán đóng góp $\text{contribution}_j = w_j \cdot z_j$ cho từng đặc trưng,
/// trích xuất Top-K yếu tố ảnh hưởng mạnh nhất kèm nhãn tiếng Việt rõ ràng.
class Explainer {
  Explainer._();

  static PredictionExplanation explain({
    required LogisticRegression model,
    required Standardizer standardizer,
    required List<double> rawFeatures,
    int topK = 3,
    List<FeatureDefinition>? featureDefs,
  }) {
    final defs = featureDefs ?? TaskFeatureSpec.definitions;
    final z = standardizer.transform(rawFeatures);
    final weights = model.weights;
    final dim = min(weights.length, z.length);

    final allContributions = <FeatureContribution>[];
    double sumContributions = 0.0;

    for (int j = 0; j < dim; j++) {
      final wj = weights[j];
      final zj = z[j];
      final c = wj * zj;
      sumContributions += c;

      final def = j < defs.length
          ? defs[j]
          : FeatureDefinition(
              index: j,
              key: 'feature_$j',
              labelVi: 'Đặc trưng #$j',
              descriptionVi: '',
              minValue: 0,
              maxValue: 1,
              defaultCheckpointValue: 0,
            );

      allContributions.add(
        FeatureContribution(
          featureIndex: j,
          featureKey: def.key,
          labelVi: def.labelVi,
          rawValue: j < rawFeatures.length ? rawFeatures[j] : 0.0,
          standardizedValue: zj,
          weight: wj,
          contribution: c,
        ),
      );
    }

    final totalLogit = (sumContributions + model.bias).clamp(-500.0, 500.0);
    final prob = LogisticRegression.sigmoid(totalLogit);

    final sortedByMagnitude = List<FeatureContribution>.from(allContributions)
      ..sort((a, b) => b.magnitude.compareTo(a.magnitude));

    final safeK = max(0, min(topK, sortedByMagnitude.length));
    final topList = sortedByMagnitude.take(safeK).toList(growable: false);

    return PredictionExplanation(
      probability: prob,
      logit: totalLogit,
      bias: model.bias,
      contributions: allContributions,
      topContributors: topList,
    );
  }
}
