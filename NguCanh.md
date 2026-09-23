# 📌 NHẬT KÝ CÔNG VIỆC DỰ ÁN SCRUMFLOW (NguCanh.md)

> **Mục đích tài liệu:** Lưu lại tiến độ và toàn bộ công việc nhóm đã thực hiện trong quá trình phát triển dự án ứng dụng di động **Scrumflow**. Dùng để các thành viên trong nhóm và AI theo dõi, phối hợp liền mạch qua các phiên làm việc.

---

## 1. 📋 Thông Tin Dự Án

* **Tên dự án:** **Scrumflow** - Ứng dụng Quản lý Dự án theo mô hình Agile/Scrum trên Di động
* **Môn học:** CMP177 - Lập trình trên thiết bị di động
* **Nền tảng & Công nghệ:** 
  * Nền tảng: **Flutter**
  * Ngôn ngữ: **Dart**
  * Công cụ lập trình chính: **VS Code** (kết hợp nền tảng Android SDK & JDK)
* **Tài liệu tham chiếu:**
  * [README_MoTaDoAnMonHoc.md](file:///e:/BTVN/L%E1%BA%ADp%20tr%C3%ACnh%20di%20%C4%91%E1%BB%99ng%20b%C3%A0i%20t%E1%BA%ADp/D%E1%BB%B1%20%C3%A1n%20Scrumflow/README_MoTaDoAnMonHoc.md)
  * [README_MoTaChucNang.md](file:///e:/BTVN/L%E1%BA%ADp%20tr%C3%ACnh%20di%20%C4%91%E1%BB%99ng%20b%C3%A0i%20t%E1%BA%ADp/D%E1%BB%B1%20%C3%A1n%20Scrumflow/README_MoTaChucNang.md)
  * [NguCanh.md](file:///e:/BTVN/L%E1%BA%ADp%20tr%C3%ACnh%20di%20%C4%91%E1%BB%99ng%20b%C3%A0i%20t%E1%BA%ADp/D%E1%BB%B1%20%C3%A1n%20Scrumflow/NguCanh.md)

---

## 2. 📝 Công Việc Đã Thực Hiện

### Ngày 18/09/2026: Khởi tạo và đồng bộ mã nguồn
- Kết nối và đồng bộ dự án với GitHub repository `https://github.com/troicomay0385/ScrumFlow.git` (nhánh `main`).
- Tích hợp tài liệu yêu cầu đồ án ([README_MoTaDoAnMonHoc.md](file:///e:/BTVN/L%E1%BA%ADp%20tr%C3%ACnh%20di%20%C4%91%E1%BB%99ng%20b%C3%A0i%20t%E1%BA%ADp/D%E1%BB%B1%20%C3%A1n%20Scrumflow/README_MoTaDoAnMonHoc.md)), tài liệu đặc tả chức năng ([README_MoTaChucNang.md](file:///e:/BTVN/L%E1%BA%ADp%20tr%C3%ACnh%20di%20%C4%91%E1%BB%99ng%20b%C3%A0i%20t%E1%BA%ADp/D%E1%BB%B1%20%C3%A1n%20Scrumflow/README_MoTaChucNang.md)) và nhật ký công việc ([NguCanh.md](file:///e:/BTVN/L%E1%BA%ADp%20tr%C3%ACnh%20di%20%C4%91%E1%BB%99ng%20b%C3%A0i%20t%E1%BA%ADp/D%E1%BB%B1%20%C3%A1n%20Scrumflow/NguCanh.md)) vào repo.
- Rà soát cấu trúc thư mục kiến trúc phân tầng sẵn có trong repo:
  - Tầng `lib/app/`: Bảng màu (`AppColors`), chuỗi tĩnh (`AppStrings`), điều hướng (`AppRoutes`), dịch vụ mạng (`ConnectivityService`), giao diện (`AppTheme`).
  - Tầng `lib/data/`: Data Sources (Firebase Auth, Firestore, Local Cache), Model (`UserModel`), Repositories (`AuthRepository`, `AuthRepositoryImpl`).

-----------------------------------------------------------------------------------------

### Ngày 21/09/2026: Hoàn thành User Story "Phân quyền vai trò PO/SM/Member"
- **Bối cảnh:** Trước đó project chưa có khái niệm "Project" nào trong app (chỉ có Auth + màn hình hồ sơ trống). Đã xây dựng tối thiểu tính năng Project làm nền tảng để gắn tính năng phân quyền thành viên vào.
- **Database (Cloud Firestore):**
  - Thêm collection `projects/{projectId}` (name, description, createdBy, createdAt, updatedAt).
  - Thêm collection `projectMembers/{projectId_userId}` (projectId, userId, role, createdBy, createdAt, updatedAt) — role gắn theo từng project, không gắn cứng vào `users`.
- **Backend/Service:** `ProjectDataSource`, `ProjectMemberDataSource` (CRUD Firestore), `ProjectRepository`/`ProjectMemberRepository` (business logic: tạo project tự động thành PO, thêm/đổi role/xoá thành viên). Mở rộng `FirestoreDataSource` có sẵn (tìm user theo email, đọc nhiều hồ sơ) thay vì viết mới, tái sử dụng tối đa code Auth hiện có.
- **Authorization tập trung:** `ProjectRole` enum (PO/SM/MEMBER), `Permission` enum, bảng ánh xạ Role → Permission (`role_permissions.dart`) — toàn bộ UI/Bloc chỉ hỏi qua `hasPermission()`, không so sánh role rải rác.
- **Cơ chế chống mất quyền quản trị:** PO không thể tự đổi role của chính mình (chặn ở cả Bloc lẫn Firestore Security Rules) — đảm bảo project luôn còn tối thiểu 1 PO.
- **Firestore Security Rules:** viết mới `firestore.rules` (trước đây repo chưa có) cho `users`, `projects`, `projectMembers` — kiểm soát: chỉ thành viên mới đọc được dữ liệu project, chỉ PO mới đổi role/thêm/xoá thành viên, không ai tự nâng quyền chính mình. Đã deploy lên Firebase project `scrumflow-c835d`.
- **UI/Navigation:** màn Tạo project, Chi tiết Project, Quản lý thành viên (danh sách + đổi role có xác nhận + thêm thành viên theo email); `HomeScreen` đổi từ hiển thị hồ sơ đơn thuần sang danh sách "Project của tôi" (vẫn giữ nguyên chức năng đăng xuất).
- **Test:** thêm unit test cho permission logic, parse role không hợp lệ, và `ProjectMembersBloc` (14/14 test pass); `flutter analyze` sạch.
- **Kiểm thử thực tế trên emulator + Firebase project thật**, phát hiện và sửa 3 bug trong lúc test:
  1. Hàm và biến path trùng tên trong `firestore.rules` (`membershipId`) khiến rule tạo membership luôn bị từ chối.
  2. Rule `read` của `projectMembers` không xử lý document chưa tồn tại (`resource == null`), khiến bước kiểm tra trùng thành viên bị từ chối oan.
  3. Bug điều hướng: Flutter tự thêm route ẩn `"/"` vào đáy navigation stack khi dùng `initialRoute` dạng named-route, khiến bấm back ở Home lộ ra màn "Route not found" — sửa bằng cách đổi `pushReplacementNamed` → `pushNamedAndRemoveUntil` ở `login_screen.dart`/`register_screen.dart` và thêm case `'/'` phòng vệ trong `app_routes.dart`.
- Đã xác minh trực tiếp trên thiết bị: tạo project → tự động thành PO → thêm thành viên → đổi role real-time → tự đổi role chính mình bị chặn đúng như thiết kế.

-----------------------------------------------------------------------------------------

### Ngày 22/09/2026: Hoàn thiện tính năng Quản lý Project & Chỉnh sửa thông tin/Mục tiêu
- **Chức năng đã hoàn thành:**
  - **Tạo Project mới:** Quản trị viên/PO tạo project với tên và mục tiêu/mô tả cụ thể (định hướng cho Backlog và Sprint). Khi tạo xong, người tạo tự động trở thành PO với toàn quyền quản trị.
  - **Chỉnh sửa thông tin Project:** Cho phép PO/Quản trị viên chỉnh sửa tên, cập nhật mục tiêu hoặc mô tả dự án trực tiếp qua hộp thoại `showEditProjectDialog`. Dữ liệu cập nhật real-time lên Firestore và giao diện qua Stream.
  - **Phân quyền tập trung (RBAC):** Bổ sung `Permission.manageProject` cho `ProjectRole.po` trong `role_permissions.dart`. Các vai trò Scrum Master (SM) và Member bị hạn chế không thể chỉnh sửa thông tin dự án (kiểm soát 2 lớp: Repository và Firestore Security Rules).
  - **Không gian làm việc Scrum & Thêm thành viên:** Nâng cấp màn hình `ProjectDetailScreen` hiển thị tổng quan dự án, khu vực không gian Scrum (Product Backlog & Sprint Board) và khu vực quản lý/thêm thành viên tham gia làm việc.
  - **Kiểm thử tự động:** Bổ sung unit tests cho phân quyền `manageProject` và `ProjectRepositoryImpl` (tạo project, rollback khi lỗi, cập nhật thành công, chặn quyền khi không phải PO) — 19/19 test pass sạch.

---
### Ngày 23/09/2026: Đẩy code lên GitHub (nhánh `hieu`)
- **Push code**: Tất cả các thay đổi mới đã được commit và push lên repository GitHub `https://github.com/troicomay0385/ScrumFlow.git` trên nhánh `hieu`.
- **Các file đã tạo và chỉnh sửa**:
  - **Mới tạo**: `lib/presentation/projects/widgets/edit_project_dialog.dart`, `test/data/repositories/project_repository_impl_test.dart`
  - **Sửa đổi**: `.idea/libraries/Dart_SDK.xml`, `.idea/libraries/Flutter_Plugins.xml`, `.idea/workspace.xml`, `NguCanh.md`, `analysis_options.yaml`, `android/scrumflow_android.iml`, `lib/app/authorization/role_permissions.dart`, `lib/data/datasources/project_datasource.dart`, `lib/data/repositories/project_repository.dart`, `lib/data/repositories/project_repository_impl.dart`, `lib/presentation/projects/screens/create_project_screen.dart`, `lib/presentation/projects/screens/project_detail_screen.dart`, `linux/flutter/generated_plugin_registrant.cc`, `linux/flutter/generated_plugin_registrant.h`, `linux/flutter/generated_plugins.cmake`, `macos/Flutter/GeneratedPluginRegistrant.swift`, `pubspec.yaml`, `scrumflow.iml`, `test/app/authorization/role_permissions_test.dart`, `test/widget_test.dart`, `windows/flutter/generated_plugin_registrant.cc`, `windows/flutter/generated_plugin_registrant.h`, `windows/flutter/generated_plugins.cmake`
  - **Xóa**: `.idea/libraries/Dart_Packages.xml`

## 3. 📌 Hướng Dẫn Cập Nhật Tài Liệu Này
* Mỗi khi kết thúc một cuộc trao đổi quan trọng, hoàn thành một chức năng hoặc tạo commit mới, cập nhật thêm nội dung công việc vào phần **2. Công Việc Đã Thực Hiện**.

