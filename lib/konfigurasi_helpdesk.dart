/// Konfigurasi Help Desk AI (DeepSeek, format OpenAI-compatible).
///
/// Suntikkan API key dengan salah satu cara:
/// 1. Ganti [kunciApiHelpdesk] di bawah: `defaultValue: 'sk-...'`.
/// 2. Atau saat build:
///    `flutter build apk --dart-define=HELPDESK_API_KEY=sk-...`
///
/// Endpoint resmi DeepSeek memakai `/chat/completions`. Model default
/// `deepseek-flash` (V4.1 Flash). Alias `deepseek-v4-flash` masih diterima,
/// dan bisa diganti lewat `--dart-define=HELPDESK_MODEL=...`.
const String alamatApiHelpdesk = String.fromEnvironment(
  'HELPDESK_API_URL',
  defaultValue: 'https://api.deepseek.com/chat/completions',
);

/// Key sengaja TIDAK ditanam di kode agar tidak ikut terkirim ke repo/PWA
/// publik. Untuk build Android yang Help Desk-nya aktif, jalankan:
/// `flutter build apk --split-per-abi --dart-define=HELPDESK_API_KEY=sk-...`
const String kunciApiHelpdesk = String.fromEnvironment(
  'HELPDESK_API_KEY',
  defaultValue: '',
);

const String modelHelpdesk = String.fromEnvironment(
  'HELPDESK_MODEL',
  defaultValue: 'deepseek-flash',
);
