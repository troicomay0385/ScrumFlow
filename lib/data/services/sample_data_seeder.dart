import 'package:flutter/foundation.dart';

import '../../app/services/notification_service.dart';
import '../models/attachment_model.dart';
import '../models/project_member_display.dart';
import '../models/user_story_model.dart';
import '../repositories/attachment_repository.dart';
import '../repositories/backlog_repository.dart';
import '../repositories/sprint_repository.dart';
import '../repositories/task_repository.dart';

/// Dịch vụ tự động sinh dữ liệu mẫu (Sample / Seed Test Data) cho dự án.
/// Phục vụ kiểm thử toàn diện Sprint 2, Sprint 3, và Sprint 4:
/// - Tìm kiếm (US-007), Lọc đa tiêu chí (US-008), Xóa (US-012)
/// - Đổi người phụ trách & Trợ lý AI tính điểm (US-043, US-057, US-058)
/// - Tệp đính kèm & Liên kết ngoài (US-047)
/// - Nhắc nhở hạn chót Local Notification (US-059)
/// - Sprint & Kanban Board (US-055, US-056)
class SampleDataSeeder {
  final BacklogRepository backlogRepo;
  final TaskRepository taskRepo;
  final AttachmentRepository attachmentRepo;
  final SprintRepository sprintRepo;
  final NotificationService notificationService;

  SampleDataSeeder({
    required this.backlogRepo,
    required this.taskRepo,
    required this.attachmentRepo,
    required this.sprintRepo,
    NotificationService? notificationService,
  }) : notificationService = notificationService ?? NotificationService();

