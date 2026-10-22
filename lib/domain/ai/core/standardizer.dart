import 'dart:math';

/// Bộ chuẩn hoá đặc trưng Z-score (`Standardizer`):
///
/// Đưa mỗi đặc trưng thứ `j` về phân phối có kỳ vọng bằng 0 và độ lệch chuẩn bằng 1:
/// $$z_j = \frac{x_j - \mu_j}{\sigma_j}$$
///
/// Trong đó:
/// - $\mu_j = \frac{1}{N} \sum_{i=1}^{N} x_{i,j}$ là trung bình mẫu trên tập huấn luyện.
/// - $\sigma_j = \sqrt{\frac{1}{N} \sum_{i=1}^{N} (x_{i,j} - \mu_j)^2}$ là độ lệch chuẩn.
///
/// **An toàn phương sai bằng 0:** Nếu một đặc trưng là hằng số trên tập huấn luyện
/// ($\sigma_j < 10^{-9}$), bộ chuẩn hoá tự động gán $\sigma_j = 1.0$ để tránh chia cho 0
/// (không bao giờ sinh `NaN` hay `Infinity`).
class Standardizer {
  static const int currentSchemaVersion = 1;
  static const double _minStdEpsilon = 1e-9;

  final List<double> means;
  final List<double> stds;

  Standardizer({required List<double> means, required List<double> stds})
    : assert(means.length == stds.length, 'means và stds phải cùng độ dài'),
      means = List<double>.unmodifiable(means),
      stds = List<double>.unmodifiable(
        stds.map(
          (s) =>
              (s.isNaN || s.isInfinite || s.abs() < _minStdEpsilon) ? 1.0 : s,
        ),
      );

  int get dimension => means.length;

  /// Tạo bộ chuẩn hoá mặc định (trung bình = 0, độ lệch chuẩn = 1) cho [dimension] chiều.
  factory Standardizer.identity(int dimension) {
    return Standardizer(
      means: List<double>.filled(dimension, 0.0),
      stds: List<double>.filled(dimension, 1.0),
    );
  }

  /// Ước lượng $\mu_j$ và $\sigma_j$ từ ma trận đặc trưng tập huấn luyện [featureMatrix].
  ///
  /// Lưu ý: Chỉ gọi `fit` trên tập Train, sau đó dùng lại cho tập Validation/Test
  /// để tránh rò rỉ thông tin thống kê (data leakage).
  factory Standardizer.fit(
    List<List<double>> featureMatrix, {
    int defaultDim = 10,
  }) {
    if (featureMatrix.isEmpty || featureMatrix.first.isEmpty) {
      return Standardizer.identity(defaultDim);
    }

    final n = featureMatrix.length;
    final dim = featureMatrix.first.length;
    final means = List<double>.filled(dim, 0.0);
    final stds = List<double>.filled(dim, 1.0);

    for (int j = 0; j < dim; j++) {
      double sum = 0.0;
      for (int i = 0; i < n; i++) {
        final v = featureMatrix[i][j];
        if (!v.isNaN && !v.isInfinite) {
          sum += v;
        }
      }
      final mean = sum / n;
      means[j] = mean;

      double sqDiffSum = 0.0;
      for (int i = 0; i < n; i++) {
        final v = featureMatrix[i][j];
        if (!v.isNaN && !v.isInfinite) {
          final diff = v - mean;
          sqDiffSum += diff * diff;
        }
      }
      final variance = sqDiffSum / n;
      final std = sqrt(max(0.0, variance));
      stds[j] = std < _minStdEpsilon ? 1.0 : std;
    }

    return Standardizer(means: means, stds: stds);
  }

  /// Chuẩn hoá một vector đặc trưng `x` sang `z`.
  /// Nếu một phần tử đầu vào là `NaN` hoặc `Infinite`, trả về `0.0` (tức giá trị trung bình).
  List<double> transform(List<double> features) {
    final dim = means.length;
    final result = List<double>.filled(dim, 0.0);
    final limit = min(dim, features.length);

    for (int j = 0; j < limit; j++) {
      final raw = features[j];
      if (raw.isNaN || raw.isInfinite) {
        result[j] = 0.0;
      } else {
        final z = (raw - means[j]) / stds[j];
        // Kẹp ngưỡng [-20, 20] để tránh tràn số khi suy luận với dữ liệu ngoại lai cực đoan
        result[j] = z.isNaN || z.isInfinite ? 0.0 : z.clamp(-20.0, 20.0);
      }
    }
    return result;
  }

  /// Chuẩn hoá toàn bộ danh sách các vector đặc trưng.
  List<List<double>> transformAll(List<List<double>> featureMatrix) {
    return featureMatrix.map(transform).toList(growable: false);
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'means': means,
    'stds': stds,
  };

  factory Standardizer.fromJson(Map<String, dynamic> json) {
    final rawMeans =
        (json['means'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        const <double>[];
    final rawStds =
        (json['stds'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        const <double>[];
    if (rawMeans.isEmpty || rawMeans.length != rawStds.length) {
      throw const FormatException('Dữ liệu Standardizer JSON không hợp lệ.');
    }
    return Standardizer(means: rawMeans, stds: rawStds);
  }
}
