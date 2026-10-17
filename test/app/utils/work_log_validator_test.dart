import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/utils/work_log_validator.dart';

void main() {
  group('WorkLogValidator.parseHours Tests', () {
    test('nhận cả dấu chấm (.) và dấu phẩy (,)', () {
      expect(WorkLogValidator.parseHours('1.5'), 1.5);
      expect(WorkLogValidator.parseHours('1,5'), 1.5);
      expect(WorkLogValidator.parseHours(' 2,25 '), 2.25);
      expect(WorkLogValidator.parseHours('0,25'), 0.25);
      expect(WorkLogValidator.parseHours('8'), 8.0);
    });

    test('chuỗi không hợp lệ hoặc rỗng trả về null', () {
      expect(WorkLogValidator.parseHours(''), isNull);
      expect(WorkLogValidator.parseHours('   '), isNull);
      expect(WorkLogValidator.parseHours('abc'), isNull);
      expect(WorkLogValidator.parseHours('1..5'), isNull);
      expect(WorkLogValidator.parseHours('1,2,3'), isNull);
    });
  });

  group('WorkLogValidator.validateHours Tests', () {
    test('hours null trả về thông báo yêu cầu nhập', () {
      expect(
        WorkLogValidator.validateHours(null),
        'Vui lòng nhập số giờ làm việc',
      );
    });

    test('biên 0 và số âm trả về lỗi phải lớn hơn 0', () {
      expect(
        WorkLogValidator.validateHours(0),
        'Số giờ làm việc phải lớn hơn 0',
      );
      expect(
        WorkLogValidator.validateHours(-0.25),
        'Số giờ làm việc phải lớn hơn 0',
      );
    });

    test('biên 24 giờ hợp lệ, vượt quá 24 trả về lỗi', () {
      expect(WorkLogValidator.validateHours(24.0), isNull);
      expect(
        WorkLogValidator.validateHours(24.25),
        'Số giờ làm việc không được vượt quá 24 giờ',
      );
      expect(
        WorkLogValidator.validateHours(25),
        'Số giờ làm việc không được vượt quá 24 giờ',
      );
    });

    test('phải là bội số của 0.25 (15 phút)', () {
      // Hợp lệ
      expect(WorkLogValidator.validateHours(0.25), isNull);
      expect(WorkLogValidator.validateHours(0.5), isNull);
      expect(WorkLogValidator.validateHours(0.75), isNull);
      expect(WorkLogValidator.validateHours(1.0), isNull);
      expect(WorkLogValidator.validateHours(1.25), isNull);
      expect(WorkLogValidator.validateHours(7.75), isNull);

      // Không hợp lệ (0.3, 0.1, 1.33)
      expect(
        WorkLogValidator.validateHours(0.3),
        'Số giờ phải là bội số của 0.25 (ví dụ: 0.25, 0.5, 0.75, 1)',
      );
      expect(
        WorkLogValidator.validateHours(0.1),
        'Số giờ phải là bội số của 0.25 (ví dụ: 0.25, 0.5, 0.75, 1)',
      );
      expect(
        WorkLogValidator.validateHours(1.33),
        'Số giờ phải là bội số của 0.25 (ví dụ: 0.25, 0.5, 0.75, 1)',
      );
    });
  });

  group('WorkLogValidator.validateNote Tests', () {
    test('null hoặc rỗng đều hợp lệ (ghi chú tùy chọn)', () {
      expect(WorkLogValidator.validateNote(null), isNull);
      expect(WorkLogValidator.validateNote(''), isNull);
      expect(WorkLogValidator.validateNote('Đã sửa bug giao diện'), isNull);
    });

    test('giới hạn tối đa 500 ký tự', () {
      final validNote = 'a' * 500;
      expect(WorkLogValidator.validateNote(validNote), isNull);

      final tooLongNote = 'a' * 501;
      expect(
        WorkLogValidator.validateNote(tooLongNote),
        'Ghi chú không được vượt quá 500 ký tự',
      );
    });
  });

  group('WorkLogValidator.validateWorkDate Tests', () {
    final fixedNow = DateTime(2026, 10, 17, 15, 0);

    test('hôm nay hoặc ngày trong quá khứ là hợp lệ', () {
      final today = DateTime(2026, 10, 17, 8, 0);
      expect(
        WorkLogValidator.validateWorkDate(today, now: fixedNow),
        isNull,
      );

      final yesterday = DateTime(2026, 10, 16);
      expect(
        WorkLogValidator.validateWorkDate(yesterday, now: fixedNow),
        isNull,
      );
    });

    test('ngày trong tương lai trả về lỗi', () {
      final tomorrow = DateTime(2026, 10, 18);
      expect(
        WorkLogValidator.validateWorkDate(tomorrow, now: fixedNow),
        'Ngày làm việc không được ở tương lai',
      );
    });
  });

  group('WorkLogValidator.formatHours Tests', () {
    test('định dạng số nguyên và số thập phân chuẩn xác', () {
      expect(WorkLogValidator.formatHours(1.0), '1');
      expect(WorkLogValidator.formatHours(1.5), '1.5');
      expect(WorkLogValidator.formatHours(0.25), '0.25');
      expect(WorkLogValidator.formatHours(2.75), '2.75');
      expect(WorkLogValidator.formatHours(0.0), '0');
    });
  });
}
