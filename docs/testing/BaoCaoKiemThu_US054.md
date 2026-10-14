# Báo cáo kiểm thử ScrumFlow — US-054 (5 Sprint)

> Ngày chạy kiểm thử: **14/10/2026** · Máy: Windows 11, Flutter 3.47.5 / Dart 3.13.4
> File đi kèm: [`test_cases.csv`](test_cases.csv), mở được bằng Excel hoặc Google Sheets (UTF-8 có BOM).

## 1. Tóm tắt

| Hạng mục | Kết quả thực tế |
|---|---|
| `flutter test` (unit + widget) | **286 / 286 PASS**, 0 fail (trước phiên này: 194 / 194) |
| `flutter analyze` | **0 error, 0 warning**, 46 info đều có từ trước (giảm từ 51, không thêm issue mới) |
| `flutter build web` | **Thành công** |
| `flutter build apk --debug` | **Thành công** (`build/app/outputs/flutter-apk/app-debug.apk`, Gradle 459.7s). Chưa cài lên thiết bị |
| Integration test trên thiết bị | **NOT RUN**: không có thiết bị/emulator Android và chưa có Firebase test project (xem mục 5) |
| Test Case trong bảng | 72 TC: **48 PASS** (đã chạy tự động), **22 NOT RUN**, **2 BLOCKED** |

Phân bố theo Sprint:

| Sprint | PASS | NOT RUN | BLOCKED | Tổng |
|---|---|---|---|---|
| 1. Tài khoản, Project, Phân quyền | 10 | 5 | 1 | 16 |
| 2. Product Backlog & Sprint Planning | 10 | 4 | 0 | 14 |
| 3. Task Board & Cộng tác | 7 | 4 | 1 | 12 |
| 4. Đóng/Mở Sprint & Báo cáo | 5 | 3 | 0 | 8 |
| 5. Hoàn thiện, Mạng, Responsive | 16 | 6 | 0 | 22 |

> **Lưu ý:** chưa thể khẳng định cả 5 Sprint đã được kiểm thử đầy đủ. Mọi TC có trạng thái **PASS** đều do test tự động đã thực sự chạy trong phiên này. Các luồng chỉ kiểm thử được trên thiết bị thật hoặc với Firebase thật được ghi **NOT RUN/BLOCKED** kèm lý do, chưa được xác nhận.

## 2. Kiểm kê chức năng theo mã nguồn

Đối chiếu bảng Sprint Backlog trong `NguCanh.md` với mã nguồn thực tế:

- **Đã có trong code và có test tự động:** phân quyền (US-004), Project (US-036/037), Backlog: tìm/lọc/sắp xếp/tạo/xoá/tag (US-005→014), Sprint list (US-015), Task: assignee/deadline (US-043/044), Comment (US-045/046), Attachment (US-047), Performance score (US-057/058), trạng thái Story (US-048), Burndown (US-025), xử lý mạng/timeout (US-063), chuyển trang/loading (US-064), responsive (US-055).
- **Đã có trong code nhưng chưa có test tự động** (kiểm thử thủ công): Đăng ký/Đăng nhập/Đăng xuất thao tác UI, sinh trắc học (US-056), thêm/xoá thành viên (US-039/041), sửa Story (US-011/013), tạo/chi tiết Sprint (US-016/017/018), thao tác hàng loạt (US-053), Task Board kéo-thả (US-019→021), Stand-up (US-022/033), thông báo (US-029/059), Start/Close Sprint (US-049/050), giao diện Review/Retro/Hiệu suất (US-023/024/060).
- **Chưa triển khai:** US-030 (dark mode), US-038 (xoá Project trên UI), US-062 (cache SQLite Backlog/Task). Các TC của những US này để **NOT RUN**.

## 3. Danh sách Test Case

Cột **Loại**: `AUTO` là đã tự động hoá và chạy thật; `MANUAL` là kiểm thử thủ công theo checklist ở mục 6. Đủ các cột (tiền đề, dữ liệu, các bước, kết quả thực tế) có trong `test_cases.csv`.

### Sprint 1

