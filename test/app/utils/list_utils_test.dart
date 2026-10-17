import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/utils/list_utils.dart';

void main() {
  group('chunkList', () {
    test('danh sách rỗng trả về rỗng với bất kỳ size hợp lệ', () {
      expect(chunkList<int>([], 1), isEmpty);
      expect(chunkList<String>([], 10), isEmpty);
    });

    test('chia đủ: danh sách chia hết cho size tạo các chunk đều nhau', () {
      final input = [1, 2, 3, 4, 5, 6];
      final result = chunkList(input, 2);
      expect(result, [
        [1, 2],
        [3, 4],
        [5, 6],
      ]);
    });

    test('chia dư: chunk cuối cùng chứa các phần tử còn lại', () {
      final input = ['a', 'b', 'c', 'd', 'e'];
      final result = chunkList(input, 2);
      expect(result, [
        ['a', 'b'],
        ['c', 'd'],
        ['e'],
      ]);
    });

    test('size > length: trả về đúng 1 chunk chứa toàn bộ danh sách ban đầu', () {
      final input = [10, 20, 30];
      final result = chunkList(input, 10);
      expect(result, [
        [10, 20, 30],
      ]);
    });

    test('size <= 0 ném lỗi ArgumentError', () {
      expect(() => chunkList([1, 2], 0), throwsArgumentError);
      expect(() => chunkList([1, 2], -5), throwsArgumentError);
    });
  });
}
