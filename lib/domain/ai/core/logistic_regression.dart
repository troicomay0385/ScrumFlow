import 'dart:math';

/// Lịch sử quá trình huấn luyện của mô hình [LogisticRegression].
class TrainingHistory {
  final List<double> trainLosses;
  final List<double> valLosses;
  final int epochsRun;
  final int bestEpoch;
  final bool stoppedEarly;

  TrainingHistory({
    required List<double> trainLosses,
    required List<double> valLosses,
    required this.epochsRun,
    required this.bestEpoch,
    required this.stoppedEarly,
  }) : trainLosses = List<double>.unmodifiable(trainLosses),
       valLosses = List<double>.unmodifiable(valLosses);

  double get initialLoss => trainLosses.isNotEmpty ? trainLosses.first : 0.0;
  double get finalLoss => trainLosses.isNotEmpty ? trainLosses.last : 0.0;
  double get bestValLoss => valLosses.isNotEmpty && bestEpoch < valLosses.length
      ? valLosses[bestEpoch]
      : finalLoss;

  Map<String, dynamic> toJson() => {
    'trainLosses': trainLosses,
    'valLosses': valLosses,
    'epochsRun': epochsRun,
    'bestEpoch': bestEpoch,
    'stoppedEarly': stoppedEarly,
  };

  factory TrainingHistory.fromJson(Map<String, dynamic> json) {
    final train = (json['trainLosses'] as List<dynamic>? ?? const [])
        .map((e) => (e as num).toDouble())
        .toList();
    final val = (json['valLosses'] as List<dynamic>? ?? const [])
        .map((e) => (e as num).toDouble())
        .toList();
    return TrainingHistory(
      trainLosses: train,
      valLosses: val,
      epochsRun: (json['epochsRun'] as num?)?.toInt() ?? train.length,
      bestEpoch: (json['bestEpoch'] as num?)?.toInt() ?? 0,
      stoppedEarly: json['stoppedEarly'] as bool? ?? false,
    );
  }
}

/// Mô hình Hồi quy Logistic (Logistic Regression) tự xây dựng thuần Dart
/// dùng cho bài toán phân loại nhị phân dự đoán xác suất trễ hạn của Task (US-069).
///
/// ### Công thức toán học cốt lõi:
/// 1. **Tổ hợp tuyến tính (Logit):**
///    $$z = \mathbf{w} \cdot \mathbf{z}_{norm} + b = \sum_{j=1}^{d} w_j z_j + b$$
///    Trong đó $\mathbf{z}_{norm}$ là vector đặc trưng đã chuẩn hoá Z-score,
///    $\mathbf{w}$ là vector trọng số được học, $b$ là độ lệch (bias).
///
/// 2. **Hàm kích hoạt Sigmoid (ổn định số học):**
///    $$p = \sigma(z) = \frac{1}{1 + e^{-z}}$$
///    Để chống tràn số học (`exp` với $\pm 10^6$), cài đặt tách nhánh:
///    - Nếu $z \ge 0$: $\sigma(z) = \frac{1}{1 + e^{-z}}$
///    - Nếu $z < 0$: $\sigma(z) = \frac{e^{z}}{1 + e^{z}}$
///
/// 3. **Hàm mất mát Binary Cross-Entropy (BCE) có trọng số lớp & điều chuẩn L2:**
///    $$\mathcal{L}(\mathbf{w}, b) = -\frac{1}{N} \sum_{i=1}^{N} \alpha_{y_i} \left[ y_i \ln(\hat{p}_i) + (1 - y_i)\ln(1 - \hat{p}_i) \right] + \frac{\lambda}{2} \sum_{j=1}^{d} w_j^2$$
///    Trong đó $\alpha_{1}, \alpha_{0}$ là trọng số cân bằng lớp (`class_weight`),
///    $\lambda$ là hệ số điều chuẩn L2 (`l2Lambda`) chống quá khớp (overfitting).
///
/// 4. **Đạo hàm riêng (Gradient) trên mini-batch kích thước $B$:**
///    $$\frac{\partial \mathcal{L}}{\partial w_j} = \frac{1}{B} \sum_{i=1}^{B} \alpha_{y_i} (\hat{p}_i - y_i) z_{i,j} + \lambda w_j$$
///    $$\frac{\partial \mathcal{L}}{\partial b} = \frac{1}{B} \sum_{i=1}^{B} \alpha_{y_i} (\hat{p}_i - y_i)$$
///    Cập nhật tham số ngược chiều gradient với tốc độ học $\eta$ (`learningRate`):
///    $$w_j \leftarrow w_j - \eta \frac{\partial \mathcal{L}}{\partial w_j}, \quad b \leftarrow b - \eta \frac{\partial \mathcal{L}}{\partial b}$$
class LogisticRegression {
  static const int currentSchemaVersion = 1;
  static const double _eps = 1e-12;

