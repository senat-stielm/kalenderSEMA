# Kalender Kemahasiswaan

Kalender agenda organisasi mahasiswa (Senat, BEM, HMPS, UKM, UKK) berbasis
Flutter. Agenda disinkronkan lewat Supabase sehingga tanggal yang tampil sama
di semua HP yang menginstall aplikasi.

## Mode admin

- Anggota: hanya melihat kalender, menyaring per ormawa, dan menyinkronkan
  data. Tidak perlu login.
- Admin: ketuk ikon gembok di kanan atas, lalu masuk dengan
  `admin` / `Widyanurdianasenat2627`. Setelah masuk, admin dapat menambah,
  mengubah, menghapus agenda; mengelola ormawa/UKM/UKK (nama, jenis, warna,
  ikon, tambah/hapus); serta mengatur tampilan. Password dapat diganti dari
  panel admin.
- Ketuk logo di kiri atas untuk membuka **kalender tahunan** dan melompat
  cepat ke tanggal mana pun.

## Sinkronisasi

Ikuti langkah di [PANDUAN_SUPABASE.md](PANDUAN_SUPABASE.md) untuk membuat
proyek Supabase, menjalankan `supabase/skema.sql`, dan mengisi URL + anon key
di `lib/konfigurasi_supabase.dart`.

## Menjalankan

```bash
flutter pub get
flutter run
flutter test
```

Build APK terpisah per arsitektur agar lebih ringan (lihat
[PANDUAN_SUPABASE.md](PANDUAN_SUPABASE.md#5-bagikan-aplikasi)):

```bash
flutter build apk --release --split-per-abi
```

Build versi web/PWA (bisa dipasang dari browser):

```bash
flutter build web --release
```

Hasilnya di `build/web`. Panduan deploy ke GitHub Pages ada di
[PANDUAN_GITHUB_PAGES.md](PANDUAN_GITHUB_PAGES.md).
