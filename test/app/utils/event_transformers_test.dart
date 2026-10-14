// US-063 — Transformer restartable: event mới huỷ xử lý của event cũ.
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/utils/event_transformers.dart';

class _Subscribe {
  final StreamController<int> source;
  _Subscribe(this.source);
}

class _TestBloc extends Bloc<_Subscribe, int> {
  _TestBloc() : super(0) {
    on<_Subscribe>(
      (event, emit) =>
          emit.forEach<int>(event.source.stream, onData: (value) => value),
      transformer: restartable(),
    );
  }
}

void main() {
  test('event mới huỷ subscription của event trước', () async {
    var firstCancelled = false;
    final first = StreamController<int>(onCancel: () => firstCancelled = true);
    final second = StreamController<int>();
    final bloc = _TestBloc();
    final states = <int>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(_Subscribe(first));
    await Future<void>.delayed(Duration.zero);
    first.add(1);
    await Future<void>.delayed(Duration.zero);

    bloc.add(_Subscribe(second));
    await Future<void>.delayed(Duration.zero);
    expect(firstCancelled, isTrue);

    // Dữ liệu từ nguồn cũ (nếu có) không còn tới bloc.
    second.add(2);
    await Future<void>.delayed(Duration.zero);
    expect(states, [1, 2]);

    await sub.cancel();
    await bloc.close();
    await first.close();
    await second.close();
  });
}