  List<double> _weights;
  double _bias;

  LogisticRegression({required List<double> weights, required double bias})
    : _weights = List<double>.from(weights),
      _bias = bias + 0.0;

  /// Khởi tạo mô hình chưa huấn luyện với trọng số nhỏ ngẫu nhiên quanh 0.
  factory LogisticRegression.initialized({
    required int dimension,
    required Random rng,
    double initScale = 0.01,
  }) {
    final w = List<double>.generate(
      dimension,
      (_) => (rng.nextDouble() * 2.0 - 1.0) * initScale,
    );
    return LogisticRegression(weights: w, bias: 0.0);
  }

  List<double> get weights => List<double>.unmodifiable(_weights);
  double get bias => _bias;
  int get dimension => _weights.length;

  /// Hàm Sigmoid ổn định số học: $\sigma(z) = \frac{1}{1 + e^{-z}}$.
  ///
  /// Không bao giờ trả về `NaN` hay `Infinity` ngay cả với $z = \pm 10^6$.
  static double sigmoid(double z) {
    if (z.isNaN) return 0.5;
    if (z >= 500.0) return 1.0;
    if (z <= -500.0) return 0.0;
    if (z >= 0.0) {
      return 1.0 / (1.0 + exp(-z));
    } else {
      final ez = exp(z);
      return ez / (1.0 + ez);
    }
  }

  /// Tính giá trị tổ hợp tuyến tính $z = \mathbf{w} \cdot \mathbf{z} + b$.
  double logit(List<double> standardizedFeatures) {
    double sum = _bias;
    final len = min(_weights.length, standardizedFeatures.length);
    for (int j = 0; j < len; j++) {
      final xj = standardizedFeatures[j];
      if (!xj.isNaN && !xj.isInfinite) {
        sum += _weights[j] * xj;
      }
    }
    return sum.isNaN ? 0.0 : sum.clamp(-500.0, 500.0);
  }

  /// Dự đoán xác suất lớp dương (`label = 1`, tức Task bị trễ hạn):
  /// $p = \sigma(\mathbf{w} \cdot \mathbf{z} + b) \in [0, 1]$.
  double predictProba(List<double> standardizedFeatures) {
    return sigmoid(logit(standardizedFeatures));
  }

  /// Dự đoán nhãn phân loại `0` hoặc `1` theo ngưỡng [threshold] (mặc định 0.5).
  int predictClass(
    List<double> standardizedFeatures, {
    double threshold = 0.5,
  }) {
    return predictProba(standardizedFeatures) >= threshold ? 1 : 0;
  }

  /// Tính hàm mất mát Binary Cross-Entropy kèm điều chuẩn L2 trên tập dữ liệu.
  double computeLoss(
    List<List<double>> X,
    List<int> y, {
    double l2Lambda = 0.01,
    double posWeight = 1.0,
    double negWeight = 1.0,
  }) {
    if (X.isEmpty || y.isEmpty) return 0.0;
    final n = min(X.length, y.length);
    double dataLoss = 0.0;

    for (int i = 0; i < n; i++) {
      final p = predictProba(X[i]).clamp(_eps, 1.0 - _eps);
      final yi = y[i];
      if (yi == 1) {
        dataLoss -= posWeight * log(p);
      } else {
        dataLoss -= negWeight * log(1.0 - p);
      }
    }
    dataLoss /= n;

    double l2Sum = 0.0;
    for (final w in _weights) {
      l2Sum += w * w;
    }
    return dataLoss + 0.5 * l2Lambda * l2Sum;
  }

