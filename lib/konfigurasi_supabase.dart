/// Konfigurasi koneksi Supabase.
///
/// Nilai di bawah bisa diganti langsung di sini, atau saat build dengan:
/// `flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
///
/// Lihat `PANDUAN_SUPABASE.md` untuk langkah pembuatan proyek.
const String alamatSupabase = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://rncsnhvepeqkvyszlkdp.supabase.co',
);

const String kunciAnonSupabase = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuY3NuaHZlcGVxa3Z5c3psa2RwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMzNTE1NTcsImV4cCI6MjEwODkyNzU1N30.C41KrrF-267Sb9PUd85p31n88xlatiKseNJvpnXzZMM',
);

/// Kunci rahasia untuk menulis data. Nilai ini harus sama dengan baris
/// pada tabel `kunci_aplikasi` di `supabase/skema.sql`.
const String kunciTulisSupabase = String.fromEnvironment(
  'SUPABASE_KUNCI_TULIS',
  defaultValue: 'senat-kalender-ormawa-2026-kunci-tulis-9f3c',
);
