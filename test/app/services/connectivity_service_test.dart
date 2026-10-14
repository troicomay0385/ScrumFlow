// US-063 — Kiểm tra trạng thái mạng (pre-check) và stream thay đổi.
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/services/connectivity_service.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  late _MockConnectivity connectivity;
  late ConnectivityService service;

  setUp(() {
    connectivity = _MockConnectivity();
    service = ConnectivityService(connectivity: connectivity);
  });

  test('wifi → có mạng', () async {
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    expect(await service.isOnline(), isTrue);
  });

  test('none → không có mạng', () async {
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);
    expect(await service.isOnline(), isFalse);
  });

  test('danh sách rỗng → không có mạng', () async {
    when(() => connectivity.checkConnectivity()).thenAnswer((_) async => []);
    expect(await service.checkConnectivity(), isFalse);
  });

  test(
    'plugin lỗi → isOnline coi như có mạng (không chặn người dùng)',
    () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenThrow(Exception('MissingPluginException'));
      expect(await service.isOnline(), isTrue);
    },
  );

  test('onStatusChanged chỉ phát khi trạng thái thực sự đổi', () async {
    final controller = StreamController<List<ConnectivityResult>>();
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => controller.stream);

    final values = <bool>[];
    final sub = service.onStatusChanged.listen(values.add);
    controller
      ..add([ConnectivityResult.wifi])
      ..add([ConnectivityResult.mobile]) // vẫn online → bỏ qua
      ..add([ConnectivityResult.none])
      ..add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);

    expect(values, [true, false, true]);
    await sub.cancel();
    await controller.close();
  });
}
