# ScrumFlow – Mô tả chức năng & Kiến trúc kỹ thuật

> README này là tài liệu bổ sung (README 2) cho **README 1 – Yêu cầu đồ án CMP177**, và đã được đối chiếu/cập nhật theo **Sprint Backlog (Sprint_Backlog_LTTTBDD.xlsx, 5 sprint, US-001 → US-064)** để phản ánh đúng những gì nhóm đã lên kế hoạch thực hiện. Mọi mục ở dưới được đối chiếu trực tiếp với các yêu cầu bắt buộc trong README 1 để đảm bảo không thiếu sót khi review/nộp bài.

## 1. Tổng quan đồ án

| Thông tin | Nội dung |
|---|---|
| Tên đồ án | ScrumFlow – Ứng dụng quản lý dự án theo mô hình Agile Scrum trên thiết bị di động |
| Nền tảng | Flutter |
| Ngôn ngữ | Dart |
| Quản lý trạng thái | **BLoC** |
| Lưu trữ cục bộ | **SQLite** (chốt theo US-062 — cache Backlog/Task để xem offline) |
| Backend / Lưu trữ đám mây | **REST API tự xây dựng**, deploy trên Render/Railway (chốt theo US-031), có **Socket.io** cho realtime Task Board (US-028, bonus) — không dùng Firebase Firestore |
| Push Notification | Cần tích hợp FCM (Firebase Cloud Messaging) hoặc dịch vụ push tương đương, dù backend chính là REST tự build (xem mục 2.8) |
| Thiết kế UI | Antigravity + MCP kết nối Stitch để tạo mockup, sau đó chuyển thành widget Flutter |

---

## 2. Danh sách chức năng chi tiết

### 2.1. Quản lý Tài khoản & Bảo mật
- Đăng ký / Đăng nhập / Đăng xuất bằng email và mật khẩu.
- Phân quyền theo vai trò: Product Owner, Scrum Master, Team Member.
- Khóa ứng dụng bằng mã PIN hoặc sinh trắc học (vân tay / khuôn mặt).

### 2.2. Quản lý Dự án
- Tạo mới / Chỉnh sửa / Xóa dự án.
- Thêm / Xóa thành viên và gán vai trò.

### 2.3. Quản lý Product Backlog
- CRUD User Story.
- Gán Story Point và nhãn (Tag).
- Tìm kiếm và lọc User Story (theo trạng thái, ưu tiên, nhãn).
- Sắp xếp backlog theo tiêu chí (ưu tiên/deadline).
- Cập nhật trạng thái User Story — enum chốt theo US-048: **To Do / In Progress / Done / Rejected**.
- **[Mới]** Chọn nhiều User Story cùng lúc (checkbox) để di chuyển sang Sprint khác hoặc xóa hàng loạt (US-053).
- **[Mới]** Phân trang danh sách Backlog: UI hiển thị ≥10 row/màn không cần scroll, API load theo trang thay vì load toàn bộ (US-051, US-052 — tối ưu performance).
- **[Mới]** Bình luận (comment) trong User Story (US-045).
- **[Mới]** Tải lên file/attachment cho User Story (US-047).

### 2.4. Quản lý Sprint
- Tạo Sprint mới (tên, mục tiêu, ngày bắt đầu/kết thúc).
- Xem danh sách và chi tiết Sprint.
- Thêm User Story từ Backlog vào Sprint.
- Bắt đầu (Start Sprint) / Kết thúc (Close Sprint).
- **[Mới]** Sprint Review: ghi nhận kết quả demo + feedback (US-023).
- **[Mới]** Sprint Retrospective (US-024).
- **[Mới]** Export báo cáo Sprint ra PDF/Excel (US-027).

