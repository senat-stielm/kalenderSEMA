# Panduan Sinkronisasi Agenda dengan Supabase

Aplikasi ini menyimpan agenda di Supabase agar **semua HP yang menginstall
aplikasi melihat tanggal yang sama**. HP anggota hanya membaca data; hanya
admin yang dapat menambah, mengubah, dan menghapus agenda.

## 1. Buat proyek Supabase (sekali saja)

1. Buka <https://supabase.com> lalu daftar/masuk (bisa pakai akun Google atau
   GitHub).
2. Klik **New project**.
   - Nama: `kalender-ormawa` (bebas).
   - Database password: bebas, simpan sendiri.
   - Region: **Southeast Asia (Singapore)** agar cepat diakses dari Indonesia.
3. Tunggu sampai proyek selesai dibuat (±2 menit).

## 2. Jalankan skrip tabel

1. Di dashboard proyek, buka **SQL Editor** > **New query**.
2. Buka berkas `supabase/skema.sql` di proyek ini, salin **seluruh** isinya,
   tempel ke editor, lalu klik **Run**.
3. Pastikan tidak ada pesan error. Skrip ini membuat tabel `agenda` dan
   `ormawa`, kunci tulis, fungsi simpan/hapus, serta mengisi contoh data.

> **Sudah pernah memakai versi sebelumnya?** Cukup jalankan
> `supabase/tambahan_ormawa.sql` sekali. Berkas itu menambahkan tabel `ormawa`
> tanpa mengubah agenda yang sudah ada.

## 3. Ambil URL dan anon key

1. Buka **Project Settings** (ikon gerigi) > **API**.
2. Salin:
   - **Project URL**, contoh: `https://abcdefghijklm.supabase.co`
   - **anon public** key (bagian `Project API keys`).

> Anon key memang dirancang untuk dibagikan di aplikasi. Hak tulis tetap
> dibatasi oleh kebijakan RLS + kunci tulis di skrip SQL.

## 4. Isi konfigurasi di aplikasi

Buka `lib/konfigurasi_supabase.dart`, lalu ganti dua nilai berikut:

```dart
const String alamatSupabase = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://abcdefghijklm.supabase.co',
);

const String kunciAnonSupabase = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOi...',
);
```

Alternatif tanpa mengubah kode (nilai tetap tertanam saat build):

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://abcdefghijklm.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

## 5. Bagikan aplikasi

Build APK lalu bagikan ke anggota. **Semua HP harus memakai APK dengan
konfigurasi Supabase yang sama** agar membaca data yang sama.

Untuk ukuran lebih ringan, build terpisah per arsitektur:

```bash
flutter build apk --release --split-per-abi
```

Hasil di `build/app/outputs/flutter-apk/`:

| File | Perkiraan ukuran | Dipakai untuk |
| --- | --- | --- |
| `app-arm64-v8a-release.apk` | ±19 MB | HP Android modern (kebanyakan anggota) |
| `app-armeabi-v7a-release.apk` | ±16 MB | HP lama 32-bit |
| `app-x86_64-release.apk` | ±20 MB | Emulator / Chromebook |

Bagikan satu file sesuai jenis HP anggota. Jika ingin satu APK untuk semua
perangkat, gunakan `flutter build apk --release` (±53 MB).

## 6. Masuk sebagai admin

1. Ketuk ikon **gembok** di kanan atas.
2. Nama pengguna: `admin`
3. Password bawaan: `Widyanurdianasenat2627`
4. Setelah masuk, admin dapat:
   - Menambah, mengubah, dan menghapus agenda.
   - Membuka **Tampilan** untuk mengelola ormawa/UKM/UKK: mengubah nama,
     jenis, warna, dan ikon; menambah organisasi baru; atau menghapusnya.
     Perubahan ini ikut tersinkron ke semua perangkat.
   - **Ubah Password Admin**, **Sinkronkan Agenda Sekarang**, dan
     **Keluar Mode Admin** lewat panel gembok.

Selama belum masuk admin, anggota hanya dapat melihat kalender, memilih
ormawa, mengubah tema tampilan, dan menyinkronkan data. Tombol tambah/edit/
hapus agenda dan pengelolaan ormawa disembunyikan.

## 7. Cara kerja sinkronisasi

- Saat aplikasi dibuka, agenda dan daftar ormawa diambil dari Supabase lalu
  disimpan sebagai salinan lokal (cache).
- Admin menambah/mengubah/menghapus agenda atau ormawa → langsung dikirim ke
  Supabase. Menghapus ormawa ikut menghapus agenda miliknya.
- HP anggota melihat perubahan saat membuka aplikasi, menekan ikon sinkron,
  atau menarik daftar agenda ke bawah.
- Jika tidak ada internet, aplikasi tetap menampilkan salinan terakhir dan
  memberi tahu bahwa sinkronisasi gagal.
- Tanggal disimpan sebagai `date` (tanpa jam/zona waktu), sehingga tanggal
  yang tampil sama di semua perangkat.

## 8. Keamanan

- Password admin disimpan sebagai hash SHA-256 + salt di HP admin, bukan teks
  biasa. Password ini berlaku **per HP**: bila ada lebih dari satu HP admin,
  ubah password di tiap HP tersebut.
- Password yang sama **tidak dikirim** ke server; penulisan data memakai
  `kunciTulisSupabase` yang tercantum di `supabase/skema.sql`.
- Siapa pun yang memiliki anon key + kunci tulis secara teknis dapat menulis
  langsung ke database. Untuk keamanan tingkat lanjut, gunakan Supabase Auth
  dan batasi penulisan hanya untuk pengguna yang login.
- Jika password admin lupa setelah diganti, tidak ada pemulihan dari aplikasi;
  hapus data aplikasi (clear app data) lalu masuk kembali dengan password
  bawaan.

## 9. Mengganti kunci tulis

1. Ubah baris `insert into public.kunci_aplikasi ...` di `supabase/skema.sql`
   (atau jalankan `update public.kunci_aplikasi set kunci = '...' where id = 1;`).
2. Ubah `kunciTulisSupabase` di `lib/konfigurasi_supabase.dart` dengan nilai
   yang sama.
3. Build ulang aplikasi.

## 10. Jika terjadi masalah

| Gejala | Penyebab & solusi |
| --- | --- |
| Banner "Supabase belum dikonfigurasi" | URL/anon key masih placeholder di `lib/konfigurasi_supabase.dart`. |
| `relation "public.agenda" does not exist` | Skrip `supabase/skema.sql` belum dijalankan. |
| `Kunci tidak valid` | Nilai kunci di SQL dan di aplikasi berbeda. |
| `401 / 403` | Anon key salah, atau kebijakan RLS belum dijalankan ulang. |
| Data berbeda antar HP | Pastikan semua HP memakai APK dengan konfigurasi yang sama dan menekan tombol sinkron. |
