# Radar Saku — Project Summary & Konteks untuk Diskusi AI
> Dokumen ini dibuat sebagai materi pengenalan project ke AI (Gemini) untuk mendiskusikan rencana pengembangan lebih lanjut.
> Diperbarui: Juni 2026

---

## 1. Gambaran Umum

**Radar Saku** adalah aplikasi pelacak keuangan pribadi (*personal finance tracker*) berbasis mobile (Android & iOS), dibangun menggunakan **Flutter**. Konsep utamanya adalah **offline-first** — semua data disimpan secara lokal di SQLite, dan disinkronkan secara otomatis ke server Laravel REST API ketika perangkat terhubung ke internet.

### Tagline
> *"Catat keuanganmu kapan saja, di mana saja — tanpa butuh internet."*

---

## 2. Arsitektur Aplikasi

### 2.1 Pola Arsitektur
Aplikasi mengadopsi pola **Offline-First Architecture** dengan lapisan berikut:

```
┌─────────────────────────────────────────────┐
│              UI Layer (Screens)             │
│  (Membaca HANYA dari SQLite lokal)          │
├─────────────────────────────────────────────┤
│           State Management Layer            │
│         (Provider — ChangeNotifier)         │
├─────────────────────────────────────────────┤
│            Local Database Layer             │
│       (SQLite via sqflite — sumber kebenaran)│
├──────────────────────┬──────────────────────┤
│    Sync Layer        │   API Layer          │
│  (SyncManager)       │  (ApiService)        │
│  Push & Pull delta   │  HTTP REST calls     │
└──────────────────────┴──────────────────────┘
              ↕ Network (optional)
┌─────────────────────────────────────────────┐
│          Laravel REST API (Backend)         │
└─────────────────────────────────────────────┘
```

### 2.2 Prinsip Kunci
- **SQLite sebagai sumber kebenaran (single source of truth)** — UI tidak pernah membaca langsung dari API.
- **Sinkronisasi delta (incremental)** — hanya data yang berubah sejak `last_synced_at` yang ditransfer.
- **Batch sync hingga 500 transaksi** per request push.
- **Quarantine system** — transaksi yang gagal sync (error 422) ditandai `sync_status = 'error'` dan ditampilkan ke user dengan badge error, bukan dibuang.
- **ULID sebagai Primary Key** — digunakan agar ID bisa di-generate di sisi client sebelum tersinkronisasi ke server.

### 2.3 Struktur Folder
```
mobile_radar_saku/
├── lib/
│   ├── core/
│   │   ├── app_router.dart          # Routing terpusat (named routes)
│   │   ├── constants/
│   │   │   └── app_constants.dart   # Konstanta global (table names, sync status, dll.)
│   │   ├── theme/
│   │   │   └── app_theme.dart       # Design system (warna, tipografi, komponen)
│   │   └── utils/
│   │       ├── formatters.dart      # Format tanggal, mata uang (Rupiah)
│   │       └── ulid_generator.dart  # Helper generate ULID baru
│   ├── database/
│   │   └── database_helper.dart     # Singleton SQLite — inisialisasi & helper CRUD
│   ├── models/
│   │   ├── transaction.dart         # Model transaksi (income/expense/neutral)
│   │   ├── transaction_category.dart
│   │   ├── transaction_type.dart
│   │   ├── transfer.dart            # Model transfer antar-dompet
│   │   ├── user.dart
│   │   └── wallet.dart
│   ├── providers/                   # State management (ChangeNotifier)
│   │   ├── auth_provider.dart       # Auth state, login, register, logout
│   │   ├── sync_provider.dart       # Status sinkronisasi (pending/error count)
│   │   ├── transaction_provider.dart
│   │   ├── transaction_category_provider.dart
│   │   ├── transaction_type_provider.dart
│   │   └── wallet_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── sync_screen.dart    # Initial sync setelah login pertama
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── transaction/
│   │   │   ├── add_transaction_screen.dart
│   │   │   ├── all_transactions_screen.dart
│   │   │   └── transaction_detail_screen.dart
│   │   ├── wallet/
│   │   │   └── wallets_screen.dart
│   │   ├── transfer/
│   │   │   └── transfer_screen.dart
│   │   ├── settings/               # Manajemen tipe & kategori transaksi
│   │   │   ├── transaction_type_list_screen.dart
│   │   │   ├── transaction_type_form_screen.dart
│   │   │   ├── transaction_category_list_screen.dart
│   │   │   └── transaction_category_form_screen.dart
│   │   ├── profile/
│   │   │   └── profile_sync_screen.dart  # Profil + status sync manual
│   │   └── components/             # Shared UI components
│   └── services/
│       ├── api_service.dart         # HTTP client (semua endpoint REST API)
│       ├── connectivity_service.dart # Monitor status jaringan
│       ├── initial_sync_service.dart # Sync penuh saat login pertama
│       ├── sync_manager.dart        # Logika push & pull delta
│       └── widget_service.dart      # Kirim data ke Android Home Screen Widget
└── main.dart                        # Entry point aplikasi
```