| ID | US | Chức năng | Mục tiêu | Kết quả mong đợi | Loại | Trạng thái | Ghi chú |
|---|---|---|---|---|---|---|---|
| TC-S1-01 | US-001 | Đăng ký | Đăng ký bằng email/mật khẩu hợp lệ | Tạo tài khoản, chuyển vào Trang chủ | MANUAL | **NOT RUN** | Cần Firebase thật; chưa thực hiện trong phiên này |
| TC-S1-02 | US-001 | Đăng ký | Mật khẩu yếu bị chặn bởi checklist | Checklist chưa đạt, nút Đăng ký bị vô hiệu | MANUAL | **NOT RUN** |  |
| TC-S1-03 | US-001 | Đăng ký | Email đã tồn tại → thông báo tiếng Việt | Thông báo "Email này đã được sử dụng..." | AUTO | **PASS** | `test/app/constants/firebase_error_mapper_test.dart` |
| TC-S1-04 | US-002 | Đăng nhập | Đăng nhập đúng thông tin | Vào Trang chủ, hiện tên người dùng | MANUAL | **NOT RUN** |  |
| TC-S1-05 | US-002 | Đăng nhập | Sai mật khẩu / thông tin không hợp lệ | Thông báo tiếng Việt tương ứng, không lộ mã | AUTO | **PASS** | `test/app/constants/firebase_error_mapper_test.dart` |
| TC-S1-06 | US-002 | Đăng nhập | Đăng nhập khi mất mạng | Báo lỗi kết nối mạng, không crash | AUTO | **PASS** | `firebase_error_mapper_test.dart; app_error_handler_test.dart` — Bản thao tác tay trên thiết bị: NOT RUN |
| TC-S1-07 | US-003 | Đăng xuất | Đăng xuất từ hộp thoại Cài đặt | Quay về Đăng nhập; Back không vào lại Home | MANUAL | **NOT RUN** |  |
| TC-S1-08 | US-056 | Sinh trắc học | Mở khoá bằng vân tay sau lần đăng nhập đầu | Đăng nhập thành công bằng vân tay | MANUAL | **BLOCKED** | Không có thiết bị Android có vân tay trong phiên này; Web không hỗ trợ |
| TC-S1-09 | US-004 | Phân quyền | Ma trận quyền PO/SM/MEMBER đúng thiết kế | Chỉ role được cấp mới có quyền; role null/không hợp lệ không có quyền | AUTO | **PASS** | `test/app/authorization/role_permissions_test.dart` |
| TC-S1-10 | US-004/US-040 | Phân quyền | PO không tự đổi role của chính mình | Báo lỗi, role không đổi | AUTO | **PASS** | `test/presentation/project_members/project_members_bloc_test.dart` |
| TC-S1-11 | US-036 | Tạo Project | Tạo project → người tạo tự thành PO; lỗi thì rollback | Thành công: user là PO. Lỗi: project bị xoá | AUTO | **PASS** | `test/data/repositories/project_repository_impl_test.dart` |
| TC-S1-12 | US-037 | Sửa Project | Chỉ PO sửa được thông tin project | PO thành công; MEMBER/người ngoài bị từ chối | AUTO | **PASS** | `test/data/repositories/project_repository_impl_test.dart` |
| TC-S1-13 | US-039 | Thêm thành viên | PO thêm thành viên theo email | Thành viên xuất hiện real-time | MANUAL | **NOT RUN** |  |
| TC-S1-14 | US-040 | Thành viên | MEMBER không được xem trang quản lý thành viên | Hiện màn "không có quyền" | AUTO | **PASS** | `test/presentation/project_members/project_members_bloc_test.dart` |
| TC-S1-15 | US-005 | Product Backlog | Danh sách story cập nhật real-time | Danh sách cập nhật, giữ filter/sort | AUTO | **PASS** | `test/presentation/backlog/backlog_bloc_test.dart` |
| TC-S1-16 | US-006 | Chi tiết Story | Đọc được dữ liệu cũ thiếu tags/deadline | Không crash; tags=[] và deadline=null | AUTO | **PASS** | `test/data/models/user_story_model_test.dart` |

### Sprint 2

