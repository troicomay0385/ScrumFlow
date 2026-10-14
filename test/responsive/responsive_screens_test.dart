// US-055 — Kiểm thử responsive: dựng các màn hình chính ở kích thước điện
// thoại nhỏ / lớn và cỡ chữ phóng to, đảm bảo không có lỗi tràn
// (`RenderFlex overflowed`) hay exception khi layout.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/app/errors/app_failure.dart';
import 'package:scrumflow/data/models/project_member_display.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/models/sprint_model.dart';
import 'package:scrumflow/data/models/user_model.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/data/repositories/project_member_repository.dart';
import 'package:scrumflow/data/repositories/sprint_repository.dart';
import 'package:scrumflow/presentation/auth/bloc/auth_bloc.dart';
import 'package:scrumflow/presentation/auth/bloc/auth_event.dart';
import 'package:scrumflow/presentation/auth/bloc/auth_state.dart';
import 'package:scrumflow/presentation/auth/screens/login_screen.dart';
import 'package:scrumflow/presentation/auth/screens/register_screen.dart';
import 'package:scrumflow/presentation/backlog/screens/backlog_list_screen.dart';
import 'package:scrumflow/presentation/common/widgets/app_state_views.dart';
import 'package:scrumflow/presentation/project_members/screens/project_members_screen.dart';
import 'package:scrumflow/presentation/sprints/screens/sprint_list_screen.dart';

import '../helpers/test_setup.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockBacklogRepository extends Mock implements BacklogRepository {}

class _MockSprintRepository extends Mock implements SprintRepository {}

class _MockProjectMemberRepository extends Mock
    implements ProjectMemberRepository {}

/// Kích thước màn hình kiểm thử (logical pixel).
const _smallPhone = Size(320, 568); // iPhone SE đời 1 / Android nhỏ
const _largePhone = Size(430, 932); // điện thoại lớn

final _now = DateTime(2026, 10, 14);

UserStoryModel _story(int i) => UserStoryModel(
  id: 's$i',
  projectId: 'p1',
  storyKey: 'US-${i.toString().padLeft(3, '0')}',
  title:
      'Là người dùng, tôi muốn một tiêu đề User Story rất dài số $i '
      'để kiểm tra việc xuống dòng và cắt chữ trên màn hình hẹp',
  description: 'Mô tả $i',
  priority: const ['CAO', 'TB', 'THẤP'][i % 3],
  storyPoints: 13,
  status: const ['To Do', 'In Progress', 'Done'][i % 3],
  assigneeName: 'Nguyễn Văn Thành Viên Có Tên Rất Dài',
  tags: const ['frontend', 'mobile-ui', 'performance', 'backend'],
  deadline: _now.add(Duration(days: i)),
  createdAt: _now,
  updatedAt: _now,
);

SprintModel _sprint(int i, String status) => SprintModel(
  id: 'sp$i',
  projectId: 'p1',
  name: 'Sprint $i — Hoàn thiện tính năng cộng tác thời gian thực',
  goal:
      'Mục tiêu sprint khá dài để kiểm tra việc hiển thị trên '
      'màn hình điện thoại nhỏ khi tăng cỡ chữ hệ thống',
  storyIds: const ['s1', 's2'],
  startDate: _now,
  endDate: _now.add(const Duration(days: 14)),
  status: status,
  createdAt: _now,
  updatedAt: _now,
);

ProjectMemberDisplay _member(int i, ProjectRole role) => ProjectMemberDisplay(
  membership: ProjectMemberModel(
    id: 'p1_u$i',
    projectId: 'p1',
    userId: 'u$i',
    role: role,
    createdBy: 'u0',
    createdAt: _now,
    updatedAt: _now,
  ),
  user: UserModel(
    id: 'u$i',
    fullName: 'Thành viên số $i với họ tên đầy đủ khá dài',
    email: 'thanh.vien.so.$i.email.rat.dai@scrumflow-company.com',
    createdAt: _now,
    loginProvider: 'email',
  ),
);

