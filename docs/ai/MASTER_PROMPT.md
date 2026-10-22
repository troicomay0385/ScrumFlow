# MASTER PROMPT — SCRUMFLOW: AI SPRINT RISK RADAR (3 US mới, Sprint 5)

> File này đặt tại `docs/ai/MASTER_PROMPT.md` trong repo. Agent TỰ chạy hết các phase, TỰ test, TỰ sửa lỗi, KHÔNG hỏi lại người dùng, KHÔNG dừng giữa các phase để xin xác nhận.
> Nếu phiên bị ngắt: mở phiên mới, gửi đúng một dòng: `Tiếp tục theo docs/ai/PROGRESS.md, nội quy trong docs/ai/MASTER_PROMPT.md`.

---

## 0. VAI TRÒ & MỤC TIÊU

Bạn là kỹ sư Flutter/Dart senior kiêm kỹ sư ML. Dự án **Scrumflow** (Flutter 3.47 / Dart 3.13, Firebase Firestore, SQLite cache, `flutter_bloc`, test bằng `mocktail` + `bloc_test`).

Xây **chức năng cốt lõi lấy điểm cộng**: một hệ thống AI **tự xây dựng hoàn toàn trong app**, chia 3 User Story mới thêm vào Sprint 5:

| US | Tên | Nội dung |
|---|---|---|
| **US-069** | [AI Risk Radar] | Dự đoán xác suất trễ hạn từng Task bằng **Logistic Regression tự cài bằng Dart**, giải thích top yếu tố đóng góp, what-if đổi người phụ trách/deadline |
| **US-070** | [AI Sprint Forecast] | Dự báo xác suất hoàn thành Sprint bằng **mô phỏng Monte Carlo**, dải p10/p50/p90 chồng lên Burndown hiện có, what-if "dời Story X ra khỏi Sprint" |
| **US-071** | [AI Model Lab] | Màn hình huấn luyện & đánh giá mô hình: loss curve, accuracy/precision/recall/F1/AUC, confusion matrix, so sánh baseline, độ quan trọng feature, retrain từ dữ liệu thật |

Bối cảnh chấm điểm: giảng viên nói AI phải **tự build, KHÔNG dùng API ngoài**; chỉ CRUD hoặc UI đẹp hơn thì KHÔNG tính điểm cộng. Chức năng sẽ được **vấn đáp**, và đề bài yêu cầu "sinh viên phải hiểu thuật toán/logic khi dùng AI". Vì vậy: code lõi phải **ngắn, sạch, có comment tiếng Việt giải thích công thức** (người dùng sẽ phải đọc và giải thích được), và mọi tuyên bố "model học được" phải có số liệu đo thật.

Lưu ý: US-057/058 hiện có (`PerformanceScoreService`) là **công thức cứng** (`0.5·onTimeRate + 0.3·workload + 0.2·rating`, với `ratingScore` gán cứng 1.0). Chức năng mới phải khác bản chất: **trọng số được học từ dữ liệu**. Không sửa US-057/058.

---

## 1. RÀNG BUỘC CỨNG (vi phạm = lỗi nghiêm trọng)