| ID | US | Chức năng | Mục tiêu | Kết quả mong đợi | Loại | Trạng thái | Ghi chú |
|---|---|---|---|---|---|---|---|
| TC-S2-01 | US-007 | Tìm kiếm | Tìm theo tiêu đề / mã / mô tả / tag, không phân biệt hoa thường | Chỉ hiện story khớp | AUTO | **PASS** | `test/presentation/backlog/backlog_search_filter_test.dart` |
| TC-S2-02 | US-008 | Bộ lọc | Lọc kết hợp trạng thái + ưu tiên + tag; Đặt lại | Kết quả đúng; Đặt lại về mặc định | AUTO | **PASS** | `test/presentation/backlog/backlog_search_filter_test.dart` |
| TC-S2-03 | US-009 | Sắp xếp | Sort ưu tiên CAO→TB→THẤP, deadline gần nhất, null xếp cuối | Thứ tự đúng, ổn định, không mất story | AUTO | **PASS** | `test/presentation/backlog/backlog_view_test.dart` |
| TC-S2-04 | US-010 | Tạo Story | Tạo story hợp lệ, bấm liên tục chỉ tạo 1 lần | Chỉ 1 request, dialog đóng | AUTO | **PASS** | `test/presentation/backlog/create_user_story_cubit_test.dart` |
| TC-S2-05 | US-010 | Tạo Story | Dữ liệu không hợp lệ bị từ chối | Báo lỗi tại form, không gọi Firestore | AUTO | **PASS** | `test/presentation/backlog/create_user_story_cubit_test.dart` |
| TC-S2-06 | US-010 | Phân quyền Backlog | MEMBER không tạo được story; lỗi Firebase/timeout được ánh xạ | Bị từ chối với thông báo rõ ràng | AUTO | **PASS** | `test/data/repositories/backlog_repository_impl_test.dart` |
| TC-S2-07 | US-011/US-013 | Sửa Story + Story Points | Sửa tiêu đề, ưu tiên, điểm Fibonacci | Dữ liệu cập nhật real-time | MANUAL | **NOT RUN** | Chưa có test tự động cho EditUserStoryCubit |
| TC-S2-08 | US-012 | Xoá Story | Xoá có xác nhận, chống bấm lặp | Chỉ 1 lần xoá | AUTO | **PASS** | `test/presentation/backlog/delete_user_story_cubit_test.dart` |
| TC-S2-09 | US-014 | Tag | Tag rỗng / trùng (không phân biệt hoa thường) / >30 ký tự / >10 tag | Báo lỗi đúng từng trường hợp; lưu không đè field khác | AUTO | **PASS** | `test/presentation/backlog/story_tags_cubit_test.dart` |
| TC-S2-10 | US-015 | Danh sách Sprint | Tải danh sách Sprint; mất mạng/timeout có trạng thái lỗi riêng | SprintLoadFailure kèm "Thử lại" | AUTO | **PASS** | `test/presentation/sprints/sprint_network_test.dart` |
| TC-S2-11 | US-016 | Tạo Sprint | Ngày kết thúc phải sau ngày bắt đầu | Báo lỗi, không tạo | MANUAL | **NOT RUN** |  |
| TC-S2-12 | US-016 | Tạo Sprint | Tạo thất bại không làm mất danh sách đang hiển thị | SnackBar lỗi; danh sách giữ nguyên | AUTO | **PASS** | `test/presentation/sprints/sprint_network_test.dart` — Phát hiện & sửa BUG-05 |
| TC-S2-13 | US-017 | Chi tiết Sprint | Xem mục tiêu, ngày, story trong Sprint | Hiển thị đúng; lỗi tải có "Thử lại" | MANUAL | **NOT RUN** |  |
| TC-S2-14 | US-018 | Thêm story vào Sprint | Chọn nhiều story từ Backlog vào Sprint | storyIds cập nhật 1 lần (batch) | MANUAL | **NOT RUN** |  |

### Sprint 3

