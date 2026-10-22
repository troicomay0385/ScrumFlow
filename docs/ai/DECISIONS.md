# NHẬT KÝ QUYẾT ĐỊNH THIẾT KẾ & KỸ THUẬT (DECISIONS.md)

## 1. Ngưỡng Chấp Nhận Mô Hình ML (Chốt Trước Khi Chạy — Mục 5 MASTER_PROMPT)

Trên **tập test giữ riêng (seed khác)**:
- ROC-AUC ≥ 0.75
- Accuracy ≥ accuracy baseline (a) + 5 điểm %
- AUC hoặc F1 của model > baseline (b)
- Độ lệch chuẩn AUC qua 5 seed ≤ 0.03
- `ai_invariants_test`: 0 vi phạm

---

## 2. Các Quyết Định Kiến Trúc & Kỹ Thuật

### QĐ-01: Tách biệt tuyệt đối lõi ML thuần Dart (`lib/domain/ai/core/**`)
- **Quyết định:** Toàn bộ thuật toán học máy (Dataset, Standardizer, LogisticRegression, Metrics, Explainer, BaselineModels, SyntheticHistoryGenerator, SprintForecastEngine) chỉ import `dart:core`, `dart:math`, `dart:convert`.
- **Lý do:** Đảm bảo không phụ thuộc Flutter hay Firebase (`cloud_firestore`), cho phép chạy trực tiếp bằng `dart run tool/ai_eval.dart` trên CLI cực nhanh và dễ kiểm chứng độc lập khi vấn đáp.

### QĐ-02: Bộ 10 đặc trưng (Feature Set) cho bài toán dự đoán trễ hạn Task (US-069)
- **Quyết định:** Sử dụng đúng 10 đặc trưng định lượng có thể trích xuất trực tiếp từ dữ liệu thật của dự án:
  1. `storyPoints`: Điểm độ phức tạp của User Story cha (1..21, mặc định 3 nếu không tìm thấy story).
  2. `priorityRank`: Độ ưu tiên của User Story cha (`CAO` = 2.0, `TB` = 1.0, `THẤP` = 0.0; giá trị cao = ưu tiên cao/áp lực cao).
  3. `daysToDeadline`: Số ngày từ hiện tại (`now`) đến `deadline`, kẹp trong khoảng `[-7.0, 14.0]`.
  4. `elapsedRatio`: Tỷ lệ thời gian đã trôi qua `= (now - createdAt) / max(1 ngày, deadline - createdAt)`, kẹp trong `[0.0, 1.5]`.
  5. `loggedHoursPerDay`: Cường độ ghi nhận giờ làm `= loggedHours / max(1.0, tuổi task theo ngày)`, kẹp trong `[0.0, 12.0]`.
  6. `statusProgress`: Tiến độ trạng thái hiện tại (`To Do` = 0.0, `In Progress` = 0.5). Task `Done` hoặc không có `deadline` không đưa vào dự đoán rủi ro.
  7. `assigneeOnTimeRate`: Tỷ lệ hoàn thành đúng hạn lịch sử của người phụ trách `[0.0, 1.0]` (từ `MemberPerformanceScore`; nếu chưa phân công đặt = 0.75 trung tính).
  8. `assigneeWorkload`: Tải công việc hiện tại của người phụ trách `= inProgressTasks / 5.0` kẹp `[0.0, 1.5]` (tương ứng nghịch đảo của `workloadFactor` trong US-058; nếu chưa phân công đặt = 0.0).
  9. `sprintElapsedRatio`: Tỷ lệ thời gian đã trôi qua của Sprint chứa Story `[0.0, 1.2]` (nếu không thuộc Sprint đang chạy đặt = 0.5).
  10. `unassigned`: Biến chỉ báo chưa có người phụ trách (`1.0` nếu `assigneeId == null || assigneeId.isEmpty`, ngược lại `0.0`).
- **Lý do:** Đầy đủ ngữ cảnh phạm vi (Story), tiến độ thời gian (Task & Sprint), năng lực/tải thành viên (US-058) và trạng thái phân công. Loại bỏ hoàn toàn `ratingScore` vì trong US-058 trường này là hằng số `1.0` (phương sai = 0).

