
# gr2 (Flutter)

Hướng dẫn nhanh để clone repo và chạy ứng dụng Flutter này trên thiết bị Android và iOS.

> Lưu ý: để build và chạy iOS bạn cần máy macOS với Xcode cài đặt sẵn.

## 1. Yêu cầu (Prerequisites)

- Git
- Flutter SDK (ổn định) — https://flutter.dev/docs/get-started/install
- Android Studio (hoặc Android SDK + platform-tools) để có adb và emulator
- (macOS only) Xcode và CocoaPods
- Java (JDK) nếu Android Studio chưa cài
- Thiết bị thật: Android (developer mode + USB debugging), iOS (trusted device, provisioning)

## 2. Clone repository

```powershell
cd C:\somewhere
git clone https://github.com/PhucAnh0502/mobile-supervisor-app.git gr2
cd gr2
```

## 3. Tạo file env theo mẫu của file env.example

## 4. Cài Flutter dependencies

```powershell
flutter --version
flutter pub get
```

Nếu bạn gặp lỗi về PATH, đảm bảo `flutter` có trong `PATH`.

## 5. Cấu hình Android (Windows/Linux)

- Mở Android Studio → SDK Manager → cài Android SDK, platform-tools, build-tools phù hợp
- Chấp nhận license:

```powershell
flutter doctor --android-licenses
```

- Kết nối thiết bị Android hoặc khởi động emulator

Kiểm tra thiết bị:

```powershell
flutter devices
```

Chạy app trên thiết bị/emulator:

```powershell
flutter run
# hoặc chọn device cụ thể
flutter run -d <deviceId>
```

Build APK để cài thủ công:

```powershell
flutter build apk --release
# file: build/app/outputs/flutter-apk/app-release.apk
```

## 6. Cấu hình iOS (macOS only)

- Cài Xcode từ App Store
- Cài CocoaPods nếu chưa có:

```bash
sudo gem install cocoapods
```

- Trong thư mục `ios`:

```bash
cd ios
pod install
cd ..
```

- Mở workspace bằng Xcode nếu cần cấu hình signing: `ios/Runner.xcworkspace`
- Kết nối thiết bị iOS thật, chọn team/provisioning trong Xcode (Signing & Capabilities)

Chạy app trên thiết bị từ terminal:

```bash
flutter devices
flutter run -d <ios-device-id>
```

Build archive / ipa (cần cấu hình signing):

```bash
flutter build ipa --export-method ad-hoc
```

## 7. Lưu ý về môi trường và biến PATH

- Thêm Flutter `bin` vào PATH trên Windows (System Environment Variables)
- Thêm Android `platform-tools` (chứa adb) vào PATH

## 8. Thao tác hữu ích & debug

- Kiểm tra tình trạng môi trường:

```powershell
flutter doctor -v
```

- Làm sạch build:

```powershell
flutter clean
flutter pub get
```

- Xem logs runtime:

```powershell
flutter logs -d <deviceId>
```

## 9. Vấn đề phổ biến

- `pod install` lỗi → thử `pod repo update` rồi `pod install`.
- Lỗi signing iOS → mở `ios/Runner.xcworkspace` bằng Xcode và chọn team đúng, đảm bảo provisioning profile hợp lệ.
- Thiết bị không hiện trong `flutter devices` → kiểm tra USB debugging (Android) hoặc trust this computer (iOS), và adb/idevice đã cài.

## 10. Tài nguyên hữu ích

- Flutter docs: https://flutter.dev/docs
- Troubleshooting Android: https://developer.android.com/studio
- iOS signing: https://developer.apple.com/support/