### 2.5. Task Board (Kanban)
- Xem Task Board theo Sprint.
- Tạo task cho một User Story, kéo-thả cập nhật trạng thái.
- Gán người phụ trách và đặt deadline; đổi người phụ trách khi cần phân công lại (US-043).
- **[Mới]** Bình luận (comment) trong Task để trao đổi tiến độ (US-046).
- **[Mới]** Tải lên file/attachment cho Task (US-047).
- **[Mới]** Realtime update Task Board bằng Socket.io (US-028, bonus) — khi 1 thành viên kéo-thả, các thiết bị khác thấy cập nhật ngay không cần refresh.
- **[Mới]** AI gợi ý thành viên phù hợp nhất để giao task mới, dựa trên tỷ lệ hoàn thành đúng hạn + workload hiện tại (US-057).
- **[Mới]** Tự động tính performance score từng thành viên làm đầu vào cho gợi ý AI ở trên (US-058):
  `performance_score = w1*(task đúng hạn / tổng task đã giao) + w2*(1 - task đang đảm nhận/giới hạn workload) + w3*(điểm đánh giá trung bình, nếu có)`
- **[Mới]** Bảng thống kê hiệu suất từng thành viên (tỷ lệ đúng hạn, số task đang xử lý) cho PO/Admin (US-060).

### 2.6. Daily Stand-up
- Ghi nhận báo cáo theo 3 câu hỏi chuẩn Scrum.
- Xem lịch sử Daily Stand-up.

### 2.7. Thống kê & Báo cáo
- Burndown Chart.
- Velocity Chart.
- Bảng thống kê hiệu suất thành viên (xem 2.5).
- Export báo cáo Sprint ra PDF/Excel (xem 2.4).

### 2.8. Thông báo
- **Local Notification:** nhắc task sắp đến hạn (ví dụ trước 1 ngày — US-059); *(cần bổ sung backlog nếu vẫn muốn giữ nhắc Daily Stand-up / Sprint sắp kết thúc — xem mục 8)*.
- **[Mới] Push Notification** (US-029): khi được giao task mới, khi có bình luận mới, khi task đổi trạng thái. Vượt yêu cầu tối thiểu của README 1 (chỉ bắt buộc 1 loại) — cần tích hợp FCM.
- **[Mới]** Thông báo rõ khi mất mạng hoặc API timeout, để người dùng biết trạng thái và thử lại (US-063).

### 2.9. Lưu trữ dữ liệu
- Cục bộ: **SQLite** — cache Backlog/Task để xem được khi mất mạng (US-062).
- Đám mây: **REST API tự xây dựng**, backend deploy Render/Railway (US-031); realtime qua Socket.io cho Task Board (US-028).

### 2.10. Giao diện & Trải nghiệm
- Light / Dark Mode.
- Responsive trên nhiều kích thước màn hình (tối ưu riêng — US-055).
- Animation chuyển trang mượt và loading animation khi tải dữ liệu (US-064).

### 2.11. Đóng gói & Kiểm thử *(mới, tách riêng để không bị bỏ sót khi chấm điểm)*
- Viết và chạy Test Case cho toàn bộ 5 Sprint để đảm bảo không phát sinh lỗi khi cập nhật tính năng mới (US-054).
- Build và đóng gói file APK/AAB để cài đặt (US-031).

---

## 3. Mapping chức năng vào yêu cầu kỹ thuật bắt buộc (README 1 – mục B.5)

| Yêu cầu bắt buộc | Chức năng đáp ứng | Trạng thái |
|---|---|---|
| a) CRUD | CRUD User Story, CRUD Dự án, CRUD Task, CRUD Sprint | ✅ Đủ, dư yêu cầu tối thiểu |
| b) Chức năng cốt lõi theo chủ đề (thống kê/biểu đồ) | Burndown Chart, Velocity Chart, bảng hiệu suất thành viên | ✅ Dư yêu cầu |
| c) Bảo mật – dữ liệu cá nhân | Khóa app bằng PIN/sinh trắc học (Face ID/vân tay) | ✅ |
| c) Bảo mật – dữ liệu online | Đăng ký/Đăng nhập (email + mật khẩu), phân quyền vai trò | ✅ |
| d) Thông báo | Local Notification (task đến hạn) **+** Push Notification (giao task, comment, đổi trạng thái) | ✅ Dư yêu cầu (làm cả 2 loại thay vì chỉ 1) |
| e) Tìm kiếm | Tìm kiếm & lọc User Story | ✅ |
| f) Lưu trữ cục bộ | **SQLite** (đã chốt) | ✅ |
| f) Lưu trữ đám mây | **REST API tự xây dựng** (Render/Railway) + Socket.io realtime | ✅ |