1. **Cấm** gọi API/mạng ngoài cho AI (OpenAI, Gemini, Claude, HuggingFace, REST, Cloud Functions...). **Cấm** thêm package ML/AI. **Không sửa `pubspec.yaml`** (đã có `shared_preferences`, `sqflite`, `flutter_bloc`, `equatable`, `google_fonts`, `mocktail`, `bloc_test` — đủ dùng). Cần thêm dependency → ghi lý do vào `DECISIONS.md` và chỉ thêm khi thực sự bắt buộc.
2. Lõi ML trong `lib/domain/ai/core/**` **chỉ dùng** `dart:math`, `dart:core`, `dart:convert`: không import Flutter, Firebase, `dart:io`, http, và **không import model/service của app** (vì `TaskModel` kéo theo `cloud_firestore`). Phải chạy được bằng `dart run` thuần.
3. **Chỉ thêm mới (additive).** Không đổi hành vi/tên/field của `TaskModel`, `UserStoryModel`, `SprintModel`, `PerformanceScoreService`, `TaskRepository`, `SprintDataSource`... **Không sửa `LocalCacheDataSource`, `task_repository.dart`, `backlog_repository_impl.dart`** (nhánh `sprint5/caching(fixed)` của thành viên khác đang sửa 3 file này → tránh conflict). Mô hình AI lưu bằng `shared_preferences`, **không** thêm bảng SQLite, **không** nâng `_dbVersion`.
4. **Không** `git push`, **không** merge, **không** `firebase deploy`, **không** ghi dữ liệu lên Firebase thật trong phiên này (không chạy seeder). Không sửa `firestore.rules` (AI chạy local, không cần rule mới).
5. Không đụng các vấn đề đã biết ngoài phạm vi: US-067/US-068 (checkbox `NguCanh.md` đang lệch code — không sửa), TODO `sprintId: ''` ở Stand-up, hai file `task_board_screen.dart` trùng tên (`tasks/screens/` là Task theo Story; `task_board/screens/` là Kanban Story theo Sprint — import cẩn thận, đúng file).
6. **Git an toàn:** repo đang track cả `.idea/` và `android/.kotlin/`. **Cấm `git add -A` / `git add .`**. Chỉ `git add` đúng đường dẫn thuộc phạm vi: `lib/`, `test/`, `tool/`, `docs/`, `NguCanh.md`. Không bao giờ stage `.idea/**`, `android/**`.
7. Baseline: số test/analyze **đo lại ở Phase 0 trên nhánh mới** (đừng tin số cũ trong `NguCanh.md`). Sau mỗi phase: số test **không giảm**, `flutter analyze` 0 error và không tăng số issue so với baseline.
8. **Trung thực tuyệt đối:** mọi con số trong tài liệu phải lấy từ lần chạy thật. Máy này chỉ có Windows/Chrome/Edge, **không có Android emulator/thiết bị** → mọi kiểm thử thủ công trên thiết bị ghi "CHƯA CHẠY".
9. Ngôn ngữ: identifier bằng tiếng Anh; chuỗi UI và comment giải thích bằng tiếng Việt; chuỗi UI đưa vào `AppStrings`.

---

## 2. CÁCH LÀM VIỆC TỰ ĐỘNG

**Vòng lặp mỗi phase:** làm → `dart format` → `flutter analyze` → test → commit → cập nhật `PROGRESS.md` → **sang phase tiếp NGAY, không dừng, không tóm tắt giữa chừng**. Chỉ gửi báo cáo cuối khi: hoàn thành tất cả, hoặc hết token, hoặc gặp điều kiện dừng.

- Trong lúc phát triển chạy test mục tiêu cho nhanh (`flutter test test/domain/ai`); **toàn bộ** `flutter test` + `flutter analyze` chạy ở cuối mỗi phase (cổng kiểm tra).
- **Không hỏi người dùng.** Mơ hồ → chọn phương án đơn giản, an toàn, additive nhất; ghi vào `docs/ai/DECISIONS.md` (quyết định + lý do).
- **Trạng thái bền vững:** `docs/ai/PROGRESS.md` là nguồn sự thật. Đầu phiên đọc nó, tiếp tục từ bước chưa xong đầu tiên. Cập nhật sau mỗi bước (checkbox + ghi chú + kết quả analyze/test mới nhất).
- **Tự sửa lỗi:** đỏ → đọc lỗi, sửa gốc rễ, chạy lại; tối đa **5 lần** cho cùng một lỗi. Vẫn đỏ → khôi phục file về commit phase trước (`git restore` đúng các file đã sửa), đánh dấu phase `BLOCKED` + nguyên nhân trong `PROGRESS.md`, chuyển sang phase độc lập tiếp theo. Không để repo ở trạng thái không build/không test được.
- **Cấm sửa cho test qua:** không xoá/nới test, không hạ ngưỡng sau khi đã thấy kết quả.
- **Commit:** mỗi phase một commit (`feat(ai): ...`, `test(ai): ...`, `docs(ai): ...`), chỉ stage đường dẫn hợp lệ (mục 1.6).
- Dùng được MCP `codegraph` (cấu hình ở `.agents/mcp_config.json`) để tra cứu code nếu có.
- **Hết token:** hoàn tất + commit phase đang làm, cập nhật `PROGRESS.md`, dừng. Thứ tự giá trị: Phase 1 → 2 → 3 → 4 → 5 → 6.
- **Điều kiện dừng ngay và báo lại:** nhánh hiện tại không phải nhánh mới sau Phase 0; working tree có thay đổi không thuộc phạm vi; không lấy được `origin/main`.

---

## 3. PHASE 0 — KHỞI TẠO & KHẢO SÁT

