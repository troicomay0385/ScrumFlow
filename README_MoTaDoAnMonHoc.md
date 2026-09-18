**YÊU CẦU ĐỒ ÁN MÔN HỌC**&nbsp;

**CMP177 \- LẬP TRÌNH TRÊN THIẾT BỊ DI ĐỘNG A. Đề xuất đề tài**&nbsp;

Mỗi nhóm tự đề xuất một ý tưởng ứng dụng để thực hiện đồ án. Bản đề xuất phải bao gồm: 1\. Tên đồ án&nbsp;&nbsp;

2\. Danh sách chức năng: Liệt kê các chức năng chính của ứng dụng mà nhóm dự định xây  dựng, phát triển.&nbsp;

**B. Yêu cầu kỹ thuật**&nbsp;

Ứng dụng của các nhóm phải đáp ứng các yêu cầu kỹ thuật tối thiểu sau đây: **1\. Công nghệ**&nbsp;

\- Nền tảng: Flutter.&nbsp;

\- Ngôn ngữ: Dart.&nbsp;

**2\. Cấu trúc dự án**&nbsp;

\- Mã nguồn bắt buộc phải được tổ chức theo một cấu trúc rõ ràng, có phân tách các thành  phần. Ví dụ: Không được viết tất cả logic và UI trong cùng một tệp.&nbsp;

\- Ví dụ tổ chức theo các lớp:&nbsp;

\+ Data: Chứa Models (mô hình dữ liệu), Repositories (xử lý logic dữ liệu), Data Sources  (API, DB).&nbsp;

\+ Presentation (hoặc UI/Features): Chứa các Screens (màn hình), Widgets (thành phần  con), và State Management (Blocs/Providers/Controllers).&nbsp;

\+ App/Core: Chứa các tệp dùng chung như Routes (điều hướng), Constants (hằng số),  Theme (chủ đề).&nbsp;

**3\. Giao diện và Trải nghiệm người dùng (UI/UX)**&nbsp;

\- Thiết kế: Giao diện phải rõ ràng, đồng bộ theo một chủ đề.&nbsp;

\- Thích ứng (Responsive): Layout phải hiển thị tốt trên nhiều kích thước màn hình điện  thoại (không bị vỡ).&nbsp;

\- Hiệu ứng giao diện: Sử dụng animation (ví dụ: chuyển trang mượt mà, hiệu ứng loading)  để tăng trải nghiệm người dùng.&nbsp;

**4\. Yêu cầu dự án**&nbsp;

\- Dự án bắt buộc phải sử dụng một trong các giải pháp quản lý trạng thái trong chương trình  học:&nbsp;

\+ Provider&nbsp;

\+ BLoC

\+ GetX&nbsp;

\- Yêu cầu phải tách biệt rõ ràng giao diện (UI) và logic nghiệp vụ (Business Logic). Ví dụ không được gọi API hay truy vấn CSDL trực tiếp từ tệp UI&nbsp;

\- Bảo trì: Thiết kế mã nguồn theo nguyên tắc clean code, dễ mở rộng tính năng trong tương  lai.&nbsp;

\- Tối ưu hóa API: Nếu dùng API, cần xử lý lỗi (timeout, không có mạng) và lưu cache dữ liệu để tăng tốc độ tải.&nbsp;

\- Bảo trì: Thiết kế mã nguồn theo nguyên tắc clean code, dễ mở rộng tính năng trong tương  lai.&nbsp;

\- Kiểm thử: Đảm bảo chất lượng, tính đúng đắn của ứng dụng.&nbsp;

\- Sinh viên phải hiểu thuật toán/logic khi sử dụng AI trong quá trình làm đồ án. **5\. Chức năng bắt buộc**&nbsp;

**a) Chức năng CRUD**&nbsp;

\- Ứng dụng phải có chức năng CRUD (Tạo \- Đọc \- Cập nhật \- Xóa) đối với đối tượng dữ liệu của ứng dụng (ví dụ: chi tiêu, công việc, bài đăng, sản phẩm...).&nbsp;

**b) Chức năng cốt lõi (Theo chủ đề)**&nbsp;

Dựa trên đề tài của nhóm, phải có các chức năng đặc thù:&nbsp;

\- Quản lý cá nhân: Phải có chức năng thống kê hoặc vẽ biểu đồ.&nbsp;

\- Mạng xã hội: Phải có chức năng gửi/nhận dữ liệu.&nbsp;

\- Thương mại điện tử: Phải có chức năng giỏ hàng và mô phỏng thanh toán. \- Sức khỏe: Phải có chức năng theo dõi tiến độ.&nbsp;

**c) Bảo mật**&nbsp;

\- Nếu ứng dụng có dữ liệu cá nhân (chi tiêu, nhật ký) phải có cơ chế bảo mật:  \+ Sử dụng xác thực sinh trắc học (vân tay/khuôn mặt) hoặc Mã PIN để mở ứng dụng. \- Nếu ứng dụng có dữ liệu online (Firebase/API):&nbsp;

\+ Bắt buộc phải có chức năng Đăng nhập/Đăng ký.&nbsp;

**d) Thông báo của ứng dụng**&nbsp;

\- Ứng dụng phải có ít nhất một loại thông báo:&nbsp;

\+ Local Notifications: Cho các app nhắc nhở (công việc, học từ vựng). \+ Push Notifications: Cho các app mạng xã hội, chat, (ví dụ: “Bạn có tin nhắn mới”). **e) Tìm kiếm**&nbsp;

\- Ứng dụng phải có chức năng tìm kiếm (Search) cho danh sách dữ liệu chính (danh sách  chi tiêu, sản phẩm, bạn bè...).

**f) Lưu trữ**&nbsp;

Ứng dụng phải có chức năng lưu trữ dữ liệu:&nbsp;

\- Lưu trữ cục bộ (Local): Ví dụ sử dụng SQLite.&nbsp;

\- Lưu trữ đám mây (Cloud): Sử dụng Firebase (Firestore/Realtime Database) hoặc gọi  REST API (từ server tự xây dựng hoặc API công cộng).&nbsp;

▪ The end