| ID | US | Chức năng | Mục tiêu | Kết quả mong đợi | Loại | Trạng thái | Ghi chú |
|---|---|---|---|---|---|---|---|
| TC-S3-01 | US-053 | Thao tác hàng loạt | Chọn nhiều story → chuyển Sprint / xoá hàng loạt | Áp dụng đúng các story đã chọn | MANUAL | **NOT RUN** |  |
| TC-S3-02 | US-051/US-052 | Phân trang / hàng gọn | Hàng gọn hiển thị không tràn, phân trang hoạt động | Không tràn layout; nút trang ≥40px | AUTO | **PASS** | `test/responsive/responsive_screens_test.dart` — Phần chuyển trang thao tác tay: NOT RUN |
| TC-S3-03 | US-019/020/021 | Task Board | Tạo task, kéo-thả đổi trạng thái | Trạng thái cập nhật | MANUAL | **NOT RUN** |  |
| TC-S3-04 | US-022/US-033 | Daily Stand-up | Ghi 3 câu hỏi và xem lịch sử | Bản ghi xuất hiện đúng ngày | MANUAL | **NOT RUN** |  |
| TC-S3-05 | US-043 | Đổi người phụ trách | Đổi assignee theo quyền; không chọn người ngoài project | Chỉ cập nhật 3 field assignee; người ngoài bị từ chối | AUTO | **PASS** | `test/presentation/tasks/task_detail_cubit_test.dart` |
| TC-S3-06 | US-044 | Deadline Task | Đặt/đổi/xoá deadline; từ chối ngày quá khứ | Ngày quá khứ bị từ chối | AUTO | **PASS** | `test/presentation/tasks/task_detail_cubit_test.dart; test/data/models/task_model_test.dart` |
| TC-S3-07 | US-045 | Bình luận Story | Comment rỗng/toàn khoảng trắng/>1000 ký tự bị từ chối | Báo lỗi; author luôn là user đăng nhập | AUTO | **PASS** | `test/presentation/comments/comments_cubit_test.dart; comment_repository_impl_test.dart` |
| TC-S3-08 | US-046 | Bình luận Task | Comment task không lẫn sang story | Lưu đúng collection tasks/{id}/comments | AUTO | **PASS** | `test/data/repositories/comment_repository_impl_test.dart` |
| TC-S3-09 | US-029 | Thông báo | Người phụ trách nhận thông báo khi có bình luận mới | B thấy thông báo, badge tăng | MANUAL | **NOT RUN** |  |
| TC-S3-10 | US-047 | Đính kèm | Thêm liên kết / xoá tệp; người ngoài project bị chặn | Thành công với thành viên; người ngoài bị từ chối | AUTO | **PASS** | `attachment_repository_impl_test.dart; attachments_cubit_test.dart; attachment_model_test.dart` |
| TC-S3-11 | US-057/US-058 | Điểm hiệu suất & gợi ý | Tính score theo công thức 0.5/0.3/0.2, xếp hạng | Score và thứ tự đúng | AUTO | **PASS** | `performance_score_service_test.dart; performance_score_model_test.dart` |
| TC-S3-12 | US-059 | Nhắc deadline | Local notification trước hạn 1 ngày | Hiện thông báo heads-up | MANUAL | **BLOCKED** | Cần thiết bị Android; Web không hỗ trợ local notification |

### Sprint 4

| ID | US | Chức năng | Mục tiêu | Kết quả mong đợi | Loại | Trạng thái | Ghi chú |
|---|---|---|---|---|---|---|---|
| TC-S4-01 | US-048 | Trạng thái Story | PO/SM đổi trạng thái; MEMBER/người ngoài/chưa đăng nhập bị chặn | Đúng quyền; thông báo "Chỉ PO/SM..." | AUTO | **PASS** | `story_repository_impl_test.dart; update_story_status_usecase_test.dart; change_status_dialog_test.dart` |
| TC-S4-02 | US-048 | Trạng thái Story | Done/Rejected đặt completedAt; quay lại thì xoá | completedAt đúng | AUTO | **PASS** | `test/data/repositories/story_repository_impl_test.dart` |
| TC-S4-03 | US-049 | Bắt đầu Sprint | Chỉ PO/SM; chỉ 1 Sprint Active; Sprint phải có ≥1 story | Báo lỗi đúng ràng buộc | MANUAL | **NOT RUN** | Chưa có test tự động cho StartSprintUseCase/SprintRepositoryImpl.startSprint |
| TC-S4-04 | US-050 | Đóng Sprint | Story chưa xong chuyển về Backlog / Sprint kế (batch atomic) | Sprint Completed; story chuyển đúng đích | MANUAL | **NOT RUN** | Chưa có test tự động cho closeSprint |
| TC-S4-05 | US-025 | Burndown | Dữ liệu đường lý tưởng/thực tế đúng | Giá trị đúng | AUTO | **PASS** | `test/presentation/sprints/burndown_data_test.dart` |
| TC-S4-06 | US-023 | Sprint Review | Lưu/đọc biên bản review | Dữ liệu khứ hồi đúng | AUTO | **PASS** | `test/data/models/sprint_review_model_test.dart` — Chỉ model; UI dialog: NOT RUN |
| TC-S4-07 | US-024 | Retrospective | Lưu/đọc ý kiến retro | Dữ liệu khứ hồi đúng | AUTO | **PASS** | `test/data/models/sprint_retro_item_model_test.dart` — Chỉ model; UI 3 cột + vote: NOT RUN |
| TC-S4-08 | US-060 | Hiệu suất đội | KPI toàn đội và thẻ thành viên | Số liệu khớp PerformanceScoreService | MANUAL | **NOT RUN** | Logic tính điểm đã có test tự động (TC-S3-11) |