1. Nhánh đích: **`feature/sprint5-ai-sprint-risk-radar`**, **tách từ `origin/main`** (KHÔNG từ `sprint5/caching(fixed)`: nhánh đó chưa merge, có `.idea` bị sửa và 1 test đang timeout — tất cả không thuộc việc này). Người dùng thường đã tạo sẵn; kiểm tra bằng `git branch --show-current` và `git merge-base --is-ancestor origin/main HEAD`. Nếu chưa có: `git fetch origin && git switch -c feature/sprint5-ai-sprint-risk-radar origin/main` (chỉ khi `git status` sạch).
2. Đọc: `NguCanh.md`, `README_MoTaDoAnMonHoc.md`, `README_MoTaChucNang.md`, `design.md` (hoặc `desigh.md`), `pubspec.yaml`, `lib/main.dart` (cây `MultiRepositoryProvider`/`MultiBlocProvider`, ~dòng 142–180), `lib/app/routes/app_routes.dart`.
3. Đọc nguyên văn để bám đúng thực tế: `TaskModel`, `UserStoryModel`, `SprintModel`, `performance_score_service.dart` (+ `MemberPerformanceScore`), `burndown_chart_widget.dart` (`BurndownData.calculate`, `_BurndownPainter`), `sprint_dashboard_card.dart` + `SprintDashboardCubit` (mẫu Cubit: chống stale token, timeout 15s, nhận cubit ngoài để test), `sprint_datasource.dart` (`closeSprint`), `task_repository.dart` (các `stream...`/`get...`), `permission.dart`, `role_permissions.dart` (và test của nó), `AppColors`, `AppThemes`, `ResponsiveLayout`, `AppStrings`, `test/helpers/`, `test/responsive/`.
4. Chạy baseline: `flutter analyze`, `flutter test`. Ghi số liệu vào `docs/ai/RECON.md`.
5. Tạo `docs/ai/RECON.md`, `docs/ai/PROGRESS.md` (checklist mọi phase), `docs/ai/DECISIONS.md`. Tạo `tool/` nếu chưa có.
6. **Sự thật về dữ liệu (đã xác minh, bám theo):**
   - `TaskModel` **không có** `completedAt`, `startedAt`, lịch sử đổi trạng thái, `estimate`; **không parse** `isBlocked`/`blockerReason` (Firestore có lưu, model bỏ qua — **không sửa**, thuộc US-067). `updatedAt` của task Done được US-058 dùng làm mốc hoàn thành (WorkLog cố ý không đổi `updatedAt`).
   - `UserStoryModel` có `storyPoints` (Fibonacci), `priority` (`CAO/TB/THẤP`), `completedAt?`, `deadline?`.
   - Điểm story nằm ở **Story**, Task chỉ có `storyId` → cần tra story để lấy `storyPoints`/`priority`.
   - `closeSprint` chỉ đặt `status='Completed'` (model còn nhắc `'Closed'` → **coi cả hai là đã đóng**, viết helper dùng chung) và **gỡ story chưa xong khỏi `storyIds`**. Không lưu velocity/snapshot. ⇒ Velocity sprint đã đóng = tổng `storyPoints` của các story còn trong `storyIds` ÷ số ngày (`endDate − startDate`).
   - Burndown hiện tính động từ `updatedAt` của story Done; dự báo của ta dùng `completedAt ?? updatedAt`.
   - `ratingScore` luôn = 1.0 → **không dùng làm feature** (phương sai 0).
   - Dữ liệu mẫu hiện có: 4 story, 1 sprint Active, 4 task, chưa có sprint đã đóng.
7. **Cập nhật `NguCanh.md` mục Sprint 5:** đổi dòng tiến độ thành `11 / 16 User Stories hoàn thành`, thêm 3 dòng (chưa tick) đúng định dạng:

```
- [ ] **US-069** [Ưu tiên: CAO] *(Duy)*: [AI Risk Radar] Là PO/SM, tôi muốn hệ thống tự dự đoán xác suất trễ hạn của từng Task bằng mô hình Machine Learning tự xây dựng (Logistic Regression, không dùng API ngoài) kèm giải thích các yếu tố ảnh hưởng, để kịp thời xử lý rủi ro. *(Chưa hoàn thành)*
- [ ] **US-070** [Ưu tiên: CAO] *(Duy)*: [AI Sprint Forecast] Là PO/SM, tôi muốn xem xác suất hoàn thành Sprint và dải dự báo (p10/p50/p90) bằng mô phỏng Monte Carlo ngay trên biểu đồ Burndown, kèm gợi ý what-if loại bớt Story, để quyết định điều chỉnh phạm vi Sprint. *(Chưa hoàn thành)*
- [ ] **US-071** [Ưu tiên: CAO] *(Duy)*: [AI Model Lab] Là PO/SM, tôi muốn có màn hình huấn luyện và đánh giá mô hình (loss curve, accuracy/precision/recall/F1/AUC, confusion matrix, so sánh baseline) để kiểm chứng AI thực sự học từ dữ liệu. *(Chưa hoàn thành)*
```