Future<void> _setScreen(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home, {double textScale = 1.0}) {
  return MaterialApp(
    home: home,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
  );
}

void main() {
  setUpAll(setUpWidgetTestEnvironment);

  late _MockAuthBloc authBloc;
  late _MockBacklogRepository backlogRepository;
  late _MockSprintRepository sprintRepository;
  late _MockProjectMemberRepository memberRepository;

  setUp(() {
    authBloc = _MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: AuthUnauthenticated(),
    );

    backlogRepository = _MockBacklogRepository();
    when(
      () => backlogRepository.streamUserStories('p1'),
    ).thenAnswer((_) => Stream.value(List.generate(12, _story)));

    sprintRepository = _MockSprintRepository();
    when(() => sprintRepository.streamSprints('p1')).thenAnswer(
      (_) => Stream.value([
        _sprint(1, 'Completed'),
        _sprint(2, 'Active'),
        _sprint(3, 'Planned'),
      ]),
    );

    memberRepository = _MockProjectMemberRepository();
    when(
      () => memberRepository.streamCurrentUserRole('p1'),
    ).thenAnswer((_) => Stream.value(ProjectRole.po));
    when(() => memberRepository.streamMembers('p1')).thenAnswer(
      (_) => Stream.value([
        _member(0, ProjectRole.po),
        _member(1, ProjectRole.sm),
        _member(2, ProjectRole.member),
      ]),
    );
  });

  Widget withProviders(Widget child) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<BacklogRepository>.value(value: backlogRepository),
      RepositoryProvider<SprintRepository>.value(value: sprintRepository),
      RepositoryProvider<ProjectMemberRepository>.value(
        value: memberRepository,
      ),
    ],
    child: BlocProvider<AuthBloc>.value(value: authBloc, child: child),
  );

  for (final size in [_smallPhone, _largePhone]) {
    for (final textScale in [1.0, 1.3]) {
      final label =
          '${size.width.toInt()}x${size.height.toInt()} '
          '@ chữ x$textScale';

      testWidgets('Đăng nhập không tràn layout ($label)', (tester) async {
        await _setScreen(tester, size);
        await tester.pumpWidget(
          withProviders(_app(const LoginScreen(), textScale: textScale)),
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('Đăng ký không tràn layout ($label)', (tester) async {
        await _setScreen(tester, size);
        await tester.pumpWidget(
          withProviders(_app(const RegisterScreen(), textScale: textScale)),
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
      });

      testWidgets('Product Backlog không tràn layout ($label)', (tester) async {
        await _setScreen(tester, size);
        await tester.pumpWidget(
          withProviders(
            _app(
              const BacklogListScreen(
                projectId: 'p1',
                projectName: 'ScrumFlow',
              ),
              textScale: textScale,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.textContaining('tiêu đề User Story'), findsWidgets);
      });

      testWidgets('Danh sách Sprint không tràn layout ($label)', (
        tester,
      ) async {
        await _setScreen(tester, size);
        await tester.pumpWidget(
          withProviders(
            _app(
              const SprintListScreen(projectId: 'p1', projectName: 'ScrumFlow'),
              textScale: textScale,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Sprint 2'), findsOneWidget);
      });

      testWidgets('Quản lý thành viên không tràn layout ($label)', (
        tester,
      ) async {
        await _setScreen(tester, size);
        await tester.pumpWidget(
          withProviders(
            _app(
              const ProjectMembersScreen(projectId: 'p1'),
              textScale: textScale,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Thành viên số 1'), findsOneWidget);
      });

      testWidgets('Màn lỗi dùng chung không tràn layout ($label)', (
        tester,
      ) async {
        await _setScreen(tester, size);
        await tester.pumpWidget(
          _app(
            Scaffold(
              appBar: AppBar(title: const Text('Lỗi')),
              body: AppErrorView.fromFailure(
                const AppFailure.noConnection(),
                onRetry: () {},
              ),
            ),
            textScale: textScale,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Thử lại'), findsOneWidget);
      });
    }
  }
}
