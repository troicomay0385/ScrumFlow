import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/domain/usecases/story/update_story_status_usecase.dart';
import 'package:scrumflow/presentation/story/bloc/update_story_status_cubit.dart';
import 'package:scrumflow/presentation/story/widgets/change_status_dialog.dart';

class MockUpdateStoryStatusUseCase extends Mock
    implements UpdateStoryStatusUseCase {}

void main() {
  late MockUpdateStoryStatusUseCase mockUseCase;
  late UpdateStoryStatusCubit cubit;

  setUp(() {
    mockUseCase = MockUpdateStoryStatusUseCase();
    cubit = UpdateStoryStatusCubit(useCase: mockUseCase);
  });

  Widget buildTestWidget({
    required Widget child,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('ChangeStatusDialog Widget Test', () {
    testWidgets('hiển thị đầy đủ 4 tuỳ chọn trạng thái', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showChangeStatusDialog(
                context: context,
                projectId: 'p1',
                storyId: 's1',
                currentStatus: 'To Do',
                cubit: cubit,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Cập nhật trạng thái'), findsOneWidget);
      expect(find.text('To Do'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Hiện tại'), findsOneWidget); // Tag on To Do
    });

    testWidgets('chọn trạng thái Done và bấm Cập nhật gọi Cubit', (tester) async {
      when(
        () => mockUseCase(
          projectId: 'p1',
          storyId: 's1',
          newStatus: 'Done',
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showChangeStatusDialog(
                context: context,
                projectId: 'p1',
                storyId: 's1',
                currentStatus: 'To Do',
                cubit: cubit,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Bấm vào tuỳ chọn Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Bấm nút Cập nhật
      await tester.tap(find.text('Cập nhật'));
      await tester.pumpAndSettle();

      verify(
        () => mockUseCase(
          projectId: 'p1',
          storyId: 's1',
          newStatus: 'Done',
        ),
      ).called(1);
    });

    testWidgets('chặn quyền MEMBER với thông báo "Chỉ PO/SM mới có quyền cập nhật trạng thái"', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showChangeStatusDialog(
                context: context,
                projectId: 'p1',
                storyId: 's1',
                currentStatus: 'To Do',
                userRole: ProjectRole.member,
                cubit: cubit,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Không mở dialog mà hiển thị SnackBar
      expect(find.text('Chỉ PO/SM mới có quyền cập nhật trạng thái'), findsOneWidget);
      expect(find.text('Cập nhật trạng thái'), findsNothing);
    });
  });
}
