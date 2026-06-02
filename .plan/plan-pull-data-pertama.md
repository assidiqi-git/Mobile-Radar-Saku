## Context & Role

Kamu adalah AI Native Engineer dan Expert Flutter Developer. Saya sedang mengembangkan aplikasi pencatat keuangan bernama "Radar Saku" dengan arsitektur offline-first (Flutter di frontend dengan SQLite lokal, dan Laravel 13 di backend dengan database MySQL). Aplikasi menggunakan pendekatan di mana klien mobile menghasilkan ULID untuk setiap record (seperti transaksi) sebelum disinkronkan ke server.

## Task

Buatkan implementasi `Dedicated Sync Screen` di Flutter. Layar ini akan dipanggil tepat setelah pengguna berhasil login dan mendapatkan Bearer token, tetapi sebelum mereka diarahkan ke layar `Dashboard`. Tujuannya adalah melakukan inisialisasi data awal (menarik data dari server ke SQLite lokal) dengan UX yang informatif.

---

## Langkah Sinkronisasi Data (Sesuai OpenAPI Spec)

Layar ini harus menjalankan fungsi asynchronous yang melakukan langkah-langkah fetch API berikut secara berurutan atau paralel menggunakan `Future.wait`:

### 1. Tarik Data Master

- Panggil `GET /wallets` untuk mendapatkan daftar dompet.
- Panggil `GET /transaction-types` untuk mendapatkan tipe transaksi (income, outcome, saving, dll).
- Panggil `GET /transaction-categories` untuk mendapatkan kategori transaksi.

### 2. Tarik Data Transaksi (Initial Full Sync)

- Panggil `GET /sync/transactions/pull`.
- Jangan sertakan parameter `last_synced_at` karena ini adalah sinkronisasi pertama kali.
- Simpan timestamp dari `updated_at` data terakhir yang diterima untuk keperluan delta sync di masa mendatang.

### 3. (Opsional/Safety Net) Push Data Lokal

- Jika entah bagaimana ada data transaksi lokal yang belum tersinkronisasi, gunakan `POST /sync/transactions` dengan payload JSON berisi array transaksi beserta ULID-nya.

---

## Requirements UI/UX

- Layar tidak boleh memiliki `AppBar` dan tidak bisa di-back (`WillPopScope` / `PopScope` dinonaktifkan).
- Tampilkan teks loading yang dinamis dan ramah, misalnya: "Menyiapkan Catatan Anda...", lalu berubah menjadi "Mengunduh data dompet...", "Menyinkronkan transaksi...", dll sesuai proses yang sedang berjalan.
- Gunakan `LinearProgressIndicator` atau `CircularProgressIndicator`. Jika memungkinkan, buat persentase progres berdasarkan step API yang selesai (misalnya **25%**, **50%**, **75%**, **100%**).
- Setelah seluruh fungsi sync mengembalikan nilai `true` / selesai, gunakan `Navigator.pushReplacement` atau router yang setara untuk memindahkan pengguna ke `DashboardScreen`.

---

## Requirements Code Structure

- Gunakan pola arsitektur yang rapi (pisahkan logic sync ke Service atau Repository tersendiri, bukan di dalam blok UI widget).
- Sertakan error handling (`try-catch`). Jika sync gagal (misalnya karena timeout jaringan), tampilkan pesan error dan tombol "Coba Lagi", tetapi sediakan juga tombol "Lewati" jika Anda ingin mengizinkan pengguna tetap masuk ke dashboard dengan status data kosong.

> **Tolong berikan kode Flutter lengkap untuk UI `SyncScreen` dan kerangka fungsi service-nya.**