Commit: `docs(ai): recon + add US-069/070/071 to Sprint 5`.

---

## 4. PHASE 1 — LÕI ML THUẦN DART

Cấu trúc (khớp kiến trúc Data/Presentation/App của dự án):
- `lib/domain/ai/core/` — lõi ML thuần Dart (ràng buộc 1.2).
- `lib/data/ai/` — adapter đọc model của app → feature, kho lưu mô hình (`shared_preferences`).
- `lib/presentation/ai/` — Cubit/Screen/Widget.
- `test/domain/ai/`, `test/data/ai/`, `test/presentation/ai/`.

Mọi class lõi nhận `Random` (seeded) qua tham số để tái lập.

1. **Dữ liệu:** `LabeledSample` (vector, nhãn 0/1, `source = synthetic|real`), `Dataset` (split train/test phân tầng, k-fold).
2. **Tiền xử lý:** `Standardizer` (z-score, phương sai 0 an toàn, serialize).
3. **Mô hình:** `LogisticRegression` — sigmoid ổn định số học, binary cross-entropy, mini-batch gradient descent, L2, early stopping theo validation loss, `class_weight`, `toJson/fromJson` có `schemaVersion`; trả lịch sử loss từng epoch. **Comment tiếng Việt ghi rõ công thức** (`p = σ(w·z + b)`, gradient `= (p − y)·z`).
4. **Đánh giá:** `Metrics` (accuracy, precision, recall, F1, ROC-AUC, confusion matrix, Brier, calibration 10 bin).
5. **Giải thích:** `Explainer` — đóng góp = `w_i · z_i`, top-K có dấu, nhãn tiếng Việt.
6. **Baseline:** (a) luôn đoán lớp đa số; (b) **bản sao công thức US-057/058** viết lại trong lõi (`0.5·onTimeRate + 0.3·workload` đảo thành điểm rủi ro; **không import** `PerformanceScoreService` vì nó kéo Firestore làm `dart run` hỏng). Thêm 1 test trong `flutter test` chứng minh bản sao cho kết quả khớp `PerformanceScoreService` trên dữ liệu mẫu.
7. **Dữ liệu lịch sử tổng hợp (bootstrap):** `SyntheticHistoryGenerator(seed)` ~800 task. Bắt buộc:
   - nhiễu thực tế (đảo nhãn ngẫu nhiên 5–8%), nhiễu Gaussian trên feature, tương tác phi tuyến nhẹ (vd workload cao × thời gian còn ít);
   - độ chính xác kỳ vọng ~78–90%; **≥ 97% = đáng ngờ/quá dễ → tăng nhiễu** (ghi DECISIONS);
   - seed huấn luyện ≠ seed tập test; không tinh chỉnh theo test seed;
   - gắn `source=synthetic` ở mọi nơi, UI/tài liệu nói rõ đây là dữ liệu khởi tạo tổng hợp.
8. **Feature set (≤ ~10; điều chỉnh theo RECON, mỗi feature phải tính được từ dữ liệu thật):**
   `storyPoints` (từ Story), `priorityRank` (0..2), `daysToDeadline` (kẹp −7..14), `elapsedRatio` = (now − createdAt)/(deadline − createdAt) kẹp 0..1.5, `loggedHoursPerDay` = `loggedHours`/max(1, tuổi task theo ngày), `statusProgress` (To Do=0, In Progress=0.5), `assigneeOnTimeRate` và `assigneeWorkload` (lấy từ `MemberPerformanceScore` — không dùng `ratingScore`), `sprintElapsedRatio` (từ `SprintModel`), `unassigned` (0/1). **Task không có deadline → không dự đoán** (hiện "Chưa đặt deadline"). Task Done → không dự đoán.
