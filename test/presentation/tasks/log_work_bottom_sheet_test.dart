import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/repositories/work_log_repository.dart';
import 'package:scrumflow/presentation/tasks/widgets/log_work_bottom_sheet.dart';

class MockWorkLogRepository extends Mock implements WorkLogRepository {}

class FakeTaskModel extends Fake implements TaskModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTaskModel());
    registerFallbackValue(DateTime.now());
  });

  const projectId = 'proj-123';
  final now = DateTime(2026, 10, 17);

  final testTask = TaskModel(
    id: 'task-789',
    storyId: 'story-1',
    projectId: projectId,
    title: 'Xây dựng giao diện Log Work',
    description: 'Mô tả công việc',
    status: 'In Progress',
    createdAt: now,
    updatedAt: now,
  );

  late MockWorkLogRepository repository;

  setUp(() {
    repository = MockWorkLogRepository();
  });

  Widget buildTestApp({
    double width = 400,
    double height = 800,
    double textScale = 1.0,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) {
    return RepositoryProvider<WorkLogRepository>.value(
      value: repository,
      child: MaterialApp(
        builder: (context, child) {
          final query = MediaQuery.of(context);
          return MediaQuery(
            data: query.copyWith(
              size: Size(width, height),
              textScaler: TextScaler.linear(textScale),
              viewInsets: viewInsets,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  key: const Key('open_sheet_button'),
                  onPressed: () => showLogWorkBottomSheet(
                    context,
                    task: testTask,
                    projectId: projectId,
                  ),
                  child: const Text('Mở Sheet'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  group('LogWorkBottomSheet', () {
    testWidgets('chọn chip điền đúng giá trị vào ô nhập giờ', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.byType(LogWorkBottomSheet), findsOneWidget);

      // Chọn chip 2h
      await tester.tap(find.byKey(const Key('quick_hours_2')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '2'), findsOneWidget);

      // Chọn chip 0.5h
      await tester.tap(find.byKey(const Key('quick_hours_0.5')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '0.5'), findsOneWidget);

      // Chọn chip 4h
      await tester.tap(find.byKey(const Key('quick_hours_4')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '4'), findsOneWidget);

      verifyZeroInteractions(repository);
    });

    testWidgets('giờ 0, 25, 0.3, rỗng hiện lỗi và KHÔNG gọi repository',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      final hoursInput = find.byKey(const Key('log_work_hours_input'));
      final submitBtn = find.byKey(const Key('log_work_submit_button'));

      // 1. Rỗng
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập số giờ làm việc'), findsOneWidget);

      // 2. Giờ = 0
      await tester.enterText(hoursInput, '0');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Số giờ làm việc phải lớn hơn 0'), findsOneWidget);

      // 3. Giờ = 25
      await tester.enterText(hoursInput, '25');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Số giờ làm việc không được vượt quá 24 giờ'), findsOneWidget);

      // 4. Giờ = 0.3 (không là bội số 0.25)
      await tester.enterText(hoursInput, '0.3');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(
        find.text('Số giờ phải là bội số của 0.25 (ví dụ: 0.25, 0.5, 0.75, 1)'),
        findsOneWidget,
      );

      verifyZeroInteractions(repository);
    });

    testWidgets('lưu hợp lệ gọi logWork đúng tham số rồi đóng sheet + SnackBar',
        (tester) async {
      when(() => repository.logWork(
            task: any(named: 'task'),
            projectId: any(named: 'projectId'),
            hours: any(named: 'hours'),
            note: any(named: 'note'),
            workDate: any(named: 'workDate'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      final hoursInput = find.byKey(const Key('log_work_hours_input'));
      final noteInput = find.byKey(const Key('log_work_note_input'));
      final submitBtn = find.byKey(const Key('log_work_submit_button'));

      await tester.enterText(hoursInput, '1,5'); // Dấu phẩy
      await tester.enterText(noteInput, 'Đã hoàn thành module test');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      verify(() => repository.logWork(
            task: testTask,
            projectId: projectId,
            hours: 1.5,
            note: 'Đã hoàn thành module test',
            workDate: any(named: 'workDate'),
          )).called(1);

      // Sheet đã đóng
      expect(find.byType(LogWorkBottomSheet), findsNothing);
      // SnackBar hiển thị
      expect(find.text('Đã ghi 1.5 giờ'), findsOneWidget);
    });

    testWidgets('"Bỏ qua" đóng sheet và không gọi repository', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.byType(LogWorkBottomSheet), findsOneWidget);

      await tester.tap(find.byKey(const Key('log_work_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.byType(LogWorkBottomSheet), findsNothing);
      verifyZeroInteractions(repository);
    });

    testWidgets('bấm Lưu liên tiếp chỉ gọi repository 1 lần', (tester) async {
      final completer = Completer<void>();
      when(() => repository.logWork(
            task: any(named: 'task'),
            projectId: any(named: 'projectId'),
            hours: any(named: 'hours'),
            note: any(named: 'note'),
            workDate: any(named: 'workDate'),
          )).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('log_work_hours_input')), '2');

      final submitBtn = find.byKey(const Key('log_work_submit_button'));

      // Lần bấm 1
      await tester.tap(submitBtn);
      await tester.pump();

      // Lần bấm 2 & 3 khi đang submitting
      await tester.tap(submitBtn, warnIfMissed: false);
      await tester.pump();
      await tester.tap(submitBtn, warnIfMissed: false);
      await tester.pump();

      completer.complete();
      await tester.pumpAndSettle();

      verify(() => repository.logWork(
            task: any(named: 'task'),
            projectId: any(named: 'projectId'),
            hours: 2.0,
            note: any(named: 'note'),
            workDate: any(named: 'workDate'),
          )).called(1);
    });

    testWidgets('không overflow ở 320x568 với bàn phím 260px và textScale 1.3',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(buildTestApp(
        width: 320,
        height: 568,
        textScale: 1.3,
        viewInsets: const EdgeInsets.only(bottom: 260),
      ));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LogWorkBottomSheet), findsOneWidget);

      // Thử cuộn kiểm tra không bị lỗi layout
      await tester.drag(
        find.descendant(
          of: find.byType(LogWorkBottomSheet),
          matching: find.byType(SingleChildScrollView),
        ),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