### QĐ-03: Chống rò rỉ nhãn (Anti-Label Leakage) cho mẫu `real` khi Retrain (US-071)
- **Quyết định:** Mẫu `real` được lấy từ các Task đã `Done` và có `deadline != null`. Nhãn thực tế `y = 1` (trễ hạn) nếu `updatedAt.isAfter(deadline!)`, ngược lại `y = 0` (khớp định nghĩa US-058). Khi trích xuất vector đặc trưng cho mẫu `real`, **tuyệt đối không dùng `updatedAt`** hay thời điểm hiện tại để tính các đặc trưng động:
  - `daysToDeadline` tính tại mốc chuẩn giữa kỳ: `0.5 * (deadline - createdAt)` kẹp `[-7.0, 14.0]`.
  - `elapsedRatio` cố định ở checkpoint `0.5` (giữa vòng đời kế hoạch của task).
  - `statusProgress` cố định ở checkpoint `0.5` (đang thực hiện).
  - `loggedHoursPerDay` đặt bằng trung bình chuẩn (`1.5` giờ/ngày) vì `loggedHours` cuối kỳ tương quan với tổng thời gian làm việc đến khi `Done`.
  - Điểm lịch sử của người phụ trách (`assigneeOnTimeRate`) khi tính cho mẫu `real` thứ `i` được tính **loại trừ chính task `i` đó** (leave-one-out) để không rò rỉ nhãn của task `i` vào tỷ lệ đúng hạn của người được giao.
- **Lý do:** Do `TaskModel` không lưu lịch sử snapshot trạng thái theo thời gian, nếu dùng `updatedAt` làm mốc tính `daysToDeadline` hay `elapsedRatio` thì `elapsedRatio > 1.0 ⇔ updatedAt > deadline ⇔ y = 1`, gây rò rỉ nhãn 100%. Cố định tại checkpoint giữa kỳ đảm bảo vector đặc trưng của mẫu `real` hoàn toàn bất biến khi thay đổi `updatedAt`.

### QĐ-04: Thiết kế bộ sinh dữ liệu tổng hợp `SyntheticHistoryGenerator`
- **Quyết định:** Sinh 800 mẫu lịch sử với quy luật thực tế của dự án phần mềm Agile, kết hợp:
  - Tương tác phi tuyến nhẹ (ví dụ: workload cao đi kèm thời gian còn lại ít `assigneeWorkload * max(0, 1 - daysToDeadline/7)`, hoặc task chưa bắt đầu khi đã qua 70% thời gian).
  - Nhiễu Gaussian trên đặc trưng đo lường và xác suất đảo nhãn ngẫu nhiên (label flip noise ~5.5%) mô phỏng các yếu tố ngoại cảnh không quan sát được (nghỉ ốm, thay đổi yêu cầu đột xuất).
  - Đảm bảo độ chính xác kỳ vọng của mô hình tuyến tính nằm trong khoảng thực tế **78% – 90%** (không vượt quá 97%).
- **Nhật ký cân chỉnh (Vòng 1/3):** Ở cấu hình khởi tạo đầu tiên (`latentGaussianNoiseStd = 0.55`, hệ số tín hiệu `1.0`), do phép lấy mẫu Bernoulli trên hàm Sigmoid vốn đã mang nhiễu Logistic nội tại ($\sigma = \pi/\sqrt{3} \approx 1.81$), việc cộng chồng thêm nhiễu Gaussian lớn làm Accuracy tập test đạt `75.33%` (hơi thấp hơn dải mục tiêu `78–90%` ở mục 4.7 dù AUC đạt `0.8443`). Đã điều chỉnh `latentGaussianNoiseStd = 0.35`, `labelFlipNoiseRate = 0.055` và hệ số tín hiệu tuyến tính `1.45` (giữ nguyên `holdoutTestSeed = 2026`). Kết quả sau Vòng 1: Holdout Accuracy = `79.33%`, 5-Seed Accuracy = `80.00% ± 0.94%`, Holdout ROC-AUC = `0.8783`, 5-Seed AUC = `0.8812 ± 0.0065` — đạt toàn bộ cổng kiểm tra.
