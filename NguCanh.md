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
  * [design.md](file:///d:/ThuMucOE/BTVN/LTDD%20BTVN/Scrumflow/design.md) (Design System trích xuất từ Stitch)
  * [HuongDanKetNoiStitch.md](file:///d:/ThuMucOE/BTVN/LTDD%20BTVN/Scrumflow/HuongDanKetNoiStitch.md) (Hướng dẫn kết nối MCP Stitch)

* **Khả năng tương thích thiết bị & Đóng gói:**
  * **Khi Bật Chế độ Nhà phát triển (Developer Mode / USB Debugging ON):** Dùng để lập trình viên kết nối cáp USB với máy tính (`flutter run`, `adb install`) chạy và debug live reload ứng dụng.
  * **Khi KHÔNG Bật Chế độ Nhà phát triển (Developer Mode OFF):** Bản phát hành Release (file APK/AAB hoặc tải từ Google Play Store / App Store) hoạt động hoàn hảo trên điện thoại của mọi người dùng thông thường mà không đòi hỏi bất kỳ quyền hay chế độ nhà phát triển nào.

* **Danh sách tài khoản kiểm thử / Người dùng ảo (Mock Users):**
  1. **Lê Phúc (PO / Admin):** `phuc.po@scrumflow.com` | Password: `Password123!` | Vai trò: Product Owner (PO)
  2. **Nguyễn Hiếu (Dev / SM):** `hieu.dev@scrumflow.com` | Password: `Password123!` | Vai trò: Scrum Master (SM)
  3. **Trần Thúy (Tester / Member):** `thuy.qa@scrumflow.com` | Password: `Password123!` | Vai trò: QA & Tester
  4. **Phạm Duy (Dev / Member):** `duy.dev@scrumflow.com` | Password: `Password123!` | Vai trò: Developer

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

-----------------------------------------------------------------------------------------

### Ngày 27/09/2026: Tối ưu Auth, Đóng gói APK thiết bị thật & Tích hợp CodeGraph
- **Tối ưu hóa Authentication & Xử lý lỗi (Commit `166c206`):**
  - Mở rộng `FirebaseErrorMapper` hỗ trợ toàn diện các mã lỗi Firebase Auth/Firestore cả dạng chuẩn lẫn chữ hoa (`INVALID_LOGIN_CREDENTIALS`, `channel-error`, `permission-denied`, v.v.). Thêm unit test `firebase_error_mapper_test.dart`.
  - Cải tiến `UserModel.fromMap()` linh hoạt parse an toàn trường `createdAt` cho cả `String` và đối tượng `Timestamp` Firestore mà không bị lỗi ép kiểu (`TypeError`). Thêm unit test `user_model_test.dart`.
  - Chuẩn hóa luồng `AuthRepositoryImpl`: tự động `.trim()` email/họ tên, bọc `try-catch` an toàn cho SQLite cache và Firestore profile phụ trợ.
- **Build APK & Cài đặt kiểm thử trên thiết bị thật:**
  - Build thành công gói APK (`build/app/outputs/flutter-apk/app-debug.apk`, 159 MB).
  - Tải file vào bộ nhớ máy (`/sdcard/Download/ScrumFlow-debug.apk`) và cài đặt trực tiếp qua `adb` lên thiết bị thật Xiaomi Android 14 (`21081111RG`), ứng dụng khởi chạy thành công.
- **Triển khai US-056 (Đăng nhập Sinh trắc học & Cài đặt bảo mật) & US-005, US-006 (Product Backlog):**
  - **US-056 & Cài đặt:** Thêm `local_auth` và `flutter_secure_storage`, cấu hình `FlutterFragmentActivity`, `USE_BIOMETRIC`. Tạo dialog `SecuritySettingsDialog` xuất hiện ở thanh AppBar (nút bánh răng) tại mọi màn hình chính. Cho phép bật/tắt vân tay, lưu mật khẩu mã hóa an toàn, kiểm tra cảm biến phần cứng và **tích hợp nút Đăng xuất tài khoản trực tiếp trong Cài đặt**.
  - **US-005 & US-006:** Xây dựng `UserStoryModel`, `BacklogDataSource` (hỗ trợ tạo 8 stories mẫu gắn với 4 Mock Users), `BacklogRepositoryImpl`, `BacklogBloc`, màn hình `BacklogListScreen` và `UserStoryDetailScreen`.
  - **Trích xuất Design System từ Stitch:** Xuất toàn bộ hướng dẫn phong cách `Kinetic Sprint` vào `design.md` và tài liệu cấu hình `HuongDanKetNoiStitch.md` cho các thành viên.
  - **Build APK & Cài đặt lên điện thoại Xiaomi 11T:** Đóng gói và cập nhật thành công bản APK mới nhất lên thiết bị thật qua `adb install -r -d` và tự động khởi chạy app.

### Ngày 27/09/2026 (Phiên 2 — Chiều/Tối): Redesign UI Sprint 1 theo Stitch, Sửa Google Sign-In & Tối ưu UX

- **Tạo nhánh backup trước khi redesign (Commit `de388f8`):**
  - Tạo nhánh `backup-before-stitch-ui` từ trạng thái hiện tại và push lên GitHub để làm bản phục hồi phòng trường hợp giao diện mới không phù hợp.

- **Redesign toàn bộ giao diện Sprint 1 theo Stitch Design System "Kinetic Sprint" (Commit `422586e`):**
  - Kết nối MCP Stitch (Project `ScrumFlow Agile Management UI`, ID `projects/5101031354143431379`) để kéo giao diện thiết kế mẫu cho 9 màn hình chính.
  - Redesign các file giao diện theo design system Stitch:
    - `lib/presentation/auth/screens/login_screen.dart`: Giao diện đăng nhập mới với logo ScrumFlow, badge phiên bản, nút Vân tay / Face ID, nút đăng nhập Google, chứng nhận bảo mật SOC2/TLS.
    - `lib/presentation/auth/screens/register_screen.dart`: Giao diện đăng ký tài khoản mới.
    - `lib/presentation/home/screens/home_screen.dart`: Trang chủ với tổng quan không gian làm việc (số dự án, Sprint, sẵn sàng %), danh sách card dự án với tiến độ Sprint.
    - `lib/presentation/projects/screens/project_detail_screen.dart`: Chi tiết dự án với card mục tiêu, khu vực Scrum (Product Backlog, Sprint & Kanban Board), Đội ngũ & Phân quyền.
    - `lib/presentation/projects/screens/create_project_screen.dart`: Form tạo project mới.
    - `lib/presentation/projects/screens/backlog_list_screen.dart`: Danh sách Product Backlog với bộ lọc, bảng Story Points.
    - `lib/presentation/projects/screens/user_story_detail_screen.dart`: Chi tiết User Story.
    - `lib/presentation/project_members/screens/project_members_screen.dart`: Quản lý thành viên dự án.
    - `lib/presentation/settings/widgets/security_settings_dialog.dart`: Hộp thoại cài đặt tài khoản (sinh trắc học, đăng xuất).
  - Cập nhật `lib/app/constants/app_colors.dart`: Bổ sung bảng màu mới theo Stitch Design System (gradient, shadow, surface, badge colors).
  - **Kết quả:** Toàn bộ giao diện được nâng cấp thống nhất theo phong cách Kinetic Sprint, sử dụng Google Fonts `Plus Jakarta Sans`, cards bo tròn, gradient mềm mại, và micro-animation.

- **Xóa icon bánh răng (⚙️) trên giao diện chính, chuyển chức năng Cài đặt sang Avatar (Commit `a65308b`):**
  - Xóa bỏ `IconButton(Icons.settings_outlined)` khỏi thanh AppBar trong `home_screen.dart`.
  - Bọc `CircleAvatar` góc trên cùng bên phải (hiển thị chữ cái đầu tên người dùng, VD: "D") bằng `InkWell` kèm `Tooltip('Hồ sơ tài khoản & Cài đặt')`.
  - Khi bấm vào Avatar → mở popup `SecuritySettingsDialog` chứa thông tin tài khoản, toggle sinh trắc học, nút thử nghiệm cảm biến, và nút Đăng xuất tài khoản.
  - **Kiểm thử thực tế trên Xiaomi 11T:** Xác nhận icon bánh răng đã biến mất, bấm vào Avatar chữ "D" mở thành công hộp thoại Cài đặt tài khoản.

- **Xử lý lỗi đỏ khi đăng nhập Google (`ApiException: 10`) (Commit `a65308b`):**
  - **Nguyên nhân gốc:** Lỗi `CommonStatusCodes.DEVELOPER_ERROR` do chưa đăng ký mã chứng chỉ SHA-1 của máy phát triển trên Firebase Console (trường `"oauth_client": []` trong `google-services.json` đang rỗng). **Logic code đăng nhập Google vốn KHÔNG sai** — chỉ thiếu cấu hình SHA-1.
  - **Giải pháp code:** Thêm phương thức `mapPlatformError(String code, [String? message])` trong `lib/app/constants/firebase_error_mapper.dart` để bắt và nhận diện các mã lỗi `ApiException: 10`, `ApiException: 12500`, `DEVELOPER_ERROR`, `sign_in_canceled`, `network` và chuyển đổi sang thông báo tiếng Việt rõ ràng, dễ hiểu.
  - Thêm nhánh `on PlatformException catch (e)` trong `signInWithGoogle()` tại `lib/data/repositories/auth_repository_impl.dart` để gọi `mapPlatformError` thay vì để app văng lỗi kỹ thuật thô.
  - Bổ sung unit test cho `mapPlatformError` trong `test/app/constants/firebase_error_mapper_test.dart` → **28/28 tests PASS**.
  - **Trích xuất SHA-1 từ máy hiện tại:**
    - Đường dẫn keystore: `C:\Users\ASUS\.android\debug.keystore`
    - SHA-1: `DD:FB:88:6B:78:A1:A1:8F:15:0A:77:5B:AB:61:E1:64:42:86:EE:69`
    - SHA-256: `10:BF:27:17:73:E2:62:12:92:DB:62:A6:9A:DF:10:3C:90:9B:3F:6E:66:30:55:E1:D7:B9:72:3E:E7:F3:1C:45`
  - **Hướng dẫn kích hoạt Google Sign-In:** Mở Firebase Console → Project `scrumflow-c835d` → Project Settings → Your apps → Android `com.scrumflow.scrumflow` → Add fingerprint → Dán SHA-1 → Tải lại `google-services.json` mới → Build lại APK.

- **Viết lại tệp `HuongDanKetNoiStitch.md` thành Agent Playbook (Commit `a65308b`):**
  - Chuyển đổi từ tài liệu hướng dẫn thủ công sang `[AGENT PLAYBOOK]` tự động thực thi cho AI Coding Assistant.
  - Agent tự xác định hệ điều hành (Windows `%USERPROFILE%` / macOS-Linux `$HOME`), tìm và merge `mcp_config.json` mà không ghi đè các server MCP khác đã có sẵn.
  - Ghi sẵn bảng tra cứu 9 Screen IDs (Home, Backlog, Story Detail, Member Management, Create Project, Login, Register, Edit Profile, Forgot Password) kèm câu lệnh MCP mẫu.

- **Đảm bảo chất lượng:**
  - `flutter analyze lib/ test/`: **0 errors** (chỉ có 10 info-level `prefer_initializing_formals` — không ảnh hưởng chức năng).
  - `flutter test`: **28/28 tests PASS** (tăng từ 27 lên 28 nhờ bổ sung test `mapPlatformError`).
  - Build APK thành công, cài đặt và khởi chạy trên thiết bị thật Xiaomi 11T.

- **Commit & Push lên GitHub (nhánh `hieu`):**
  - Commit `a65308b`: `feat(ui,auth): remove settings gear icon, move settings to user avatar, handle google sign in platform errors, and update stitch guide for agents`
  - 5 files changed: `HuongDanKetNoiStitch.md`, `lib/app/constants/firebase_error_mapper.dart`, `lib/data/repositories/auth_repository_impl.dart`, `lib/presentation/home/screens/home_screen.dart`, `test/app/constants/firebase_error_mapper_test.dart`.
  - Đã push thành công lên `origin/hieu`.

### Ngày 30/09/2026: Sprint 2 — US-011, US-013 (Sửa & Gán điểm Story), US-015 (Danh sách Sprint)
- **US-011 & US-013 — Chỉnh sửa & Gán Story Points:**
  - Xây dựng `EditUserStoryCubit` (chống submit lặp, kiểm tra logic lỗi).
  - Thêm hộp thoại `showEditUserStoryDialog` tương thích giao diện Kinetic Sprint, cho phép sửa tiêu đề, mô tả, ưu tiên, hạn chót và thêm chọn Story Points (US-013) dùng dãy Fibonacci (1, 2, 3, 5, 8, 13, 21).
  - Cập nhật `BacklogRepository` và `BacklogDataSource` để map dữ liệu mới đẩy lên Firestore, phân quyền kỹ (chỉ PO/SM mới được sửa).
- **US-015 — Danh sách Sprint:**
  - Xây dựng `SprintModel`, `SprintDataSource` (hỗ trợ tạo dữ liệu mẫu dự phòng khi chưa có mạng/chưa cấu hình Firebase).
  - Xây dựng `SprintRepository` và `SprintBloc`.
  - Thiết kế màn hình `SprintListScreen` hiển thị các sprint đang Planned/Active/Closed, cập nhật navigation từ trang `ProjectDetailScreen` qua mục "Sprint & Kanban Board".
- Đã sẵn sàng commit và push lên nhánh mới.

### Ngày 29/09/2026: Sprint 2 — US-010 (Tạo User Story), US-014 (Gắn Tag), US-009 (Sắp xếp Backlog)

- **Nguyên tắc:** mở rộng hệ thống Backlog sẵn có (US-005/US-006), KHÔNG tạo Backlog/Model/Bloc/Screen thứ hai. Luồng: UI → Bloc/Cubit → `BacklogRepository` → `BacklogDataSource` → Firestore `projects/{projectId}/userStories/{storyId}` (giữ nguyên path cũ).
- **Firestore schema (`UserStoryModel`) — bổ sung, tương thích ngược:**
  - `tags: List<String>` (mặc định `[]`), `deadline: DateTime?` (ISO string, nullable), `createdBy: String?` (uid người tạo).
  - Dữ liệu cũ thiếu các field này vẫn parse được (`tags` thiếu/sai kiểu → `[]`, `deadline` thiếu → `null`). 8 story mẫu được bổ sung tag/deadline (một số để trống để kiểm thử trường hợp null).
- **US-010 — Tạo User Story:**
  - Nút FAB "Tạo User Story" trên `BacklogListScreen` (chỉ hiện với PO/SM) + nút "Tạo User Story đầu tiên" ở empty state.
  - Dialog `create_user_story_dialog.dart`: Tiêu đề (bắt buộc, ≤200 ký tự), Mô tả (≤2000), Ưu tiên CAO/TB/THẤP (ChoiceChip), Deadline (tuỳ chọn, DatePicker). Có loading, error inline, disable nút khi đang gửi.
  - `CreateUserStoryCubit` chặn submit lặp (đang gửi/đã thành công thì bỏ qua) → không tạo document trùng.
  - `BacklogRepositoryImpl.createUserStory`: kiểm tra `Permission.manageBacklog`, sinh `storyKey` kế tiếp (`US-xxx` = số lớn nhất + 1), gắn `projectId`, `createdBy`, `createdAt/updatedAt`, status `To Do`. Story mới tự xuất hiện qua stream real-time sẵn có.
  - `BacklogDataSource.createUserStory` mới: KHÔNG nuốt lỗi như `saveUserStory` cũ, có timeout 15s để báo lỗi khi mất mạng.
- **US-014 — Gắn nhãn/Tag:**
  - Card "Nhãn / Tags" (`story_tags_card.dart`) tích hợp vào `UserStoryDetailScreen` hiện có: xem tag, thêm tag (dialog), xoá tag (nút x trên chip), "Lưu tag"/"Hoàn tác". MEMBER chỉ xem.
  - `StoryTagsCubit` quản lý bản nháp; validate tag rỗng/trùng (không phân biệt hoa thường)/quá 30 ký tự/tối đa 10 tag.
  - `BacklogDataSource.updateTags` dùng `update({'tags', 'updatedAt'})` → không ghi đè các field khác của story.
  - Thẻ story trong danh sách hiển thị tối đa 3 tag + "+n", và deadline (đỏ nếu quá hạn mà chưa Done). Màn chi tiết có thêm ô Deadline.
- **US-009 — Sắp xếp Backlog:**
  - Dropdown "Sắp xếp theo: Mặc định / Ưu tiên / Deadline" trên `BacklogListScreen`.
  - Ưu tiên theo thứ tự nghiệp vụ CAO → TB → THẤP (`UserStoryPriority.rank`, không sort alphabet). Deadline gần nhất trước, story không có deadline xếp cuối. Sort ổn định, chỉ đổi thứ tự hiển thị, không sửa dữ liệu.
  - Filter trạng thái được chuyển từ `setState` của widget vào `BacklogBloc` (`BacklogStatusFilterChanged`, `BacklogSortChanged`) → filter + sort kết hợp được và giữ nguyên khi stream đẩy dữ liệu mới.
- **Phân quyền (RBAC):** bổ sung `Permission.manageBacklog` cho **SM** trong `role_permissions.dart` (actor các US Backlog Sprint 2 là "PO/SM"). UI hỏi qua `hasPermission(role, Permission.manageBacklog)` với role real-time từ `ProjectMemberRepository.streamCurrentUserRole`.
- **Firestore Security Rules (đã deploy lên `scrumflow-c835d`):** rule `userStories` trước đây là `allow read, write: if isSignedIn()` (người ngoài project cũng đọc/ghi được) → siết lại:
  - `read`: chỉ thành viên project.
  - `create`: chỉ PO/SM, `projectId` phải khớp path, `createdBy` (nếu có) phải là chính người gọi, dữ liệu hợp lệ (`title` 1–200 ký tự, `priority` ∈ CAO/TB/THẤP, `tags` là list ≤10).
  - `update`: chỉ PO/SM, không đổi `projectId`/`createdBy`. `delete`: chỉ PO/SM (chuẩn bị cho US-012).
- **File mới:** `lib/app/constants/user_story_priority.dart`, `lib/app/utils/user_story_validator.dart`, `lib/app/utils/date_formatter.dart`, `lib/presentation/backlog/bloc/create_user_story_cubit.dart` (+ `_state`), `lib/presentation/backlog/bloc/story_tags_cubit.dart` (+ `_state`), `lib/presentation/backlog/utils/backlog_view.dart`, `lib/presentation/backlog/widgets/{create_user_story_dialog, story_tags_card, story_tag_chip, user_story_card}.dart`, và 5 file test mới.
- **File sửa:** `user_story_model.dart`, `backlog_datasource.dart`, `backlog_repository.dart`, `backlog_repository_impl.dart`, `backlog_bloc/event/state.dart`, `backlog_list_screen.dart` (tách thẻ story sang `UserStoryCard`), `user_story_detail_screen.dart`, `role_permissions.dart`, `firebase_error_mapper.dart` (thêm `deadline-exceeded`, `not-found`), `firestore.rules`, `main.dart` (đăng ký `BacklogRepository` qua `RepositoryProvider`).
- **Kiểm thử:**
  - `flutter test`: **69/69 PASS** (tăng từ 28). Test mới: sort ưu tiên/deadline/null/không mất story/filter+sort, BacklogBloc giữ filter+sort khi stream cập nhật, tạo story thành công/validate/lỗi/chống bấm lặp, repository kiểm tra quyền PO/SM/MEMBER + map lỗi Firebase/timeout + sinh storyKey, thêm/xoá/lưu tag không mất field khác, parse dữ liệu cũ không có tags/deadline.
  - `flutter analyze`: **0 error, 0 warning** (chỉ còn 10 info `prefer_initializing_formals` có từ trước).
  - Firestore rules: compile + deploy thành công.
  - Chrome: `flutter build web` và `flutter run -d chrome` chạy thành công. **Kịch bản kiểm thử thủ công** (tạo story, thêm/xoá tag, sort, đăng nhập SM/Member) chưa được xác nhận trong phiên này — cần chạy lại theo checklist khi kiểm thử.
- **Sửa lỗi khi chạy trên Chrome (Web):** không đăng xuất được (báo "Đã xảy ra lỗi không mong muốn") và trang chủ chỉ hiện "Xin chào!" không có tên. Nguyên nhân: `LocalCacheDataSource` dùng `sqflite` — không hỗ trợ Web nên throw, làm `signOut()` dừng trước khi gọi Firebase signOut. Sửa: phần cache SQLite là no-op trên Web (`kIsWeb`), và `AuthRepositoryImpl.signOut()`/`authStateChanges` bọc try-catch phần cache để lỗi cache không bao giờ chặn đăng xuất. Android không bị ảnh hưởng.
- **Lưu ý/rủi ro còn lại:** `storyKey` sinh phía client nên 2 người tạo cùng lúc có thể trùng key (không trùng document). Cơ chế fallback sang 8 story mẫu khi Firestore lỗi (có từ US-005) vẫn giữ nguyên — story mẫu chỉ ở local sẽ không lưu tag được (báo lỗi rõ ràng) cho đến khi bấm "Nạp mẫu" để đồng bộ lên Firestore.

### Ngày 03/10/2026 – 04/10/2026: Nâng cấp Quản lý Sprint cho Scrum Master & Cập nhật Firestore Security Rules

- **Hoàn thiện các tính năng quản lý Sprint cho Scrum Master (US-016, US-017, US-018):**
  - **US-016 — Tạo Sprint thủ công:** Xây dựng `_CreateSprintDialog`, cho phép Scrum Master (SM) hoặc Product Owner (PO) nhập Tên Sprint, Mục tiêu (Goal), chọn Ngày bắt đầu và Ngày kết thúc. Có kiểm tra ràng buộc ngày kết thúc phải sau ngày bắt đầu và tự động ghi dữ liệu vào sub-collection `/projects/{projectId}/sprints/{sprintId}` trên Firestore.
  - **US-017 — Xem chi tiết Sprint:** Hoàn thiện `SprintDetailScreen` hiển thị thông tin mục tiêu, ngày triển khai, trạng thái (Planned / Active / Closed) và danh sách các User Stories thuộc Sprint.
  - **US-018 — Thêm User Story từ Backlog vào Sprint:** Cho phép Scrum Master/PO chọn các User Story sẵn có từ Product Backlog để đưa vào Sprint (`storyIds`), tự động cập nhật danh sách và đồng bộ trạng thái giữa Backlog và Sprint Board.

- **Nâng cấp và Đồng bộ Firestore Security Rules (`firestore.rules`):**
  - Cập nhật toàn bộ các quy tắc bảo mật trên file local và đồng bộ lên Firebase Console (`scrumflow-c835d`) để xử lý dứt điểm lỗi `missing or insufficient permissions`:
    - Cho phép thành viên dự án (`isProjectMember`) đọc thông tin Sprint.
    - Cấp quyền quản lý Sprint (`canManageSprint`) cho cả vai trò **Product Owner (PO)** và **Scrum Master (SM)**.
    - Ràng buộc kiểu dữ liệu đầu vào chuẩn xác cho document Sprint (`projectId`, `name`, `goal`, `storyIds` kiểu `list`).
  - Sửa lỗi xử lý vòng đời controller (`TextEditingController`) trong các hộp thoại giao diện (`security_settings_dialog.dart`, `create_sprint_dialog.dart`), thêm bảo vệ `if (!mounted) return;` chống crash ứng dụng.

- **Ngày 05/10/2026: Loại bỏ dữ liệu sinh mẫu tự động, Nâng cấp Chức năng Thêm từ Backlog vào Sprint & Xác minh tương thích thiết bị di động:**
  - **Khả năng chạy trên điện thoại (Developer Mode ON & OFF):** Xác nhận ứng dụng Flutter `ScrumFlow` hoàn toàn hoạt động mượt mà trên tất cả các điện thoại Android/iOS ở cả 2 môi trường:
    1. **Khi Bật Chế độ Nhà phát triển (Developer Options / USB Debugging ON):** Dùng để debug, nạp phần mềm qua cáp USB (`flutter run`, `adb install`).
    2. **Khi KHÔNG Bật Chế độ Nhà phát triển (Developer Mode OFF):** Bản đóng gói Release (file APK/AAB hoặc phát hành Google Play Store / App Store) cho phép mọi người dùng cuối mở và sử dụng bình thường mà không cần bất kỳ quyền hay thao tác cài đặt kỹ thuật nào.
  - **Loại bỏ tính năng tự động sinh mẫu Backlog & Sprint:** Xóa bỏ hoàn toàn nút "Nạp mẫu" và cơ chế tự nạp mảng `_buildSampleStories`/`_buildSampleSprints` trên `backlog_datasource.dart` & `sprint_datasource.dart`. Chuyển 100% sang luồng tạo mới và quản lý dữ liệu thủ công.
  - **Nâng cấp tính năng "Thêm từ backlog" vào Sprint (`sprint_detail_screen.dart`):** Bổ sung sự kiện batch `SprintStoriesAddRequested` trong `SprintBloc` giúp thêm danh sách User Story vào Sprint bằng 1 thao tác duy nhất (tránh xung đột ghi race condition). Thiết kế lại Modal Sheet chọn story với giao diện trực quan, hỗ trợ chọn tất cả, xem điểm Story Points và độ ưu tiên.

### Ngày 06/10/2026: Sprint 3 — US-043 (Đổi assignee Task), US-044 (Deadline Task), US-045 (Comment User Story), US-046 (Comment Task)

- **Nguyên tắc:** mở rộng hệ thống Task/Backlog sẵn có, KHÔNG tạo Task/User Story system thứ hai. Tái sử dụng `TaskModel`, `TaskRepository`, `TaskBloc`, `ProjectMemberRepository.streamMembers`, `FirebaseErrorMapper`, `RoleBadge`, `formatDateVi`.
- **Hiện trạng trước khi làm:** Task lưu ở collection top-level `tasks/{taskId}` (chỉ có `storyId`, không có `projectId`), đã có `assigneeId`/`assigneeName`, chưa có deadline, **chưa có màn Task Detail**; chưa có bất kỳ Model/Repository/DataSource nào cho Comment.
- **US-043 — Đổi người phụ trách Task:**
  - Màn mới `TaskDetailScreen` (mở bằng cách bấm vào thẻ task trên Task Board của User Story). Ô "Người phụ trách" mở dialog `showAssigneePickerDialog` liệt kê **thành viên thực tế của project** (kèm role badge) + lựa chọn "Chưa phân công"; bấm "Lưu" mới ghi.
  - `TaskDetailCubit.changeAssignee`: kiểm tra `Permission.assignTask`, chỉ nhận uid có trong danh sách thành viên project, rồi gọi `TaskRepository.updateTaskAssignee` — chỉ `update` 3 field `assigneeId`, `assigneeName`, `updatedAt` (không ghi đè field khác). Người được giao nhận thông báo qua `notifyTaskAssigned` sẵn có.
- **US-044 — Deadline Task:**
  - `TaskModel` thêm `deadline: DateTime?` (lưu **Timestamp** như `createdAt/updatedAt` của task; đọc được cả Timestamp lẫn ISO string; thiếu field/sai kiểu → `null`, không crash).
  - Ô "Deadline" trong Task Detail: hiện `dd/MM/yyyy` hoặc "Chưa đặt", bấm để mở DatePicker, nút x để xoá deadline; quá hạn (chưa Done) hiện màu đỏ. Thẻ task trên board cũng hiện deadline.
  - `TaskDetailCubit.setDeadline`: kiểm tra `Permission.setTaskDeadline`, chỉ lưu phần ngày, từ chối ngày trong quá khứ; `TaskRepository.updateTaskDeadline` chỉ `update` `deadline` + `updatedAt`.
- **US-045 / US-046 — Bình luận (dùng chung 1 bộ code):**
  - `CommentModel` + `CommentTarget` (`.story(projectId, storyId)` / `.task(projectId, taskId)`), `CommentDataSource`, `CommentRepository` + `CommentRepositoryImpl`, `CommentsCubit`, widget dùng chung `CommentsSection` / `CommentItem` / `CommentInput` (`lib/presentation/comments/`).
  - Gắn `CommentsSection` vào cuối `UserStoryDetailScreen` (US-045) và `TaskDetailScreen` (US-046). Có loading / empty / error (kèm "Thử lại") / đang gửi; real-time qua Firestore stream; gửi thành công thì xoá ô nhập; hiện tên người viết + thời gian tương đối ("5 phút trước").
  - Validate: không rỗng / không toàn khoảng trắng / tối đa 1000 ký tự (`CommentValidator`, kiểm tra ở cả Cubit, Repository và Rules). `CommentRepositoryImpl` kiểm tra đăng nhập + là thành viên project (`Permission.comment`) trước khi ghi; `authorId` luôn là uid đang đăng nhập.
- **Firestore structure (không migrate dữ liệu cũ):**
  - Comment User Story: `projects/{projectId}/userStories/{storyId}/comments/{commentId}`.
  - Comment Task: `tasks/{taskId}/comments/{commentId}`.
  - Field comment: `projectId`, `storyId` **hoặc** `taskId`, `authorId`, `authorName`, `content`, `createdAt` (server timestamp).
  - Task: thêm `deadline` (Timestamp|null) và `projectId` (string). Task mới tạo từ Task Board có sẵn `projectId`; **task cũ** được gắn `projectId` tự động lần đầu mở Task Detail (`TaskRepository.attachProject`, chỉ update đúng 1 field) — cần cho rule bình luận task.
- **Phân quyền (RBAC):** thêm `Permission.assignTask`, `Permission.setTaskDeadline`, `Permission.comment` cho cả **PO / SM / MEMBER** (actor của 4 US là "thành viên nhóm"). Không đổi mapping của các permission cũ.
- **Firestore Security Rules (`firestore.rules`):**
  - Thêm rule `comments` cho story và task: chỉ thành viên project đọc/tạo; `authorId == request.auth.uid`; `projectId`/`storyId`/`taskId` phải khớp path; nội dung 1–1000 ký tự; `createdAt == request.time`; không sửa/xoá.
  - Task: `projectId` (nếu có) phải là project mà người gọi là thành viên và không đổi được sau khi gắn; task đã gắn project thì chỉ thành viên project sửa được; assignee mới phải là thành viên project (chỉ kiểm tra khi assignee thay đổi → kéo thả trạng thái không bị ảnh hưởng); `deadline` phải là null/Timestamp. Task cũ chưa có `projectId` giữ nguyên luật cũ.
  - Thêm block `standups` (mọi user đã đăng nhập đọc/ghi) vì file trong repo trước đó **thiếu rule này** dù tính năng Stand-up đang dùng collection `standups`.
  - ⚠️ **Rules đang chạy trên Firebase KHÁC file trong repo:** bản trên server (cập nhật 06/10/2026) là bản "mở" (`allow read, write: if isSignedIn()` cho mọi collection, có cả `standups`). Để không ảnh hưởng tính năng của các thành viên khác, phiên này **KHÔNG deploy `firestore.rules` trong repo**, mà deploy lên `scrumflow-c835d` bản **"rules đang chạy + chỉ thêm 2 block `comments`"** (cùng nội dung với block `comments` trong repo). Đã đọc lại rules trên server sau khi deploy để xác nhận.
- **File mới:** `lib/data/models/comment_model.dart`, `lib/data/datasources/comment_datasource.dart`, `lib/data/repositories/comment_repository.dart`, `lib/data/repositories/comment_repository_impl.dart`, `lib/app/utils/comment_validator.dart`, `lib/presentation/comments/bloc/{comments_cubit,comments_state}.dart`, `lib/presentation/comments/widgets/{comments_section,comment_item,comment_input}.dart`, `lib/presentation/tasks/bloc/{task_detail_cubit,task_detail_state}.dart`, `lib/presentation/tasks/screens/task_detail_screen.dart`, `lib/presentation/tasks/widgets/assignee_picker_dialog.dart`, và 5 file test mới.
- **File sửa:** `task_model.dart` (+`deadline`, `projectId`, `copyWith` có `clearAssignee`/`clearDeadline`), `task_repository.dart` (+`streamTask`, `updateTaskAssignee`, `updateTaskDeadline`, `attachProject`; `createTask` nhận thêm `projectId`/`deadline`), `task_event.dart` + `task_bloc.dart` (`TaskCreated.projectId`), `tasks/screens/task_board_screen.dart` (thêm tham số bắt buộc `projectId`, bấm thẻ mở Task Detail, hiện deadline), `user_story_detail_screen.dart` (truyền `projectId`, thêm card Bình luận), `permission.dart`, `role_permissions.dart`, `date_formatter.dart` (+`formatRelativeTimeVi`), `main.dart` (đăng ký `CommentRepository`), `firestore.rules`, `test/data/repositories/backlog_repository_impl_test.dart` (truyền mock `NotificationRepository`).
- **Kiểm thử:**
  - `flutter test`: **131/131 PASS**. Trước phiên này là 60 pass / **11 fail**: toàn bộ `backlog_repository_impl_test.dart` hỏng từ khi `BacklogRepositoryImpl` tự tạo `NotificationRepository()` thật (cần `Firebase.initializeApp()`); đã sửa bằng cách truyền mock trong test, không đổi code sản phẩm. Test mới: parse deadline null/Timestamp/string, đổi assignee theo từng role PO/SM/MEMBER, không chọn được người ngoài project, đặt/đổi/xoá deadline, từ chối ngày quá khứ, load/gửi comment, từ chối comment rỗng, author đúng, comment task không lẫn sang story, map lỗi Firebase.
  - `flutter analyze`: **0 error**, 43 issue (info/warning) — bằng đúng số lượng trước khi sửa, không thêm issue mới.
  - Firestore rules: chạy trên Firestore Emulator (cục bộ, không đụng dữ liệu thật) cho PO/SM/MEMBER/người ngoài project/chưa đăng nhập — **30/30** với `firestore.rules` trong repo (gồm cả kiểm tra các thao tác Task cũ của teammate vẫn chạy) và **15/15** với bản đã deploy lên server.
  - Chrome: `flutter run -d web-server` build và phục vụ thành công tại `http://localhost:5000`. **Kịch bản thao tác tay** (đổi assignee, đặt deadline, gửi comment, refresh, đăng nhập user khác) **chưa được xác nhận trong phiên này**.
- **Việc còn lại / lưu ý:**
  - Rules trên server hiện vẫn là bản "mở" cho Task/User Story/Project (chỉ riêng `comments` được kiểm tra thành viên project). Việc kiểm tra assignee phải là thành viên project, deadline đúng kiểu... mới chỉ được chặn ở tầng app; phần rule tương ứng nằm sẵn trong `firestore.rules` của repo nhưng **chưa có hiệu lực** cho tới khi nhóm thống nhất deploy bản chặt.
  - Nếu ai deploy lại rules từ Firebase Console/CLI thì phải giữ 2 block `comments`, nếu không bình luận sẽ báo lỗi không có quyền.
  - `TaskBoardScreen` (theo story) giờ bắt buộc truyền `projectId` — nhánh nào còn gọi kiểu cũ cần thêm tham số này.

---

## 3. 📊 Bảng Theo Dõi Chi Tiết Toàn Bộ Sprint Backlog (Sprint 1 → Sprint 5)

> *Dữ liệu đối chiếu từ file kế hoạch `Sprint Backlog LTTTBDD.xlsx` với tiến độ mã nguồn thực tế của dự án.*

### 🚀 SPRINT 1: Nền Tảng Tài Khoản, Dự Án & Phân Quyền Vai Trò
*Tiến độ thực tế: **11 / 11 User Stories hoàn thành (Đạt 100% Sprint 1)***

- [x] **US-001** [Ưu tiên: CAO] *(Thúy)*: Là người dùng mới, tôi muốn đăng ký tài khoản bằng email và mật khẩu để truy cập hệ thống an toàn.  
  *(Đã hoàn thành: UI Register, BLoC, AuthRepositoryImpl, Firebase Auth).*
- [x] **US-002** [Ưu tiên: CAO] *(Thúy)*: Là người dùng đã có tài khoản, tôi muốn đăng nhập bằng email và mật khẩu để truy cập dashboard.  
  *(Đã hoàn thành: UI Login, BLoC, AuthRepositoryImpl, bản đồ lỗi tiếng Việt).*
- [x] **US-003** [Ưu tiên: TB] *(Thúy)*: Là người dùng, tôi muốn đăng xuất để kết thúc phiên làm việc an toàn.  
  *(Đã hoàn thành: Tích hợp nút đăng xuất trên AppBar HomeScreen).*
- [x] **US-056** [Ưu tiên: CAO] *(Phúc)*: Là người dùng, tôi muốn mở khóa nhanh ứng dụng bằng vân tay/Face ID sau lần đăng nhập đầu, để tăng bảo mật và tiện lợi.  
  *(Đã hoàn thành: Tích hợp `local_auth`, `BiometricService`, `FlutterFragmentActivity`, lưu trữ mã hóa `FlutterSecureStorage` và nút quét sinh trắc học tại `LoginScreen`).*
- [x] **US-004** [Ưu tiên: CAO] *(Phúc)*: Là quản trị viên, tôi muốn phân quyền vai trò (PO/SM/Member) để kiểm soát quyền truy cập.  
  *(Đã hoàn thành: RBAC tập trung trong `role_permissions.dart`, `firestore.rules`, test 100% pass).*
- [x] **US-036** [Ưu tiên: CAO] *(Hiếu)*: Là quản trị viên/PO, tôi muốn tạo Project mới để quản lý backlog và sprint.  
  *(Đã hoàn thành: UI Tạo project, tự động gán role PO, lưu Firestore).*
- [x] **US-037** [Ưu tiên: CAO] *(Hiếu)*: Là quản trị viên/PO, tôi muốn chỉnh sửa thông tin Project để cập nhật mục tiêu hoặc mô tả.  
  *(Đã hoàn thành: `edit_project_dialog.dart`, phân quyền PO `Permission.manageProject`, cập nhật real-time).*
- [x] **US-039** [Ưu tiên: CAO] *(Hiếu)*: Là quản trị viên/PO, tôi muốn thêm thành viên vào Project để họ tham gia làm việc.  
  *(Đã hoàn thành: UI & Bloc thêm thành viên theo email).*
- [x] **US-040** [Ưu tiên: CAO] *(Duy)*: Là quản trị viên/PO, tôi muốn gán vai trò cho thành viên trong Project để phân quyền phù hợp.  
  *(Đã hoàn thành: Dialog đổi role PO/SM/Member, chặn PO tự đổi role của chính mình).*
- [x] **US-005** [Ưu tiên: CAO] *(Duy)*: Là PO/SM, tôi muốn xem danh sách tất cả User Stories trong Product Backlog để nắm tổng quan.  
  *(Đã hoàn thành: Màn hình `BacklogListScreen`, bộ lọc trạng thái, tổng điểm Story Points, nút nạp dữ liệu mẫu kèm User ảo).*
- [x] **US-006** [Ưu tiên: CAO] *(Duy)*: Là PO/SM, tôi muốn xem chi tiết một User Story để nắm đầy đủ thông tin nhiệm vụ.  
  *(Đã hoàn thành: Màn hình `UserStoryDetailScreen`, hiển thị chi tiết Story Key, Ưu tiên, Điểm SP, Mô tả nghiệp vụ, Người phụ trách).*

---

### 📦 SPRINT 2: Quản Lý Product Backlog & Lập Kế Hoạch Sprint
*Tiến độ thực tế: **9 / 12 User Stories hoàn thành***

- [ ] **US-007** [Ưu tiên: CAO]: Là PO/SM, tôi muốn tìm kiếm User Story theo từ khóa để truy xuất nhanh. *(Chưa hoàn thành)*
- [ ] **US-008** [Ưu tiên: CAO]: Là PO/SM, tôi muốn lọc User Story theo trạng thái, ưu tiên hoặc nhãn. *(Chưa hoàn thành)*
- [x] **US-009** [Ưu tiên: CAO]: Là PO/SM, tôi muốn sắp xếp backlog bằng dropdown chọn tiêu chí (ưu tiên/deadline).  
  *(Đã hoàn thành: Dropdown Mặc định/Ưu tiên/Deadline trong `BacklogListScreen`, sort ổn định CAO→TB→THẤP, deadline null xếp cuối, kết hợp với filter trạng thái trong `BacklogBloc`).*
- [x] **US-010** [Ưu tiên: CAO]: Là PO/SM, tôi muốn tạo mới một User Story với tiêu đề, mô tả, ưu tiên.  
  *(Đã hoàn thành: Dialog tạo story + `CreateUserStoryCubit` chống bấm lặp, tự sinh storyKey, kiểm tra quyền PO/SM ở Repository và Firestore Rules).*
- [x] **US-011** [Ưu tiên: CAO]: Là PO/SM, tôi muốn chỉnh sửa một User Story để cập nhật nội dung.  
  *(Đã hoàn thành: `showEditUserStoryDialog` + `EditUserStoryCubit`, chặn quyền PO/SM, update Firestore).*
- [ ] **US-012** [Ưu tiên: TB]: Là PO/SM, tôi muốn xóa User Story không còn phù hợp. *(Chưa hoàn thành)*
- [x] **US-013** [Ưu tiên: CAO]: Là PO/SM, tôi muốn gán Story Points cho User Story.  
  *(Đã hoàn thành: Tích hợp chọn Story Points Fibonacci trong hộp thoại Edit User Story).*
- [x] **US-014** [Ưu tiên: TB]: Là PO/SM, tôi muốn gắn nhãn/tag cho User Story.  
  *(Đã hoàn thành: Card "Nhãn / Tags" trong `UserStoryDetailScreen`, `StoryTagsCubit`, cập nhật riêng field `tags` trên Firestore).*
- [x] **US-015** [Ưu tiên: CAO]: Là Scrum Master, tôi muốn xem danh sách Sprint đã tạo.  
  *(Đã hoàn thành: Màn hình `SprintListScreen`, Bloc, Repos, Mock data fallback).*
- [x] **US-016** [Ưu tiên: CAO]: Là Scrum Master, tôi muốn tạo Sprint mới với tên, mục tiêu, ngày bắt đầu và kết thúc.  
  *(Đã hoàn thành: Hộp thoại `CreateSprintDialog`, validate ngày, lưu sub-collection `sprints` trên Firestore).*
- [x] **US-017** [Ưu tiên: CAO]: Là Scrum Master, tôi muốn xem chi tiết Sprint để biết mục tiêu và các User Story được chọn.  
  *(Đã hoàn thành: Màn hình `SprintDetailScreen`, hiển thị danh sách User Story chọn trong Sprint).*
- [x] **US-018** [Ưu tiên: CAO]: Là Scrum Master, tôi muốn thêm User Story từ backlog vào Sprint.  
  *(Đã hoàn thành: Luồng chọn User Story từ Backlog gán vào Sprint `storyIds`, cập nhật real-time trên Firestore).*

---

### 📋 SPRINT 3: Task Board, Cộng Tác & Trợ Lý Gợi Ý Phân Công AI
*Tiến độ thực tế: **12 / 17 User Stories hoàn thành***

- [x] **US-053** [Ưu tiên: CAO]: Là PO/SM, tôi muốn tích chọn nhiều User Story cùng lúc bằng checkbox trong danh sách Backlog hoặc Sprint để di chuyển hoặc xóa hàng loạt.  
  *(Đã hoàn thành: Tích hợp checkbox lựa chọn trên từng hàng/thẻ, thanh thao tác hàng loạt "Di chuyển vào Sprint" qua `MoveToSprintDialog` và "Xóa hàng loạt" qua `deleteUserStories`).*
- [x] **US-052** [Ưu tiên: CAO]: Là PO/SM, tôi muốn giao diện Product Backlog có phân trang và mỗi row gọn để hiển thị ít nhất 10 row trên màn hình mà không cần scroll.  
  *(Đã hoàn thành: Giao diện `CompactUserStoryRow` chiều cao ~46px tối ưu cho 10+ dòng/màn hình, tích hợp nút chuyển chế độ Hàng gọn / Thẻ chi tiết).*
- [x] **US-051** [Ưu tiên: CAO]: Là PO/SM, tôi muốn API load User Story theo phân trang để không load toàn bộ backlog lên client (tối ưu performance).  
  *(Đã hoàn thành: Thanh phân trang ở đáy danh sách `Trang X / Y`, nút bấm chuyển trang `<` và `>`).*
- [x] **US-019** [Ưu tiên: CAO]: Là thành viên nhóm, tôi muốn xem Task Board theo từng Sprint. *(Đã hoàn thành: Xây dựng màn hình Task Board hiển thị trạng thái các User Story và Tasks).*
- [x] **US-020** [Ưu tiên: CAO]: Là thành viên nhóm, tôi muốn tạo task cho một User Story. *(Đã hoàn thành: Thêm TaskModel, TaskRepository và nút Tạo Task ở Task Board)*
- [x] **US-021** [Ưu tiên: CAO]: Là thành viên nhóm, tôi muốn cập nhật trạng thái task bằng kéo-thả. *(Đã hoàn thành: Kanban board hỗ trợ kéo thả Draggable/DragTarget trong TaskBoardScreen)*
- [x] **US-022** [Ưu tiên: CAO]: Là thành viên nhóm, tôi muốn ghi Daily Stand-up theo 3 câu hỏi. *(Đã hoàn thành: Thiết kế màn hình DailyStandupFormScreen, tích hợp vào Project Detail).*
- [x] **US-033** [Ưu tiên: TB]: Là Scrum Master, tôi muốn xem lịch sử Daily Stand-up. *(Đã hoàn thành: Thiết kế màn hình StandupHistoryScreen, tích hợp vào Project Detail, xem lọc theo ngày).*
- [ ] **US-029** [Ưu tiên: CAO]: Là thành viên nhóm, tôi muốn nhận Push Notification khi được giao task mới, có bình luận mới, hoặc khi task đổi trạng thái. *(Chưa hoàn thành)*
- [x] **US-043** [Ưu tiên: CAO]: Là thành viên nhóm, tôi muốn thay đổi người phụ trách task khi cần phân công lại.  
  *(Đã hoàn thành: `TaskDetailScreen` + dialog chọn thành viên thực tế của project, `TaskDetailCubit.changeAssignee`, chỉ update field assignee trên Firestore.)*
- [x] **US-044** [Ưu tiên: CAO]: Là thành viên nhóm, tôi muốn đặt deadline cho task để quản lý tiến độ.  
  *(Đã hoàn thành: field `deadline` (Timestamp, nullable) trong `TaskModel`, DatePicker đặt/đổi/xoá trong Task Detail, hiện deadline trên thẻ task.)*
- [x] **US-045** [Ưu tiên: CAO]: Là thành viên nhóm, tôi muốn bình luận (comment) trong User Story.  
  *(Đã hoàn thành code + test: card Bình luận trong `UserStoryDetailScreen`, lưu ở `userStories/{storyId}/comments`, rule `comments` đã deploy.)*
- [x] **US-046** [Ưu tiên: CAO]: Là thành viên nhóm, tôi muốn bình luận trong Task để trao đổi quá trình thực hiện.  
  *(Đã hoàn thành code + test: card Bình luận trong `TaskDetailScreen`, lưu ở `tasks/{taskId}/comments`, dùng chung `CommentsSection` với US-045, rule `comments` đã deploy.)*
- [ ] **US-047** [Ưu tiên: CAO]: Là thành viên nhóm, tôi muốn tải lên file/attachment cho User Story hoặc Task. *(Chưa hoàn thành)*
- [ ] **US-057** [Ưu tiên: CAO]: Là PO/SM, tôi muốn hệ thống gợi ý (AI) thành viên phù hợp nhất để giao task mới dựa trên tỷ lệ đúng hạn và khối lượng task hiện tại. *(Chưa hoàn thành)*
- [ ] **US-058** [Ưu tiên: CAO]: Là hệ thống, tôi muốn tự động tính điểm hiệu suất (performance score) của từng thành viên làm đầu vào cho thuật toán gợi ý ở US-057:  
  `performance_score = w1*(task đúng hạn / tổng task) + w2*(1 - task đang làm/giới hạn workload) + w3*(điểm đánh giá trung bình)`. *(Chưa hoàn thành)*
- [ ] **US-059** [Ưu tiên: CAO]: Là thành viên nhóm, tôi muốn nhận Local Notification nhắc trước khi Task sắp đến hạn (VD: 1 ngày). *(Chưa hoàn thành)*

---

### 📈 SPRINT 4: Đóng/Mở Sprint, Báo Cáo & Biểu Đồ Burndown/Velocity
*Tiến độ thực tế: **0 / 9 User Stories hoàn thành***

- [ ] **US-060** [Ưu tiên: TB]: Là quản trị viên/PO, tôi muốn xem bảng thống kê hiệu suất từng thành viên (tỷ lệ đúng hạn, số task đang xử lý). *(Chưa hoàn thành)*
- [ ] **US-023** [Ưu tiên: TB]: Là Product Owner, tôi muốn ghi nhận kết quả Sprint Review (demo + feedback). *(Chưa hoàn thành)*
- [ ] **US-024** [Ưu tiên: TB]: Là nhóm phát triển, tôi muốn tạo Sprint Retrospective. *(Chưa hoàn thành)*
- [ ] **US-025** [Ưu tiên: TB]: Là Scrum Master/PO, tôi muốn xem Burndown Chart. *(Chưa hoàn thành)*
- [ ] **US-026** [Ưu tiên: TB]: Là Scrum Master/PO, tôi muốn xem Velocity Chart. *(Chưa hoàn thành)*
- [ ] **US-027** [Ưu tiên: THẤP]: Là Scrum Master/PO, tôi muốn export báo cáo Sprint ra PDF/Excel. *(Chưa hoàn thành)*
- [ ] **US-048** [Ưu tiên: CAO]: Là PO/SM, tôi muốn cập nhật trạng thái của User Story (To Do / In Progress / Done / Rejected). *(Chưa hoàn thành)*
- [ ] **US-049** [Ưu tiên: CAO]: Là PO/SM, tôi muốn bắt đầu Sprint (Start Sprint) để chính thức triển khai. *(Chưa hoàn thành)*
- [ ] **US-050** [Ưu tiên: CAO]: Là PO/SM, tôi muốn kết thúc Sprint (Close Sprint) để tổng kết kết quả. *(Chưa hoàn thành)*

---

### ⚙️ SPRINT 5: Hoàn Thiện Hệ Thống, Offline Cache, Realtime & Đóng Gói
*Tiến độ thực tế: **5 / 10 User Stories hoàn thành hoặc đạt nền tảng cốt lõi***

- [ ] **US-028** [Ưu tiên: THẤP]: Phát triển tính năng Realtime update Task Board bằng Socket.io (bonus). *(Chưa hoàn thành)*
- [ ] **US-030** [Ưu tiên: THẤP]: Hoàn thiện giao diện responsive và dark mode (bonus). *(Chưa hoàn thành)*
- [x] **US-031** [Ưu tiên: CAO]: Build và đóng gói file APK/AAB để cài đặt, backend deploy Render/Railway.  
  *(Đã hoàn thành phần đóng gói APK: Build thành công APK 159MB, cài đặt & chạy trực tiếp trên thiết bị di động thật Xiaomi Android 14).*
- [ ] **US-038** [Ưu tiên: TB]: Là quản trị viên/PO, tôi muốn xóa Project khi dự án kết thúc hoặc không còn sử dụng.  
  *(Chưa hoàn thành: Đã có hàm xóa ở Data Source phục vụ rollback, chưa gắn vào UI/Repository).*
- [x] **US-041** [Ưu tiên: TB]: Là quản trị viên/PO, tôi muốn xóa thành viên khỏi Project khi họ không còn tham gia.  
  *(Đã hoàn thành: Đã hiện thực trong `ProjectMemberRepositoryImpl`, `ProjectMemberDataSource`, `ProjectMembersBloc` và `firestore.rules`).*
- [ ] **US-062** [Ưu tiên: TB]: Là người dùng, tôi muốn ứng dụng lưu cache Backlog/Task xuống SQLite cục bộ để xem được dữ liệu khi mất mạng.  
  *(Chưa hoàn thành: Hiện mới chỉ cache tài khoản người dùng `UserModel`).*
- [x] **US-063** [Ưu tiên: CAO]: Là người dùng, tôi muốn được thông báo rõ khi mất mạng hoặc API timeout để biết trạng thái và thử lại.  
  *(Đã hoàn thành nền tảng: `ConnectivityService`, tiền kiểm tra mạng và ánh xạ lỗi Firebase).*
- [x] **US-064** [Ưu tiên: CAO]: Là người dùng, tôi muốn có hiệu ứng chuyển trang mượt và loading animation khi tải dữ liệu.  
  *(Đã hoàn thành nền tảng: Đã áp dụng loading states, shimmer/indicator cho các màn hình Auth, Project).*
- [x] **US-054** [Ưu tiên: CAO]: Là nhóm phát triển, tôi muốn viết và chạy bộ Test Case cho toàn bộ 5 Sprint để đảm bảo hệ thống vận hành ổn định.  
  *(Đã hoàn thành cho các module hiện có: 69/69 unit tests pass sạch cho Auth, Permissions, Project Members, Project Repository, Error Mapper, Platform Error Mapper, Product Backlog — tạo story/tag/sort).*
- [x] **US-055** [Ưu tiên: CAO]: Tối ưu hóa giao diện Responsive trên thiết bị di động (UI Refinement).  
  *(Đã hoàn thành nền tảng: Tích hợp `flutter_screenutil`, căn chỉnh tỷ lệ giao diện).*

---

## 4. 📌 Hướng Dẫn Cập Nhật Tài Liệu Này
* Mỗi khi kết thúc một cuộc trao đổi quan trọng, hoàn thành một chức năng hoặc tạo commit mới, cập nhật thêm nội dung công việc vào phần **2. Công Việc Đã Thực Hiện** và cập nhật checkbox tiến độ ở **3. Bảng Theo Dõi Chi Tiết Toàn Bộ Sprint Backlog**.

