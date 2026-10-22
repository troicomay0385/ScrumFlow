import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/theme/app_theme.dart';
import 'package:scrumflow/data/models/sprint_model.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/presentation/ai/bloc/sprint_forecast_cubit.dart';
import 'package:scrumflow/presentation/ai/bloc/sprint_forecast_state.dart';
import 'package:scrumflow/presentation/ai/widgets/sprint_forecast_card.dart';
import 'package:scrumflow/presentation/sprints/widgets/burndown_chart_widget.dart';

void main() {
  final now = DateTime.now();

  SprintModel makeActiveSprint() {
    return SprintModel(
      id: 'sp_1',
      projectId: 'p1',
      name: 'Sprint 5',
      goal: 'AI Sprint Risk Radar',
      storyIds: const ['s1', 's2', 's3'],
      startDate: now.subtract(const Duration(days: 4)),
      endDate: now.add(const Duration(days: 6)),
      status: 'Active',
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now,
    );
  }

  List<UserStoryModel> makeStories() {
    return [
      UserStoryModel(
        id: 's1',
        projectId: 'p1',
        storyKey: 'US-069',
        title: 'AI Risk Radar',
        description: 'Desc',
        storyPoints: 8,
        status: 'In Progress',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      ),
      UserStoryModel(
        id: 's2',
        projectId: 'p1',
        storyKey: 'US-070',
        title: 'AI Sprint Forecast',
        description: 'Desc',
        storyPoints: 8,
        status: 'To Do',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      ),
      UserStoryModel(
        id: 's3',
        projectId: 'p1',
        storyKey: 'US-068',
        title: 'Theme Tokens',
        description: 'Desc',
        storyPoints: 3,
        status: 'Done',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
        completedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  group('SprintForecastCubit & SprintForecastCard (US-070)', () {
    test(
      'Cubit computes forecast and toggles What-if story exclusion',
      () async {
        final cubit = SprintForecastCubit(projectId: 'p1');
        final sprint = makeActiveSprint();
        final stories = makeStories();

        await cubit.computeForecast(
          sprint: sprint,
          sprintStories: stories,
          allSprints: [sprint],
        );

        expect(cubit.state, isA<SprintForecastLoaded>());
        final loaded = cubit.state as SprintForecastLoaded;
        expect(loaded.hasWhatIfChanges, isFalse);
        final baseProb = loaded.baseForecast.completionProbability;

        cubit.toggleExcludedStory('s1');
        final afterToggle = cubit.state as SprintForecastLoaded;
        expect(afterToggle.hasWhatIfChanges, isTrue);
        expect(afterToggle.excludedStoryIds, contains('s1'));
        expect(
          afterToggle.activeForecast.completionProbability,
          greaterThanOrEqualTo(baseProb),
        );

        cubit.resetWhatIf();
        final afterReset = cubit.state as SprintForecastLoaded;
        expect(afterReset.hasWhatIfChanges, isFalse);

        await cubit.close();
      },
    );

    testWidgets(
      'SprintForecastCard renders p10/p50/p90, opens What-if sheet & BurndownChartWidget renders forecast band',
      (tester) async {
        final cubit = SprintForecastCubit(projectId: 'p1');
        final sprint = makeActiveSprint();
        final stories = makeStories();
        await cubit.computeForecast(
          sprint: sprint,
          sprintStories: stories,
          allSprints: [sprint],
        );
        final forecast = (cubit.state as SprintForecastLoaded).activeForecast;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: BlocProvider.value(
                value: cubit,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      BurndownChartWidget(
                        sprint: sprint,
                        stories: stories,
                        forecast: forecast,
                      ),
                      const SprintForecastCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sprintForecastCard')), findsOneWidget);
        expect(find.textContaining('Lạc quan (p10)'), findsOneWidget);
        expect(find.textContaining('Trung vị (p50)'), findsOneWidget);
        expect(find.textContaining('Thận trọng (p90)'), findsOneWidget);
        expect(find.text('Dự báo AI (p10–p90)'), findsOneWidget);

        // Mở What-if bottom sheet
        final btn = find.byKey(const Key('sprintForecast_openWhatIfButton'));
        expect(btn, findsOneWidget);
        await tester.ensureVisible(btn);
        await tester.pumpAndSettle();
        await tester.tap(btn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('sprintWhatIfBottomSheet')),
          findsOneWidget,
        );
        final tile = find.byKey(const Key('whatIfStoryTile_s1'));
        expect(tile, findsOneWidget);
        await tester.tap(tile);
        await tester.pumpAndSettle();

        expect(
          (cubit.state as SprintForecastLoaded).excludedStoryIds,
          contains('s1'),
        );

        await cubit.close();
      },
    );
  });
}