### Sprint 5

| ID | US | Chức năng | Mục tiêu | Kết quả mong đợi | Loại | Trạng thái | Ghi chú |
|---|---|---|---|---|---|---|---|
| TC-S5-01 | US-063 | Mất mạng | Tải danh sách Project khi không có mạng | Lỗi "Mất kết nối mạng" + "Thử lại"; KHÔNG gọi Firestore | AUTO | **PASS** | `test/presentation/projects/project_list_bloc_test.dart` |
| TC-S5-02 | US-063 | Timeout | Request / stream không phản hồi trong thời hạn | Lỗi "Hết thời gian chờ"; loading kết thúc | AUTO | **PASS** | `project_list_bloc_test; backlog_network_test; sprint_network_test; project_members_network_test` |
| TC-S5-03 | US-063 | Thử lại | Mạng có lại → bấm "Thử lại" tải thành công | Hiện dữ liệu; lỗi biến mất | AUTO | **PASS** | `project_list_bloc_test; test/presentation/backlog/backlog_retry_flow_test.dart` |
| TC-S5-04 | US-063 | Lỗi máy chủ | Lỗi Firebase (unavailable/internal) không làm crash, không lộ mã | Thông báo tiếng Việt, không chứa "cloud_firestore" | AUTO | **PASS** | `app_error_handler_test; project_list_bloc_test; backlog_network_test` |
| TC-S5-05 | US-063 | Chống trùng request | Bấm "Thử lại"/kéo refresh liên tục | Chỉ 1 request / 1 listener đang mở | AUTO | **PASS** | `project_list_bloc_test; backlog_network_test; project_members_network_test; event_transformers_test` — Phát hiện & sửa BUG-02 |
| TC-S5-06 | US-063 | Nút Thử lại | Nút khoá sau lần bấm đầu, mở lại khi có lỗi mới | Callback chạy 1 lần | AUTO | **PASS** | `test/presentation/common/common_widgets_test.dart` |
| TC-S5-07 | US-063 | Lỗi không thể thử lại | Lỗi quyền/không phải thành viên không hiện "Thử lại" | Ẩn nút "Thử lại" | AUTO | **PASS** | `common_widgets_test; project_members_network_test; app_error_handler_test` |
| TC-S5-08 | US-063 | Banner mạng | Dải cảnh báo khi mất mạng; "Đã kết nối lại" rồi tự ẩn | Banner hiện/ẩn đúng | AUTO | **PASS** | `test/presentation/common/common_widgets_test.dart` |
| TC-S5-09 | US-063 | Mất mạng thật | Bật chế độ máy bay trên Android rồi mở Backlog, tắt lại → Thử lại | Banner + màn lỗi; Thử lại thành công | MANUAL | **NOT RUN** | Chưa có thiết bị Android trong phiên này |
| TC-S5-10 | US-064 | Chuyển trang | MaterialPageRoute & named route dùng chung fade+slide; Back đúng | Có hiệu ứng; quay lại đúng trang | AUTO | **PASS** | `test/app/routes/page_transitions_test.dart` |
| TC-S5-11 | US-064 | Giảm chuyển động | Bật disableAnimations → chuyển trang tức thì, skeleton đứng yên | Không có animation | AUTO | **PASS** | `page_transitions_test; common_widgets_test` |
| TC-S5-12 | US-064 | Loading | Skeleton khi tải; biến mất khi lỗi hoặc thành công | Skeleton → lỗi → dữ liệu | AUTO | **PASS** | `test/presentation/backlog/backlog_retry_flow_test.dart` |
| TC-S5-13 | US-064 | Tham số route | Route cần projectId nhưng thiếu arguments | Về Login, không crash; settings được giữ nguyên | AUTO | **PASS** | `test/app/routes/page_transitions_test.dart` |
| TC-S5-14 | US-055 | Responsive màn hình | Login, Đăng ký, Backlog, Sprint, Thành viên, màn lỗi không tràn | Không có RenderFlex overflow | AUTO | **PASS** | `test/responsive/responsive_screens_test.dart` — Phát hiện & sửa BUG-06, BUG-07 |
| TC-S5-15 | US-055 | Responsive dialog | Tạo Story/Tạo Sprint/Bắt đầu Sprint/Thêm thành viên khi bàn phím mở | Không tràn, cuộn được tới nút xác nhận | AUTO | **PASS** | `test/responsive/responsive_dialogs_test.dart` |
| TC-S5-16 | US-055 | Responsive thiết bị thật | Kiểm tra trên điện thoại nhỏ & lớn, xoay ngang | Không tràn, thao tác đủ | MANUAL | **NOT RUN** | ProjectDetail/Home/TaskBoard chưa có test tự động (phụ thuộc FirebaseAuth/NotificationService) |
| TC-S5-17 | US-041 | Xoá thành viên | PO xoá thành viên khỏi project | Thành viên biến mất; người bị xoá mất quyền | MANUAL | **NOT RUN** |  |
| TC-S5-18 | US-031 | Build | Build web bản release | Build thành công | AUTO | **PASS** | `flutter build web` — Build thành công, 120.6s (build/web) |
| TC-S5-19 | US-054 | Chất lượng mã | flutter analyze không có error/warning | 0 error, 0 warning | AUTO | **PASS** | `flutter analyze` — 46 info có sẵn từ trước, không thêm issue mới |
| TC-S5-20 | US-030 | Dark mode | Giao diện tối | - | MANUAL | **NOT RUN** | Chức năng CHƯA triển khai |
| TC-S5-21 | US-038 | Xoá Project | PO xoá project | - | MANUAL | **NOT RUN** | Chức năng CHƯA triển khai trên UI |
| TC-S5-22 | US-062 | Cache offline SQLite | Xem Backlog/Task khi mất mạng | - | MANUAL | **NOT RUN** | Chức năng CHƯA triển khai (chỉ cache UserModel) |