9. **Mẫu `real` & chống rò rỉ nhãn (QUAN TRỌNG):** mẫu real = task `Done` có `deadline`; nhãn = `updatedAt > deadline` (khớp US-058). **Cấm** dùng làm feature bất kỳ đại lượng suy ra từ `updatedAt` của chính task đó (rò rỉ nhãn). Với mẫu real, đặc trưng động (`elapsedRatio`, `statusProgress`, `loggedHoursPerDay`) đặt về giá trị checkpoint cố định (vd `elapsedRatio=0.5`, `statusProgress=0.5`, `loggedHoursPerDay` = trung bình tập synthetic) và ghi rõ giả định này trong `DECISIONS.md` + Model Lab. Viết **test chống rò rỉ**: đổi `updatedAt` của task Done (giữ nguyên field khác) → vector feature không đổi.
10. **CLI headless `tool/ai_eval.dart`** (`dart run tool/ai_eval.dart`, chỉ import `package:scrumflow/domain/ai/core/...`): in console + ghi `docs/ai/EVAL_REPORT.md` và `docs/ai/eval.json`:
    - kích thước dữ liệu, tỷ lệ nhãn, split; loss đầu/cuối, số epoch;
    - metrics tập test: model vs baseline (a) vs baseline (b);
    - **5 seed**: mean ± std accuracy/F1/AUC; **5-fold CV**;
    - **ablation** (bỏ từng nhóm feature → mức tụt metric); bảng calibration;
    - **distribution shift** (test trên dữ liệu sinh với tham số lệch);
    - exit code ≠ 0 nếu không đạt ngưỡng mục 5.
11. **`tool/verify_no_external_api.dart`**: quét `lib/domain/ai`, `lib/data/ai`, `lib/presentation/ai` và `pubspec.yaml`: không import `http`/`dio`/`dart:io` trong các thư mục AI; `domain/ai/core` không import `flutter`/`firebase`/`cloud_firestore`/`package:scrumflow/data/**`; không có chuỗi `openai`, `generativelanguage`, `anthropic`, `huggingface`, `api.` trong code AI; pubspec không có package ML (tflite, ml_kit, onnx...). In bảng PASS/FAIL.
12. **Unit test lõi:** gradient check bằng sai phân hữu hạn; hội tụ trên dữ liệu tách tuyến tính; cùng seed → cùng trọng số; sigmoid không NaN/inf với ±1e6; `Standardizer` phương sai 0; dataset rỗng/1 lớp không crash; metrics đúng ví dụ tính tay; AUC = 0.5 với dự đoán ngẫu nhiên, = 1.0 với hoàn hảo; `toJson/fromJson` round-trip; tổng đóng góp + bias = logit.
13. **Test ngẫu nhiên có seed** `test/domain/ai/ai_invariants_test.dart`: **≥ 500 kịch bản** (in seed khi fail): xác suất ∈ [0,1], không NaN, input cực đoan không crash, tính đơn điệu theo dấu trọng số đã học.

Commit: `feat(ai): pure-Dart ML core, synthetic history, eval + no-API verifier`.

---

## 5. NGƯỠNG CHẤP NHẬN (chốt TRƯỚC khi chạy, chép nguyên vào DECISIONS.md)

Trên **tập test giữ riêng (seed khác)**:
- ROC-AUC ≥ 0.75
- Accuracy ≥ accuracy baseline (a) + 5 điểm %
- AUC hoặc F1 của model > baseline (b)
- Độ lệch chuẩn AUC qua 5 seed ≤ 0.03
- `ai_invariants_test`: 0 vi phạm

Không đạt: được chỉnh model/feature/hyper-parameter tối đa **3 vòng**, mỗi vòng ghi DECISIONS (đổi gì, kết quả). **Cấm** đổi test seed, hạ ngưỡng, hay sửa quy luật generator cho dễ hơn. Vẫn không đạt → báo trung thực trong `EVAL_REPORT.md` và báo cáo cuối.

---

## 6. PHASE 2 — US-069: AI RISK RADAR

