# TÀI LIỆU BẢO VỆ ĐỒ ÁN: AI SPRINT RISK RADAR (DEFENSE.md)

> **Chủ đề:** Hệ thống Dự báo Rủi ro Trễ hạn Task & Dự báo Tiến độ Sprint bằng Học máy Thuần Dart trên Thiết bị (On-Device Pure-Dart ML & Monte Carlo Simulation)
> **Phạm vi Sprint 5:** **US-069** (AI Risk Radar), **US-070** (AI Sprint Forecast), **US-071** (AI Model Lab)

---

## 1. Tại sao xây dựng AI thuần Dart ngay trên thiết bị (On-Device Pure-Dart ML)?
1. **Bảo mật & Quyền riêng tư dữ liệu dự án:** Toàn bộ dữ liệu Backlog, Sprint, Task và hiệu suất thành viên được xử lý 100% cục bộ trên thiết bị, không gửi lên bất kỳ máy chủ LLM/API bên thứ ba nào (kiểm chứng tự động qua `tool/verify_no_external_api.dart`).
2. **Hoạt động 100% Offline & Độ trễ bằng 0:** Suy luận rủi ro cho 1 Task chỉ mất trung bình **`0.448 ms`** (mục tiêu `< 5 ms`) và mô phỏng 1.000 kịch bản Monte Carlo cho cả Sprint chỉ mất **`24.81 ms`** (mục tiêu `< 300 ms`).
3. **Minh bạch toán học (White-box Explainable AI):** Khác với việc gọi API hộp đen hoặc dùng công thức cộng trọng số cố định (như US-057/US-058), mô hình **Logistic Regression có điều chuẩn L2** tự học trọng số từ dữ liệu lịch sử và giải thích chính xác đóng góp của từng đặc trưng cho từng Task cụ thể.

---

## 2. Giải thích thuật toán từng bước & Ánh xạ vào Mã nguồn

### 2.1. Chuẩn hóa đặc trưng Z-Score (`lib/domain/ai/core/standardizer.dart`)
- **Vector đầu vào $\mathbf{x} \in \mathbb{R}^{10}$** gồm 10 đặc trưng định lượng trích xuất tại `TaskRiskFeatureExtractor.extractLiveFeatures` (`lib/data/ai/task_risk_feature_extractor.dart`):
  1. `daysToDeadline` (số ngày còn lại tới hạn, chuẩn hóa `[-1, 1]`)
  2. `isOverdue` (đã quá hạn: `0` hoặc `1`)
  3. `statusCode` (`To Do = 1.0`, `In Progress = 0.45`, `Done = 0.0`)
  4. `unassigned` (chưa có người phụ trách: `1` hoặc `0`)
  5. `assigneeOnTimeRate` (tỷ lệ hoàn thành đúng hạn lịch sử của người nhận việc)
  6. `assigneeWipLoad` (tải công việc đang mở của người nhận việc)
  7. `storyPointsNorm` (điểm phức tạp của User Story cha)
  8. `storyPriorityNum` (độ ưu tiên của User Story cha)
  9. `loggedHoursRatio` (tỷ lệ giờ đã log so với kỳ vọng)
  10. `sprintTimeElapsedRatio` (tỷ lệ thời gian Sprint đã trôi qua)
- **Công thức chuẩn hóa (`Standardizer.transform`):**
  $$z_j = \begin{cases} \dfrac{x_j - \mu_j}{\sigma_j} & \text{nếu } \sigma_j > 10^{-8} \\ 0 & \text{nếu } \sigma_j \le 10^{-8} \text{ (tránh chia cho 0)} \end{cases}$$

### 2.2. Mô hình Logistic Regression & Huấn luyện Mini-batch GD (`lib/domain/ai/core/logistic_regression.dart`)
- **Hàm dự đoán xác suất (`LogisticRegression.predictProba`):**
  $$\hat{p} = \sigma(\mathbf{w}^\top \mathbf{z} + b) = \frac{1}{1 + e^{-(\mathbf{w}^\top \mathbf{z} + b)}}$$
  Trong đó hàm `_stableSigmoid(u)` tách nhánh theo dấu của $u$ để không bao giờ tràn số (`exp overflow`) với $|u|$ lớn.
- **Hàm mục tiêu Binary Cross-Entropy có trọng số lớp cân bằng & L2 (`computeLoss`):**
  $$\mathcal{L}(\mathbf{w}, b) = -\frac{1}{N}\sum_{i=1}^{N} \alpha_{y_i}\Big[y_i \ln(\hat{p}_i) + (1 - y_i)\ln(1 - \hat{p}_i)\Big] + \frac{\lambda}{2}\|\mathbf{w}\|_2^2$$