## 4. Hướng dẫn chạy test

```powershell
flutter pub get
flutter analyze                       # kỳ vọng: 0 error, 0 warning
flutter test                          # toàn bộ unit + widget test
flutter test test/responsive          # chỉ kiểm thử responsive (US-055)
flutter test test/app/errors test/presentation/projects test/presentation/backlog/backlog_network_test.dart   # US-063
flutter test test/app/routes test/presentation/common                                                          # US-064
flutter test --reporter json > test-report.json                                                                # xuất báo cáo máy đọc được
```

- Test **không** gọi Firebase production: mọi Repository/Firebase được thay bằng mock (`mocktail`). Không cần tài khoản, token hay API key.
- `test/helpers/test_setup.dart` tắt việc `google_fonts` tải font qua mạng. Chữ trong widget test hiển thị bằng font test của Flutter. Font này **rộng hơn** Plus Jakarta Sans thật nên test responsive khắt khe hơn thực tế.
- Test timeout dùng thời hạn rút ngắn (30–40 ms) qua tham số `timeout` / `firstLoadTimeout`. Ứng dụng thật dùng 15 giây.

## 5. Kết quả thực tế & các hạng mục chưa chạy

### Đã chạy
- `flutter test`: 286 test / 46 file, **tất cả PASS**. Phần mới thêm trong phiên này gồm 92 test / 13 file:

| File test | Số test | Nội dung |
|---|---|---|
| `test/app/errors/app_error_handler_test.dart` | 17 | Phân loại lỗi mạng/timeout/server/quyền/xác thực, không lộ mã kỹ thuật |
| `test/app/errors/stream_timeout_test.dart` | 5 | Timeout lần phát đầu, tự hồi phục, huỷ subscription |
| `test/app/services/connectivity_service_test.dart` | 5 | Có/không mạng, plugin lỗi, stream thay đổi trạng thái |
| `test/app/utils/event_transformers_test.dart` | 1 | `restartable()` huỷ subscription cũ |
| `test/app/routes/page_transitions_test.dart` | 5 | Hiệu ứng chuyển trang, Back, giảm chuyển động, tham số route |
| `test/presentation/projects/project_list_bloc_test.dart` | 6 | Mất mạng, timeout, lỗi server, thử lại, chống request trùng |
| `test/presentation/backlog/backlog_network_test.dart` | 7 | Như trên cho Backlog + giữ dữ liệu khi lỗi tạm thời |
| `test/presentation/backlog/backlog_retry_flow_test.dart` | 1 | Luồng UI: skeleton → lỗi → "Thử lại" → dữ liệu |
| `test/presentation/sprints/sprint_network_test.dart` | 3 | Lỗi tải Sprint; lỗi thao tác không làm mất danh sách |
| `test/presentation/project_members/project_members_network_test.dart` | 4 | Lỗi mạng/timeout/quyền; thử lại không trùng listener |
| `test/presentation/common/common_widgets_test.dart` | 10 | AppErrorView/EmptyView/LoadingView, Skeleton, banner mạng |
| `test/responsive/responsive_screens_test.dart` | 24 | 6 màn × 2 kích thước × 2 cỡ chữ |
| `test/responsive/responsive_dialogs_test.dart` | 4 | 4 dialog khi bàn phím mở, chữ ×1.3 |
| 33 file test có sẵn từ trước | 194 | Không sửa, vẫn PASS |