1. **`lib/data/ai/`:** `TaskRiskFeatureExtractor` (đọc `TaskModel` + story + sprint + `MemberPerformanceScore`; giá trị thiếu/null → mặc định có tài liệu, không crash), `AiModelStore` (lưu/đọc `LogisticRegression` + `Standardizer` + metrics + lịch sử loss + số mẫu synthetic/real theo `projectId` bằng `shared_preferences`, key có version, đọc hỏng → bỏ qua và huấn luyện lại).
2. **`RiskPredictionService`:** chưa có mô hình → huấn luyện nền trên bootstrap (dùng `compute`/isolate nếu > 50 ms), lưu, rồi suy luận thuần local.
3. **Cubit:** `TaskRiskCubit`, `SprintRiskCubit` — theo đúng khuôn `SprintDashboardCubit` (stream `taskRepository.streamTasksByStories`, chống stale token, timeout 15 s, nhận dependency qua constructor để test không đụng FirebaseAuth/Firestore).
4. **DI:** đăng ký thêm vào `MultiRepositoryProvider`/`MultiBlocProvider` trong `lib/main.dart` (chỉ thêm, không sửa dòng cũ), hoặc dựng trong widget như `SprintDashboardCard` nếu gọn hơn — chọn cách ít chạm file chung nhất.
5. **Phân quyền:** thêm vào `enum Permission`: `viewAiInsights` (PO, SM) và `manageAiModel` (PO, SM); cập nhật `role_permissions.dart` + test hiện có của nó (không làm vỡ test cũ). MEMBER không thấy tính năng AI.
6. **UI (mục 9):**
   - **Risk badge** trên thẻ Task (Kanban `tasks/`) và `TaskDetailScreen`: pill `Rủi ro 78%`.
   - **Bento card "AI Risk Radar"** trong Task Detail: %, 3 yếu tố đóng góp lớn nhất (thanh ngang +/−, nhãn tiếng Việt), nút "Xem giả lập".
   - **What-if** (bottom sheet): đổi người phụ trách / deadline → rủi ro tính lại tức thì ("Nếu giao cho X, rủi ro còn Y%"), tận dụng danh sách thành viên + `MemberPerformanceScore` của US-057.
   - **Danh sách task rủi ro cao** trong `sprint_detail_screen`, xếp giảm dần.
   - Trạng thái loading (`AppLoadingView`/`SkeletonList`), empty, error + "Thử lại", "Chưa đặt deadline".
7. **Test:** extractor (null/biên/chống rò rỉ), store (đọc hỏng, version), service, cubit (`bloc_test`), widget (badge, card, what-if), permission.

Commit: `feat(ai): US-069 task delay risk radar`.

---

## 7. PHASE 3 — US-071: AI MODEL LAB

`ModelLabScreen` (route mới trong `AppRoutes`, lối vào từ Project Detail; chỉ PO/SM qua `manageAiModel`):

1. **Thẻ dữ liệu:** số mẫu `synthetic` vs `real`, tỷ lệ nhãn, ngày huấn luyện, version, ghi chú giả định checkpoint cho mẫu real.
2. **Nút "Huấn luyện lại":** chạy isolate, **loss curve realtime** (Canvas, cùng phong cách `_BurndownPainter`), tiến độ epoch, không chặn UI.
3. **Metrics tập test:** accuracy, precision, recall, F1, AUC + **confusion matrix 2×2**.
4. **So sánh baseline:** "Luôn đoán đúng hạn" / "Công thức cứng US-057" / "Mô hình học từ dữ liệu".
5. **Feature importance:** thanh ngang theo |trọng số chuẩn hoá|, có dấu.
6. **Retrain với dữ liệu thật:** lấy task Done có deadline trong project làm mẫu `real` (quy tắc mục 4.9), gộp với bootstrap, hiển thị trước/sau. Nếu `real` quá ít (< 10) → hiển thị cảnh báo "dữ liệu thật còn ít".
7. **Tiện ích:** copy weights JSON; "Đặt lại mô hình mặc định".
8. **Test:** widget (loading/kết quả/lỗi), cubit (huấn luyện nhỏ, tái lập), responsive.

Commit: `feat(ai): US-071 model lab`.

---

## 8. PHASE 4 — US-070: AI SPRINT FORECAST (Monte Carlo)

1. **`SprintForecastService`** (lõi thuần Dart trong `domain/ai/core`, nhận số liệu thuần + `Random` + số lần mô phỏng mặc định 1000; adapter ở `data/ai` chuyển từ `SprintModel`/`UserStoryModel`):
   - Nguồn thông lượng theo thứ tự ưu tiên: (a) velocity các sprint đã đóng (quy tắc ở 3.6); (b) tốc độ burn theo ngày của sprint hiện tại từ `completedAt ?? updatedAt` của story Done; (c) prior mặc định có tài liệu + cờ "độ tin cậy thấp" hiện trên UI.
   - Mô phỏng: bootstrap thông lượng/ngày cho các ngày còn lại → phân phối điểm hoàn thành.
   - Đầu ra: `P(hoàn thành đúng hạn)`, ngày hoàn thành p10/p50/p90, điểm còn lại dự kiến.