---

## 3. Package / Library yang Digunakan

### 3.1 Dependencies Utama

| Package | Versi | Fungsi |
|---|---|---|
| `flutter` | SDK | Framework utama |
| `provider` | ^6.1.5+1 | State management (ChangeNotifier pattern) |
| `sqflite` | ^2.4.2 | SQLite — database lokal offline |
| `http` | ^1.6.0 | HTTP client untuk REST API calls |
| `connectivity_plus` | ^7.1.1 | Monitor status koneksi internet |
| `shared_preferences` | ^2.5.5 | Simpan auth token & user data secara persisten |
| `flutter_dotenv` | ^6.0.1 | Baca konfigurasi dari file `.env` |
| `google_fonts` | ^6.2.1 | Tipografi Google Fonts |
| `intl` | ^0.19.0 | Format tanggal & angka (locale `id_ID`) |
| `ulid` | ^2.0.1 | Generate ULID sebagai primary key di sisi client |
| `path` | ^1.9.0 | Utilitas path untuk SQLite |
| `path_provider` | ^2.1.5 | Akses direktori penyimpanan perangkat |
| `home_widget` | ^0.9.2 | Android & iOS Home Screen Widget |

### 3.2 Dev Dependencies

| Package | Fungsi |
|---|---|
| `flutter_lints` | Linting & code style |
| `flutter_launcher_icons` | Generate app icon untuk Android & iOS |

### 3.3 Flutter SDK Version
```
environment:
  sdk: ^3.9.2
```

---

## 4. Database Lokal (SQLite)

### 4.1 Info Database
- **Nama file**: `radar_saku.db`
- **Versi saat ini**: `3` (ada migrasi dari v1 → v2 → v3)
- **Foreign Keys**: Diaktifkan via `PRAGMA foreign_keys = ON`

### 4.2 Skema Tabel

#### `users`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | TEXT PK | ULID dari server |
| `name` | TEXT | Nama pengguna |
| `email` | TEXT | Email |
| `email_verified_at` | TEXT | Timestamp verifikasi |
| `created_at` | TEXT | |
| `updated_at` | TEXT | |

#### `wallets`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | TEXT PK | ULID |
| `name` | TEXT | Nama dompet |
| `type` | TEXT | `checking`, `savings`, `cash`, `investment` |
| `balance` | TEXT | Saldo (disimpan sebagai string) |
| `created_at` | TEXT | |
| `updated_at` | TEXT | |
| `deleted_at` | TEXT | Soft delete |

#### `transaction_types`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | TEXT PK | ULID |
| `name` | TEXT | Nama tipe (mis. "Pengeluaran") |
| `action` | TEXT | `addition`, `deduction`, `neutral` |
| `description` | TEXT | Opsional |
| `sync_status` | TEXT | `pending`, `synced`, `error` |
| `sync_error_message` | TEXT | Pesan error sync |
| `created_at` | TEXT | |
| `updated_at` | TEXT | |
| `deleted_at` | TEXT | Soft delete |

#### `transaction_categories`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | TEXT PK | ULID |
| `transaction_type_id` | TEXT FK | → `transaction_types.id` (CASCADE DELETE) |
| `name` | TEXT | Nama kategori (mis. "Makanan") |
| `description` | TEXT | Opsional |
| `sync_status` | TEXT | `pending`, `synced`, `error` |
| `sync_error_message` | TEXT | |
| `created_at` | TEXT | |
| `updated_at` | TEXT | |
| `deleted_at` | TEXT | Soft delete |

