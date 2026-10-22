import 'package:flutter/foundation.dart';

import '../models/project_member_display.dart';
import '../models/user_story_model.dart';
import '../repositories/backlog_repository.dart';
import '../repositories/sprint_repository.dart';
import '../repositories/task_repository.dart';

/// Kết quả nạp dữ liệu Demo AI (US-069, US-070, US-071).
class AiDemoSeedResult {
  final int createdClosedSprints;
  final int createdActiveSprints;
  final int createdStories;
  final int createdTasks;

  const AiDemoSeedResult({
    required this.createdClosedSprints,
    required this.createdActiveSprints,
    required this.createdStories,
    required this.createdTasks,
  });
}

/// Dịch vụ sinh dữ liệu mẫu chuyên biệt cho AI Sprint Risk Radar (US-069, US-070, US-071):
/// - Tạo 2 Sprint đã đóng (`Completed`) kèm các User Story `Done` có `completedAt` để
///   mô phỏng Monte Carlo (`SprintForecastService`) lấy được thông lượng thực nghiệm.
/// - Tạo 1 Sprint đang chạy (`Active`) kèm các User Story đa dạng điểm & ưu tiên.
/// - Tạo 12 Tasks với phân bố đa dạng:
///   - Rủi ro CAO (chưa phân công, sát hạn/quá hạn, thành viên quá tải WIP, chưa log giờ).
///   - Rủi ro TRUNG BÌNH (In Progress, hạn 2–3 ngày, tải vừa).
///   - Rủi ro THẤP (đã log giờ đều, hạn xa, tải nhẹ).
///   - Các Task `Done` thực tế (có đủ đúng hạn & trễ hạn) để `ModelLabScreen` kết hợp
///     mẫu `real` cùng mẫu `synthetic`.
class AiDemoDataSeeder {
  final BacklogRepository backlogRepo;
  final SprintRepository sprintRepo;
  final TaskRepository taskRepo;

  const AiDemoDataSeeder({
    required this.backlogRepo,
    required this.sprintRepo,
    required this.taskRepo,
  });