**Ghi chú:** README 1 chỉ bắt buộc **1** loại thông báo, và Push Notification chỉ bắt buộc với app mạng xã hội/chat. ScrumFlow thuộc nhóm "Quản lý cá nhân/nhóm" nên Local Notification vốn đã đủ điều kiện — nhưng theo Sprint Backlog, nhóm chủ động làm **cả 2 loại** (Local + Push, US-029/US-059), vượt yêu cầu tối thiểu. Vì có Push Notification thật (không chỉ optional), cần đảm bảo backend REST tự build có tích hợp gửi qua **FCM**, chứ không chỉ có Socket.io (Socket.io chỉ hoạt động khi app đang mở/foreground, không thay được Push khi app đã tắt).

---

## 4. Cấu trúc thư mục dự kiến (theo BLoC)

```
lib/
├── app/                        # App/Core
│   ├── constants/              # Hằng số (enum vai trò, story point scale...)
│   ├── theme/                  # ThemeData, màu sắc, typography (Light/Dark)
│   ├── routes/                 # Định tuyến (go_router hoặc Navigator 2.0)
│   └── di/                     # Dependency injection (get_it, injectable...)
│
├── core/
│   └── widgets/                # ⭐ UI Kit dùng chung: Button, TextField, Card, Loading...
│                                #    (đây là "file cố định UI với btn" mà thành viên đề cập – xem mục 5)
│
├── data/
│   ├── models/                 # UserModel, ProjectModel, UserStoryModel, SprintModel, TaskModel, CommentModel, AttachmentModel...
│   ├── repositories/           # ProjectRepository, BacklogRepository, SprintRepository, TaskRepository, ReportRepository...
│   └── datasources/
│       ├── local/               # SQLite datasource (cache offline — Backlog/Task, US-062)
│       └── remote/              # REST API datasource (Render/Railway) + SocketService (Socket.io realtime, US-028) + PushService (FCM, US-029)
│
└── presentation/               # Features (mỗi feature 1 module)
    ├── auth/
    │   ├── bloc/                # AuthBloc, AuthEvent, AuthState
    │   └── screens/
    ├── project/
    │   ├── bloc/
    │   └── screens/
    ├── backlog/
    │   ├── bloc/                # bao gồm xử lý bulk-select, pagination (US-051/052/053)
    │   └── screens/
    ├── sprint/
    │   ├── bloc/                # bao gồm Sprint Review, Retrospective (US-023/024)
    │   └── screens/
    ├── taskboard/
    │   ├── bloc/                # kết nối SocketService để realtime (US-028)
    │   └── screens/
    ├── comment_attachment/      # ⭐ module dùng chung cho comment + upload file (User Story & Task – US-045/046/047)
    │   ├── bloc/
    │   └── widgets/
    ├── standup/
    │   ├── bloc/
    │   └── screens/
    ├── statistics/
    │   ├── bloc/                # Burndown, Velocity, hiệu suất thành viên (US-060), export PDF/Excel (US-027)
    │   └── screens/
    ├── task_assignment_ai/      # ⭐ module gợi ý AI + performance score (US-057/058)
    │   ├── bloc/
    │   └── screens/
    └── settings/
        ├── bloc/
        └── screens/
```

**Nguyên tắc tách biệt (README 1 – mục B.4):**
- Mỗi `screens/` **chỉ gọi BLoC** qua `context.read<XBloc>().add(...)`, tuyệt đối không gọi API/DB trực tiếp.
- Mọi logic nghiệp vụ (validate, tính Velocity, xử lý cache...) nằm trong `bloc/` hoặc `repositories/`, không nằm trong widget UI.

---

## 5. UI Kit dùng chung — trả lời yêu cầu của thành viên nhóm

Theo lựa chọn đã xác nhận, ý của thành viên **"tạo file cố định UI với btn"** và **"giao diện làm file độc lập để đồng nhất"** được hiểu là: xây một **UI Kit / Design System** riêng, tách khỏi từng màn hình, để khi cả nhóm code UI thì mọi nơi đều dùng chung 1 bộ component — tránh mỗi người tự vẽ 1 kiểu Button/Input khác nhau.

