# DANH SÁCH KIỂM THỬ THỦ CÔNG TRÊN THIẾT BỊ ANDROID (MANUAL_CHECKLIST.md)

> **Mục đích:** Hướng dẫn kiểm thử thủ công 12 bước trên thiết bị Android thật hoặc máy ảo Android cho 3 User Story mới của Sprint 5 (**US-069**, **US-070**, **US-071**).
> **Trạng thái thực thi bởi AI Agent:** `NOT RUN` trên thiết bị vật lý (Agent chỉ chạy kiểm thử tự động `flutter test` đạt `PASS`).

---

## Tài khoản kiểm thử chuẩn trong hệ thống
| Vai trò Scrum | Họ tên hiển thị | Quyền AI dự kiến |
|---|---|---|
| **Product Owner (PO)** | **Lê Phúc** | Có `viewAiInsights` & `manageAiModel` (Xem đầy đủ AI Risk Radar, Sprint Forecast, AI Model Lab) |
| **Scrum Master (SM)** | **Nguyễn Hiếu** | Có `viewAiInsights` & `manageAiModel` (Xem đầy đủ AI Risk Radar, Sprint Forecast, AI Model Lab) |
| **Developer / QA (Member)** | **Trần Thúy (QA)**, **Phạm Duy (Dev)** | **Không** có `viewAiInsights` & `manageAiModel` (Ẩn toàn bộ badge/card/lab AI để tránh áp lực giám sát) |

---

## Quy trình 12 bước kiểm thử trên Android

1. **Bước 1 — Đăng nhập tài khoản PO (`Lê Phúc`) và mở Project:**
   - Mở ứng dụng ScrumFlow trên Android, đăng nhập bằng tài khoản **Lê Phúc (PO)**, chọn dự án đang hoạt động để vào `ProjectDetailScreen`.
   - **Kỳ vọng:** Cuộn xuống mục **"Công cụ Kiểm thử Nhanh (Lab)"**, thấy đủ 3 thẻ Bento: **`AI Model Lab (US-071)`**, **`Nạp Dữ Liệu Mẫu Kiểm Thử`**, và **`Nạp Dữ Liệu Demo AI`**.

2. **Bước 2 — Kích hoạt "Nạp Dữ Liệu Demo AI":**
   - Bấm vào thẻ **`Nạp Dữ Liệu Demo AI`** → đọc hộp thoại xác nhận → bấm **`Nạp Demo AI`**.
   - **Kỳ vọng:** Hiển thị SnackBar màu xanh xác nhận đã tạo **2 Sprint đóng (`Completed`), 1 Sprint đang chạy (`Active`), 8 User Stories và 12 Tasks** phân bổ đủ 3 mức rủi ro (Cao / Trung bình / Thấp) cùng các Task `Done` lịch sử.

3. **Bước 3 — Kiểm tra AI Model Lab (`US-071`) lần đầu:**
   - Từ `ProjectDetailScreen`, bấm vào thẻ **`AI Model Lab (US-071)`**.
   - **Kỳ vọng:** Màn hình hiển thị thẻ **Nguồn dữ liệu huấn luyện** (số mẫu `synthetic` = 800, số mẫu `real` trích xuất từ các Task `Done` có `deadline`, banner cảnh báo nếu `< 10` mẫu `real`, và ghi chú giả định checkpoint `50%` chống rò rỉ nhãn).

4. **Bước 4 — Huấn luyện lại mô hình & quan sát Loss Curve (`US-071`):**
   - Trong `ModelLabScreen`, bấm nút **`Huấn luyện lại mô hình`**.
   - **Kỳ vọng:** Thanh tiến trình epoch chạy mượt mà, đồ thị **BCE Loss Curve** (`CustomPainter`) vẽ đường mất mát giảm dần theo epoch, không gây đơ giao diện.

5. **Bước 5 — Đối chiếu bảng Metrics, Confusion Matrix 2×2 & So sánh Baseline (`US-071`):**
   - Cuộn xuống xem **Ma trận nhầm lẫn 2×2** (`TP`, `FP`, `FN`, `TN`), các chỉ số `Accuracy`, `Precision`, `Recall`, `F1-Score`, `ROC-AUC`, `Brier Score` và bảng **So sánh với 2 Baseline** (Đoán lớp đa số vs. Công thức cứng US-058).
   - **Kỳ vọng:** Mô hình Logistic Regression vượt rõ rệt cả 2 Baseline trên tập kiểm thử; biểu đồ **Trọng số đặc trưng (Feature Importance)** hiển thị thanh ngang có dấu (`+` cam/đỏ tăng rủi ro, `-` xanh giảm rủi ro).

6. **Bước 6 — Sao chép JSON trọng số & Đặt lại mô hình mặc định (`US-071`):**
   - Bấm **`Sao chép JSON`** → kiểm tra thông báo đã chép vào Clipboard; sau đó bấm **`Đặt lại mặc định`**.
   - **Kỳ vọng:** Mô hình khôi phục về trạng thái bootstrap chuẩn và lưu lại vào `SharedPreferences`.

