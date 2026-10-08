import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/data/models/sprint_review_model.dart';

void main() {
  final now = DateTime(2026, 10, 8);

  group('SprintReviewModel (US-023)', () {
    test('toMap and fromMap work correctly with Timestamp', () {
      final review = SprintReviewModel(
        id: 'rev-1',
        sprintId: 'sp-1',
        projectId: 'p-1',
        demoNotes: 'Demo feature A and B',
        stakeholderFeedback: 'Good job, need UI tweaks',
        acceptedStoryIds: const ['s1', 's2'],
        rejectedStoryIds: const ['s3'],
        reviewedBy: 'u1',
        reviewedByName: 'PO Name',
        createdAt: now,
        updatedAt: now,
      );

      final map = review.toMap();
      expect(map['id'], 'rev-1');
      expect(map['sprintId'], 'sp-1');
      expect(map['acceptedStoryIds'], ['s1', 's2']);
      expect(map['rejectedStoryIds'], ['s3']);
      expect(map['createdAt'], isA<Timestamp>());

      final parsed = SprintReviewModel.fromMap(map, 'rev-1');
      expect(parsed.id, 'rev-1');
      expect(parsed.demoNotes, 'Demo feature A and B');
      expect(parsed.acceptedStoryIds, ['s1', 's2']);
      expect(parsed.rejectedStoryIds, ['s3']);
      expect(parsed.reviewedByName, 'PO Name');
    });

    test('copyWith updates fields cleanly', () {
      final review = SprintReviewModel(
        id: 'rev-1',
        sprintId: 'sp-1',
        projectId: 'p-1',
        demoNotes: 'Demo',
        stakeholderFeedback: '',
        createdAt: now,
        updatedAt: now,
      );

      final updated = review.copyWith(
        demoNotes: 'Updated Demo',
        acceptedStoryIds: ['s1'],
      );

      expect(updated.demoNotes, 'Updated Demo');
      expect(updated.acceptedStoryIds, ['s1']);
      expect(updated.sprintId, 'sp-1');
    });
  });
}