Đề xuất triển khai tại `lib/core/widgets/`:

```
core/widgets/
├── app_button.dart        # AppButton (primary, secondary, outline, loading state)
├── app_text_field.dart    # AppTextField (input chuẩn, có validate error style)
├── app_card.dart          # AppCard (dùng cho Backlog item, Task card...)
├── app_loading.dart       # Loading indicator / shimmer đồng bộ
├── app_badge.dart         # Badge trạng thái (To Do / Doing / Done, Story Point)
└── app_dialog.dart        # Dialog/BottomSheet xác nhận dùng chung
```

**Quy trình đề xuất khi dùng Stitch (qua Antigravity MCP):**
1. Dùng Stitch tạo mockup từng màn hình → xuất ra ảnh/spec (màu, spacing, border-radius, font).
2. Từ mockup, rút ra các **component lặp lại** (nút "Thêm User Story", nút "Bắt đầu Sprint", thẻ Task...) → đưa vào `core/widgets/` **một lần duy nhất**.
3. Các màn hình trong `presentation/*/screens/` chỉ **import và tái sử dụng** widget từ `core/widgets/`, không viết `ElevatedButton(...)` tay từng nơi.
4. Khi cần đổi theme (Light/Dark) hoặc đổi style toàn app, chỉ sửa tại `core/widgets/` + `app/theme/`, không phải sửa từng màn hình.

Cách này vừa đáp ứng yêu cầu README 1 mục B.3 ("Giao diện phải rõ ràng, đồng bộ theo một chủ đề"), vừa giải quyết đúng ý "làm file độc lập để đồng nhất giao diện sau" của thành viên.

---

## 6. Lưu ý tuân thủ khi dùng AI Agent

README 1 cho phép dùng AI hỗ trợ nhưng yêu cầu: *"Sinh viên phải hiểu thuật toán/logic khi sử dụng AI trong quá trình làm đồ án."* Gợi ý checklist cho nhóm:

- [ ] Mỗi thành viên đọc và giải thích được logic BLoC (Event → Bloc → State) của module mình phụ trách.
- [ ] Không copy nguyên code từ AI mà không hiểu — nếu AI sinh ra đoạn xử lý cache/timeout API, phải note lại tại sao xử lý như vậy.
- [ ] Giữ lại lịch sử prompt/agent (nếu giảng viên yêu cầu) để chứng minh quá trình làm việc.
- [ ] Review chéo giữa các thành viên trước khi merge code vào nhánh chính.

---

## 7. Việc còn cần nhóm quyết định (chưa chốt)

- [ ] Package quản lý route: `go_router` hay `Navigator` mặc định.
- [ ] Package DI (nếu dùng): `get_it`, `injectable`, hoặc không dùng DI riêng mà khởi tạo BLoC qua `MultiBlocProvider`.
- [ ] **Local Notification cho Daily Stand-up / Sprint sắp kết thúc:** Sprint Backlog hiện chỉ có US-059 (nhắc task đến hạn). Nhóm cần thêm 2 User Story mới nếu vẫn muốn giữ 2 loại nhắc này, hoặc cập nhật lại mục 2.8 nếu quyết định bỏ.
- [ ] **Thuật toán AI gợi ý (US-057/058):** dùng model AI thật hay chỉ là công thức tính điểm (rule-based) như đã cho trong US-058? Cần chốt trước khi phân công code, vì ảnh hưởng đến việc có cần gọi API AI ngoài hay không.
- [ ] **Push Notification (US-029):** xác nhận dùng Firebase Cloud Messaging (FCM) làm dịch vụ đẩy tin, dù backend chính không phải Firebase — cần đăng ký Firebase Project riêng chỉ cho mục đích FCM.
- [ ] **Socket.io (US-028):** đây là mục "bonus" — xác nhận có đưa vào phạm vi nộp bài chính hay để làm sau nếu còn thời gian, vì ảnh hưởng đến kiến trúc `remote/` (cần thêm socket server ở backend).