  Future<AiDemoSeedResult> seedAiDemoData({
    required String projectId,
    required List<ProjectMemberDisplay> members,
    String? currentUserId,
    String? currentUserName,
    DateTime? referenceNow,
  }) async {
    final now = referenceNow ?? DateTime.now();
    final epoch = now.millisecondsSinceEpoch;

    final m1 = members.isNotEmpty ? members[0] : null;
    final m2 = members.length > 1 ? members[1] : m1;
    final m3 = members.length > 2 ? members[2] : m1;

    final uid1 = m1?.userId ?? currentUserId ?? 'demo_user_1';
    final name1 = m1?.user?.fullName ?? currentUserName ?? 'Lê Phúc (PO)';
    final uid2 = m2?.userId ?? 'demo_user_2';
    final name2 = m2?.user?.fullName ?? 'Nguyễn Hiếu (SM)';
    final uid3 = m3?.userId ?? 'demo_user_3';
    final name3 = m3?.user?.fullName ?? 'Phạm Duy (Dev)';

    int createdClosedSprints = 0;
    int createdActiveSprints = 0;
    int createdStories = 0;
    int createdTasks = 0;

    // ── 1. Tạo 4 User Stories lịch sử cho 2 Sprint đã đóng (Completed) ─────────
    final closedStoriesSprintA = <UserStoryModel>[
      UserStoryModel(
        id: 'ai_hist_story_${epoch}_1',
        projectId: projectId,
        storyKey: 'US-061',
        title: 'Thiết lập khung kiến trúc Clean Architecture & Auth',
        description: 'Hoàn thiện cấu trúc BLoC, Repository và phân quyền RBAC.',
        priority: 'CAO',
        storyPoints: 8,
        status: 'Done',
        assigneeId: uid1,
        assigneeName: name1,
        tags: const ['Architecture', 'Auth'],
        deadline: now.subtract(const Duration(days: 22)),
        createdAt: now.subtract(const Duration(days: 35)),
        updatedAt: now.subtract(const Duration(days: 23)),
        completedAt: now.subtract(const Duration(days: 23)),
      ),
      UserStoryModel(
        id: 'ai_hist_story_${epoch}_2',
        projectId: projectId,
        storyKey: 'US-062',
        title: 'Đồng bộ bộ nhớ đệm SQLite Offline-first',
        description:
            'Tự động lưu trữ đệm Backlog, Sprint và Task khi mất mạng.',
        priority: 'CAO',
        storyPoints: 8,
        status: 'Done',
        assigneeId: uid2,
        assigneeName: name2,
        tags: const ['Offline', 'SQLite'],
        deadline: now.subtract(const Duration(days: 21)),
        createdAt: now.subtract(const Duration(days: 34)),
        updatedAt: now.subtract(const Duration(days: 21)),
        completedAt: now.subtract(const Duration(days: 21)),
      ),
    ];

    final closedStoriesSprintB = <UserStoryModel>[
      UserStoryModel(
        id: 'ai_hist_story_${epoch}_3',
        projectId: projectId,
        storyKey: 'US-065',
        title: 'Thống kê hiệu suất thành viên & biểu đồ Burndown',
        description: 'Tính điểm KPI theo tỷ lệ đúng hạn và vẽ Burndown Chart.',
        priority: 'TB',
        storyPoints: 5,
        status: 'Done',
        assigneeId: uid2,
        assigneeName: name2,
        tags: const ['Analytics', 'Chart'],
        deadline: now.subtract(const Duration(days: 8)),
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 9)),
        completedAt: now.subtract(const Duration(days: 9)),
      ),
      UserStoryModel(
        id: 'ai_hist_story_${epoch}_4',
        projectId: projectId,
        storyKey: 'US-066',
        title: 'Ghi nhận thời gian làm việc (Work Log) trên từng Task',
        description:
            'Cộng dồn số giờ làm việc an toàn bằng giao dịch nguyên tử.',
        priority: 'CAO',
        storyPoints: 8,
        status: 'Done',
        assigneeId: uid3,
        assigneeName: name3,
        tags: const ['WorkLog', 'Task'],
        deadline: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 19)),
        updatedAt: now.subtract(const Duration(days: 7)),
        completedAt: now.subtract(const Duration(days: 7)),
      ),
    ];

    for (final s in [...closedStoriesSprintA, ...closedStoriesSprintB]) {
      try {
        await backlogRepo.saveUserStory(projectId, s);
        createdStories++;
      } catch (e) {
        debugPrint('Lỗi nạp Story lịch sử AI Demo: $e');
      }
    }

    try {
      await sprintRepo.seedSprint(
        projectId: projectId,
        name: 'Sprint 3 (Lịch sử AI) — Nền tảng & Offline',
        goal: 'Hoàn thành 16 SP nền tảng kiến trúc và SQLite cache',
        startDate: now.subtract(const Duration(days: 35)),
        endDate: now.subtract(const Duration(days: 21)),
        status: 'Completed',
        storyIds: closedStoriesSprintA.map((s) => s.id).toList(),
      );
      createdClosedSprints++;
    } catch (e) {
      debugPrint('Lỗi nạp Closed Sprint A: $e');
    }

    try {
      await sprintRepo.seedSprint(
        projectId: projectId,
        name: 'Sprint 4 (Lịch sử AI) — Hiệu suất & Work Log',
        goal: 'Hoàn thành 13 SP thống kê hiệu suất đội ngũ và log giờ',
        startDate: now.subtract(const Duration(days: 20)),
        endDate: now.subtract(const Duration(days: 6)),
        status: 'Completed',
        storyIds: closedStoriesSprintB.map((s) => s.id).toList(),
      );
      createdClosedSprints++;
    } catch (e) {
      debugPrint('Lỗi nạp Closed Sprint B: $e');
    }

    // ── 2. Tạo 4 User Stories cho Sprint 5 đang chạy (Active) ──────────────────
    final activeStories = <UserStoryModel>[
      UserStoryModel(
        id: 'ai_active_story_${epoch}_1',
        projectId: projectId,
        storyKey: 'US-069',
        title: 'AI Risk Radar — Dự đoán rủi ro trễ hạn từng Task',
        description:
            'Huấn luyện mô hình Logistic Regression thuần Dart và giải thích Top-3 lý do rủi ro.',
        priority: 'CAO',
        storyPoints: 8,
        status: 'In Progress',
        assigneeId: uid1,
        assigneeName: name1,
        tags: const ['AI', 'ML', 'RiskRadar', 'Blocked'],
        deadline: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      ),
      UserStoryModel(
        id: 'ai_active_story_${epoch}_2',
        projectId: projectId,
        storyKey: 'US-070',
        title: 'AI Sprint Forecast — Dự báo tiến độ bằng Monte Carlo',
        description:
            'Mô phỏng 1.000 kịch bản thông lượng ngày, hiển thị dải p10/p50/p90 và What-if.',
        priority: 'CAO',
        storyPoints: 5,
        status: 'In Progress',
        assigneeId: uid2,
        assigneeName: name2,
        tags: const ['AI', 'MonteCarlo', 'Forecast'],
        deadline: now.add(const Duration(days: 4)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      ),
      UserStoryModel(
        id: 'ai_active_story_${epoch}_3',
        projectId: projectId,
        storyKey: 'US-071',
        title: 'AI Model Lab — Phòng thí nghiệm huấn luyện & đánh giá mô hình',
        description:
            'Trực quan hóa đường cong BCE Loss, ma trận nhầm lẫn và trọng số đặc trưng.',
        priority: 'TB',
        storyPoints: 5,
        status: 'To Do',
        assigneeId: uid3,
        assigneeName: name3,
        tags: const ['AI', 'ModelLab', 'Metrics'],
        deadline: now.add(const Duration(days: 6)),
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now,
      ),
      UserStoryModel(
        id: 'ai_active_story_${epoch}_4',
        projectId: projectId,
        storyKey: 'US-068',
        title: 'Chuẩn hóa bộ màu trạng thái rủi ro Dark/Light Mode',
        description:
            'Bổ sung token màu rủi ro Thấp/Trung bình/Cao đạt chuẩn tương phản.',
        priority: 'THẤP',
        storyPoints: 3,
        status: 'Done',
        assigneeId: uid1,
        assigneeName: name1,
        tags: const ['UI', 'Theme'],
        deadline: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 2)),
        completedAt: now.subtract(const Duration(days: 2)),
      ),
    ];

    for (final s in activeStories) {
      try {
        await backlogRepo.saveUserStory(projectId, s);
        createdStories++;
      } catch (e) {
        debugPrint('Lỗi nạp Active Story AI Demo: $e');
      }
    }

    try {
      await sprintRepo.seedSprint(
        projectId: projectId,
        name: 'Sprint 5 (AI Demo) — AI Sprint Risk Radar',
        goal:
            'Triển khai trọn bộ AI Risk Radar, Monte Carlo Forecast & Model Lab',
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 9)),
        status: 'Active',
        storyIds: activeStories.map((s) => s.id).toList(),
      );
      createdActiveSprints++;
    } catch (e) {
      debugPrint('Lỗi nạp Active Sprint AI Demo: $e');
    }

    // ── 3. Tạo 12 Tasks đa dạng mức độ rủi ro (High / Medium / Low) & lịch sử Done ──
    final sHigh = activeStories[0].id;
    final sMed = activeStories[1].id;
    final sTodo = activeStories[2].id;
    final sHistA = closedStoriesSprintA[0].id;
    final sHistB = closedStoriesSprintB[0].id;

    final taskDefs = <_AiTaskSeedDef>[
      // 1-4: Rủi ro CAO (quá hạn / sát hạn / chưa gán người / thành viên uid3 bị dồn nhiều việc)
      _AiTaskSeedDef(
        storyId: sHigh,
        title:
            '🔥 [Rủi ro Cao] Tích hợp trích xuất 10 đặc trưng chống rò rỉ nhãn',
        description:
            'Cần rà soát kỹ thời điểm trích xuất đặc trưng, kiểm thử biên NaN/Infinity và chuẩn hóa Z-score cho toàn bộ 10 chiều dữ liệu.',
        status: 'To Do',
        assigneeId: null,
        assigneeName: null,
        deadline: now.add(const Duration(hours: 14)),
      ),
      _AiTaskSeedDef(
        storyId: sHigh,
        title: '⚠️ [Rủi ro Cao] Xử lý cảnh báo Task quá hạn trên Sprint Board',
        description:
            'Task đã quá hạn 1 ngày nhưng vẫn ở trạng thái To Do, thành viên phụ trách đang ôm nhiều việc cùng lúc.',
        status: 'To Do',
        assigneeId: uid3,
        assigneeName: name3,
        deadline: now.subtract(const Duration(days: 1)),
      ),
      _AiTaskSeedDef(
        storyId: sHigh,
        title:
            '🚨 [Rủi ro Cao] Tối ưu hóa giải thích đóng góp đặc trưng z_j * w_j',
        description:
            'Hiển thị đúng Top-3 nguyên nhân làm tăng rủi ro trễ hạn bằng tiếng Việt dễ hiểu trên thẻ Task Detail.',
        status: 'In Progress',
        assigneeId: uid3,
        assigneeName: name3,
        deadline: now.add(const Duration(hours: 20)),
      ),
      _AiTaskSeedDef(
        storyId: sMed,
        title: '⏳ [Rủi ro Cao] Kiểm thử hội tụ 1.000 kịch bản Monte Carlo',
        description:
            'Đảm bảo thời gian chạy dưới 300ms trên thiết bị tầm trung và không chặn luồng giao diện chính.',
        status: 'To Do',
        assigneeId: uid3,
        assigneeName: name3,
        deadline: now.add(const Duration(days: 1)),
      ),

      // 5-7: Rủi ro TRUNG BÌNH (In Progress, hạn 2–4 ngày)
      _AiTaskSeedDef(
        storyId: sMed,
        title: '📊 [Rủi ro TB] Vẽ dải phân vị p10–p50–p90 trên Burndown Chart',
        description:
            'Vẽ miền bán trong suốt nối từ ngày hiện tại tới cuối Sprint.',
        status: 'In Progress',
        assigneeId: uid2,
        assigneeName: name2,
        deadline: now.add(const Duration(days: 3)),
      ),
      _AiTaskSeedDef(
        storyId: sTodo,
        title:
            '🧪 [Rủi ro TB] Xây dựng bảng Confusion Matrix 2x2 trong Model Lab',
        description:
            'Hiển thị TP, FP, FN, TN kèm Accuracy, Precision, Recall, F1.',
        status: 'In Progress',
        assigneeId: uid3,
        assigneeName: name3,
        deadline: now.add(const Duration(days: 3)),
      ),
      _AiTaskSeedDef(
        storyId: sTodo,
        title: '📈 [Rủi ro TB] Vẽ đồ thị BCE Loss Curve bằng CustomPainter',
        description:
            'Hiển thị đường cong hàm mất mát theo từng epoch huấn luyện.',
        status: 'To Do',
        assigneeId: uid2,
        assigneeName: name2,
        deadline: now.add(const Duration(days: 4)),
      ),

      // 8-9: Rủi ro THẤP (hạn còn xa 7–9 ngày, người phụ trách ít việc)
      _AiTaskSeedDef(
        storyId: sMed,
        title: '✅ [Rủi ro Thấp] Viết tài liệu hướng dẫn đọc chỉ số Monte Carlo',
        description: 'Mô tả ngắn gọn ý nghĩa p10, p50, p90.',
        status: 'In Progress',
        assigneeId: uid1,
        assigneeName: name1,
        deadline: now.add(const Duration(days: 8)),
      ),
      _AiTaskSeedDef(
        storyId: sTodo,
        title: '🛡️ [Rủi ro Thấp] Kiểm tra phân quyền PO/SM cho AI Model Lab',
        description: 'Ẩn nút Model Lab đối với tài khoản Member.',
        status: 'In Progress',
        assigneeId: uid1,
        assigneeName: name1,
        deadline: now.add(const Duration(days: 9)),
      ),

      // 10-12: Các Task đã hoàn thành (Done) tạo mẫu `real` cho AI Model Lab
      _AiTaskSeedDef(
        storyId: sHistA,
        title: '✔️ [Đã xong đúng hạn] Khởi tạo cấu trúc thư mục domain/ai/core',
        description: 'Tách biệt hoàn toàn lõi toán học thuần Dart.',
        status: 'Done',
        assigneeId: uid1,
        assigneeName: name1,
        deadline: now.subtract(const Duration(days: 15)),
      ),
      _AiTaskSeedDef(
        storyId: sHistB,
        title:
            '✔️ [Đã xong đúng hạn] Cài đặt bộ chuẩn hóa Z-Score Standardizer',
        description: 'Xử lý an toàn phương sai bằng 0.',
        status: 'Done',
        assigneeId: uid2,
        assigneeName: name2,
        deadline: now.subtract(const Duration(days: 5)),
      ),
      _AiTaskSeedDef(
        storyId: sHistB,
        title:
            '✔️ [Đã xong trễ hạn] Tinh chỉnh siêu tham số L2 & Balanced Weights',
        description:
            'Hoàn tất kiểm thử gradient giải tích so với xấp xỉ sai phân.',
        status: 'Done',
        assigneeId: uid3,
        assigneeName: name3,
        deadline: now.subtract(const Duration(days: 10)),
      ),
    ];

    for (final def in taskDefs) {
      try {
        final created = await taskRepo.createTask(
          storyId: def.storyId,
          projectId: projectId,
          title: def.title,
          description: def.description,
          assigneeId: def.assigneeId,
          assigneeName: def.assigneeName,
          deadline: def.deadline,
        );
        if (def.status != 'To Do') {
          await taskRepo.updateTaskStatus(created.id, def.status);
        }
        createdTasks++;
      } catch (e) {
        debugPrint('Lỗi nạp Task AI Demo: $e');
      }
    }

    return AiDemoSeedResult(
      createdClosedSprints: createdClosedSprints,
      createdActiveSprints: createdActiveSprints,
      createdStories: createdStories,
      createdTasks: createdTasks,
    );
  }
}

class _AiTaskSeedDef {
  final String storyId;
  final String title;
  final String description;
  final String status;
  final String? assigneeId;
  final String? assigneeName;
  final DateTime? deadline;

  const _AiTaskSeedDef({
    required this.storyId,
    required this.title,
    required this.description,
    required this.status,
    this.assigneeId,
    this.assigneeName,
    this.deadline,
  });
}
