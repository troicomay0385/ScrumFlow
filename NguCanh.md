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

---

## 3. 📌 Hướng Dẫn Cập Nhật Tài Liệu Này
* Mỗi khi kết thúc một cuộc trao đổi quan trọng, hoàn thành một chức năng hoặc tạo commit mới, cập nhật thêm nội dung công việc vào phần **2. Công Việc Đã Thực Hiện**.
