/// Đặc tả bộ đặc trưng (Feature Specification) và ngưỡng phân loại rủi ro
/// dùng chung cho toàn bộ hệ thống AI Sprint Risk Radar (US-069, US-071).
///
/// Tệp này thuộc tầng lõi thuần Dart (`lib/domain/ai/core/`), chỉ sử dụng
/// thư viện chuẩn `dart:core`.
library;

/// Ngưỡng phân loại mức độ rủi ro trễ hạn của Task (mục 9 MASTER_PROMPT):
/// - Thấp: `< 0.35` (< 35%) → Token màu Done (Xanh ngọc)
/// - Trung bình: `0.35 .. 0.65` (35% – 65%) → Token màu In Progress (Vàng Hổ phách)
/// - Cao: `> 0.65` (> 65%) → Token màu Blocker (Đỏ Thẫm)
class RiskThresholds {
  RiskThresholds._();

  static const double lowMax = 0.35;
  static const double mediumMax = 0.65;

  /// Phân loại xác suất rủi ro `p ∈ [0, 1]` thành nhãn mức độ.
  static RiskLevel classify(double probability) {
    if (probability < lowMax) return RiskLevel.low;
    if (probability <= mediumMax) return RiskLevel.medium;
    return RiskLevel.high;
  }
}

/// Mức độ rủi ro của một Task hoặc Sprint.
enum RiskLevel {
  low,
  medium,
  high;

  String get labelVi {
    switch (this) {
      case RiskLevel.low:
        return 'Rủi ro thấp';
      case RiskLevel.medium:
        return 'Rủi ro TB';
      case RiskLevel.high:
        return 'Rủi ro cao';
    }
  }
}

/// Định nghĩa siêu dữ liệu của 1 đặc trưng đầu vào cho mô hình học máy.
class FeatureDefinition {
  final int index;
  final String key;
  final String labelVi;
  final String descriptionVi;
  final double minValue;
  final double maxValue;

  /// Giá trị checkpoint cố định hoặc mặc định khi thiếu dữ liệu / chống rò rỉ nhãn.
  final double defaultCheckpointValue;

  const FeatureDefinition({
    required this.index,
    required this.key,
    required this.labelVi,
    required this.descriptionVi,
    required this.minValue,
    required this.maxValue,
    required this.defaultCheckpointValue,
  });
}

/// Danh sách 10 đặc trưng chuẩn của mô hình dự đoán trễ hạn Task (US-069).
class TaskFeatureSpec {
  TaskFeatureSpec._();

  static const int featureCount = 10;

  static const int idxStoryPoints = 0;
  static const int idxPriorityRank = 1;
  static const int idxDaysToDeadline = 2;
  static const int idxElapsedRatio = 3;
  static const int idxLoggedHoursPerDay = 4;
  static const int idxStatusProgress = 5;
  static const int idxAssigneeOnTimeRate = 6;
  static const int idxAssigneeWorkload = 7;
  static const int idxSprintElapsedRatio = 8;
  static const int idxUnassigned = 9;

  /// Giả định checkpoint cố định cho các đặc trưng động khi trích xuất mẫu `real`
  /// từ các Task đã `Done` nhằm chống rò rỉ nhãn `updatedAt > deadline` (mục 4.9).
  static const double realCheckpointElapsedRatio = 0.5;
  static const double realCheckpointStatusProgress = 0.5;
  static const double realCheckpointLoggedHoursPerDay = 1.5;

  static const List<FeatureDefinition> definitions = [
    FeatureDefinition(
      index: idxStoryPoints,
      key: 'storyPoints',
      labelVi: 'Điểm phức tạp (Story Points)',
      descriptionVi: 'Điểm ước lượng Fibonacci của User Story cha (1..21).',
      minValue: 1.0,
      maxValue: 21.0,
      defaultCheckpointValue: 3.0,
    ),
    FeatureDefinition(
      index: idxPriorityRank,
      key: 'priorityRank',
      labelVi: 'Độ ưu tiên Story (Thấp→Cao)',
      descriptionVi: 'Mức độ ưu tiên của User Story: THẤP=0, TB=1, CAO=2.',
      minValue: 0.0,
      maxValue: 2.0,
      defaultCheckpointValue: 1.0,
    ),
    FeatureDefinition(
      index: idxDaysToDeadline,
      key: 'daysToDeadline',
      labelVi: 'Số ngày còn lại tới hạn',
      descriptionVi:
          'Khoảng thời gian còn lại tính đến deadline (kẹp -7..14 ngày).',
      minValue: -7.0,
      maxValue: 14.0,
      defaultCheckpointValue: 3.0,
    ),
    FeatureDefinition(
      index: idxElapsedRatio,
      key: 'elapsedRatio',
      labelVi: 'Tỷ lệ thời gian đã trôi qua',
      descriptionVi:
          'Tỷ lệ (now - createdAt) / (deadline - createdAt), kẹp 0..1.5.',
      minValue: 0.0,
      maxValue: 1.5,
      defaultCheckpointValue: realCheckpointElapsedRatio,
    ),
    FeatureDefinition(
      index: idxLoggedHoursPerDay,
      key: 'loggedHoursPerDay',
      labelVi: 'Cường độ làm việc (giờ/ngày)',
      descriptionVi: 'Số giờ log work trung bình mỗi ngày kể từ khi tạo task.',
      minValue: 0.0,
      maxValue: 12.0,
      defaultCheckpointValue: realCheckpointLoggedHoursPerDay,
    ),
    FeatureDefinition(
      index: idxStatusProgress,
      key: 'statusProgress',
      labelVi: 'Tiến độ trạng thái hiện tại',
      descriptionVi: 'To Do = 0.0, In Progress = 0.5.',
      minValue: 0.0,
      maxValue: 1.0,
      defaultCheckpointValue: realCheckpointStatusProgress,
    ),
    FeatureDefinition(
      index: idxAssigneeOnTimeRate,
      key: 'assigneeOnTimeRate',
      labelVi: 'Tỷ lệ đúng hạn của người nhận',
      descriptionVi: 'Tỷ lệ hoàn thành task đúng hạn trong lịch sử (0..1).',
      minValue: 0.0,
      maxValue: 1.0,
      defaultCheckpointValue: 0.75,
    ),
    FeatureDefinition(
      index: idxAssigneeWorkload,
      key: 'assigneeWorkload',
      labelVi: 'Tải công việc người nhận',
      descriptionVi:
          'Tỷ lệ số task đang In Progress trên ngưỡng tối đa 5 task.',
      minValue: 0.0,
      maxValue: 1.5,
      defaultCheckpointValue: 0.2,
    ),
    FeatureDefinition(
      index: idxSprintElapsedRatio,
      key: 'sprintElapsedRatio',
      labelVi: 'Tiến độ thời gian Sprint',
      descriptionVi:
          'Tỷ lệ thời gian đã trôi qua của Sprint hiện tại (0..1.2).',
      minValue: 0.0,
      maxValue: 1.2,
      defaultCheckpointValue: 0.5,
    ),
    FeatureDefinition(
      index: idxUnassigned,
      key: 'unassigned',
      labelVi: 'Chưa phân công người làm',
      descriptionVi: '1.0 nếu task chưa có người phụ trách, 0.0 nếu đã giao.',
      minValue: 0.0,
      maxValue: 1.0,
      defaultCheckpointValue: 0.0,
    ),
  ];

  static List<String> get keys =>
      definitions.map((d) => d.key).toList(growable: false);

  static List<String> get labelsVi =>
      definitions.map((d) => d.labelVi).toList(growable: false);
}