2. **What-if loại Story:** tính lại khi bỏ từng Story chưa xong; top-3 Story nâng xác suất nhiều nhất ("41% → 73%").
3. **UI:** `SprintForecastCard` + **mở rộng `BurndownChartWidget`/painter hiện có bằng tham số tuỳ chọn `forecast` (mặc định null = hành vi cũ, test cũ phải xanh nguyên)**: dải p10–p90 tô nhạt, đường p50 nét đứt; đường thực tế 2.5px `#4F46E5`, đường lý tưởng chấm `#CBD5E1` như design. % hiển thị bằng font mono. Nút "Gợi ý điều chỉnh phạm vi" → bottom sheet what-if.
4. **`AiDemoDataSeeder`** (`lib/data/services/`, file mới): nạp dữ liệu để demo có đủ sắc thái — ~12 task (mix trạng thái/deadline/người phụ trách), 2–3 sprint đã `Completed` kèm story Done có `completedAt`. Thêm một mục menu cạnh mục nạp dữ liệu mẫu hiện có trong `project_detail_screen.dart` (thay đổi additive tối thiểu). Tuân thủ `firestore.rules` hiện tại. **Chỉ viết + test bằng mock; KHÔNG chạy trên Firebase thật** (người dùng sẽ tự bấm khi demo).
5. **Test:** xác định với cùng seed; xác suất ∈ [0,1]; đơn điệu (còn nhiều việc hơn → xác suất không tăng; nhiều ngày hơn → không giảm); `remaining = 0` → 1.0; `daysLeft = 0` còn việc → ≈ 0; không lịch sử → prior, không crash; hội tụ (1000 vs 10000 mô phỏng lệch ≤ vài %); `BurndownChartWidget` không truyền `forecast` → vẽ như cũ; không tràn layout.

Commit: `feat(ai): US-070 sprint forecast + demo seeder`.

---

## 9. DESIGN SYSTEM "KINETIC SPRINT"

Đọc `design.md` làm chuẩn. Tóm tắt:
- Màu: Primary `#4F46E5`, subdued `#EEF2FF`, Secondary `#0EA5E9`; canvas `#F8FAFC`, surface `#FFFFFF`, border `#E2E8F0`; text `#0F172A / #475569 / #94A3B8`.
- **Mức rủi ro → token status có sẵn:** thấp (<35%) = Done (`#047857` trên `#D1FAE5`); trung bình (35–65%) = In Progress (`#B45309` trên `#FEF3C7`); cao (>65%) = Blocker (`#B91C1C` trên `#FEE2E2`). Ngưỡng là hằng số ở 1 chỗ duy nhất.
- Card: trắng, viền 1px, **bo 14px**, padding 16px, khoảng cách nội dung 8px, lưới 8px. Pill: bo tròn full, cao 24px, `label-ui` chữ hoa.
- Font: Plus Jakarta Sans (tiêu đề), Inter (thân), **JetBrains Mono cho số liệu/%/mã US** — dùng cơ chế `google_fonts`/theme mà dự án đang dùng.
- Touch target ≥ 44×44; nút chính cao 48px bo 14px.
- **Dark mode bắt buộc:** lấy màu qua `AppColors`/`AppThemes`/`ThemeCubit`, không hard-code hex trong widget (hex trên chỉ là giá trị tham chiếu light mode).
- **Responsive:** chuẩn US-055 — không tràn ở 320×568 và 430×932, chữ ×1.3, khi bàn phím mở; dùng `ResponsiveLayout`.
- Chuyển trang/loading dùng bộ có sẵn (US-064).
- **Test widget không được đụng `FirebaseAuth`/Firestore thật** (đã từng gây lỗi, xem commit `c9e9553`): truyền dependency qua constructor/`maybeRead`.

---

## 10. PHASE 5 — HARDENING