  /// Nạp toàn bộ dữ liệu mẫu vào dự án và bắn thông báo mẫu.
  Future<SampleSeedResult> seedSampleData({
    required String projectId,
    required List<ProjectMemberDisplay> members,
    String? currentUserId,
    String? currentUserName,
  }) async {
    int createdSprints = 0;
    int createdStories = 0;
    int createdTasks = 0;
    int createdAttachments = 0;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final tomorrow = now.add(const Duration(days: 1));
    final inThreeDays = now.add(const Duration(days: 3));
    final inFiveDays = now.add(const Duration(days: 5));

    // Lấy thành viên để phân công
    final m1 = members.isNotEmpty ? members[0] : null;
    final m2 = members.length > 1 ? members[1] : m1;
    final m3 = members.length > 2 ? members[2] : m1;

    // ── 1. Tạo 4 User Stories mẫu đa dạng trạng thái, priority, tags ───────────
    final storiesToCreate = [
      _StoryDef(
        title: 'Thiết kế UI Đăng ký & Đăng nhập phong cách Stitch Bento',
        description:
            'Áp dụng bảng màu tím Indigo, Bento Card và hiệu ứng chuyển trang mượt mà theo Stitch Design System.',
        priority: 'CAO',
        status: 'Done',
        storyPoints: 5,
        tags: ['UI', 'Design', 'Auth'],
        deadline: yesterday,
        assigneeId: m1?.userId ?? currentUserId,
        assigneeName: m1?.user?.fullName ?? currentUserName,
        assigneeEmail: m1?.user?.email,
      ),
      _StoryDef(
        title: 'Xây dựng API xác thực Firebase Auth & Quản lý phiên',
        description:
            'Hỗ trợ Email/Password và Google Sign-In, đồng bộ token xác thực trên Firestore.',
        priority: 'CAO',
        status: 'In Progress',
        storyPoints: 8,
        tags: ['Backend', 'API', 'Security'],
        deadline: tomorrow,
        assigneeId: m2?.userId,
        assigneeName: m2?.user?.fullName,
        assigneeEmail: m2?.user?.email,
      ),
      _StoryDef(
        title: 'Viết bộ lọc Backlog đa tiêu chí và tìm kiếm theo từ khóa',
        description:
            'Hỗ trợ tìm kiếm theo tiêu đề, mã US, mô tả và lọc theo trạng thái, mức ưu tiên, nhãn tags (US-007 & US-008).',
        priority: 'TB',
        status: 'To Do',
        storyPoints: 3,
        tags: ['Filter', 'Search', 'Sprint2'],
        deadline: inThreeDays,
        assigneeId: m3?.userId,
        assigneeName: m3?.user?.fullName,
        assigneeEmail: m3?.user?.email,
      ),
      _StoryDef(
        title: 'Tối ưu hóa hiệu năng danh sách và bộ nhớ đệm Offline Cache',
        description:
            'Cải thiện thời gian tải dữ liệu, cache SQLite và hiển thị thông báo mất mạng thân thiện.',
        priority: 'THẤP',
        status: 'To Do',
        storyPoints: 13,
        tags: ['Performance', 'Database', 'Sprint5'],
        deadline: inFiveDays,
        assigneeId: null,
        assigneeName: null,
        assigneeEmail: null,
      ),
    ];

    final createdStoryModels = <UserStoryModel>[];

    for (int i = 0; i < storiesToCreate.length; i++) {
      final def = storiesToCreate[i];
      final storyId = 'sample_story_${DateTime.now().millisecondsSinceEpoch}_$i';
      final story = UserStoryModel(
        id: storyId,
        projectId: projectId,
        storyKey: 'US-00${i + 1}',
        title: def.title,
        description: def.description,
        priority: def.priority,
        status: def.status,
        storyPoints: def.storyPoints,
        tags: def.tags,
        deadline: def.deadline,
        assigneeId: def.assigneeId,
        assigneeName: def.assigneeName,
        assigneeEmail: def.assigneeEmail,
        createdAt: now,
        updatedAt: now,
      );

      try {
        await backlogRepo.saveUserStory(projectId, story);
        createdStories++;
        createdStoryModels.add(story);
      } catch (e) {
        debugPrint('Lỗi tạo User Story mẫu: $e');
      }
    }

    // ── 2. Tạo 1 Sprint Mẫu Active và gán User Stories (Sprint & Kanban Board) ──
    try {
      final sprintStoryIds = createdStoryModels.take(3).map((s) => s.id).toList();
      await sprintRepo.seedSprint(
        projectId: projectId,
        name: 'Sprint 1 - Phát triển Tính năng Cốt lõi',
        goal: 'Hoàn thiện luồng Đăng nhập, API xác thực và giao diện Kanban Board',
        startDate: yesterday,
        endDate: now.add(const Duration(days: 13)),
        status: 'Active',
        storyIds: sprintStoryIds,
      );
      createdSprints++;
    } catch (e) {
      debugPrint('Lỗi tạo Sprint mẫu: $e');
    }

    // ── 3. Tạo 4 Tasks mẫu gắn vào Story 1 và Story 2 ─────────────────────────
    final targetStory1 = createdStoryModels.isNotEmpty
        ? createdStoryModels[0]
        : null;
    final targetStory2 = createdStoryModels.length > 1
        ? createdStoryModels[1]
        : targetStory1;

    String? urgentTaskId;
    String? urgentTaskTitle;
    DateTime? urgentTaskDeadline;

    if (targetStory1 != null) {
      // Task 1: Hoàn thành đúng hạn (Status: Done)
      try {
        final t = await taskRepo.createTask(
          storyId: targetStory1.id,
          projectId: projectId,
          title: 'Tạo Wireframe & Mockup giao diện Login',
          description: 'Vẽ khung giao diện trên Figma và duyệt bố cục.',
          assigneeId: m1?.userId ?? currentUserId,
          assigneeName: m1?.user?.fullName ?? currentUserName,
          deadline: yesterday,
        );
        await taskRepo.updateTaskStatus(t.id, 'Done');
        createdTasks++;
      } catch (_) {}
    }

    if (targetStory2 != null) {
      // Task 2: Task đang làm dở và SẮP ĐẾN HẠN (US-059 Test Case)
      try {
        urgentTaskTitle = '⏰ Lập trình Form đăng ký Email & Mật khẩu (Sắp hết hạn)';
        urgentTaskDeadline = tomorrow;

        final t = await taskRepo.createTask(
          storyId: targetStory2.id,
          projectId: projectId,
          title: urgentTaskTitle,
          description:
              'Xử lý validate mật khẩu mạnh và phản hồi giao diện. Hạn chót ngày mai!',
          assigneeId: currentUserId ?? m1?.userId,
          assigneeName: currentUserName ?? m1?.user?.fullName,
          deadline: urgentTaskDeadline,
        );
        urgentTaskId = t.id;
        // Cập nhật trạng thái In Progress
        await taskRepo.updateTaskStatus(t.id, 'In Progress');
        createdTasks++;
      } catch (_) {}

      // Task 3: Task đang làm (In Progress)
      try {
        final t = await taskRepo.createTask(
          storyId: targetStory2.id,
          projectId: projectId,
          title: 'Thiết kế Banner Trợ lý AI Bento Box',
          description: 'Tích hợp card gradient tím và nút chọn nhanh 1-chạm.',
          assigneeId: m2?.userId,
          assigneeName: m2?.user?.fullName,
          deadline: inThreeDays,
        );
        await taskRepo.updateTaskStatus(t.id, 'In Progress');
        createdTasks++;
      } catch (_) {}

      // Task 4: Task To Do
      try {
        await taskRepo.createTask(
          storyId: targetStory2.id,
          projectId: projectId,
          title: 'Viết kịch bản kiểm thử trên thiết bị di động Xiaomi',
          description: 'Chạy kiểm thử chức năng trên Android 14.',
          assigneeId: m3?.userId,
          assigneeName: m3?.user?.fullName,
          deadline: inFiveDays,
        );
        createdTasks++;
      } catch (_) {}
    }

    // ── 4. Tạo Tệp đính kèm mẫu (Attachments US-047) ─────────────────────────
    if (targetStory1 != null) {
      try {
        // Link Figma mẫu
        await attachmentRepo.addAttachment(
          target: AttachmentTarget.story(
            projectId: projectId,
            storyId: targetStory1.id,
          ),
          fileName: 'Bản vẽ thiết kế Figma Stitch UI/UX',
          fileSize: 0,
          fileType: 'link',
          fileUrl: 'https://www.figma.com',
          isLink: true,
        );
        createdAttachments++;

        // Ảnh mockup UI mẫu (mở xem trước trực tiếp)
        await attachmentRepo.addAttachment(
          target: AttachmentTarget.story(
            projectId: projectId,
            storyId: targetStory1.id,
          ),
          fileName: 'UI_Mockup_Kanban_Board.png',
          fileSize: 450000,
          fileType: 'png',
          fileUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
          isLink: false,
        );
        createdAttachments++;
      } catch (_) {}
    }

    if (urgentTaskId != null) {
      try {
        // Link Google Docs
        await attachmentRepo.addAttachment(
          target: AttachmentTarget.task(
            projectId: projectId,
            taskId: urgentTaskId,
          ),
          fileName: 'Tài liệu Đặc tả API Backend (Google Docs)',
          fileSize: 0,
          fileType: 'link',
          fileUrl: 'https://docs.google.com',
          isLink: true,
        );
        createdAttachments++;

        // Tài liệu PDF mẫu (có link để bấm mở xem ngay)
        await attachmentRepo.addAttachment(
          target: AttachmentTarget.task(
            projectId: projectId,
            taskId: urgentTaskId,
          ),
          fileName: 'KichBanKiemThuSprint2_3.pdf',
          fileSize: 1420000,
          fileType: 'pdf',
          fileUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          isLink: false,
        );
        createdAttachments++;
      } catch (_) {}
    }

    // ── 5. Bắn Local Notification cảnh báo hạn chót ngay lập tức (US-059) ────
    if (urgentTaskTitle != null && urgentTaskDeadline != null) {
      try {
        await notificationService.showTaskDeadlineAlert(
          taskTitle: urgentTaskTitle,
          deadline: urgentTaskDeadline,
          hoursRemaining: 24,
        );
      } catch (e) {
        debugPrint('Lỗi bắn thông báo mẫu: $e');
      }
    }

    return SampleSeedResult(
      createdSprints: createdSprints,
      createdStories: createdStories,
      createdTasks: createdTasks,
      createdAttachments: createdAttachments,
      hasNotifiedDeadline: urgentTaskTitle != null,
    );
  }
}

class _StoryDef {
  final String title;
  final String description;
  final String priority;
  final String status;
  final int storyPoints;
  final List<String> tags;
  final DateTime? deadline;
  final String? assigneeId;
  final String? assigneeName;
  final String? assigneeEmail;

  _StoryDef({
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.storyPoints,
    required this.tags,
    this.deadline,
    this.assigneeId,
    this.assigneeName,
    this.assigneeEmail,
  });
}

class SampleSeedResult {
  final int createdSprints;
  final int createdStories;
  final int createdTasks;
  final int createdAttachments;
  final bool hasNotifiedDeadline;

  const SampleSeedResult({
    this.createdSprints = 0,
    required this.createdStories,
    required this.createdTasks,
    required this.createdAttachments,
    required this.hasNotifiedDeadline,
  });
}
