// US-063 / US-064 — Widget trạng thái dùng chung, banner mạng, skeleton.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/errors/app_failure.dart';
import 'package:scrumflow/presentation/common/widgets/app_state_views.dart';
import 'package:scrumflow/presentation/common/widgets/network_status_banner.dart';
import 'package:scrumflow/presentation/common/widgets/skeleton_list.dart';

import '../../helpers/test_setup.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(body: child),
  ),
);

void main() {
  setUpAll(setUpWidgetTestEnvironment);

  group('AppErrorView', () {
    testWidgets('mất mạng: hiện tiêu đề, thông báo và nút "Thử lại"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AppErrorView.fromFailure(
            const AppFailure.noConnection(),
            onRetry: () {},
          ),
        ),
      );
      expect(find.text('Mất kết nối mạng'), findsOneWidget);
      expect(find.textContaining('Không có kết nối mạng'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('bấm "Thử lại" liên tục chỉ gọi callback 1 lần', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          AppErrorView.fromFailure(
            const AppFailure.timeout(),
            onRetry: () => calls++,
          ),
        ),
      );

      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      // Nút đã khoá, hiện "Đang thử lại..."
      expect(find.text('Đang thử lại...'), findsOneWidget);
      await tester.tap(find.text('Đang thử lại...'), warnIfMissed: false);
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('lỗi mới được truyền vào → mở khoá nút để thử lại tiếp', (
      tester,
    ) async {
      var calls = 0;
      Widget build(AppFailure failure) =>
          _wrap(AppErrorView.fromFailure(failure, onRetry: () => calls++));

      await tester.pumpWidget(build(const AppFailure.timeout()));
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      await tester.pumpWidget(build(const AppFailure.noConnection()));
      await tester.tap(find.text('Thử lại'));
      await tester.pump();

      expect(calls, 2);
    });

    testWidgets('lỗi quyền truy cập → ẩn nút "Thử lại"', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppErrorView.fromFailure(
            const AppFailure(AppFailureType.permission, 'Không có quyền.'),
            onRetry: () {},
          ),
        ),
      );
      expect(find.text('Không có quyền'), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
    });
  });

  testWidgets('AppEmptyView hiển thị tiêu đề, mô tả và hành động', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        AppEmptyView(
          icon: Icons.inbox,
          title: 'Chưa có dữ liệu',
          message: 'Hãy tạo mới.',
          action: TextButton(onPressed: () {}, child: const Text('Tạo')),
        ),
      ),
    );
    expect(find.text('Chưa có dữ liệu'), findsOneWidget);
    expect(find.text('Hãy tạo mới.'), findsOneWidget);
    expect(find.text('Tạo'), findsOneWidget);
  });

  testWidgets('AppLoadingView hiển thị vòng loading và thông điệp', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const AppLoadingView(message: 'Đang tải...')),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Đang tải...'), findsOneWidget);
  });

  group('SkeletonList', () {
    testWidgets('chạy animation khi bình thường', (tester) async {
      await tester.pumpWidget(_wrap(const SkeletonList(itemCount: 3)));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('tắt animation khi bật "Giảm chuyển động"', (tester) async {
      await tester.pumpWidget(
        _wrap(const SkeletonList(itemCount: 3), disableAnimations: true),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('NetworkStatusBanner', () {
    testWidgets('mất mạng hiện dải cảnh báo, có mạng lại thì báo rồi tự ẩn', (
      tester,
    ) async {
      final status = StreamController<bool>();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => NetworkStatusBanner(
            statusStream: status.stream,
            reconnectedDisplay: const Duration(seconds: 1),
            child: child!,
          ),
          home: const Scaffold(body: Text('Nội dung')),
        ),
      );
      expect(find.textContaining('Không có kết nối mạng'), findsNothing);

      status.add(false);
      await tester.pumpAndSettle();
      expect(find.textContaining('Không có kết nối mạng'), findsOneWidget);
      expect(find.text('Nội dung'), findsOneWidget);

      status.add(true);
      await tester.pumpAndSettle();
      expect(find.text('Đã kết nối lại.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Đã kết nối lại.'), findsNothing);
      await status.close();
    });

    testWidgets('lần đầu báo "có mạng" thì không hiện gì', (tester) async {
      final status = StreamController<bool>();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              NetworkStatusBanner(statusStream: status.stream, child: child!),
          home: const Scaffold(body: Text('Nội dung')),
        ),
      );
      status.add(true);
      await tester.pumpAndSettle();
      expect(find.text('Đã kết nối lại.'), findsNothing);
      await status.close();
    });
  });
}
