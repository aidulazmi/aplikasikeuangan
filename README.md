# DompetKu – Pencatatan Keuangan dengan OCR

Struktur:
- `backend/` → REST API Node.js + MySQL (login, transaksi, kategori, anggaran, upload struk, ekspor CSV)
- `app/`     → Aplikasi Flutter (Android/iOS)

## 1. Database & Backend
```bash
mysql -u root -p < backend/schema.sql
cd backend
cp .env.example .env     # isi DB_PASSWORD dan JWT_SECRET
npm install
npm start                # http://localhost:3000
```

## 2. Aplikasi Flutter
```bash
cd app
flutter create . --org com.dompetku --project-name dompetku   # membuat folder android/ios (file lib/ & pubspec.yaml tidak ditimpa)
flutter pub get
flutter run
```

### Android – wajib
`android/app/build.gradle(.kts)` → `minSdk = 23`

`android/app/src/main/AndroidManifest.xml`, sebelum `<application>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
```
dan pada tag `<application ...>` tambahkan `android:usesCleartextTraffic="true"` (agar bisa http saat pengembangan).

### iOS – wajib
`ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key><string>Untuk memotret struk</string>
<key>NSPhotoLibraryUsageDescription</key><string>Untuk mengimpor gambar struk</string>
```

### Alamat server
- Emulator Android: `http://10.0.2.2:3000` (default)
- HP fisik: `http://IP-KOMPUTER:3000` (satu Wi-Fi) → ubah lewat **Pengaturan server** di layar login / menu Pengaturan.
