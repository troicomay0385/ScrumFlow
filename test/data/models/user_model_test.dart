import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/data/models/user_model.dart';

class MockTimestamp {
  final DateTime _date;
  MockTimestamp(this._date);
  DateTime toDate() => _date;
}

void main() {
  group('UserModel.fromMap', () {
    test('parses standard map with String createdAt', () {
      final nowStr = '2026-09-27T00:00:00.000Z';
      final map = {
        'id': 'user123',
        'fullName': 'Nguyen Van A',
        'email': 'a@example.com',
        'photoUrl': 'https://example.com/photo.png',
        'createdAt': nowStr,
        'loginProvider': 'email',
      };

      final user = UserModel.fromMap(map);
      expect(user.id, equals('user123'));
      expect(user.fullName, equals('Nguyen Van A'));
      expect(user.email, equals('a@example.com'));
      expect(user.createdAt, equals(DateTime.parse(nowStr)));
      expect(user.loginProvider, equals('email'));
    });

    test('parses map with Timestamp object for createdAt without throwing TypeError', () {
      final now = DateTime(2026, 9, 27);
      final mockTimestamp = MockTimestamp(now);
      final map = {
        'id': 'user123',
        'fullName': 'Nguyen Van A',
        'email': 'a@example.com',
        'createdAt': mockTimestamp,
      };

      final user = UserModel.fromMap(map);
      expect(user.id, equals('user123'));
      expect(user.fullName, equals('Nguyen Van A'));
      expect(user.createdAt, equals(now));
      expect(user.loginProvider, equals('email'));
    });

    test('parses map with missing or null fields gracefully', () {
      final map = <String, dynamic>{};

      final user = UserModel.fromMap(map);
      expect(user.id, isEmpty);
      expect(user.fullName, isEmpty);
      expect(user.email, isEmpty);
      expect(user.loginProvider, equals('email'));
      expect(user.createdAt, isNotNull);
    });
  });
}
