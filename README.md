# 🛍️ Pastel Shop

Aplikasi katalog produk mobile (Flutter) bertema warna pastel dengan **CRUD penuh** (tambah, lihat, ubah, hapus) yang terhubung ke **backend REST API** buatan sendiri (folder `backend/`). Data awal backend diambil sekali dari [DummyJSON Products](https://dummyjson.com/docs/products), setelah itu semua perubahan disimpan permanen di server.

## 🎥 Video Penjelasan & Demo

**Link YouTube:** (https://youtu.be/1ycVaUo1S-k?si=WT6LAaGxiOrikjvN)

## ✨ Fitur

- **Halaman depan**: menampilkan seluruh produk (194 item) dalam grid 2 kolom dengan kartu berwarna pastel.
- **Halaman detail produk**: galeri gambar (geser), kategori, brand, rating, harga + diskon, deskripsi, stok, pengiriman, garansi, kebijakan retur, dan ulasan. Dibuka dengan menekan produk di halaman depan.
- **Search fungsional**: ketik kata kunci lalu tekan tombol search (atau enter di keyboard). Mencari ke endpoint `/products/search`. Ada tombol ✕ untuk menghapus pencarian.
- **Create**: tombol **+ Tambah** di halaman depan membuka form produk (validasi lengkap).
- **Update**: ikon ✏️ di halaman detail membuka form yang sudah terisi.
- **Delete**: ikon 🗑️ di halaman detail, dengan dialog konfirmasi.
- Semua perubahan disimpan di backend dan tetap ada setelah aplikasi ditutup.
- State loading, error (dengan tombol coba lagi), dan hasil kosong.
- Pull-to-refresh di halaman depan.

## 🎨 Skema Warna Pastel

| Warna | Hex |
|-------|-----|
| Pink | `#FAD4E1` |
| Mint | `#CDF0DD` |
| Sky | `#C6E2FB` |
| Peach | `#FFDCC4` |
| Lavender | `#DDD2F7` |
| Yellow | `#FFF1B8` |
| Background (krem) | `#FFF8F3` |
| Aksen (ungu pastel) | `#B39DDB` |

Palet ada di `lib/theme/app_colors.dart`.

## 🔌 Backend & API

Backend ada di folder `backend/` (Node.js 18+, **tanpa dependensi**, data disimpan di `backend/data/products.json`).

| Operasi | Endpoint | Keterangan |
|---------|----------|------------|
| Read (semua) | `GET /products` | |
| Read (cari) | `GET /products?q=<kata>` | cari di judul, deskripsi, kategori, brand |
| Read (satu) | `GET /products/:id` | |
| Create | `POST /products` | body JSON, mengembalikan produk baru (201) |
| Update | `PUT /products/:id` | field yang tidak dikirim tetap utuh |
| Delete | `DELETE /products/:id` | |

Field wajib saat create: `title`, `category`, `price`, `thumbnail`. Error validasi dikembalikan sebagai `400` berisi daftar `errors`.

## 🚀 Cara Menjalankan

Prasyarat: [Flutter SDK](https://docs.flutter.dev/get-started/install), [Node.js 18+](https://nodejs.org), dan HP Android dengan **USB debugging** aktif (atau emulator).

### 1. Jalankan backend (terminal 1)

```bash
cd backend
node server.js          # atau: npm start
```

Saat pertama jalan, backend mengambil 194 produk dari DummyJSON (perlu internet sekali saja). Untuk mengembalikan data ke awal: hentikan server, jalankan `npm run reset`, lalu start lagi.

### 2. Jalankan aplikasi (terminal 2)

```bash
git clone <link-repo-ini>
cd pastel_shop

# membuat folder android/ios (hanya sekali)
flutter create . --project-name pastel_shop

flutter pub get
flutter devices        # pastikan HP terdeteksi
```

Alamat backend diatur lewat `--dart-define=API_URL=...`:

```bash
# Emulator Android (default, 10.0.2.2 = laptop kamu)
flutter run

# HP asli: HP & laptop harus di WiFi yang sama, ganti dengan IP laptop kamu
flutter run --dart-define=API_URL=http://192.168.1.10:3000
```

Cek IP laptop: `ipconfig` (Windows) atau `ifconfig` / `ip a` (Mac/Linux). Jika HP tidak bisa terhubung, izinkan port 3000 di firewall laptop.

### 3. Pengaturan Android (wajib, sekali saja)

Setelah `flutter create .`, buka `android/app/src/main/AndroidManifest.xml` dan pada tag `<manifest>` / `<application>` pastikan ada:

```xml
<uses-permission android:name="android.permission.INTERNET"/>

<application
    android:usesCleartextTraffic="true"
    ... >
```

`usesCleartextTraffic` diperlukan karena backend lokal memakai `http://` (bukan https). Tanpa ini aplikasi tidak bisa terhubung ke backend.

> Untuk dipakai publik, deploy backend ke hosting (Render, Railway, VPS, dll.) lalu isi `API_URL` dengan alamat `https://` miliknya.

## 📁 Struktur Project

```
backend/
├── server.js               # REST API (CRUD) + penyimpanan JSON
└── package.json
lib/
├── main.dart
├── config.dart             # alamat backend (API_URL)
├── models/product.dart
├── services/product_service.dart   # CRUD ke backend
├── screens/
│   ├── home_screen.dart
│   ├── detail_screen.dart          # + tombol ubah & hapus
│   └── product_form_screen.dart    # form tambah / ubah
├── widgets/product_card.dart
└── theme/app_colors.dart
```