### Chưa chạy (NOT RUN / BLOCKED) và lý do
| Hạng mục | Lý do |
|---|---|
| Integration test (`integration_test`) | Phiên làm việc không có emulator/thiết bị Android (`flutter devices` chỉ thấy Chrome/Edge). Chưa có Firebase project riêng cho kiểm thử, và yêu cầu không được ghi/xoá dữ liệu thật. **Chưa thêm** package `integration_test`. |
| TC thao tác tay trên Firebase thật (đăng ký, đăng nhập, thêm thành viên, Start/Close Sprint…) | Cần tài khoản và dữ liệu Firebase thật. Chưa thực hiện trong phiên này. |
| Sinh trắc học (TC-S1-08), Local notification (TC-S3-12) | **BLOCKED**: cần thiết bị Android thật, Web không hỗ trợ. |
| `ProjectDetailScreen`, `HomeScreen`, `TaskBoard` trong test responsive | Các màn này gọi trực tiếp `FirebaseAuth.instance` / `NotificationService()` nên không dựng được trong widget test nếu không khởi tạo Firebase. Cần kiểm tra tay (TC-S5-16). |
| US-030, US-038, US-062 | Chức năng chưa được triển khai. |

## 6. Checklist kiểm thử thủ công trên Android

Chuẩn bị: `flutter run` trên điện thoại hoặc emulator; dùng tài khoản thử nghiệm trong `NguCanh.md` mục 1.

**US-063: Mất mạng / timeout**
1. Mở app, đăng nhập. Bật **Chế độ máy bay**. Dải cam "Không có kết nối mạng…" phải hiện trên đầu màn hình.
2. Kéo để làm mới Trang chủ. Màn "Mất kết nối mạng" hiện kèm nút **Thử lại**, không có vòng loading vô tận.
3. Vào Product Backlog / Sprint / Thành viên khi vẫn đang offline. Mỗi màn hiện màn lỗi tương ứng, không crash.
4. Bấm **Thử lại** nhanh nhiều lần. Nút chuyển sang "Đang thử lại…" và chỉ gửi 1 yêu cầu.
5. Tắt chế độ máy bay. Dải xanh "Đã kết nối lại." hiện khoảng 3 giây. Bấm **Thử lại**: dữ liệu tải thành công.
6. Bật Wi-Fi nhưng chặn Internet (ví dụ Wi-Fi không có mạng). Sau khoảng 15 giây hiện "Hết thời gian chờ", bấm Thử lại được.

**US-064: Chuyển trang & loading**
1. Mở Project → Backlog → Story → Back liên tục: hiệu ứng mờ dần và trượt nhẹ đồng nhất, Back về đúng màn trước.
2. Cài đặt Android → Hỗ trợ tiếp cận → **Xoá hiệu ứng động** → mở lại app: chuyển trang tức thì, skeleton đứng yên.
3. Khi mở Trang chủ/Backlog/Sprint lần đầu: hiện khung skeleton, sau đó là dữ liệu hoặc màn lỗi (không giữ skeleton mãi).
4. Tạo User Story và bấm "Tạo User Story" nhiều lần: chỉ tạo 1 story, nút hiện vòng loading.

