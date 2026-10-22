# BÁO CÁO KHẢO SÁT HỆ THỐNG (RECON) — PHASE 0

## 1. Trạng thái Git & Baseline
- **Nhánh hiện tại:** `feature/sprint5-ai-sprint-risk-radar` (tách trực tiếp từ `origin/main` @ `116c139395f64203b408780da572bdea8a94a8fb`).
- **Baseline `flutter analyze`:** **0 error, 0 warning, 49 info issues** (toàn bộ có sẵn từ các sprint trước).
- **Baseline `flutter test`:** **391 / 391 tests PASS (100%)**.
- **Dependencies sẵn có (`pubspec.yaml`):** `flutter_bloc: ^9.1.1`, `equatable: ^2.0.7`, `shared_preferences: ^2.5.6`, `google_fonts: ^6.2.1`, `sqflite: ^2.4.2`, `mocktail: ^1.0.4`, `bloc_test: ^10.0.0`. Không cần thêm bất kỳ package nào.

## 2. Cấu trúc Dữ liệu & Thực tế Nghiệp vụ

### 2.1. `TaskModel` (`lib/data/models/task_model.dart`)
- Các trường hiện có: `id`, `storyId`, `projectId?`, `title`, `description`, `status` (`'To Do'`, `'In Progress'`, `'Done'`), `assigneeId?`, `assigneeName?`, `deadline?` (`DateTime?`), `loggedHours` (`double`, mặc định `0.0`), `createdAt` (`DateTime`), `updatedAt` (`DateTime`).
- **Không có:** `completedAt`, `startedAt`, lịch sử chuyển trạng thái, `estimate`, `isBlocked`/`blockerReason` (trên model).
- **Quy ước mốc hoàn thành (US-058 & US-066):** Khi task ở trạng thái `'Done'`, `updatedAt` là thời điểm hoàn thành. `WorkLogDataSource` cố ý dùng `FieldValue.increment(hours)` mà không chạm vào `updatedAt` để giữ nguyên mốc hoàn thành.

### 2.2. `UserStoryModel` (`lib/data/models/user_story_model.dart`)
- Các trường chính: `id`, `projectId`, `storyKey` (`US-xxx`), `title`, `description`, `priority` (`'CAO'`, `'TB'`, `'THẤP'`), `storyPoints` (`int`, Fibonacci 1, 2, 3, 5, 8, 13, 21), `status` (`'To Do'`, `'In Progress'`, `'Done'`, `'Rejected'`), `assigneeId?`, `tags`, `deadline?`, `createdAt`, `updatedAt`, `completedAt?` (`DateTime?`).
- Story Points và Priority nằm trên `UserStoryModel`; `TaskModel` liên kết qua `storyId`.

### 2.3. `SprintModel` & `SprintDataSource` (`lib/data/models/sprint_model.dart`, `lib/data/datasources/sprint_datasource.dart`)
- Các trường: `id`, `projectId`, `name`, `goal`, `storyIds` (`List<String>`), `startDate`, `endDate`, `status`, `createdAt`, `updatedAt`.
- Khi đóng Sprint (`closeSprint` - US-050):
  - Đặt `status = 'Completed'` (trong `SprintModel` comment còn nhắc `'Closed'`, `SprintStatus.completed` trong `sprint_status.dart` là `'Completed'`, còn `NguCanh.md` từng ghi `'Closed'` → **helper chuẩn hoá coi cả `'Completed'` và `'Closed'` không phân biệt hoa thường là đã đóng**).
  - Gỡ các `incompleteStoryIds` ra khỏi `storyIds` của Sprint vừa đóng.
  - Không lưu trường velocity riêng ⇒ **Velocity của một Sprint đã đóng** = `(tổng storyPoints của các story còn trong sprint.storyIds) / max(1, endDate.difference(startDate).inDays)`.

### 2.4. `PerformanceScoreService` & `MemberPerformanceScore` (US-057/058)
- Công thức cứng hiện tại:
  - `onTimeRate = completedTasks > 0 ? completedOnTime / completedTasks : 1.0`
  - `workloadFactor = clamp(1.0 - inProgress / 5.0, 0.0, 1.0)`
  - `ratingScore = 1.0` (hằng số cố định → phương sai bằng 0, **không đưa vào feature học máy**)
  - `finalScore = 0.5 * onTimeRate + 0.3 * workloadFactor + 0.2 * ratingScore`

### 2.5. `BurndownChartWidget` (`lib/presentation/sprints/widgets/burndown_chart_widget.dart`)
- Tính `BurndownData.calculate(sprint, stories)` với `totalDays = max(1, end.difference(start).inDays + 1)`.
- Vẽ bằng `_BurndownPainter` trên Canvas cao 180px.
- Mở rộng thêm tham số tuỳ chọn `forecast` (`SprintForecastResult?`) để vẽ dải phân vị `p10–p90` và đường trung vị `p50` nét đứt mà vẫn giữ nguyên 100% hành vi cũ khi `forecast == null`.

### 2.6. Kiến trúc Cubit & Phân quyền
- Mẫu chuẩn từ `SprintDashboardCubit`: quản lý `_loadToken` chống stale event, `timeoutFirstEvent` (15s), kiểm tra `ConnectivityService`, truyền dependency qua constructor và dùng `maybeRead<T>(context)` trong Widget để test độc lập với Firebase.
- Phân quyền tập trung tại `lib/app/authorization/permission.dart` và `role_permissions.dart`: bổ sung `Permission.viewAiInsights` và `Permission.manageAiModel` cho `ProjectRole.po` và `ProjectRole.sm` (`ProjectRole.member` không có).

### 2.7. Design System & Ràng buộc File
- Theo `design.md` ("Kinetic Sprint"), `AppColors`, `AppTheme` (hỗ trợ Light & Dark mode), `ResponsiveLayout` (`lib/app/utils/responsive_layout.dart`), chuỗi tiếng Việt trong `AppStrings`.
- Hai file `task_board_screen.dart` trùng tên:
  - `lib/presentation/tasks/screens/task_board_screen.dart`: Kanban của các Task trong 1 User Story (có `TaskCard`).
  - `lib/presentation/task_board/screens/task_board_screen.dart`: Kanban của các User Story trong 1 Sprint.
- Các file **tuyệt đối không chạm vào**: `pubspec.yaml`, `lib/data/datasources/local_cache_datasource.dart`, `lib/data/repositories/task_repository.dart`, `lib/data/repositories/backlog_repository_impl.dart`, `firestore.rules`.