- **Cập nhật tham số & Dừng sớm (`fit`):** Sử dụng Mini-batch Gradient Descent (kích thước lô `32`), giảm nhẹ tốc độ học theo chu kỳ và dừng sớm (`earlyStoppingPatience = 18`) khi `valLoss` không giảm thêm, sau đó khôi phục bộ trọng số tại `bestEpoch`. Độ chính xác của đạo hàm giải tích được kiểm chứng khớp với đạo hàm sai phân hữu hạn tới $10^{-5}$ trong `LogisticRegression.maxGradientDifference`.

### 2.3. Giải thích đóng góp đặc trưng cục bộ (`lib/domain/ai/core/explainer.dart`)
- **Công thức đóng góp vào log-odds (`Explainer.explain`):**
  $$c_j = w_j \cdot z_j$$
  - Nếu $c_j > 0$: đặc trưng thứ $j$ đang **đẩy xác suất trễ hạn tăng lên** (hiển thị thanh màu đỏ/cam trên `TaskRiskRadarCard`).
  - Nếu $c_j < 0$: đặc trưng thứ $j$ đang **giúp giảm nguy cơ trễ hạn** (hiển thị thanh màu xanh lá).
- Hệ thống sắp xếp $|c_j|$ giảm dần và sinh câu giải thích tiếng Việt kèm số liệu thực tế của Task (ví dụ: *"Hạn chót rất gấp (còn 0.5 ngày)"*, *"Người phụ trách đang ôm nhiều việc (WIP = 4 task)"*).

### 2.4. Thiết kế Chống rò rỉ nhãn (Anti-Label Leakage) cho dữ liệu thật (`lib/data/ai/task_risk_feature_extractor.dart`)
- Khi thu thập các Task đã `Done` để huấn luyện bổ sung (`extractCompletedTaskSample`), nếu lấy trạng thái lúc đã xong (`status = Done`, `loggedHours` cuối kỳ, hay `now = updatedAt`) thì mô hình sẽ bị **rò rỉ nhãn (label leakage)**.
- **Giải pháp:** `TaskRiskFeatureExtractor.extractCompletedTaskSample` tái tạo thời điểm quan sát ở **giữa vòng đời dự kiến của Task**:
  $$t_{\text{obs}} = t_{\text{created}} + 0.5 \cdot (t_{\text{deadline}} - t_{\text{created}})$$
  Tại $t_{\text{obs}}$, trạng thái được cố định ở giai đoạn đang thực hiện và giờ làm việc được ước lượng theo tiến độ kỳ vọng tại thời điểm đó. Nhãn thực tế $y = \mathbb{I}(t_{\text{completed}} > t_{\text{deadline}})$ chỉ dùng làm mục tiêu huấn luyện. Tính bất biến này được kiểm chứng bằng unit test tự động trong `test/data/ai/task_risk_data_test.dart`.

### 2.5. Mô phỏng Monte Carlo Dự báo Tiến độ Sprint (`lib/domain/ai/core/sprint_forecast_engine.dart`)
- **Bài toán:** Với $R_0$ Story Points còn lại và $D$ ngày còn lại của Sprint, xác suất hoàn thành toàn bộ điểm đúng hạn là bao nhiêu?
- **Thuật toán (`SprintForecastEngine.simulate` & `SprintForecastService.forecastSprint`):**
  1. Xác định tập mẫu thông lượng ngày (SP/ngày) theo thứ tự ưu tiên:
     - **(a)** Velocity/ngày của các Sprint đã đóng (`Completed` / `Closed`).
     - **(b)** Tốc độ burn thực tế theo ngày của Sprint đang chạy (từ `story.completedAt ?? story.updatedAt`).
     - **(c)** Phân phối prior khởi tạo (`defaultPriorSamples`) kèm cờ cảnh báo `isLowConfidence = true`.
  2. Chạy $N = 1000$ kịch bản độc lập: mỗi ngày lấy mẫu bootstrap có hoàn lại kèm nhiễu tự nhiên $\pm 15\%$, cập nhật $R_{t+1} = \max(0, R_t - v_t)$.
  3. Trích xuất xác suất hoàn thành $\hat{P}(R_D = 0)$, các phân vị số ngày cần thêm (`p10`, `p50`, `p90`) và dải quỹ đạo điểm còn lại (`bandP10`, `bandP50`, `bandP90`) vẽ trực tiếp lên `BurndownChartWidget`.

