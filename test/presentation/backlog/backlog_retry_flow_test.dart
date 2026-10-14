// US-063 / US-064 — Luồng UI trên màn Product Backlog:
// skeleton khi tải → lỗi thân thiện kèm "Thử lại" → bấm thử lại → dữ liệu.
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/data/repositories/project_member_repository.dart';
import 'package:scrumflow/presentation/backlog/screens/backlog_list_screen.dart';
import 'package:scrumflow/presentation/common/widgets/skeleton_list.dart';

import '../../helpers/test_setup.dart';

class _MockBacklogRepository extends Mock implements BacklogRepository {}

class _MockProjectMemberRepository extends Mock
    implements ProjectMemberRepository {}

void main() {
  setUpAll(setUpWidgetTestEnvironment);

  testWidgets('lỗi tải → "Thử lại" → hiển thị Backlog', (tester) async {
    final backlogRepository = _MockBacklogRepository();
    final memberRepository = _MockProjectMemberRepository();
    when(
      () => memberRepository.streamCurrentUserRole('p1'),
    ).thenAnswer((_) => Stream.value(ProjectRole.po));

    var attempt = 0;
    final firstAttempt = StreamController<List<UserStoryModel>>();
    when(() => backlogRepository.streamUserStories('p1')).thenAnswer((_) {
      attempt++;
      if (attempt == 1) return firstAttempt.stream;
      return Stream.value([
        UserStoryModel(
          id: 's1',
          projectId: 'p1',
          storyKey: 'US-001',
          title: 'Đăng nhập bằng email',
          description: '',
          createdAt: DateTime(2026, 10, 1),
          updatedAt: DateTime(2026, 10, 1),
        ),
      ]);
    });

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<BacklogRepository>.value(value: backlogRepository),
          RepositoryProvider<ProjectMemberRepository>.value(
            value: memberRepository,
          ),
        ],
        child: const MaterialApp(
          home: BacklogListScreen(projectId: 'p1', projectName: 'ScrumFlow'),
        ),
      ),
    );
    await tester.pump();

    // Đang tải → skeleton.
    expect(find.byType(SkeletonList), findsOneWidget);

    // Máy chủ báo lỗi → màn lỗi thân thiện, không lộ mã kỹ thuật.
    firstAttempt.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Máy chủ không phản hồi'), findsOneWidget);
    expect(find.textContaining('cloud_firestore'), findsNothing);
    expect(find.byType(SkeletonList), findsNothing);

    // Thử lại → tải thành công.
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Đăng nhập bằng email'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
    expect(attempt, 2);

    unawaited(firstAttempt.close());
  });
}