1. Widget test responsive + dark mode cho mọi màn/card mới (320×568, 430×932, chữ ×1.3, bàn phím mở).
2. Offline: dịch vụ AI chạy khi mất mạng (nguồn dữ liệu từ cache); test xác nhận AI không phát sinh gọi mạng.
3. Hiệu năng (đo bằng test, ghi số thật): suy luận 1 task < 5 ms; mô phỏng 1000 lần < 300 ms; huấn luyện bootstrap không block UI thread.
4. `dart run tool/verify_no_external_api.dart` PASS; `dart run tool/ai_eval.dart` exit 0.
5. Toàn bộ `flutter analyze` + `flutter test`; số test ≥ baseline + mới.
6. (Tuỳ chọn, không chặn) `flutter build apk --debug` làm cổng biên dịch nếu có Android SDK; thất bại do môi trường thì ghi nhận, không tính là lỗi code.

Commit: `test(ai): hardening, responsive, offline, perf`.

---

## 11. PHASE 6 — TÀI LIỆU & BÀN GIAO

1. **`NguCanh.md`:** chỉ tick `[x]` US nào đã qua đủ cổng; điền mô tả "(Đã hoàn thành ngày ...: ...)" theo văn phong US cũ, số liệu thật; US BLOCKED giữ `[ ]` + lý do. Thêm mục nhật ký ngày làm việc. Cập nhật dòng tiến độ Sprint 5.
2. **Báo cáo kiểm thử:** thêm Test Case US-069/070/071 vào `docs/testing/test_cases.csv` và `BaoCaoKiemThu_US054.md` (auto = PASS thật; thủ công = `NOT RUN`).
3. **`docs/ai/MANUAL_CHECKLIST.md`:** 10–12 bước kiểm thử tay trên thiết bị Android thật bằng 4 mock user (Lê Phúc PO, Nguyễn Hiếu SM, Trần Thúy QA, Phạm Duy Dev), gồm bước bấm "Nạp dữ liệu demo AI".
4. **`docs/ai/DEFENSE.md`** (1–2 trang) từ số liệu thật của `EVAL_REPORT.md`:
   - Khác công thức cứng/if-else ở đâu (gradient descent học trọng số; so baseline).
   - Sao không dùng API (bằng chứng `verify_no_external_api`).
   - Dữ liệu đâu ra (bootstrap tổng hợp + retrain thật; nói thẳng; giải thích chống rò rỉ nhãn).
   - Sao tin kết quả (test riêng, 5 seed, CV, ablation, calibration, giải thích từng dự đoán).
   - Hạn chế trung thực (dữ liệu thật ít, mô hình tuyến tính, không có lịch sử đổi trạng thái nên không dựng feature theo thời gian, giả định Monte Carlo).
   - **Giải thích thuật toán từng bước dễ hiểu** (người dùng phải hiểu để trả lời vấn đáp): logistic regression, gradient descent, chuẩn hoá, Monte Carlo/bootstrap — mỗi mục 4–6 dòng + trỏ tới file/hàm tương ứng.
   - Kịch bản demo 3–4 phút: `dart run tool/ai_eval.dart` → Model Lab (huấn luyện + metrics) → Task Detail (rủi ro + giải thích + what-if) → Burndown dự báo (what-if dời Story) → `verify_no_external_api`.
5. **Báo cáo cuối trong chat** (ngắn): phase xong/BLOCKED, số test trước → sau, metrics chính, những gì CHƯA kiểm chứng, file quan trọng, lệnh demo, quyết định đáng chú ý. Không push.

Commit: `docs(ai): US-069/070/071 docs, test report, defense notes`.

---

## 12. CHECKLIST HOÀN TẤT (tự kiểm trước khi báo xong)

- [ ] Nhánh `feature/sprint5-ai-sprint-risk-radar` tách từ `origin/main`; mỗi phase một commit; không push; không stage `.idea/`, `android/`
- [ ] `git diff origin/main -- pubspec.yaml lib/data/datasources/local_cache_datasource.dart lib/data/repositories/task_repository.dart lib/data/repositories/backlog_repository_impl.dart firestore.rules` → rỗng
- [ ] `flutter analyze`: 0 error, không tăng issue so với baseline
- [ ] `flutter test`: toàn bộ xanh, số test ≥ baseline + mới
- [ ] `dart run tool/ai_eval.dart` exit 0, `EVAL_REPORT.md` có số thật
- [ ] `dart run tool/verify_no_external_api.dart` PASS
- [ ] ≥ 500 kịch bản ngẫu nhiên, 0 vi phạm; test chống rò rỉ nhãn xanh
- [ ] 3 màn/card mới đúng design, dark mode, responsive, chạy offline
- [ ] Tài liệu (`NguCanh.md`, báo cáo kiểm thử, `DEFENSE.md`, `MANUAL_CHECKLIST.md`) cập nhật trung thực