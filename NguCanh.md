# 📌 NHẬT KÝ CÔNG VIỆC DỰ ÁN SCRUMFLOW (NguCanh.md)

> **Mục đích tài liệu:** Lưu lại tiến độ và toàn bộ công việc nhóm đã thực hiện trong quá trình phát triển dự án ứng dụng di động **Scrumflow**. Dùng để các thành viên trong nhóm và AI theo dõi, phối hợp liền mạch qua các phiên làm việc.

---

## 1. 📋 Thông Tin Dự Án

* **Tên dự án:** **Scrumflow** - Ứng dụng Quản lý Dự án theo mô hình Agile/Scrum trên Di động
* **Môn học:** CMP177 - Lập trình trên thiết bị di động
* **Công nghệ cốt lõi:**
  * **Framework:** Flutter (Dart)
  * **Mô hình kiến trúc:** Layered Architecture (Data - Presentation - App/Core)
  * **State Management:** BLoC (`flutter_bloc`, `equatable`)
  * **Backend & Cloud:** Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`)
  * **Lưu trữ cục bộ (Local):** `sqflite`, `flutter_secure_storage`
  * **Giao diện (UI/UX):** `flutter_screenutil`, `google_fonts`, Dark/Light Mode Theme
* **Tài liệu tham chiếu trong repo:**
  * [README_MoTaDoAnMonHoc.md](file:///e:/BTVN/L%E1%BA%ADp%20tr%C3%ACnh%20di%20%C4%91%E1%BB%99ng%20b%C3%A0i%20t%E1%BA%ADp/D%E1%BB%B1%20%C3%A1n%20Scrumflow/README_MoTaDoAnMonHoc.md): Yêu cầu kỹ thuật và tiêu chí đánh giá môn học.
  * [README_MoTaChucNang.md](file:///e:/BTVN/L%E1%BA%ADp%20tr%C3%ACnh%20di%20%C4%91%E1%BB%99ng%20b%C3%A0i%20t%E1%BA%ADp/D%E1%BB%B1%20%C3%A1n%20Scrumflow/README_MoTaChucNang.md): Bản đặc tả chức năng chi tiết, User Stories và quy tắc hệ thống.

---

## 2. 📝 Nhật Ký Công Việc Đã Thực Hiện

### ✅ Giai đoạn 1: Khởi tạo Nền tảng & Đồng bộ Mã Nguồn (18/09/2026)
1. **Thiết lập Git Repository:**
   - Kết nối và đồng bộ dự án với GitHub repository: `https://github.com/troicomay0385/ScrumFlow.git` (nhánh chính `main`).
   - Tích hợp bộ tài liệu đồ án vào mã nguồn: `README_MoTaDoAnMonHoc.md`, `README_MoTaChucNang.md`, `NguCanh.md`.

2. **Khảo sát & Chuẩn bị Môi trường Kiến trúc:**
   - Khảo sát các thư viện và module hiện có trong mã nguồn dự án:
     - **Tầng Core/App (`lib/app/`):** Đã xây dựng sẵn bảng màu chuẩn (`AppColors`), hằng số chuỗi (`AppStrings`), điều hướng định tuyến (`AppRoutes`), dịch vụ kết nối mạng (`ConnectivityService`), chủ đề giao diện (`AppTheme`), và xử lý mã lỗi Firebase (`firebase_error_mapper.dart`).
     - **Tầng Dữ liệu (`lib/data/`):** Đã xây dựng Data Source Firebase Auth (`firebase_auth_datasource.dart`), Firestore (`firestore_datasource.dart`), Local Cache (`local_cache_datasource.dart`), Model người dùng (`UserModel`), và trừu tượng hóa Repository (`AuthRepository`, `AuthRepositoryImpl`).
     - **Cấu hình Dependencies (`pubspec.yaml`):** Đã khai báo đầy đủ các gói thư viện chuẩn cho Firebase, BLoC, SQLite, Secure Storage, ScreenUtil.

---

## 3. 🚀 Kế Hoạch & Phân Công Tiếp Theo (Roadmap)

- [ ] **Sprint 1: Xác thực & Quản lý Tài khoản (Authentication)**
  - Tích hợp giao diện Đăng ký / Đăng nhập / Đăng nhập Google (`presentation/auth/`).
  - Hoàn thiện luồng BLoC cho Auth (`AuthBloc`, `AuthEvent`, `AuthState`).
  - Lưu trữ phiên đăng nhập và token với `flutter_secure_storage`.
- [ ] **Sprint 2: Quản lý Dự án & Workspace**
  - CRUD Dự án (Tạo, sửa, xóa, xem danh sách dự án).
  - Quản lý thành viên trong dự án và phân quyền.
- [ ] **Sprint 3: Quản lý Backlog, Sprint & Bảng Kanban**
  - Quản lý User Stories / Tasks.
  - Kéo thả Task trên bảng Kanban (To Do, In Progress, In Review, Done).
- [ ] **Sprint 4: Báo cáo Thống kê & Biểu đồ**
  - Biểu đồ Burndown Chart, Velocity Chart (theo yêu cầu môn học).
- [ ] **Sprint 5: Thông báo & Đồng bộ Offline**
  - Local Notification nhắc việc đến hạn.
  - Đồng bộ dữ liệu cục bộ SQLite khi mất mạng.

---

## 4. 📌 Hướng Dẫn Cập Nhật Tài Liệu
* Mỗi khi thành viên trong nhóm hoàn thành một chức năng hoặc tạo PR/commit mới, hãy cập nhật mục tương ứng trong phần **2. Nhật Ký Công Việc Đã Thực Hiện**.
* Đánh dấu `[x]` vào các đầu việc trong **3. Kế Hoạch & Phân Công Tiếp Theo** khi hoàn thành để theo dõi tiến độ đồ án.
