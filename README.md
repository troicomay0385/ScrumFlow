# ScrumFlow

Ứng dụng Flutter quản lý dự án theo Scrum.

## Môi trường cần thiết

- Flutter SDK tương thích Dart `^3.12.0` trong `pubspec.yaml`.
- JDK 17 và Android SDK để chạy Android.
- Visual Studio với workload **Desktop development with C++** để build Windows desktop.

## Developer Mode: khi nào cần?

**Developer Mode của Windows và Developer options của Android là hai cài đặt khác nhau.**

- **Android Emulator:** không cần bật Developer Mode của Windows hay Developer options trên điện thoại. Cài Android Studio/Android SDK, khởi động emulator và chạy `flutter run`.
- **Điện thoại Android thật qua USB:** bật **Developer options** và **USB debugging** trên điện thoại, sau đó xác nhận kết nối máy tính. Đây là yêu cầu để ADB cài/chạy bản debug, không phải yêu cầu khi sử dụng app đã cài.
- **Windows desktop:** Developer Mode thường không cần. Chỉ bật nếu Flutter báo thiếu quyền tạo symlink/plugin; thay vào đó có thể cấp quyền phù hợp. Cần Windows desktop toolchain, và một số plugin Firebase/Google Sign-In có thể không hỗ trợ Windows đầy đủ.
- **APK Android phát hành:** người dùng không cần bật Developer options để chạy ứng dụng. Firebase/Google Sign-In vẫn cần cấu hình đúng.

## Cài đặt và chạy

PowerShell:

```powershell
git clone https://github.com/troicomay0385/ScrumFlow.git
cd ScrumFlow
flutter pub get
flutter doctor
flutter devices
```

### Android Emulator hoặc điện thoại Android

Cấu hình Firebase Android rồi chạy `flutter run` hoặc chọn thiết bị trong IDE. Điện thoại thật cần bật USB debugging.

### Windows desktop

```powershell
flutter run -d windows
```

Nếu Windows chưa được bật làm target Flutter desktop, chạy `flutter config --enable-windows-desktop`, sau đó kiểm tra bằng `flutter doctor`.

## Cấu hình Firebase Android

Ứng dụng dùng Firebase Authentication và Cloud Firestore. `android/app/google-services.json` phải thuộc Firebase project/package Android đúng. Để dùng Google Sign-In, thêm SHA-1 của debug/release signing key tương ứng vào Firebase Console rồi tải lại file cấu hình.

Lấy SHA-1 debug trên Windows:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

## Xử lý sự cố

```powershell
flutter clean
flutter pub get
flutter doctor
```

Nếu ADB không thấy điện thoại, kiểm tra USB debugging/ADB. Nếu Windows desktop gặp lỗi plugin hoặc symlink, kiểm tra toolchain và quyền tạo symlink như hướng dẫn Developer Mode phía trên.
