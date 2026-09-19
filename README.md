🛠️ Yêu cầu môi trường (Tested Environment)
- **Flutter SDK**: 3.x trở lên
- **Java/JDK**: JDK 17 (Khuyên dùng OpenJDK / Eclipse Adoptium 17)
- **Android SDK**: API 33 (Android 13) trở lên
- **Hệ điều hành**: Windows 10/11 *(Lưu ý: Bật **Developer Mode** trong Windows Settings)*

---

## 🚀 Các bước cài đặt & chạy dự án

### Bước 1: Clone dự án & Tải thư viện
Mở Terminal / PowerShell và chạy:
```bash
git clone [https://github.com/troicomay0385/ScrumFlow.git](https://github.com/troicomay0385/ScrumFlow.git)
cd ScrumFlow
flutter pub get
Bước 2: Cấu hình Firebase
Lấy file google-services.json từ Firebase Console (hoặc từ trưởng nhóm) và đặt vào đúng đường dẫn:
android/app/google-services.json

Bước 3: Lấy mã SHA-1 cho Google Sign-In
Chạy lệnh sau trong PowerShell để lấy mã SHA-1 máy của bạn:

PowerShell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
(Hoặc vào thư mục android/ và chạy: .\gradlew signingReport)

👉 Sao chép chuỗi SHA1 thu được dán vào Firebase Console (Project Settings -> SHA certificate fingerprints).

Bước 4: Khởi chạy ứng dụng
Cách 1 (Bằng Android Studio): Mở dự án -> Bật máy ảo Android -> Bấm nút Play ▶️ (Run).

Cách 2 (Bằng Terminal): Chạy lệnh flutter run.

💡 Xử lý sự cố nhanh (Troubleshooting)
Khi gặp lỗi build hoặc đổi máy làm việc, chạy lệnh sau để dọn dẹp cache:

Bash
flutter clean
flutter pub get