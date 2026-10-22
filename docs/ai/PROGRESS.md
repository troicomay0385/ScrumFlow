# TIẾN ĐỘ THỰC HIỆN (PROGRESS.md) — AI SPRINT RISK RADAR

## Trạng thái tổng quan
- **Nhánh:** `feature/sprint5-ai-sprint-risk-radar`
- **Baseline (Phase 0):** `flutter analyze` = 0 error, 0 warning, 49 info | `flutter test` = 391 / 391 PASS

---

## Checklist Các Phase

### Phase 0 — Khởi tạo & Khảo sát
- [x] Kiểm tra nhánh `feature/sprint5-ai-sprint-risk-radar` tách từ `origin/main`, working tree sạch.
- [x] Đọc toàn bộ tài liệu & code liên quan (`NguCanh.md`, `design.md`, models, repositories, cubits, widgets).
- [x] Chạy baseline `flutter analyze` (0 error, 49 info) và `flutter test` (391 PASS).
- [x] Tạo `docs/ai/RECON.md`, `docs/ai/DECISIONS.md`, `docs/ai/PROGRESS.md`.
- [x] Cập nhật `NguCanh.md` mục Sprint 5 (`11 / 16 User Stories hoàn thành` + thêm US-069, US-070, US-071 chưa tick).
- [x] Commit Phase 0: `docs(ai): recon + add US-069/070/071 to Sprint 5`.

### Phase 1 — Lõi ML Thuần Dart (`lib/domain/ai/core/`)
- [x] `LabeledSample`, `Dataset` (stratified train/test split, k-fold CV).
- [x] `Standardizer` (z-score, xử lý phương sai 0 an toàn, JSON serialize).
- [x] `LogisticRegression` (sigmoid ổn định số học, BCE loss, mini-batch GD, L2, early stopping, class_weight, JSON serialize có schemaVersion, comment tiếng Việt giải thích công thức).
- [x] `Metrics` (accuracy, precision, recall, F1, ROC-AUC, confusion matrix, Brier score, 10-bin calibration).
- [x] `Explainer` (đóng góp `w_i * z_i`, top-K có dấu, nhãn tiếng Việt).
- [x] `BaselineModels` (majority class classifier + công thức cứng US-057/058 viết lại trong lõi).
- [x] `SyntheticHistoryGenerator` (~800 task, nhiễu thực tế, tương tác phi tuyến nhẹ, accuracy ~78–90%).
- [x] `SprintForecastEngine` (lõi Monte Carlo thuần Dart cho Phase 4).
- [x] CLI `tool/ai_eval.dart` + xuất `docs/ai/EVAL_REPORT.md` và `docs/ai/eval.json` (Holdout Accuracy = 79.33%, F1 = 0.7891, ROC-AUC = 0.8783, Brier = 0.1456).
- [x] CLI `tool/verify_no_external_api.dart` (kiểm tra PASS toàn bộ ràng buộc không gọi API ngoài).
- [x] Unit test lõi (`test/domain/ai/`) + test khớp `PerformanceScoreService` + test ngẫu nhiên `ai_invariants_test.dart` (700 kịch bản).
- [x] Commit Phase 1: `feat(ai): pure-Dart ML core, synthetic history, eval + no-API verifier`.

### Phase 2 — US-069: AI Risk Radar
- [x] `TaskRiskFeatureExtractor` (trích xuất 10 feature từ `TaskModel` + Story + Sprint + `MemberPerformanceScore`, chống rò rỉ nhãn cho mẫu `real`).
- [x] `AiModelStore` (`shared_preferences`, lưu theo `projectId` có version, tự khôi phục khi dữ liệu hỏng).
- [x] `RiskPredictionService` (tự huấn luyện nền trên bootstrap nếu chưa có model, suy luận local, tính What-if đổi người phụ trách / deadline).
- [x] Phân quyền: thêm `Permission.viewAiInsights` và `Permission.manageAiModel` cho PO/SM + cập nhật test phân quyền.
- [x] Cubit: `TaskRiskCubit`, `SprintRiskCubit` (chống stale token, timeout 15s, DI sạch cho test).
- [x] UI: Risk badge trên `TaskCard` & `TaskDetailScreen`, Bento card "AI Risk Radar" trong `TaskDetailScreen`, Bottom sheet What-if, danh sách task rủi ro cao trong `SprintDetailScreen`.
- [x] Unit & Widget tests cho US-069 (extractor, chống rò rỉ nhãn, store, service, cubit, widget).
- [x] Commit Phase 2: `feat(ai): US-069 task delay risk radar`.

