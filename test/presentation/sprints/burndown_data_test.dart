import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/data/models/sprint_model.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/presentation/sprints/widgets/burndown_chart_widget.dart';

void main() {
  final now = DateTime(2026, 10, 8);
  final start = DateTime(2026, 10, 1);
  final end = DateTime(2026, 10, 14);

  group('BurndownData.calculate (US-025)', () {
    test('calculates total story points, ideal points, and completed points correctly', () {
      final sprint = SprintModel(
        id: 'sp-1',
        projectId: 'p-1',
        name: 'Sprint 1',
        goal: 'Goal',
        startDate: start,
        endDate: end,
        createdAt: start,
        updatedAt: start,
      );

      final stories = [
        UserStoryModel(
          id: 's1',
          projectId: 'p-1',
          storyKey: 'US-01',
          title: 'Story 1',
          description: '',
          priority: 'CAO',
          status: 'Done',
          storyPoints: 5,
          createdAt: start,
          updatedAt: DateTime(2026, 10, 5),
        ),
        UserStoryModel(
          id: 's2',
          projectId: 'p-1',
          storyKey: 'US-02',
          title: 'Story 2',
          description: '',
          priority: 'TB',
          status: 'In Progress',
          storyPoints: 8,
          createdAt: start,
          updatedAt: now,
        ),
      ];

      final data = BurndownData.calculate(sprint: sprint, stories: stories);

      expect(data.totalStoryPoints, 13);
      expect(data.completedStoryPoints, 5);
      expect(data.remainingStoryPoints, 8);
      expect(data.totalDays, 14);
      expect(data.idealPoints.first, 13.0);
      expect(data.idealPoints.last, 0.0);
      expect(data.idealPoints.length, 14);
      expect(data.dayLabels.length, 14);
    });
  });
}
