import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/data/models/sprint_retro_item_model.dart';

void main() {
  final now = DateTime(2026, 10, 8);

  group('SprintRetroItemModel (US-024)', () {
    test('toMap and fromMap parse column types and voters count correctly', () {
      final item = SprintRetroItemModel(
        id: 'retro-1',
        sprintId: 'sp-1',
        projectId: 'p-1',
        column: RetroColumnType.wentWell,
        content: 'Hoàn thành Sprint đúng hạn',
        authorId: 'u1',
        authorName: 'Developer',
        voterIds: const ['u1', 'u2', 'u3'],
        createdAt: now,
      );

      expect(item.votesCount, 3);

      final map = item.toMap();
      expect(map['column'], 'wentWell');
      expect(map['content'], 'Hoàn thành Sprint đúng hạn');
      expect(map['createdAt'], isA<Timestamp>());

      final parsed = SprintRetroItemModel.fromMap(map, 'retro-1');
      expect(parsed.id, 'retro-1');
      expect(parsed.column, RetroColumnType.wentWell);
      expect(parsed.votesCount, 3);
      expect(parsed.authorName, 'Developer');
    });

    test('RetroColumnTypeX extensions mapping', () {
      expect(RetroColumnType.wentWell.key, 'wentWell');
      expect(RetroColumnType.couldImprove.key, 'couldImprove');
      expect(RetroColumnType.actionItem.key, 'actionItem');

      expect(RetroColumnTypeX.fromString('couldImprove'), RetroColumnType.couldImprove);
      expect(RetroColumnTypeX.fromString('actionItem'), RetroColumnType.actionItem);
      expect(RetroColumnTypeX.fromString('unknown'), RetroColumnType.wentWell);
    });
  });
}
