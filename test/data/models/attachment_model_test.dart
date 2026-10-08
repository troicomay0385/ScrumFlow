import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/data/models/attachment_model.dart';

void main() {
  group('AttachmentModel & AttachmentTarget', () {
    test('AttachmentTarget identifies story vs task correctly', () {
      const storyTarget = AttachmentTarget.story(
        projectId: 'p1',
        storyId: 's1',
      );
      expect(storyTarget.isStory, isTrue);
      expect(storyTarget.isTask, isFalse);
      expect(storyTarget.projectId, 'p1');
      expect(storyTarget.storyId, 's1');

      const taskTarget = AttachmentTarget.task(
        projectId: 'p1',
        taskId: 't1',
      );
      expect(taskTarget.isTask, isTrue);
      expect(taskTarget.isStory, isFalse);
      expect(taskTarget.taskId, 't1');
    });

    test('AttachmentType resolves from extension accurately', () {
      expect(AttachmentType.fromExtension('png'), AttachmentType.image);
      expect(AttachmentType.fromExtension('.jpg'), AttachmentType.image);
      expect(AttachmentType.fromExtension('pdf'), AttachmentType.pdf);
      expect(AttachmentType.fromExtension('.docx'), AttachmentType.doc);
      expect(AttachmentType.fromExtension('zip'), AttachmentType.archive);
      expect(AttachmentType.fromExtension('url'), AttachmentType.link);
      expect(AttachmentType.fromExtension('xyz'), AttachmentType.other);
      expect(AttachmentType.fromExtension(null), AttachmentType.other);
    });

    test('AttachmentModel formats file size appropriately', () {
      final now = DateTime(2026, 10, 7);
      final small = AttachmentModel(
        id: '1',
        projectId: 'p1',
        fileName: 'readme.txt',
        fileSize: 500,
        fileType: 'txt',
        uploadedById: 'u1',
        uploadedByName: 'Alex',
        createdAt: now,
      );
      expect(small.formattedSize, '500 B');

      final medium = AttachmentModel(
        id: '2',
        projectId: 'p1',
        fileName: 'spec.pdf',
        fileSize: 2048 * 1024,
        fileType: 'pdf',
        uploadedById: 'u1',
        uploadedByName: 'Alex',
        createdAt: now,
      );
      expect(medium.formattedSize, '2.0 MB');

      final link = AttachmentModel(
        id: '3',
        projectId: 'p1',
        fileName: 'Figma',
        fileSize: 0,
        fileType: 'link',
        isLink: true,
        uploadedById: 'u1',
        uploadedByName: 'Alex',
        createdAt: now,
      );
      expect(link.formattedSize, 'Liên kết web');
      expect(link.typeEnum, AttachmentType.link);
    });

    test('AttachmentModel serialization toMap and fromMap roundtrip', () {
      final now = DateTime(2026, 10, 7, 10, 0);
      final model = AttachmentModel(
        id: 'att1',
        projectId: 'p1',
        storyId: 's1',
        fileName: 'diagram.png',
        fileSize: 1024,
        fileType: 'png',
        fileUrl: 'https://example.com/diagram.png',
        isLink: false,
        uploadedById: 'u1',
        uploadedByName: 'User One',
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['projectId'], 'p1');
      expect(map['storyId'], 's1');
      expect(map['fileName'], 'diagram.png');
      expect(map['fileSize'], 1024);

      final restored = AttachmentModel.fromMap(map, 'att1');
      expect(restored.id, 'att1');
      expect(restored.fileName, model.fileName);
      expect(restored.fileUrl, model.fileUrl);
      expect(restored.uploadedByName, 'User One');
    });

    test('AttachmentModel parses Timestamp in fromMap', () {
      final ts = Timestamp.fromDate(DateTime(2026, 10, 7));
      final model = AttachmentModel.fromMap({
        'projectId': 'p1',
        'fileName': 'test.doc',
        'fileSize': 100,
        'fileType': 'doc',
        'uploadedById': 'u1',
        'uploadedByName': 'User',
        'createdAt': ts,
      }, 'doc1');

      expect(model.id, 'doc1');
      expect(model.createdAt, ts.toDate());
    });
  });
}
