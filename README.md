# Radar Saku 📡💸

**Radar Saku** adalah aplikasi pelacak keuangan pribadi berbasis *mobile* (Android & iOS) yang dibangun menggunakan Flutter. Aplikasi ini dirancang dengan arsitektur *offline-first*, memungkinkan Anda untuk mencatat pengeluaran dan pemasukan kapan saja tanpa harus selalu terhubung ke internet, lalu otomatis melakukan sinkronisasi ketika perangkat kembali *online*.

## Fitur Utama ✨
- **Pencatatan Transaksi:** Catat pemasukan, pengeluaran, dan transaksi netral dengan mudah.
- **Manajemen Dompet:** Dukungan multi-dompet (misalnya: Dompet Utama, Rekening Bank, E-Wallet) untuk memisahkan alokasi dana.
- **Kategori Transaksi:** Kelompokkan transaksi Anda menggunakan kategori yang dapat dikustomisasi (mis. Makanan, Transportasi, Gaji).
- **Offline-First & Auto Sync:** Semua data disimpan ke dalam *database* lokal (SQLite) terlebih dahulu. Saat internet tersedia, aplikasi akan menyinkronkan data secara otomatis ke *server* di latar belakang.
- **Dashboard & Analitik:** Ringkasan saldo dan transaksi terkini dengan antarmuka pengguna yang modern dan responsif.
- **Filter Pencarian Lengkap:** Cari dan filter riwayat transaksi berdasarkan tanggal, rentang waktu, dompet, jenis transaksi, maupun kategori.

## Teknologi yang Digunakan 🛠️
- **Framework:** [Flutter](https://flutter.dev/) (SDK ^3.9.2)
- **State Management:** `provider`
- **Local Database:** `sqflite` (SQLite)
- **HTTP Client:** `http`
- **Offline Sync & Network:** `connectivity_plus`
- **UI/UX & Styling:** Material Design 3, `google_fonts`
- **Lainnya:** `shared_preferences` (Autentikasi & Config), `ulid` (Unique IDs), `flutter_dotenv` (Environment Variables)

## Struktur Folder 📂
```
lib/
├── core/           # Konstanta, konfigurasi tema, formatters, dan utility
├── database/       # Konfigurasi SQLite dan inisialisasi tabel lokal
├── models/         # Data class (Transaction, Wallet, Category, dll.)
├── providers/      # State management (Auth, Transaction, Wallet, Sync, dll.)
├── screens/        # UI aplikasi (Dashboard, Auth, Transaction Forms, Settings)
├── services/       # Integrasi API dan background sync manager
└── main.dart       # Entry point aplikasi
```

## Cara Menjalankan Project 🚀

### 1. Prasyarat
- Pastikan Anda sudah menginstal Flutter SDK (versi 3.9.2 atau lebih baru).
- Siapkan *emulator* Android/iOS atau sambungkan perangkat fisik Anda.

### 2. Kloning Repositori
```bash
git clone https://github.com/assidiqi-git/Mobile-Radar-Saku.git
cd mobile_radar_saku
```

### 3. Instalasi Dependensi
Jalankan perintah berikut untuk mengunduh semua pustaka yang dibutuhkan:
```bash
flutter pub get
```

### 4. Konfigurasi Environment (Lingkungan)
Buat file bernama `.env` di direktori utama proyek (sejajar dengan `pubspec.yaml`), lalu isi dengan base URL API Anda:
```env
API_BASE_URL=https://api.domain-anda.com/api/v1
```

### 5. Jalankan Aplikasi
```bash
flutter run
```

## Membangun APK / Rilis 📦
Untuk membuat *file* instalasi Android (APK):
```bash
flutter build apk --release
```
Untuk rilis iOS (membutuhkan macOS dan Xcode):
```bash
flutter build ipa --release
```

## Lisensi 📄
Proyek ini dibuat untuk kebutuhan internal / portofolio. Hak cipta dilindungi.
