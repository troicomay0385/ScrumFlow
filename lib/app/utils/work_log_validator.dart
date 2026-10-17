/// Bộ tiện ích kiểm tra tính hợp lệ và định dạng cho Work Log (US-066).
class WorkLogValidator {
  const WorkLogValidator._();

  /// Phân tích chuỗi số giờ làm việc, hỗ trợ cả dấu phẩy (,) và dấu chấm (.).
  ///
  /// Trả về `null` nếu chuỗi rỗng hoặc không phải số hợp lệ.
  static double? parseHours(String input) {
    final cleaned = input.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Kiểm tra tính hợp lệ của số giờ làm việc:
  /// - Phải lớn hơn 0
  /// - Không vượt quá 24 giờ
  /// - Phải là bội số của 0.25 (bước nhảy 15 phút, ví dụ: 0.25, 0.5, 0.75, 1.0)
  static String? validateHours(double? hours) {
    if (hours == null) {
      return 'Vui lòng nhập số giờ làm việc';
    }
    if (hours <= 0) {
      return 'Số giờ làm việc phải lớn hơn 0';
    }
    if (hours > 24) {
      return 'Số giờ làm việc không được vượt quá 24 giờ';
    }

    // Kiểm tra bội số của 0.25 bằng cách xét số dư khi nhân với 4
    final scaled = hours * 4;
    final diff = (scaled.roundToDouble() - scaled).abs();
    if (diff > 1e-6) {
      return 'Số giờ phải là bội số của 0.25 (ví dụ: 0.25, 0.5, 0.75, 1)';
    }

    return null;
  }

  /// Kiểm tra ghi chú công việc: không vượt quá 500 ký tự.
  static String? validateNote(String? note) {
    if (note != null && note.length > 500) {
      return 'Ghi chú không được vượt quá 500 ký tự';
    }
    return null;
  }

  /// Kiểm tra ngày làm việc: không được ở tương lai so với [now] (hoặc thời điểm hiện tại).
  /// So sánh theo ngày (bỏ qua giờ/phút).
  static String? validateWorkDate(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target.isAfter(today)) {
      return 'Ngày làm việc không được ở tương lai';
    }
    return null;
  }

  /// Định dạng số giờ gọn gàng:
  /// - 1.0 -> "1"
  /// - 1.5 -> "1.5"
  /// - 0.25 -> "0.25"
  static String formatHours(double hours) {
    if (hours == hours.roundToDouble()) {
      return hours.toInt().toString();
    }
    return hours.toString().replaceAll(RegExp(r'\.?0+$'), '');
  }
}
