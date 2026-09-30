import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/presentation/backlog/bloc/story_tags_cubit.dart';
import 'package:scrumflow/presentation/backlog/bloc/story_tags_state.dart';

class MockBacklogRepository extends Mock implements BacklogRepository {}

void main() {
  const projectId = 'p1';
  const storyId = 's1';
  late MockBacklogRepository repository;

  StoryTagsCubit buildCubit([List<String> initial = const ['Frontend']]) =>
      StoryTagsCubit(
        repository,
        projectId: projectId,
        storyId: storyId,
        initialTags: initial,
      );

  void stubUpdate(Future<void> Function() answer) {
    when(() => repository.updateTags(
          projectId: any(named: 'projectId'),
          storyId: any(named: 'storyId'),
          tags: any(named: 'tags'),
        )).thenAnswer((_) => answer());
  }

  setUp(() => repository = MockBacklogRepository());

  group('addTag / removeTag (bản nháp)', () {
    test('thêm tag hợp lệ (tự trim khoảng trắng) → isDirty', () {
      final cubit = buildCubit();
      expect(cubit.addTag('  Authentication   API '), isNull);
      expect(cubit.state.tags, ['Frontend', 'Authentication API']);
      expect(cubit.state.isDirty, isTrue);
    });

    test('tag rỗng bị từ chối, state không đổi', () {
      final cubit = buildCubit();
      expect(cubit.addTag('   '), 'Tên tag không được để trống');
      expect(cubit.state.tags, ['Frontend']);
      expect(cubit.state.isDirty, isFalse);
    });

    test('tag trùng (không phân biệt hoa thường) bị từ chối', () {
      final cubit = buildCubit();
      expect(cubit.addTag('frontend'), 'Tag "frontend" đã tồn tại');
      expect(cubit.state.tags, ['Frontend']);
    });

    test('tag quá dài và vượt số lượng tối đa bị từ chối', () {
      expect(buildCubit().addTag('x' * 31), 'Tag tối đa 30 ký tự');
      final full = buildCubit(List.generate(10, (i) => 'Tag$i'));
      expect(full.addTag('Mới'), 'Mỗi User Story chỉ gắn tối đa 10 tag');
    });

    test('xoá tag rồi thêm lại đúng tag đó → không còn thay đổi chưa lưu', () {
      final cubit = buildCubit(const ['Frontend', 'UI']);
      cubit.removeTag('UI');
      expect(cubit.state.tags, ['Frontend']);
      expect(cubit.state.isDirty, isTrue);
      cubit.addTag('UI');
      expect(cubit.state.isDirty, isFalse);
    });

    test('discardChanges quay về tag đã lưu', () {
      final cubit = buildCubit();
      cubit.addTag('Backend');
      cubit.discardChanges();
      expect(cubit.state.tags, ['Frontend']);
    });
  });

  group('save', () {
    blocTest<StoryTagsCubit, StoryTagsState>(
      'lưu thành công → chỉ gửi danh sách tags qua updateTags, savedTags cập nhật',
      build: () {
        stubUpdate(() async {});
        return buildCubit();
      },
      act: (cubit) async {
        cubit.addTag('Authentication');
        cubit.removeTag('Frontend');
        await cubit.save();
      },
      skip: 2,
      expect: () => [
        isA<StoryTagsState>()
            .having((s) => s.status, 'status', StoryTagsStatus.saving),
        isA<StoryTagsState>()
            .having((s) => s.status, 'status', StoryTagsStatus.saved)
            .having((s) => s.savedTags, 'savedTags', ['Authentication'])
            .having((s) => s.isDirty, 'isDirty', isFalse),
      ],
      verify: (_) {
        verify(() => repository.updateTags(
              projectId: projectId,
              storyId: storyId,
              tags: ['Authentication'],
            )).called(1);
      },
    );

    blocTest<StoryTagsCubit, StoryTagsState>(
      'xoá hết tag → lưu danh sách rỗng',
      build: () {
        stubUpdate(() async {});
        return buildCubit();
      },
      act: (cubit) async {
        cubit.removeTag('Frontend');
        await cubit.save();
      },
      verify: (_) {
        verify(() => repository.updateTags(
              projectId: projectId,
              storyId: storyId,
              tags: <String>[],
            )).called(1);
      },
    );

    blocTest<StoryTagsCubit, StoryTagsState>(
      'không có thay đổi → không gọi repository',
      build: buildCubit,
      act: (cubit) => cubit.save(),
      expect: () => <StoryTagsState>[],
      verify: (_) => verifyNoMoreInteractions(repository),
    );

    blocTest<StoryTagsCubit, StoryTagsState>(
      'lỗi khi lưu → failure, giữ nguyên bản nháp để thử lại',
      build: () {
        stubUpdate(() async => throw Exception(
            'Không có quyền truy cập dữ liệu. Vui lòng kiểm tra lại phân quyền tài khoản.'));
        return buildCubit();
      },
      act: (cubit) async {
        cubit.addTag('Backend');
        await cubit.save();
      },
      skip: 2,
      expect: () => [
        isA<StoryTagsState>()
            .having((s) => s.status, 'status', StoryTagsStatus.failure)
            .having((s) => s.message, 'message',
                startsWith('Không có quyền truy cập'))
            .having((s) => s.tags, 'tags', ['Frontend', 'Backend'])
            .having((s) => s.savedTags, 'savedTags', ['Frontend']),
      ],
    );
  });
}
