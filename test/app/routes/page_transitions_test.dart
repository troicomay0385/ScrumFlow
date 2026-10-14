// US-064 — Hiệu ứng chuyển trang thống nhất, tôn trọng "Giảm chuyển động",
// không làm hỏng điều hướng / nút Back / tham số route.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/routes/app_page_transitions.dart';
import 'package:scrumflow/app/routes/app_routes.dart';
import 'package:scrumflow/app/theme/app_theme.dart';

import '../../helpers/test_setup.dart';

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ElevatedButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Trang 2')),
        ),
      ),
      child: const Text('Đi'),
    ),
  );
}

void main() {
  setUpAll(setUpWidgetTestEnvironment);

  testWidgets(
    'theme đăng ký transition ScrumFlow cho Android/Windows, Cupertino cho iOS',
    (tester) async {
      final builders = AppTheme.lightTheme.pageTransitionsTheme.builders;
      expect(
        builders[TargetPlatform.android],
        isA<ScrumFlowPageTransitionsBuilder>(),
      );
      expect(
        builders[TargetPlatform.windows],
        isA<ScrumFlowPageTransitionsBuilder>(),
      );
      expect(
        builders[TargetPlatform.iOS],
        isA<CupertinoPageTransitionsBuilder>(),
      );
    },
  );

  testWidgets('MaterialPageRoute dùng fade + slide; Back quay về đúng trang', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.android),
        home: const _Home(),
      ),
    );

    await tester.tap(find.text('Đi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Đang giữa hiệu ứng: có FadeTransition của AppPageTransition.
    expect(
      find.ancestor(
        of: find.text('Trang 2'),
        matching: find.byType(FadeTransition),
      ),
      findsWidgets,
    );
    await tester.pumpAndSettle();
    expect(find.text('Trang 2'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('Đi'), findsOneWidget);
    expect(find.text('Trang 2'), findsNothing);
  });

  testWidgets('"Giảm chuyển động" bật → chuyển trang tức thì', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.android),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const _Home(),
      ),
    );

    await tester.tap(find.text('Đi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    final fades = tester.widgetList<FadeTransition>(
      find.ancestor(
        of: find.text('Trang 2'),
        matching: find.byType(FadeTransition),
      ),
    );
    // Không có FadeTransition nào đang làm mờ trang đích.
    expect(fades.every((f) => f.opacity.value == 1.0), isTrue);
  });

  testWidgets('buildRoute giữ nguyên settings (tên route + arguments)', (
    tester,
  ) async {
    final route = AppRoutes.buildRoute(
      page: const SizedBox(),
      settings: const RouteSettings(name: '/x', arguments: 'p1'),
    );
    expect(route.settings.name, '/x');
    expect(route.settings.arguments, 'p1');
    expect(route.transitionDuration, AppPageTransition.duration);
  });

  testWidgets(
    'route cần projectId nhưng thiếu arguments → về Login, không crash',
    (tester) async {
      final route = AppRoutes.generateRoute(
        const RouteSettings(name: AppRoutes.projectDetail),
      );
      expect(route.settings.name, AppRoutes.login);
    },
  );
}