  /// Tính đạo hàm giải tích `(gradW, gradB)` của hàm mất mát trên tập `(X, y)`.
  /// Dùng trong huấn luyện và dùng để kiểm chứng với sai phân hữu hạn trong unit test.
  (List<double> gradW, double gradB) computeAnalyticalGradient(
    List<List<double>> X,
    List<int> y, {
    double l2Lambda = 0.01,
    double posWeight = 1.0,
    double negWeight = 1.0,
  }) {
    final dim = _weights.length;
    final gradW = List<double>.filled(dim, 0.0);
    double gradB = 0.0;
    if (X.isEmpty || y.isEmpty) return (gradW, gradB);

    final n = min(X.length, y.length);
    for (int i = 0; i < n; i++) {
      final p = predictProba(X[i]);
      final yi = y[i];
      final sampleWeight = yi == 1 ? posWeight : negWeight;
      // Sai số có trọng số: (p - y) * alpha_y
      final diff = sampleWeight * (p - yi);
      gradB += diff;
      final xi = X[i];
      final len = min(dim, xi.length);
      for (int j = 0; j < len; j++) {
        gradW[j] += diff * xi[j];
      }
    }

    for (int j = 0; j < dim; j++) {
      gradW[j] = (gradW[j] / n) + l2Lambda * _weights[j];
    }
    gradB /= n;
    return (gradW, gradB);
  }

  /// Tính đạo hàm xấp xỉ số học bằng phương pháp sai phân hữu hạn trung tâm:
  /// $$\frac{\partial \mathcal{L}}{\partial \theta} \approx \frac{\mathcal{L}(\theta + \epsilon) - \mathcal{L}(\theta - \epsilon)}{2\epsilon}$$
  /// Chỉ dùng trong unit test để chứng minh công thức đạo hàm giải tích chính xác.
  (List<double> gradW, double gradB) computeNumericalGradient(
    List<List<double>> X,
    List<int> y, {
    double l2Lambda = 0.01,
    double posWeight = 1.0,
    double negWeight = 1.0,
    double epsilon = 1e-5,
  }) {
    final dim = _weights.length;
    final numGradW = List<double>.filled(dim, 0.0);

    for (int j = 0; j < dim; j++) {
      final orig = _weights[j];
      _weights[j] = orig + epsilon;
      final lossPlus = computeLoss(
        X,
        y,
        l2Lambda: l2Lambda,
        posWeight: posWeight,
        negWeight: negWeight,
      );
      _weights[j] = orig - epsilon;
      final lossMinus = computeLoss(
        X,
        y,
        l2Lambda: l2Lambda,
        posWeight: posWeight,
        negWeight: negWeight,
      );
      _weights[j] = orig;
      numGradW[j] = (lossPlus - lossMinus) / (2.0 * epsilon);
    }

    final origBias = _bias;
    _bias = origBias + epsilon;
    final lossBiasPlus = computeLoss(
      X,
      y,
      l2Lambda: l2Lambda,
      posWeight: posWeight,
      negWeight: negWeight,
    );
    _bias = origBias - epsilon;
    final lossBiasMinus = computeLoss(
      X,
      y,
      l2Lambda: l2Lambda,
      posWeight: posWeight,
      negWeight: negWeight,
    );
    _bias = origBias;
    final numGradB = (lossBiasPlus - lossBiasMinus) / (2.0 * epsilon);

    return (numGradW, numGradB);
  }

