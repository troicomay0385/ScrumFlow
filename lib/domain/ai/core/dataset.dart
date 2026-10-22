import 'dart:math';

import 'feature_spec.dart';

/// Nguồn gốc của mẫu dữ liệu huấn luyện/đánh giá:
/// - [synthetic]: Dữ liệu lịch sử tổng hợp dùng để khởi tạo (bootstrap) mô hình.
/// - [real]: Dữ liệu thực tế trích xuất từ các Task đã hoàn thành trong dự án.
enum SampleSource {
  synthetic,
  real;

  String toJson() => name;

  static SampleSource fromJson(String? value) {
    if (value == SampleSource.real.name) return SampleSource.real;
    return SampleSource.synthetic;
  }
}

/// Một mẫu dữ liệu có nhãn dùng cho huấn luyện và kiểm thử mô hình phân loại nhị phân.
///
/// - [features]: Vector đặc trưng số thực `x ∈ R^d`.
/// - [label]: Nhãn thực tế `y ∈ {0, 1}` (`1` = Trễ hạn / Overdue, `0` = Đúng hạn / On-time).
/// - [source]: Nguồn dữ liệu (`synthetic` hoặc `real`).
class LabeledSample {
  final List<double> features;
  final int label;
  final SampleSource source;
  final String? id;

  LabeledSample({
    required List<double> features,
    required this.label,
    this.source = SampleSource.synthetic,
    this.id,
  }) : assert(label == 0 || label == 1, 'Nhãn phải là 0 hoặc 1'),
       features = List<double>.unmodifiable(features);

  Map<String, dynamic> toJson() => {
    'features': features,
    'label': label,
    'source': source.toJson(),
    if (id != null) 'id': id,
  };

  factory LabeledSample.fromJson(Map<String, dynamic> json) {
    final rawFeatures = (json['features'] as List<dynamic>? ?? const [])
        .map((e) => (e as num).toDouble())
        .toList(growable: false);
    final rawLabel = (json['label'] as num?)?.toInt() ?? 0;
    return LabeledSample(
      features: rawFeatures,
      label: rawLabel == 1 ? 1 : 0,
      source: SampleSource.fromJson(json['source'] as String?),
      id: json['id'] as String?,
    );
  }
}

/// Tập dữ liệu học máy hỗ trợ chia train/test phân tầng (stratified split)
/// và kiểm chứng chéo k-fold (stratified k-fold cross-validation).
class Dataset {
  final List<LabeledSample> samples;
  final List<String> featureNames;

  Dataset({required List<LabeledSample> samples, List<String>? featureNames})
    : samples = List<LabeledSample>.unmodifiable(samples),
      featureNames = List<String>.unmodifiable(
        featureNames ?? TaskFeatureSpec.keys,
      );

  bool get isEmpty => samples.isEmpty;
  int get length => samples.length;

  int get featureCount =>
      samples.isNotEmpty ? samples.first.features.length : featureNames.length;

  /// Số lượng mẫu có nhãn `1` (trễ hạn).
  int get positiveCount => samples.where((s) => s.label == 1).length;

  /// Số lượng mẫu có nhãn `0` (đúng hạn).
  int get negativeCount => samples.length - positiveCount;

  /// Tỷ lệ mẫu dương tính (trễ hạn) trong tập dữ liệu.
  double get positiveRatio =>
      samples.isEmpty ? 0.0 : positiveCount / samples.length;

  /// Số lượng mẫu khởi tạo tổng hợp (`synthetic`).
  int get syntheticCount =>
      samples.where((s) => s.source == SampleSource.synthetic).length;

  /// Số lượng mẫu thực tế từ dự án (`real`).
  int get realCount =>
      samples.where((s) => s.source == SampleSource.real).length;

  List<List<double>> get featureMatrix =>
      samples.map((s) => s.features).toList(growable: false);

  List<int> get labels => samples.map((s) => s.label).toList(growable: false);

  /// Chia tập dữ liệu thành `(train, test)` theo phương pháp phân tầng (stratified),
  /// đảm bảo tỷ lệ nhãn 0/1 ở cả hai tập tương đương nhau.
  (Dataset train, Dataset test) stratifiedSplit({
    double testRatio = 0.2,
    required Random rng,
  }) {
    if (samples.isEmpty) {
      return (
        Dataset(samples: const [], featureNames: featureNames),
        Dataset(samples: const [], featureNames: featureNames),
      );
    }

    final clampedRatio = testRatio.clamp(0.0, 0.9);
    final positives = samples.where((s) => s.label == 1).toList()..shuffle(rng);
    final negatives = samples.where((s) => s.label == 0).toList()..shuffle(rng);

    final posTestCount = (positives.length * clampedRatio).round();
    final negTestCount = (negatives.length * clampedRatio).round();

    final testSamples = <LabeledSample>[
      ...positives.take(posTestCount),
      ...negatives.take(negTestCount),
    ]..shuffle(rng);

    final trainSamples = <LabeledSample>[
      ...positives.skip(posTestCount),
      ...negatives.skip(negTestCount),
    ]..shuffle(rng);

    return (
      Dataset(samples: trainSamples, featureNames: featureNames),
      Dataset(samples: testSamples, featureNames: featureNames),
    );
  }

  /// Tạo danh sách `k` cặp `(train, val)` phục vụ kiểm chứng chéo phân tầng
  /// (Stratified K-Fold Cross-Validation).
  List<(Dataset train, Dataset val)> stratifiedKFold({
    int k = 5,
    required Random rng,
  }) {
    final safeK = max(2, k);
    if (samples.length < safeK) {
      return [(this, this)];
    }

    final positives = samples.where((s) => s.label == 1).toList()..shuffle(rng);
    final negatives = samples.where((s) => s.label == 0).toList()..shuffle(rng);

    final buckets = List<List<LabeledSample>>.generate(safeK, (_) => []);
    for (int i = 0; i < positives.length; i++) {
      buckets[i % safeK].add(positives[i]);
    }
    for (int i = 0; i < negatives.length; i++) {
      buckets[i % safeK].add(negatives[i]);
    }

    final folds = <(Dataset, Dataset)>[];
    for (int fold = 0; fold < safeK; fold++) {
      final valSamples = List<LabeledSample>.from(buckets[fold]);
      final trainSamples = <LabeledSample>[];
      for (int j = 0; j < safeK; j++) {
        if (j != fold) {
          trainSamples.addAll(buckets[j]);
        }
      }
      folds.add((
        Dataset(samples: trainSamples, featureNames: featureNames),
        Dataset(samples: valSamples, featureNames: featureNames),
      ));
    }
    return folds;
  }
}
