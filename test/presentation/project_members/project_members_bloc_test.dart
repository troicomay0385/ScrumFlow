import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/models/project_member_display.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/models/user_model.dart';
import 'package:scrumflow/data/repositories/project_member_repository.dart';
import 'package:scrumflow/presentation/project_members/bloc/project_members_bloc.dart';
import 'package:scrumflow/presentation/project_members/bloc/project_members_event.dart';
import 'package:scrumflow/presentation/project_members/bloc/project_members_state.dart';

class MockProjectMemberRepository extends Mock implements ProjectMemberRepository {}

void main() {
  const projectId = 'p1';

  late MockProjectMemberRepository repository;

  ProjectMemberModel membership(String userId, ProjectRole role) {
    return ProjectMemberModel(
      id: '${projectId}_$userId',
      projectId: projectId,
      userId: userId,
      role: role,
      createdBy: 'po1',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  final poDisplay = ProjectMemberDisplay(
    membership: membership('po1', ProjectRole.po),
    user: UserModel(
      id: 'po1',
      fullName: 'PO User',
      email: 'po@example.com',
      createdAt: DateTime(2026, 1, 1),
      loginProvider: 'email',
    ),
  );

  setUpAll(() {
    registerFallbackValue(ProjectRole.member);
  });

  setUp(() {
    repository = MockProjectMemberRepository();
  });

  blocTest<ProjectMembersBloc, ProjectMembersState>(
    'role = MEMBER -> ProjectMembersAccessDenied, không tải danh sách thành viên',
    build: () {
      when(() => repository.streamCurrentUserRole(projectId))
          .thenAnswer((_) => Stream.value(ProjectRole.member));
      return ProjectMembersBloc(repository);
    },
    act: (bloc) => bloc.add(const ProjectMembersStarted(projectId)),
    expect: () => [
      isA<ProjectMembersLoading>(),
      isA<ProjectMembersAccessDenied>(),
    ],
    verify: (_) {
      verifyNever(() => repository.streamMembers(any()));
    },
  );

  blocTest<ProjectMembersBloc, ProjectMembersState>(
    'user không phải thành viên (role null) -> ProjectMembersError',
    build: () {
      when(() => repository.streamCurrentUserRole(projectId))
          .thenAnswer((_) => Stream.value(null));
      return ProjectMembersBloc(repository);
    },
    act: (bloc) => bloc.add(const ProjectMembersStarted(projectId)),
    expect: () => [
      isA<ProjectMembersLoading>(),
      isA<ProjectMembersError>(),
    ],
  );

  blocTest<ProjectMembersBloc, ProjectMembersState>(
    'role = PO -> tải danh sách thành viên thành công',
    build: () {
      when(() => repository.streamCurrentUserRole(projectId))
          .thenAnswer((_) => Stream.value(ProjectRole.po));
      when(() => repository.streamMembers(projectId))
          .thenAnswer((_) => Stream.value([poDisplay]));
      return ProjectMembersBloc(repository);
    },
    act: (bloc) => bloc.add(const ProjectMembersStarted(projectId)),
    // Role stream -> _RoleChanged -> members stream -> _MembersChanged đi
    // qua nhiều tick bất đồng bộ hơn mức mặc định của blocTest, cần chờ
    // thêm để state cuối kịp emit.
    wait: const Duration(milliseconds: 50),
    expect: () => [
      isA<ProjectMembersLoading>(),
      isA<ProjectMembersLoaded>()
          .having((s) => s.members.length, 'members.length', 1)
          .having((s) => s.currentUserRole, 'currentUserRole', ProjectRole.po),
    ],
  );

  blocTest<ProjectMembersBloc, ProjectMembersState>(
    'Đổi role thất bại ở Repository (vd. tự đổi role chính mình) '
    '-> actionStatus chuyển sang failure kèm message lỗi',
    build: () {
      when(() => repository.streamCurrentUserRole(projectId))
          .thenAnswer((_) => Stream.value(ProjectRole.po));
      when(() => repository.streamMembers(projectId))
          .thenAnswer((_) => Stream.value([poDisplay]));
      when(() => repository.updateMemberRole(
            projectId: any(named: 'projectId'),
            targetUserId: any(named: 'targetUserId'),
            newRole: any(named: 'newRole'),
          )).thenThrow(
              Exception('Bạn không thể tự thay đổi vai trò của chính mình.'));
      return ProjectMembersBloc(repository);
    },
    act: (bloc) async {
      bloc.add(const ProjectMembersStarted(projectId));
      // Chờ role + members stream ổn định (state Loaded ban đầu) trước khi
      // gửi hành động đổi role, tránh race condition với nested subscription.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const ProjectMemberRoleChangeRequested(
        targetUserId: 'po1',
        newRole: ProjectRole.member,
      ));
    },
    skip: 2, // bỏ qua Loading + Loaded ban đầu
    wait: const Duration(milliseconds: 50),
    expect: () => [
      isA<ProjectMembersLoaded>().having(
          (s) => s.actionStatus, 'actionStatus', MemberActionStatus.inProgress),
      isA<ProjectMembersLoaded>()
          .having((s) => s.actionStatus, 'actionStatus', MemberActionStatus.failure)
          .having((s) => s.actionMessage, 'actionMessage', contains('tự thay đổi')),
    ],
  );
}