7. **Bước 7 — Kiểm tra Dự báo Tiến độ Sprint bằng Monte Carlo (`US-070`):**
   - Quay lại `ProjectDetailScreen` → mở **`Sprint & Kanban Board`** → chọn **`Sprint 5 (AI Demo) — AI Sprint Risk Radar`** để vào `SprintDetailScreen`.
   - **Kỳ vọng:**
     - Biểu đồ **`BurndownChartWidget`** hiển thị thêm **dải dự báo AI (`p10–p90`)** tô màu xanh ngọc bán trong suốt và đường trung vị **`p50`** nét đứt nối từ ngày hiện tại đến cuối Sprint.
     - Ngay bên dưới là thẻ **`Dự báo Tiến độ Sprint (Monte Carlo)`** hiển thị xác suất hoàn thành đúng hạn (`%`), số ngày cần ở 3 mức `Lạc quan (p10)`, `Trung vị (p50)`, `Thận trọng (p90)`, và nguồn thông lượng **`Velocity các Sprint đã đóng`**.

8. **Bước 8 — Thử nghiệm What-if dời bớt User Story trong Sprint (`US-070`):**
   - Trên thẻ **`Dự báo Tiến độ Sprint (Monte Carlo)`**, bấm nút **`Thử bớt Story (What-if)`**.
   - Tích chọn thử 1–2 User Story chưa hoàn thành (`US-069` hoặc `US-070`).
   - **Kỳ vọng:** Xác suất hoàn thành Sprint tăng lên tức thì (`A% → B%`), dải dự báo trên Burndown Chart cập nhật theo, và khi bấm **`Hoàn tác` / `Đặt lại`** dữ liệu Sprint thật hoàn toàn không bị thay đổi.

9. **Bước 9 — Kiểm tra Radar Rủi ro Task trên Sprint Detail & Kanban Board (`US-069`):**
   - Cuộn xuống thẻ **`Radar Rủi ro Task trong Sprint (AI)`** trong `SprintDetailScreen`, sau đó bấm **`Mở Sprint Board`** sang màn hình Kanban.
   - **Kỳ vọng:**
     - Danh sách Task rủi ro trong Sprint xếp giảm dần theo xác suất trễ hạn kèm lý do chính.
     - Trên các thẻ `TaskCard` của cột `To Do` / `In Progress`, hiển thị `RiskBadge` màu Đỏ (`Cao`), Vàng (`Trung bình`), Xanh (`Thấp`) hoặc nhãn trung tính `CHƯA ĐẶT DEADLINE`. Các Task ở cột `Done` không hiển thị badge rủi ro.

10. **Bước 10 — Xem giải thích Top-3 đóng góp & Giả lập What-if trên Task Detail (`US-069`):**
    - Bấm vào một Task có rủi ro **Cao** (ví dụ Task giao cho **Phạm Duy** đang quá tải hoặc sát hạn) để mở `TaskDetailScreen`.
    - Xem thẻ **`AI Risk Radar`** với thanh phần trăm và **Top-3 nhân tố đóng góp (`z_j * w_j`)** bằng tiếng Việt.
    - Bấm **`Giả lập điều chỉnh (What-if)`** → chọn đổi người phụ trách sang **Lê Phúc** hoặc kéo thanh trượt gia hạn thêm `+3 ngày`.
    - **Kỳ vọng:** Xác suất rủi ro mới cập nhật tức thời (`< 5 ms`), hiển thị rõ mức giảm rủi ro (`-XX%`).

11. **Bước 11 — Kiểm tra chế độ Offline (Airplane Mode) & Dark Mode:**
    - Bật **Chế độ máy bay (Airplane Mode)** trên điện thoại Android và chuyển giao diện hệ thống sang **Dark Mode**.
    - Mở lại `SprintDetailScreen`, `TaskDetailScreen`, và `ModelLabScreen`.
    - **Kỳ vọng:** Toàn bộ dự báo AI Risk Radar, Monte Carlo Forecast và huấn luyện lại trong Model Lab vẫn hoạt động 100% bình thường, không văng lỗi mạng; màu sắc thẻ và `RiskBadge` tự động chuyển sang bộ màu Dark Mode dịu mắt.

12. **Bước 12 — Kiểm tra phân quyền RBAC với tài khoản Member (`Phạm Duy` hoặc `Trần Thúy`):**
    - Đăng xuất khỏi tài khoản PO, đăng nhập bằng tài khoản **Phạm Duy (Dev)** hoặc **Trần Thúy (QA)** (vai trò `MEMBER`).
    - Mở cùng dự án → kiểm tra `ProjectDetailScreen`, `SprintDetailScreen`, `TaskBoardScreen`, và `TaskDetailScreen`.
    - **Kỳ vọng:**
      - Không hiển thị thẻ `AI Model Lab (US-071)` trong `ProjectDetailScreen`.
      - Không hiển thị dải dự báo AI, thẻ `Dự báo Tiến độ Sprint (Monte Carlo)` hay `Radar Rủi ro Task` trong `SprintDetailScreen`.
      - Không hiển thị `RiskBadge` trên `TaskCard` hay thẻ `AI Risk Radar` trong `TaskDetailScreen`.
