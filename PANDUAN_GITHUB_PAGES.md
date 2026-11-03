# Panduan Deploy PWA ke GitHub Pages

Aplikasi web/PWA sudah dikonfigurasi dan hasil build-nya ada di `build/web`.
PWA artinya bisa dibuka di browser, dan di HP bisa dipasang seperti aplikasi
(Add to Home Screen) lewat Chrome/Edge.

## Yang sudah disiapkan

- `flutter build web --release` berhasil; hasilnya di `build/web`.
- `<base href="./">` relatif, sehingga berjalan di alamat apa pun, termasuk
  `https://pengguna.github.io/nama-repo/`.
- `web/manifest.json` + ikon PWA 192/512 (dari `assets/icon.png`).
- `.nojekyll` agar GitHub Pages tidak memproses berkas dengan Jekyll.
- Workflow `.github/workflows/deploy-web.yml` untuk build & deploy otomatis.

Data tetap memakai Supabase yang sama dengan aplikasi Android, jadi agenda
dan ormawa otomatis sama di web dan HP.

---

## Cara A — Deploy otomatis lewat GitHub Actions (disarankan)

1. Buat repositori baru di GitHub, misalnya `kalender-ormawa` (nama bebas).
   **Jangan** centang "Add README" agar tidak bentrok.
2. Di komputer, dari folder proyek:

   ```bash
   git add .
   git commit -m "Tambah PWA dan deploy GitHub Pages"
   git branch -M main
   git remote add origin https://github.com/USERNAME/NAMA-REPO.git
   git push -u origin main
   ```

   Ganti `USERNAME` dan `NAMA-REPO` sesuai milik Anda.
3. Buka repo di GitHub → **Settings** → **Pages**.
   Pada **Build and deployment → Source**, pilih **GitHub Actions**.
4. Buka tab **Actions** → workflow **Deploy Web ke GitHub Pages** akan berjalan
   otomatis. Tunggu sampai centang hijau (±2–4 menit).
5. Situs tersedia di:

   ```
   https://USERNAME.github.io/NAMA-REPO/
   ```

Setiap kali Anda `git push` ke `main`, workflow akan membangun ulang dan
men-deploy versi terbaru.

---

## Cara B — Unggah hasil build langsung (tanpa Actions)

1. Build ulang di komputer:

   ```bash
   flutter build web --release
   ```

2. Masuk ke folder hasil build dan jadikan repo `gh-pages`:

   ```bash
   cd build/web
   git init
   git add -A
   git commit -m "Deploy PWA"
   git branch -M gh-pages
   git remote add origin https://github.com/USERNAME/NAMA-REPO.git
   git push -u origin gh-pages --force
   ```

3. Di GitHub → **Settings** → **Pages** → **Source: Deploy from a branch** →
   pilih branch **gh-pages**, folder **/ (root)** → **Save**.
4. Tunggu 1–2 menit, lalu buka `https://USERNAME.github.io/NAMA-REPO/`.

Jika nanti ada perubahan, ulangi langkah 1–2 (build ulang lalu push ulang).

---

## Memasang PWA di HP

1. Buka alamat GitHub Pages di Chrome (Android) atau Safari (iPhone).
2. Chrome Android: menu ⋮ → **Tambahkan ke layar utama** / **Instal aplikasi**.
   iPhone: tombol Bagikan → **Tambahkan ke Layar Utama**.
3. Ikon Kalender Ormawa akan muncul seperti aplikasi biasa.

PWA hanya bisa dipasang lewat **HTTPS**; GitHub Pages sudah menyediakannya.

---

## Catatan

- URL web dan APK Android memakai database Supabase yang sama. Agenda dan
  daftar ormawa selalu sama di keduanya.
- Login admin, ubah password, kalender tahunan, dan pengelolaan ormawa juga
  berfungsi di browser. Password admin tersimpan per browser/perangkat.
- **Help Desk AI tidak aktif di PWA publik.** API key DeepSeek sengaja tidak
  ditanam di kode agar tidak bisa diambil dari situs. Untuk APK Android dengan
  Help Desk aktif, build dengan
  `--dart-define=HELPDESK_API_KEY=sk-...`.
- Setelah update aplikasi, service worker mungkin masih menyimpan versi lama
  sebentar. Tutup lalu buka kembali tab, atau tarik untuk menyegarkan.
- Jika halaman kosong: pastikan **Settings → Pages** sudah menunjuk ke
  **GitHub Actions** (Cara A) atau branch **gh-pages** (Cara B), dan file
  `.nojekyll` ada di hasil build (sudah otomatis).