#### `transactions` *(Tabel utama)*
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | TEXT PK | ULID — di-generate di sisi client |
| `wallet_id` | TEXT FK | → `wallets.id` |
| `transaction_category_id` | TEXT FK | → `transaction_categories.id` |
| `name` | TEXT | Nama/deskripsi transaksi |
| `amount` | TEXT | Nominal (string) |
| `note` | TEXT | Catatan opsional |
| `photo_url` | TEXT | URL foto struk (maks 2 MB) |
| `sync_status` | TEXT | `pending`, `synced`, `error` |
| `sync_error_message` | TEXT | Pesan error |
| `created_at` | TEXT | |
| `updated_at` | TEXT | |
| `deleted_at` | TEXT | Soft delete |

**Indexes yang dibuat:**
- `idx_transactions_wallet_id`
- `idx_transactions_sync_status`
- `idx_transactions_deleted_at`
- `idx_tx_categories_type_id`

#### `transfers`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | TEXT PK | ULID |
| `from_wallet_id` | TEXT FK | → `wallets.id` |
| `to_wallet_id` | TEXT FK | → `wallets.id` |
| `amount` | TEXT | Nominal |
| `fee` | TEXT | Biaya transfer (default `0`) |
| `transfer_date` | TEXT | Tanggal transfer |
| `note` | TEXT | Opsional |
| `sync_status` | TEXT | `pending`, `synced`, `error` |
| `sync_error_message` | TEXT | |
| `created_at` | TEXT | |
| `updated_at` | TEXT | |
| `deleted_at` | TEXT | Soft delete |

#### `sync_meta`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `key` | TEXT PK | Nama kunci (mis. `last_synced_at`) |
| `value` | TEXT | Nilai timestamp ISO 8601 |

---

## 5. Mekanisme Sinkronisasi (Offline-First)

### 5.1 Alur Kerja Sync

```
USER ACTION (tambah/edit transaksi)
       ↓
Simpan ke SQLite lokal
  → sync_status = 'pending'
       ↓
ConnectivityService mendeteksi internet
       ↓
SyncManager.sync() dipanggil
   ├── push(): Kirim 'pending' transactions ke POST /sync/transactions
   │     ├── Sukses → sync_status = 'synced'
   │     └── Gagal 422 → sync_status = 'error' (quarantine, tampil di UI)
   └── pull(): GET /sync/transactions/pull?last_synced_at=...
         └── Merge data dari server → update last_synced_at di sync_meta
```

### 5.2 Initial Sync (Login Pertama)
Setelah login berhasil, `InitialSyncService` menarik **semua data** dari server:
1. `GET /wallets` (semua halaman)
2. `GET /transaction-types` (semua halaman)
3. `GET /transaction-categories` (semua halaman)
4. `GET /sync/transactions/pull` (semua transaksi)

### 5.3 Status Sinkronisasi
| Status | Arti |
|---|---|
| `pending` | Disimpan lokal, belum dikirim ke server |
| `synced` | Berhasil tersinkronisasi ke server |
| `error` | Gagal sync (422), perlu perhatian user |

---

## 6. Integrasi API (Backend Laravel)

### 6.1 Konfigurasi
- Base URL dibaca dari file `.env`: `API_BASE_URL=https://api.domain.com/api/v1`
- Autentikasi: **Bearer Token** (disimpan di `SharedPreferences`)
- Header kustom: `X-Client-Type: mobile` (untuk membedakan request mobile vs web)
- Dukungan ngrok: Header `ngrok-skip-browser-warning: true` untuk development

### 6.2 Endpoint yang Dikonsumsi

**Auth:**
- `POST /login` — Login, returns `token` + `user`
- `POST /register` — Registrasi
- `POST /logout`
- `GET /user`

**Wallets:**
- `GET /wallets` (paginated)
- `POST /wallets`
- `PUT /wallets/{id}`
- `DELETE /wallets/{id}`

