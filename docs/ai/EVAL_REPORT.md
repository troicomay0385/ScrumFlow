# BÁO CÁO ĐÁNH GIÁ MÔ HÌNH HỌC MÁY (EVAL_REPORT.md)

> Sinh tự động từ lệnh thực thi thật: `dart run tool/ai_eval.dart`. Toàn bộ dữ liệu khởi tạo mang nhãn `source = synthetic` (có nhiễu thực tế và tương tác phi tuyến).

## 1. Dữ liệu & Huấn luyện
- **Tập huấn luyện (Bootstrap Train Pool, seed `42`):** `800` mẫu (`349` trễ hạn = `43.63%`, `451` đúng hạn) — tự động chia phân tầng `85% Train / 15% Validation` cho Early Stopping.
- **Tập kiểm thử độc lập (Holdout Test, seed `2026`):** `300` mẫu (`137` trễ hạn = `45.67%`, `163` đúng hạn).
- **Quá trình hội tụ:** Chạy `24` epochs (best epoch = `5`, dừng sớm = `true`).
- **Hàm mất mát (BCE + L2):** Loss đầu = `0.5408` → Loss cuối = `0.4366` (Best Val Loss = `0.5101`).

## 2. So sánh trên Tập Holdout Test (Seed 2026)

| Mô hình | Accuracy | Precision | Recall | F1-Score | ROC-AUC | Brier Score | ECE |
|---|---:|---:|---:|---:|---:|---:|---:|
| **Baseline (a): Đa số (Majority Class)** | 54.33% | 0.00% | 0.00% | 0.0000 | 0.5000 | 0.2485 | 0.0199 |
| **Baseline (b): Công thức cứng US-057/058** | 57.67% | 56.76% | 30.66% | 0.3981 | 0.5657 | 0.2684 | 0.1285 |
| **Mô hình học từ dữ liệu (Logistic Regression)** | **79.33%** | **73.89%** | **84.67%** | **0.7891** | **0.8783** | **0.1456** | **0.0890** |

### Ma trận nhầm lẫn 2×2 (Confusion Matrix — Tập Test, N = 300)

| Thực tế \ Dự đoán | Dự đoán Đúng hạn (0) | Dự đoán Trễ hạn (1) |
|---|---:|---:|
| **Thực tế Đúng hạn (0)** | TN = `122` | FP = `41` |
| **Thực tế Trễ hạn (1)** | FN = `21` | TP = `116` |

## 3. Độ ổn định qua 5 Seed & Kiểm chứng chéo 5-Fold CV

| Phương pháp kiểm định | Accuracy (Mean ± Std) | F1-Score (Mean ± Std) | ROC-AUC (Mean ± Std) |
|---|---:|---:|---:|
| **5 Seeds độc lập (`42, 101, 202, 303, 404`)** | `80.00% ± 0.94%` | `0.7917 ± 0.0074` | `0.8812 ± 0.0065` |
| **5-Fold Stratified CV (`N = 800`)** | `81.00% ± 2.48%` | `0.7882 ± 0.0320` | `0.8790 ± 0.0228` |

## 4. Trọng số đã học (Learned Standardized Weights)

| # | Mã đặc trưng | Nhãn tiếng Việt | Trọng số chuẩn hoá $w_j$ | Tác động |
|---:|---|---|---:|---|
| 1 | `storyPoints` | Điểm phức tạp (Story Points) | `+0.3011` | ↑ Tăng rủi ro trễ |
| 2 | `priorityRank` | Độ ưu tiên Story (Thấp→Cao) | `+0.1264` | ↑ Tăng rủi ro trễ |
| 3 | `daysToDeadline` | Số ngày còn lại tới hạn | `-0.7632` | ↓ Giảm rủi ro trễ |
| 4 | `elapsedRatio` | Tỷ lệ thời gian đã trôi qua | `+0.7406` | ↑ Tăng rủi ro trễ |
| 5 | `loggedHoursPerDay` | Cường độ làm việc (giờ/ngày) | `-0.3497` | ↓ Giảm rủi ro trễ |
| 6 | `statusProgress` | Tiến độ trạng thái hiện tại | `-0.2152` | ↓ Giảm rủi ro trễ |
| 7 | `assigneeOnTimeRate` | Tỷ lệ đúng hạn của người nhận | `-0.1102` | ↓ Giảm rủi ro trễ |
| 8 | `assigneeWorkload` | Tải công việc người nhận | `+0.4506` | ↑ Tăng rủi ro trễ |
| 9 | `sprintElapsedRatio` | Tiến độ thời gian Sprint | `+0.1617` | ↑ Tăng rủi ro trễ |
| 10 | `unassigned` | Chưa phân công người làm | `+0.1930` | ↑ Tăng rủi ro trễ |
| - | `bias` | Hệ số chệch (Bias b) | `-0.0777` | - |

