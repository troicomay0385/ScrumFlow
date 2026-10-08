import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/models/attachment_model.dart';
import 'package:scrumflow/data/repositories/attachment_repository.dart';
import 'package:scrumflow/presentation/attachments/bloc/attachments_cubit.dart';
import 'package:scrumflow/presentation/attachments/bloc/attachments_state.dart';

class MockAttachmentRepository extends Mock implements AttachmentRepository {}

class FakeAttachmentTarget extends Fake implements AttachmentTarget {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAttachmentTarget());
  });

  const storyTarget = AttachmentTarget.story(projectId: 'p1', storyId: 's1');
  const taskTarget = AttachmentTarget.task(projectId: 'p1', taskId: 't1');
  final now = DateTime(2026, 10, 7, 10);

  AttachmentModel attachment(String id, String fileName) => AttachmentModel(
        id: id,
        projectId: 'p1',
        storyId: 's1',
        fileName: fileName,
        fileSize: 1024,
        fileType: 'pdf',
        uploadedById: 'u1',
        uploadedByName: 'Duy',
        createdAt: now,
      );

  late MockAttachmentRepository repository;
  late StreamController<List<AttachmentModel>> stream;

  setUp(() {
    repository = MockAttachmentRepository();
    stream = StreamController<List<AttachmentModel>>.broadcast();
    when(() => repository.streamAttachments(any()))
        .thenAnswer((_) => stream.stream);
  });

  tearDown(() => stream.close());

  group('Tải tệp đính kèm (real-time stream)', () {
    blocTest<AttachmentsCubit, AttachmentsState>(
      'loading -> loaded khi có danh sách tệp',
      build: () => AttachmentsCubit(repository, target: storyTarget),
      act: (cubit) async {
        await cubit.start();
        stream.add([attachment('a1', 'spec.pdf')]);
      },
      expect: () => [
        const AttachmentsState(status: AttachmentsStatus.loading),
        AttachmentsState(
          status: AttachmentsStatus.loaded,
          attachments: [attachment('a1', 'spec.pdf')],
        ),
      ],
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'loading -> failure khi stream lỗi',
      build: () => AttachmentsCubit(repository, target: storyTarget),
      act: (cubit) async {
        await cubit.start();
        stream.addError(Exception('Network error'));
      },
      expect: () => [
        const AttachmentsState(status: AttachmentsStatus.loading),
        const AttachmentsState(
          status: AttachmentsStatus.failure,
          loadError: 'Network error',
        ),
      ],
    );
  });

  group('Thêm liên kết web (addLink)', () {
    blocTest<AttachmentsCubit, AttachmentsState>(
      'báo lỗi khi tiêu đề hoặc URL rỗng',
      build: () => AttachmentsCubit(repository, target: storyTarget),
      act: (cubit) => cubit.addLink(title: '', url: 'https://figma.com'),
      expect: () => [
        const AttachmentsState(
          actionError: 'Tiêu đề liên kết không được để trống',
        ),
      ],
    );

    blocTest<AttachmentsCubit, AttachmentsState>(
      'thêm link thành công với tiền tố https tự động bổ sung',
      build: () {
        when(() => repository.addAttachment(
              target: any(named: 'target'),
              fileName: any(named: 'fileName'),
              fileSize: any(named: 'fileSize'),
              fileType: any(named: 'fileType'),
              fileUrl: any(named: 'fileUrl'),
              isLink: any(named: 'isLink'),
            )).thenAnswer((_) async => attachment('link1', 'Figma Spec'));
        return AttachmentsCubit(repository, target: storyTarget);
      },
      act: (cubit) => cubit.addLink(
        title: 'Figma Spec',
        url: 'figma.com/file/123',
      ),
      expect: () => [
        const AttachmentsState(isUploading: true),
        const AttachmentsState(
          isUploading: false,
          actionSuccess: 'Đã thêm liên kết "Figma Spec"',
        ),
      ],
      verify: (_) {
        verify(() => repository.addAttachment(
              target: storyTarget,
              fileName: 'Figma Spec',
              fileSize: 0,
              fileType: 'link',
              fileUrl: 'https://figma.com/file/123',
              isLink: true,
            )).called(1);
      },
    );
  });

  group('Tải tệp từ thiết bị (pickAndUploadFile)', () {
    test('hủy chọn file không phát sinh lỗi', () async {
      final cubit = AttachmentsCubit(
        repository,
        target: taskTarget,
        pickFiles: () async => null,
      );

      final success = await cubit.pickAndUploadFile();
      expect(success, isFalse);
      expect(cubit.state.isUploading, isFalse);
      expect(cubit.state.actionError, isNull);
    });

    test('chọn file thành công gọi repository.addAttachment', () async {
      when(() => repository.addAttachment(
            target: any(named: 'target'),
            fileName: any(named: 'fileName'),
            fileSize: any(named: 'fileSize'),
            fileType: any(named: 'fileType'),
            fileUrl: any(named: 'fileUrl'),
            isLink: any(named: 'isLink'),
          )).thenAnswer((_) async => attachment('file1', 'document.pdf'));

      final cubit = AttachmentsCubit(
        repository,
        target: taskTarget,
        pickFiles: () async => FilePickerResult([
          PlatformFile(
            name: 'document.pdf',
            size: 1024,
            bytes: null,
            path: '/storage/document.pdf',
          ),
        ]),
      );

      final success = await cubit.pickAndUploadFile();
      expect(success, isTrue);
      expect(cubit.state.actionSuccess, 'Đã tải lên tệp "document.pdf"');
      verify(() => repository.addAttachment(
            target: taskTarget,
            fileName: 'document.pdf',
            fileSize: 1024,
            fileType: 'pdf',
            fileUrl: '/storage/document.pdf',
            isLink: false,
          )).called(1);
    });

    test('xóa attachment gọi repository.deleteAttachment', () async {
      when(() => repository.deleteAttachment(
            target: any(named: 'target'),
            attachmentId: any(named: 'attachmentId'),
          )).thenAnswer((_) async {});

      final cubit = AttachmentsCubit(repository, target: taskTarget);
      final success = await cubit.deleteAttachment('att1');

      expect(success, isTrue);
      verify(() => repository.deleteAttachment(
            target: taskTarget,
            attachmentId: 'att1',
          )).called(1);
    });
  });
}