**Transaction Types:**
- `GET /transaction-types` (paginated)
- `POST /transaction-types`
- `PUT /transaction-types/{id}`
- `DELETE /transaction-types/{id}`

**Transaction Categories:**
- `GET /transaction-categories` (paginated)
- `POST /transaction-categories`
- `PUT /transaction-categories/{id}`
- `DELETE /transaction-categories/{id}`

**Sync (Inti):**
- `POST /sync/transactions` — Push batch max 500
- `GET /sync/transactions/pull?last_synced_at=` — Pull delta

**Transfers:**
- `POST /transfers`

### 6.3 Error Handling di API
- `401` → `AuthException` — redirect ke login
- `422` → `ValidationException` — tampilkan field errors
- Non-JSON response → ditangkap dan ditampilkan pesan error yang ramah

---

## 7. State Management (Provider)

Semua provider di-inject di root `MaterialApp` menggunakan `MultiProvider`:

| Provider | Fungsi |
|---|---|
| `AuthProvider` | Status autentikasi, login, register, logout |
| `WalletProvider` | CRUD dompet, update saldo |
| `TransactionProvider` | CRUD transaksi, filter, load dashboard data |
| `TransactionTypeProvider` | CRUD tipe transaksi |
| `TransactionCategoryProvider` | CRUD kategori transaksi |
| `SyncProvider` | Status sync (pending count, error count, trigger manual sync) |

`ChangeNotifierProxyProvider` digunakan untuk meneruskan state `AuthProvider` ke semua provider lain, sehingga mereka bisa bereaksi ketika user login/logout.

---

## 8. Routing Aplikasi

Routing menggunakan **named routes** dengan animasi transisi kustom:

| Route | Screen | Transisi |
|---|---|---|
| `/` | Splash Gate (cek auth) | Default |
| `/login` | Login Screen | Slide kanan |
| `/register` | Register Screen | Slide kanan |
| `/initial-sync` | Initial Sync Screen | Fade |
| `/dashboard` | Dashboard Screen | Fade |
| `/add-transaction` | Add Transaction Screen | Slide bawah (bottom sheet style) |
| `/all-transactions` | All Transactions Screen | Slide kanan |
| `/transaction-detail` | Transaction Detail Screen | Slide kanan |
| `/wallets` | Wallets Screen | Slide kanan |
| `/transfer` | Transfer Screen | Slide kanan |
| `/profile` | Profile & Sync Screen | Slide kanan |

---

## 9. Fitur Unggulan

### 9.1 Fitur yang Sudah Diimplementasi
- ✅ Autentikasi (Login & Register)
- ✅ Manajemen multi-dompet (Checking, Savings, Cash, Investment)
- ✅ Pencatatan transaksi (income/expense/neutral)
- ✅ Transfer antar dompet (dengan biaya transfer)
- ✅ Manajemen tipe & kategori transaksi (CRUD kustom)
- ✅ Dashboard dengan ringkasan saldo & transaksi terkini
- ✅ Riwayat semua transaksi dengan filter & pencarian
- ✅ Detail transaksi
- ✅ Offline-first + auto sync
- ✅ Sinkronisasi delta (incremental) dengan `last_synced_at`
- ✅ Quarantine system untuk transaksi yang gagal sync
- ✅ Validasi form yang ketat (sesuai OpenAPI spec)
- ✅ Validasi saldo tidak mencukupi sebelum transaksi
- ✅ **Android Home Screen Widget** (State login/logout + daftar transaksi terkini)
- ✅ Connectivity-aware auto sync

### 9.2 Home Screen Widget (Fitur Terbaru)
Widget Android yang menampilkan:
- **State A (Logged Out):** Pesan login + tombol "Login"
- **State B (Logged In):** Daftar 3-5 transaksi terkini + tombol "Tambah Transaksi" ("+")

Deep link scheme: `radarsaku://login` dan `radarsaku://add_transaction`

Data dikirim via `HomeWidget.saveWidgetData` → dibaca oleh `RadarSakuWidgetProvider` (Kotlin) di sisi Android native.

---

## 10. Konfigurasi & Environment

### 10.1 File `.env`
```env
API_BASE_URL=https://api.domain-anda.com/api/v1
```