## 5. Thí nghiệm Ablation (Loại bỏ từng nhóm đặc trưng)

| Nhóm đặc trưng bị loại bỏ | Accuracy | F1-Score | ROC-AUC | Mức tụt AUC ($\Delta$AUC) |
|---|---:|---:|---:|---:|
| Nhóm Thời hạn & Tiến độ (daysToDeadline, elapsedRatio, statusProgress, sprintElapsedRatio) | 65.67% | 0.6460 | 0.7081 | `-0.1702` |
| Nhóm Năng lực & Tải thành viên (assigneeOnTimeRate, assigneeWorkload, unassigned) | 75.67% | 0.7491 | 0.8508 | `-0.0275` |
| Nhóm Phạm vi & Ưu tiên Story (storyPoints, priorityRank, loggedHoursPerDay) | 74.33% | 0.7317 | 0.8399 | `-0.0384` |

## 6. Bảng Hiệu chỉnh Xác suất 10 Bin (Calibration Table)

| Bin | Khoảng xác suất | Số mẫu | Xác suất dự đoán TB | Tỷ lệ trễ thực tế | Độ lệch $|\bar{p} - \bar{y}|$ |
|---:|---|---:|---:|---:|---:|
| 1 | `[0.0, 0.1)` | 28 | 6.34% | 7.14% | 0.80% |
| 2 | `[0.1, 0.2)` | 35 | 14.11% | 2.86% | 11.25% |
| 3 | `[0.2, 0.3)` | 30 | 25.58% | 13.33% | 12.25% |
| 4 | `[0.3, 0.4)` | 19 | 34.96% | 21.05% | 13.91% |
| 5 | `[0.4, 0.5)` | 31 | 44.57% | 32.26% | 12.31% |
| 6 | `[0.5, 0.6)` | 31 | 55.42% | 48.39% | 7.03% |
| 7 | `[0.6, 0.7)` | 29 | 65.53% | 51.72% | 13.80% |
| 8 | `[0.7, 0.8)` | 37 | 75.67% | 89.19% | 13.52% |
| 9 | `[0.8, 0.9)` | 38 | 85.15% | 86.84% | 1.70% |
| 10 | `[0.9, 1.0)` | 22 | 93.55% | 90.91% | 2.64% |

## 7. Đánh giá dưới Distribution Shift (Kịch bản Áp lực cao)
- **Kịch bản lệch phân phối (seed `9001`, N = `300`):** Tải thành viên tăng `+0.25`, thời gian đến deadline co ngắn còn `75%`, tỷ lệ chưa gán `28%` (tỷ lệ trễ thực tế tăng lên `59.00%`).
- **Kết quả mô hình (không huấn luyện lại):** Accuracy = `77.67%`, F1 = `0.8213`, ROC-AUC = `0.8756`, Brier = `0.1488`.

## 8. Ví dụ Giải thích Dự đoán (Explainer Sample)
- **Xác suất dự đoán:** `35%` (`logit = -0.6040`, `bias = -0.0777`).
  - `loggedHoursPerDay` (Cường độ làm việc (giờ/ngày)): giá trị = `4.3149`, đóng góp w_j*z_j = `-0.6186`.
  - `assigneeWorkload` (Tải công việc người nhận): giá trị = `0.6505`, đóng góp w_j*z_j = `+0.2674`.
  - `sprintElapsedRatio` (Tiến độ thời gian Sprint): giá trị = `1.0143`, đóng góp w_j*z_j = `+0.2554`.

## 9. Cổng Kiểm tra Ngưỡng Chấp nhận (Mục 5 MASTER_PROMPT)

| Tiêu chí | Yêu cầu | Kết quả đo thật | Trạng thái |
|---|---|---|---|
| ROC-AUC trên tập test riêng | `>= 0.7500` | `0.8783` | PASS |
| Accuracy vượt Baseline (a) >= 5% | `>= 59.33%` | `79.33%` | PASS |
| AUC hoặc F1 vượt Baseline (b) US-058 | `> 0.5657 (AUC)` | `0.8783 (AUC) / 0.7891 (F1)` | PASS |
| Độ lệch chuẩn AUC qua 5 seed | `<= 0.0300` | `0.0065` | PASS |
| Độ chính xác thực tế (< 97%) | `< 97.0%` | `79.33%` | PASS |

**KẾT LUẬN CỔNG KIỂM TRA:** **ĐẠT TẤT CẢ TIÊU CHÍ (PASS)**