### Phase 3 — US-071: AI Model Lab
- [x] `ModelLabCubit` & `ModelLabState` (tải thông tin mô hình, huấn luyện lại với tiến độ epoch, gộp mẫu `real` từ task Done có deadline, đặt lại mặc định).
- [x] `ModelLabScreen` + route trong `AppRoutes` + lối vào từ `ProjectDetailScreen` (chỉ hiển thị với PO/SM có `Permission.manageAiModel`).
- [x] UI: Thẻ dữ liệu (`synthetic` vs `real`, tỷ lệ nhãn, giả định checkpoint), nút "Huấn luyện lại" + biểu đồ Loss Curve Canvas, bảng Metrics + Confusion Matrix 2×2, so sánh 3 mô hình (Baseline đa số / Công thức cứng US-057 / Logistic Regression), Feature Importance thanh ngang có dấu, tiện ích Copy JSON & Đặt lại mặc định.
- [x] Unit & Widget tests cho US-071.
- [x] Commit Phase 3: `feat(ai): US-071 model lab`.

### Phase 4 — US-070: AI Sprint Forecast (Monte Carlo) & Demo Seeder
- [x] Adapter & Service dự báo Sprint (`SprintForecastService` / `SprintForecastCubit`): kết nối `SprintModel`, `UserStoryModel` với `SprintForecastEngine` (ưu tiên velocity sprint đã đóng → burn rate sprint hiện tại từ `completedAt ?? updatedAt` → prior mặc định + cờ độ tin cậy thấp).
- [x] Tính năng What-if loại từng Story chưa hoàn thành (top-3 Story nâng xác suất hoàn thành Sprint nhiều nhất).
- [x] Mở rộng `BurndownChartWidget` với tham số tuỳ chọn `forecast` (dải p10–p90 tô nhạt, đường p50 nét đứt) + `SprintForecastCard` & bottom sheet What-if trong `SprintDetailScreen`.
- [x] `AiDemoDataSeeder` (`lib/data/services/ai_demo_data_seeder.dart`) + mục nạp dữ liệu demo AI trong `ProjectDetailScreen`.
- [x] Unit & Widget tests cho US-070 và `AiDemoDataSeeder` (bằng mock, không ghi lên Firebase thật).
- [x] Commit Phase 4: `feat(ai): US-070 sprint forecast + demo seeder`.

### Phase 5 — Hardening (Responsive, Dark Mode, Offline, Hiệu năng)
- [ ] Widget test responsive (320×568, 430×932, chữ ×1.0 và ×1.3, bàn phím mở) & Dark mode cho toàn bộ màn hình/card/sheet AI mới.
- [ ] Kiểm thử Offline (AI hoạt động hoàn toàn khi mất mạng, không gọi network).
- [ ] Kiểm thử Hiệu năng (suy luận 1 task < 5 ms, Monte Carlo 1000 lần < 300 ms).
- [ ] Xác nhận `dart run tool/verify_no_external_api.dart` PASS & `dart run tool/ai_eval.dart` exit 0.
- [ ] Chạy toàn bộ `flutter analyze` và `flutter test`.
- [ ] Commit Phase 5: `test(ai): hardening, responsive, offline, perf`.

### Phase 6 — Tài liệu & Bàn giao
- [ ] Cập nhật `NguCanh.md` (tick `[x]` US-069, US-070, US-071 kèm mô tả chi tiết + nhật ký ngày làm việc + cập nhật tiến độ `14 / 16`).
- [ ] Cập nhật `docs/testing/test_cases.csv` và `docs/testing/BaoCaoKiemThu_US054.md`.
- [ ] Tạo `docs/ai/MANUAL_CHECKLIST.md` (10–12 bước kiểm thử thủ công trên Android).
- [ ] Tạo `docs/ai/DEFENSE.md` (tài liệu bảo vệ đồ án & giải thích thuật toán từng bước).
- [ ] Tự kiểm tra toàn bộ mục 12 (`CHECKLIST HOÀN TẤT`) và commit Phase 6: `docs(ai): US-069/070/071 docs, test report, defense notes`.