### 10.2 App Icon
- Sumber: `assets/icon_tanpa_bg.png`
- Background Adaptive Icon Android: `#0A192F` (dark navy)
- Dikelola via `flutter_launcher_icons`

### 10.3 Locale
- Bahasa UI: **Bahasa Indonesia**
- Format tanggal: locale `id_ID` via `intl`

### 10.4 iOS Home Widget
- App Group ID: `group.radarsaku`

---

## 11. Catatan Teknis Penting

### 11.1 Primary Key (ULID)
- Semua ID menggunakan **ULID** (Universally Unique Lexicographically Sortable Identifier)
- Di-generate di sisi **client (Flutter)** sebelum data disimpan lokal
- Ini memungkinkan data tersimpan offline tanpa menunggu ID dari server
- Kolom ID di SQLite menggunakan tipe `TEXT`

### 11.2 Soft Delete
- Semua tabel utama memiliki kolom `deleted_at`
- Data tidak dihapus fisik, hanya diberi timestamp pada `deleted_at`

### 11.3 Saldo Dompet
- Saldo disimpan sebagai `TEXT` di SQLite (untuk menghindari floating-point issues)
- Dikonversi ke `double` saat di-parsing oleh model

### 11.4 Sync Batch Size
- Maksimum **500 transaksi** per push request
- Mencegah timeout untuk pengguna dengan banyak data offline

### 11.5 Database Migrations
- **v1 → v2**: Mengganti `synced_at` dengan `sync_status` + `sync_error_message` pada tabel `transactions` dan `transfers`
- **v2 → v3**: Menambahkan `sync_status`, `sync_error_message`, dan `deleted_at` pada tabel `transaction_types` dan `transaction_categories`

---

## 12. Rencana Pengembangan (Dari File .plan)

Berdasarkan file rencana yang ada di folder `.plan/`, berikut fitur-fitur yang sudah direncanakan atau sedang dalam progres:

| Rencana | Status |
|---|---|
| Connectivity-Aware Auto Sync | ✅ Sudah diimplementasi |
| CRUD Tipe & Kategori Transaksi | ✅ Sudah diimplementasi |
| Perbaikan mekanisme save data | ✅ Sudah diimplementasi |
| Android Home Screen Widget | ✅ Sudah diimplementasi |
| Screen Detail Transaksi | ✅ Sudah diimplementasi |
| Validasi form yang ketat | ✅ Sudah diimplementasi |
| Validasi saldo tidak mencukupi | ✅ Sudah diimplementasi |
| Screen Semua Transaksi | ✅ Sudah diimplementasi |
| Perbaikan visual list transaksi | ✅ Sudah diimplementasi |
| Pull data pertama (initial sync) | ✅ Sudah diimplementasi |
| Validasi input hanya angka | ✅ Sudah diimplementasi |

---

## 13. Stack Teknologi Ringkas

```
┌─ Mobile App ──────────────────────────────────┐
│  Framework:    Flutter (Dart) SDK ^3.9.2       │
│  State:        Provider (ChangeNotifier)        │
│  DB Lokal:     SQLite (sqflite v2.4.2)         │
│  Primary Key:  ULID                             │
│  HTTP:         http package                     │
│  Network Mon:  connectivity_plus               │
│  Auth Storage: SharedPreferences               │
│  Widget:       home_widget (Android & iOS)     │
│  Fonts:        Google Fonts                     │
│  Env:          flutter_dotenv (.env file)       │
└────────────────────────────────────────────────┘
              ↕ REST API (Bearer Token)
┌─ Backend ─────────────────────────────────────┐
│  Framework:    Laravel (PHP)                   │
│  API Style:    REST + JSON                     │
│  Auth:         Sanctum / Token-based           │
│  Sync:         Delta sync via `last_synced_at` │
└────────────────────────────────────────────────┘
```

---

*Dokumen ini mencakup seluruh arsitektur, dependensi, skema database, mekanisme sync, dan fitur yang ada pada project Radar Saku per Juni 2026. Gunakan dokumen ini sebagai konteks ketika berdiskusi dengan AI untuk merencanakan pengembangan fitur baru.*
