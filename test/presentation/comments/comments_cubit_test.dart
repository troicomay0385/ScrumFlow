import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/models/comment_model.dart';
import 'package:scrumflow/data/repositories/comment_repository.dart';
import 'package:scrumflow/presentation/comments/bloc/comments_cubit.dart';
import 'package:scrumflow/presentation/comments/bloc/comments_state.dart';

class MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  const storyTarget = CommentTarget.story(projectId: 'p1', storyId: 's1');
  const taskTarget = CommentTarget.task(projectId: 'p1', taskId: 't1');

  CommentModel comment(String id, String author, String content) =>
      CommentModel(
        id: id,
        projectId: 'p1',
        taskId: 't1',
        authorId: 'u-$author',
        authorName: author,
        content: content,
        createdAt: DateTime(2026, 10, 6, 9),
      );

  late MockCommentRepository repository;
  late StreamController<List<CommentModel>> stream;

  void stubSend(Future<void> Function() answer) {
    when(() => repository.addComment(
          target: any(named: 'target'),
          content: any(named: 'content'),
        )).thenAnswer((_) => answer());
  }

  setUpAll(() => registerFallbackValue(storyTarget));

  setUp(() {
    repository = MockCommentRepository();
    stream = StreamController<List<CommentModel>>.broadcast();
    when(() => repository.streamComments(any()))
        .thenAnswer((_) => stream.stream);
  });

  tearDown(() => stream.close());

  group('tải bình luận', () {
    blocTest<CommentsCubit, CommentsState>(
      'loading → loaded (rỗng) → loaded khi có bình luận mới (real-time)',
      build: () => CommentsCubit(repository, target: taskTarget),
      act: (cubit) async {
        await cubit.start();
        stream.add(const []);
        await pumpEventQueue();
        stream.add([comment('c1', 'Phúc', 'Đã hoàn thành UI.')]);
        await pumpEventQueue();
        stream.add([
          comment('c1', 'Phúc', 'Đã hoàn thành UI.'),
          comment('c2', 'Hiếu', 'Nhớ kiểm tra validation.'),
        ]);
      },
      expect: () => [
        const CommentsState(),
        const CommentsState(status: CommentsStatus.loaded),
        isA<CommentsState>()
            .having((s) => s.comments.length, 'số bình luận', 1)
            .having((s) => s.comments.first.authorName, 'author', 'Phúc'),
        isA<CommentsState>()
            .having((s) => s.comments.length, 'số bình luận', 2)
            .having((s) => s.comments.last.content, 'bình luận mới',
                'Nhớ kiểm tra validation.'),
      ],
      verify: (_) {
        // Task comment chỉ nghe đúng target của task, không nghe story.
        verify(() => repository.streamComments(taskTarget)).called(1);
        verifyNever(() => repository.streamComments(storyTarget));
      },
    );

    blocTest<CommentsCubit, CommentsState>(
      'US-045: cubit của User Story nghe đúng target story',
      build: () => CommentsCubit(repository, target: storyTarget),
      act: (cubit) => cubit.start(),
      verify: (_) {
        verify(() => repository.streamComments(storyTarget)).called(1);
        verifyNever(() => repository.streamComments(taskTarget));
      },
    );

    blocTest<CommentsCubit, CommentsState>(
      'stream lỗi → failure kèm thông báo; start() lại để thử lại',
      build: () => CommentsCubit(repository, target: taskTarget),
      act: (cubit) async {
        await cubit.start();
        stream.addError(Exception('Không có quyền truy cập dữ liệu.'));
        await pumpEventQueue();
        await cubit.start();
        stream.add(const []);
      },
      expect: () => [
        const CommentsState(),
        const CommentsState(
          status: CommentsStatus.failure,
          loadError: 'Không có quyền truy cập dữ liệu.',
        ),
        const CommentsState(status: CommentsStatus.loading),
        const CommentsState(status: CommentsStatus.loaded),
      ],
    );
  });

  group('gửi bình luận', () {
    blocTest<CommentsCubit, CommentsState>(
      'gửi thành công → isSending bật rồi tắt, trả về true, nội dung đã trim',
      build: () {
        stubSend(() async {});
        return CommentsCubit(repository, target: taskTarget);
      },
      act: (cubit) async {
        expect(await cubit.send('  Đã hoàn thành UI.  '), isTrue);
      },
      expect: () => [
        const CommentsState(isSending: true),
        const CommentsState(),
      ],
      verify: (_) {
        verify(() => repository.addComment(
              target: taskTarget,
              content: 'Đã hoàn thành UI.',
            )).called(1);
      },
    );

    blocTest<CommentsCubit, CommentsState>(
      'US-045: gửi từ User Story dùng target story',
      build: () {
        stubSend(() async {});
        return CommentsCubit(repository, target: storyTarget);
      },
      act: (cubit) => cubit.send('Đã hoàn thành giao diện.'),
      verify: (_) {
        verify(() => repository.addComment(
              target: storyTarget,
              content: 'Đã hoàn thành giao diện.',
            )).called(1);
      },
    );

    blocTest<CommentsCubit, CommentsState>(
      'bình luận rỗng / toàn khoảng trắng bị từ chối, không gọi repository',
      build: () => CommentsCubit(repository, target: taskTarget),
      act: (cubit) async {
        expect(await cubit.send(''), isFalse);
        expect(await cubit.send('   \n  '), isFalse);
      },
      expect: () => [
        const CommentsState(sendError: 'Vui lòng nhập nội dung bình luận'),
      ],
      verify: (_) {
        verifyNever(() => repository.addComment(
              target: any(named: 'target'),
              content: any(named: 'content'),
            ));
      },
    );

    blocTest<CommentsCubit, CommentsState>(
      'gửi lỗi → trả về false, hiện thông báo, danh sách bình luận giữ nguyên',
      build: () {
        stubSend(() async => throw Exception('Lỗi kết nối mạng.'));
        return CommentsCubit(repository, target: taskTarget);
      },
      act: (cubit) async {
        await cubit.start();
        stream.add([comment('c1', 'Phúc', 'Đã hoàn thành UI.')]);
        await pumpEventQueue();
        expect(await cubit.send('Bình luận mới'), isFalse);
      },
      skip: 3, // loading, loaded, đang gửi
      expect: () => [
        isA<CommentsState>()
            .having((s) => s.isSending, 'isSending', isFalse)
            .having((s) => s.sendError, 'sendError', 'Lỗi kết nối mạng.')
            .having((s) => s.comments.length, 'số bình luận', 1),
      ],
    );

    test('đang gửi thì bấm gửi lần nữa bị bỏ qua (không gửi trùng)', () async {
      final completer = Completer<void>();
      stubSend(() => completer.future);
      final cubit = CommentsCubit(repository, target: taskTarget);

      final first = cubit.send('Một');
      expect(await cubit.send('Hai'), isFalse);
      completer.complete();
      expect(await first, isTrue);

      verify(() => repository.addComment(
            target: any(named: 'target'),
            content: any(named: 'content'),
          )).called(1);
      await cubit.close();
    });
  });
}