---

## 3. Kết quả Đánh giá Thực nghiệm (`docs/ai/EVAL_REPORT.md`)

| Mô hình / Phương pháp | Accuracy | Precision | Recall | F1-Score | ROC-AUC | Brier Score |
|---|---|---|---|---|---|---|
| **1. Baseline (a) — Đoán lớp đa số** | 54.33% | 0.0000 | 0.0000 | 0.0000 | 0.5000 | 0.2485 |
| **2. Baseline (b) — Công thức cứng US-058** | 57.67% | 0.5833 | 0.3022 | 0.3981 | 0.5657 | 0.2684 |
| **3. Logistic Regression (Đề xuất)** | **79.33%** | **0.7586** | **0.8222** | **0.7891** | **0.8783** | **0.1456** |

- **Độ ổn định qua 5 Random Seeds (`11, 29, 42, 77, 101`):** Accuracy = **`80.00% ± 0.94%`**, F1 = **`0.7917 ± 0.0074`**, ROC-AUC = **`0.8812 ± 0.0065`**.
- **Kiểm định chéo 5-Fold Stratified CV:** Accuracy = **`81.00% ± 2.48%`**, ROC-AUC = **`0.8790 ± 0.0228`**.
- **Kiểm thử lệch phân phối (Distribution Shift — Sprint khó hơn):** Accuracy = **`77.67%`**, F1 = **`0.8213`**, ROC-AUC = **`0.8756`**.

---

## 4. Hạn chế Trung thực & Hướng phát triển
1. **Dữ liệu khởi tạo (Cold-start):** Khi dự án mới tạo chưa có đủ Task `Done` thực tế, mô hình dựa chủ yếu vào 800 mẫu `synthetic` sinh từ quy luật Scrum thực nghiệm. Giao diện `ModelLabScreen` hiển thị rõ tỷ lệ mẫu `synthetic` vs `real` và cảnh báo khi số mẫu `real < 10`.
2. **Giả định tuyến tính trong log-odds:** Logistic Regression là mô hình tuyến tính trên không gian đặc trưng chuẩn hóa, chưa tự động học được các tương tác bậc cao phức tạp như Gradient Boosted Trees.
3. **Ước lượng điểm lịch sử khi thiếu snapshot:** Do `TaskModel` hiện tại không lưu lịch sử thay đổi trạng thái theo từng giờ, mẫu `real` từ Task `Done` sử dụng điểm quan sát giả định ở mốc 50% thời gian (`checkpointRatio = 0.5`).

---

## 5. Kịch bản Demo Bảo vệ 3–4 Phút
- **Phút 1 — Khởi tạo & Huấn luyện trực tiếp (`US-071`):**
  Đăng nhập tài khoản PO (`Lê Phúc`) → bấm **`Nạp Dữ Liệu Demo AI`** → mở **`AI Model Lab`** → bấm **`Huấn luyện lại mô hình`** để hội đồng quan sát đường cong **BCE Loss Curve** hội tụ trực tiếp trên thiết bị, bảng **Confusion Matrix 2×2** và mức cải thiện vượt trội so với công thức cứng US-058 (`F1 = 0.7891` vs `0.3981`).
- **Phút 2 — Dự báo Sprint bằng Monte Carlo (`US-070`):**
  Mở **`Sprint 5 (AI Demo)`** → chỉ vào **dải dự báo `p10–p90`** trên `BurndownChartWidget` và thẻ **Monte Carlo Forecast** → bấm **`Thử bớt Story (What-if)`**, tích chọn dời 1 Story lớn để thấy xác suất hoàn thành Sprint tăng tức thì.
- **Phút 3 — Giải thích Rủi ro Task & Giả lập What-if (`US-069`):**
  Mở 1 Task có badge **Rủi ro Cao (Đỏ)** → chỉ vào **Top-3 nhân tố đóng góp (`w_j * z_j`)** → bấm **`Giả lập điều chỉnh (What-if)`**, đổi người phụ trách sang thành viên đang rảnh và gia hạn thêm 3 ngày để thấy rủi ro giảm từ mức Đỏ xuống Xanh ngay lập tức.
- **Phút 4 — Kiểm chứng Bảo mật Phân quyền & Offline:**
  Bật Airplane Mode để chứng minh toàn bộ AI chạy 100% cục bộ không cần mạng; chuyển sang tài khoản Member (`Phạm Duy`) để chứng minh các chỉ số giám sát AI được ẩn hoàn toàn đúng chuẩn Scrum.