  /// Huấn luyện mô hình bằng thuật toán Mini-batch Gradient Descent kèm điều chuẩn L2,
  /// cân bằng trọng số lớp (`balancedClassWeight`) và dừng sớm (`earlyStopping`)
  /// theo mất mát trên tập thẩm định (validation loss).
  TrainingHistory fit({
    required List<List<double>> trainX,
    required List<int> trainY,
    List<List<double>>? valX,
    List<int>? valY,
    required Random rng,
    int epochs = 120,
    int batchSize = 32,
    double learningRate = 0.08,
    double l2Lambda = 0.008,
    bool balancedClassWeight = true,
    int patience = 18,
    double minDelta = 1e-4,
    void Function(int epoch, double trainLoss, double valLoss)? onEpochEnd,
  }) {
    if (trainX.isEmpty || trainY.isEmpty) {
      return TrainingHistory(
        trainLosses: const [],
        valLosses: const [],
        epochsRun: 0,
        bestEpoch: 0,
        stoppedEarly: false,
      );
    }

    final n = min(trainX.length, trainY.length);
    final dim = trainX.first.length;
    if (_weights.length != dim) {
      _weights = List<double>.generate(
        dim,
        (_) => (rng.nextDouble() * 2.0 - 1.0) * 0.01,
      );
      _bias = 0.0;
    }

    // Tính trọng số lớp cân bằng nếu được bật: N / (2 * N_c)
    double posWeight = 1.0;
    double negWeight = 1.0;
    if (balancedClassWeight) {
      int posCount = 0;
      for (int i = 0; i < n; i++) {
        if (trainY[i] == 1) posCount++;
      }
      final negCount = n - posCount;
      if (posCount > 0 && negCount > 0) {
        posWeight = n / (2.0 * posCount);
        negWeight = n / (2.0 * negCount);
      }
    }

    final hasValidation =
        valX != null && valY != null && valX.isNotEmpty && valY.isNotEmpty;

    final trainLosses = <double>[];
    final valLosses = <double>[];
    final indices = List<int>.generate(n, (i) => i);
    final safeBatchSize = max(1, min(batchSize, n));

    double bestLoss = double.infinity;
    int bestEpoch = 0;
    int wait = 0;
    bool stoppedEarly = false;
    List<double> bestWeights = List<double>.from(_weights);
    double bestBias = _bias;

    for (int epoch = 0; epoch < epochs; epoch++) {
      indices.shuffle(rng);

      for (int start = 0; start < n; start += safeBatchSize) {
        final end = min(start + safeBatchSize, n);
        final currentBatchSize = end - start;
        final gradW = List<double>.filled(dim, 0.0);
        double gradB = 0.0;

        for (int idx = start; idx < end; idx++) {
          final sampleIdx = indices[idx];
          final xi = trainX[sampleIdx];
          final yi = trainY[sampleIdx];
          final p = predictProba(xi);
          final sw = yi == 1 ? posWeight : negWeight;
          final diff = sw * (p - yi);

          gradB += diff;
          final len = min(dim, xi.length);
          for (int j = 0; j < len; j++) {
            gradW[j] += diff * xi[j];
          }
        }

        // Cập nhật trọng số w và bias b theo công thức Gradient Descent + điều chuẩn L2
        for (int j = 0; j < dim; j++) {
          final g = (gradW[j] / currentBatchSize) + l2Lambda * _weights[j];
          _weights[j] -= learningRate * g;
        }
        _bias -= learningRate * (gradB / currentBatchSize);
      }

      final tLoss = computeLoss(
        trainX,
        trainY,
        l2Lambda: l2Lambda,
        posWeight: posWeight,
        negWeight: negWeight,
      );
      final vLoss = hasValidation
          ? computeLoss(
              valX,
              valY,
              l2Lambda: l2Lambda,
              posWeight: posWeight,
              negWeight: negWeight,
            )
          : tLoss;

      trainLosses.add(tLoss);
      valLosses.add(vLoss);
      onEpochEnd?.call(epoch, tLoss, vLoss);

      if (vLoss < bestLoss - minDelta) {
        bestLoss = vLoss;
        bestEpoch = epoch;
        bestWeights = List<double>.from(_weights);
        bestBias = _bias;
        wait = 0;
      } else {
        wait++;
        if (patience > 0 && wait >= patience) {
          stoppedEarly = true;
          break;
        }
      }
    }

    // Khôi phục bộ trọng số tại epoch tốt nhất trên tập thẩm định
    _weights = bestWeights;
    _bias = bestBias;

    return TrainingHistory(
      trainLosses: trainLosses,
      valLosses: valLosses,
      epochsRun: trainLosses.length,
      bestEpoch: bestEpoch,
      stoppedEarly: stoppedEarly,
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'weights': _weights,
    'bias': _bias,
  };

  factory LogisticRegression.fromJson(Map<String, dynamic> json) {
    final version = (json['schemaVersion'] as num?)?.toInt() ?? 0;
    if (version != currentSchemaVersion) {
      throw FormatException(
        'Phiên bản schema LogisticRegression không tương thích: $version',
      );
    }
    final rawWeights =
        (json['weights'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        const <double>[];
    final rawBias = (json['bias'] as num?)?.toDouble();
    if (rawWeights.isEmpty || rawBias == null || rawBias.isNaN) {
      throw const FormatException(
        'Dữ liệu trọng số LogisticRegression bị hỏng.',
      );
    }
    return LogisticRegression(weights: rawWeights, bias: rawBias);
  }
}
