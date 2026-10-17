import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/presentation/tasks/widgets/swipeable_task_card.dart';

void main() {
  final now = DateTime(2026, 10, 17);

  TaskModel createTask({required String id, required String status}) {
    return TaskModel(
      id: id,
      storyId: 's1',
      title: 'Task $id',
      description: 'Mô tả task',
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget buildCard({
    required TaskModel task,
    required void Function(String) onStatusChange,
    double width = 300.0,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(textScale),
              ),
              child: SwipeableTaskCard(
                task: task,
                onStatusChange: onStatusChange,
                child: Container(
                  height: 80,
                  color: Colors.white,
                  child: Text(task.title),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('SwipeableTaskCard', () {
    testWidgets('To Do vuốt phải → callback "In Progress"', (tester) async {
      String? changedStatus;
      final task = createTask(id: 't1', status: 'To Do');

      await tester.pumpWidget(buildCard(
        task: task,
        onStatusChange: (status) => changedStatus = status,
      ));

      await tester.fling(find.byType(Dismissible), const Offset(200, 0), 1000);
      await tester.pumpAndSettle();

      expect(changedStatus, 'In Progress');
    });

    testWidgets('To Do vuốt trái → không gọi callback', (tester) async {
      String? changedStatus;
      final task = createTask(id: 't1', status: 'To Do');

      await tester.pumpWidget(buildCard(
        task: task,
        onStatusChange: (status) => changedStatus = status,
      ));

      await tester.drag(find.byType(Dismissible), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(changedStatus, isNull);
    });

    testWidgets('In Progress vuốt phải → "Done", vuốt trái → "To Do"', (tester) async {
      final task = createTask(id: 't2', status: 'In Progress');

      // Vuốt phải
      String? changedRight;
      await tester.pumpWidget(buildCard(
        task: task,
        onStatusChange: (status) => changedRight = status,
      ));

      await tester.drag(find.byType(Dismissible), const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(changedRight, 'Done');

      // Vuốt trái
      String? changedLeft;
      await tester.pumpWidget(buildCard(
        task: task,
        onStatusChange: (status) => changedLeft = status,
      ));

      await tester.drag(find.byType(Dismissible), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(changedLeft, 'To Do');
    });

    testWidgets('Done vuốt phải → không gọi, vuốt trái → "In Progress"', (tester) async {
      final task = createTask(id: 't3', status: 'Done');

      // Vuốt phải
      String? changedRight;
      await tester.pumpWidget(buildCard(
        task: task,
        onStatusChange: (status) => changedRight = status,
      ));

      await tester.drag(find.byType(Dismissible), const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(changedRight, isNull);

      // Vuốt trái
      String? changedLeft;
      await tester.pumpWidget(buildCard(
        task: task,
        onStatusChange: (status) => changedLeft = status,
      ));

      await tester.drag(find.byType(Dismissible), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(changedLeft, 'In Progress');
    });

    testWidgets('thẻ vẫn còn trong cây sau khi vuốt (confirmDismiss trả về false)', (tester) async {
      final task = createTask(id: 't4', status: 'In Progress');

      await tester.pumpWidget(buildCard(
        task: task,
        onStatusChange: (_) {},
      ));

      expect(find.byKey(ValueKey('swipe_${task.id}')), findsOneWidget);

      await tester.drag(find.byType(Dismissible), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('swipe_${task.id}')), findsOneWidget);
      expect(find.text('Task t4'), findsOneWidget);
    });

    testWidgets('không overflow ở cột hẹp 100px/320px và textScale 1.3 khi vuốt', (tester) async {
      final task = createTask(id: 't5', status: 'In Progress');

      // Thử ở chiều rộng cột hẹp 100px với textScale 1.3
      await tester.pumpWidget(buildCard(
        task: task,
        onStatusChange: (_) {},
        width: 100.0,
        textScale: 1.3,
      ));

      // Bắt đầu vuốt sang phải nhưng chưa thả để render background
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Dismissible)),
      );
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();

      expect(tester.takeException(), isNull);

      await gesture.up();
      await tester.pumpAndSettle();

      // Thử ở chiều rộng 320px với textScale 1.3
      await tester.pumpWidget(buildCard(
        task: task,
        onStatusChange: (_) {},
        width: 320.0,
        textScale: 1.3,
      ));

      final gestureLeft = await tester.startGesture(
        tester.getCenter(find.byType(Dismissible)),
      );
      await gestureLeft.moveBy(const Offset(-150, 0));
      await tester.pump();

      expect(tester.takeException(), isNull);

      await gestureLeft.up();
      await tester.pumpAndSettle();
    });
  });
}