**US-055: Responsive**
1. Cài đặt → Hiển thị → **Cỡ chữ lớn nhất**. Đi qua Đăng nhập, Đăng ký, Trang chủ, Chi tiết Project, Backlog (cả 2 chế độ hiển thị), Sprint, Thành viên, Task Board: không có vạch sọc vàng-đen (overflow), chữ không bị cắt mất nội dung chính.
2. Mở các dialog Tạo Story / Tạo Sprint / Thêm thành viên rồi chạm vào ô nhập: bàn phím không che nút xác nhận, dialog cuộn được.
3. Thử trên một điện thoại nhỏ (≤ 5,5") và một máy lớn; xoay ngang màn hình ở Backlog và Sprint.

Ghi kết quả vào cột *Kết quả thực tế* / *Trạng thái* của `test_cases.csv`.

## 7. Danh sách bug

### Bug phát hiện và đã sửa trong phiên này
| Mã | Mức độ | Nguồn | Mô tả | Trạng thái |
|---|---|---|---|---|
| BUG-01 | Cao | Có sẵn | `BacklogDataSource`/`SprintDataSource` nuốt lỗi stream và phát danh sách rỗng, nên khi mất mạng người dùng thấy "Backlog trống"/"Chưa có Sprint" thay vì thông báo lỗi. | Đã sửa |
| BUG-02 | Cao | Có sẵn | Mỗi lần subscribe tạo thêm một listener Firestore mà không huỷ listener cũ, gây request trùng lặp và rò rỉ khi mở lại màn hình hoặc bấm thử lại. | Đã sửa (1 listener/project, huỷ khi không còn người nghe; Bloc dùng `restartable()`) |
| BUG-03 | TB | Có sẵn | Thông báo lỗi ghép `'$error'` làm lộ mã kỹ thuật `[cloud_firestore/unavailable] …` cho người dùng. | Đã sửa ở Trang chủ, Backlog, Sprint, Thành viên |
| BUG-04 | TB | Có sẵn | Chi tiết Project: lỗi mạng bị hiển thị thành "Project không tồn tại", và stream bị tạo lại mỗi lần rebuild. | Đã sửa |
| BUG-05 | TB | Có sẵn | `SprintActionCompleted`/`SprintError` phát kèm danh sách rỗng nên sau mỗi thao tác màn Sprint có thể nháy "Chưa có Sprint nào". | Đã sửa |
| BUG-06 | TB | Có sẵn | Tràn layout (RenderFlex overflow) ở Đăng nhập, Đăng ký, checklist mật khẩu, Backlog (KPI, phân trang, sắp xếp, hàng gọn), Sprint, Thành viên và 4 dialog trên màn hẹp, chữ lớn hoặc khi bàn phím mở. | Đã sửa |
| BUG-07 | Thấp | Có sẵn | Nút chuyển trang Backlog chỉ khoảng 24 px nên khó bấm trên điện thoại. | Đã sửa (40 px) |
| BUG-08 | Thấp | Có sẵn | "Nạp dữ liệu mẫu" dùng `BuildContext` sau `await` và không có timeout/xử lý lỗi. | Đã sửa |
| BUG-09 | TB | Phát sinh khi làm | `PlatformException` mất mạng của Google Sign-In (`network_error`, `ApiException: 7`) bị phân loại thành lỗi máy chủ. Test tự động đã phát hiện lỗi này. | Đã sửa |
| BUG-10 | TB | Phát sinh khi làm | Stream kết thúc trước khi phát dữ liệu khiến state kẹt ở loading. Test tự động đã phát hiện lỗi này. | Đã sửa |

### Lỗi / hạn chế còn tồn đọng
| Mã | Mô tả | Ghi chú |
|---|---|---|
| OPEN-01 | Google Sign-In trên **Web** báo `ClientID not set`. | Có sẵn. Cần thêm `<meta name="google-signin-client_id">` (Web client ID của Firebase) vào `web/index.html`. |
| OPEN-02 | Thiếu file `assets/icons/google.png` (404 trên Web). | Có sẵn. Cần bổ sung asset và khai báo trong `pubspec.yaml`. |
| OPEN-03 | Task Board, Stand-up, Thông báo, Hiệu suất, Retro vẫn xử lý loading/lỗi theo cách cũ (chưa dùng `AppErrorView`/timeout). | Ngoài phạm vi các màn ưu tiên của phiên này. |
| OPEN-04 | Màn hình gọi trực tiếp `FirebaseAuth.instance` (chuông thông báo) nên không widget-test được. | Đề xuất inject qua Repository. |
| OPEN-05 | Chưa có integration test. | Xem mục 5. |
| OPEN-06 | 46 info của `flutter analyze` (`avoid_print`, `use_build_context_synchronously`, API deprecated…). | Có sẵn, không ảnh hưởng chức năng. |
| OPEN-07 | `storyKey` sinh phía client có thể trùng khi 2 người tạo cùng lúc. | Đã biết từ Sprint 2. |
