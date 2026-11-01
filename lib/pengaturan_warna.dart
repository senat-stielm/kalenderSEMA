import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema aplikasi: mode terang/gelap plus warna aksen yang bisa diubah
/// pengguna. Warna latar, kartu, dan teks ditentukan otomatis dari mode agar
/// kontras selalu terjaga.
@immutable
class PengaturanWarna {
  const PengaturanWarna({
    required this.aksen,
    required this.aksenGelap,
    required this.sekunder,
    this.gelap = true,
  });

  /// Warna utama: tombol, sorotan, hari terpilih.
  final Color aksen;

  /// Pasangan lebih gelap dari [aksen] untuk gradien.
  final Color aksenGelap;

  /// Warna pendukung untuk glow dan elemen sekunder.
  final Color sekunder;

  /// `true` untuk mode gelap, `false` untuk mode terang.
  final bool gelap;

  /// Tema bawaan: krem hangat dengan hijau hutan, sesuai desain aplikasi.
  static const bawaan = PengaturanWarna(
    aksen: Color(0xFF1E5B40),
    aksenGelap: Color(0xFF123F2B),
    sekunder: Color(0xFFA8C46B),
    gelap: false,
  );

  // ---------------------------------------------------------------------------
  // Latar belakang
  // ---------------------------------------------------------------------------

  /// Tiga warna gradien latar belakang (atas, tengah, bawah).
  Color get latar1 => gelap ? const Color(0xFF05060B) : const Color(0xFFFDFBF5);
  Color get latar2 => gelap ? const Color(0xFF0A0B12) : const Color(0xFFF8F2E6);
  Color get latar3 => gelap ? const Color(0xFF101020) : const Color(0xFFF2EADB);

  /// Warna dasar kartu, panel, dan dialog.
  Color get kartu => gelap ? const Color(0xFF17181F) : const Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Warna teks dan permukaan
  // ---------------------------------------------------------------------------

  /// Teks utama.
  Color get teks => gelap ? Colors.white : const Color(0xFF15251B);

  /// Teks pendukung.
  Color get teksLembut =>
      gelap ? Colors.white.withValues(alpha: 0.72) : const Color(0xFF435648);

  /// Teks yang lebih redup (keterangan).
  Color get teksRedup =>
      gelap ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF77857A);

  /// Teks paling samar (placeholder, nonaktif).
  Color get teksSamar =>
      gelap ? Colors.white.withValues(alpha: 0.36) : const Color(0xFFA3AEA4);

  /// Garis tepi kartu dan pemisah.
  Color get garis =>
      gelap ? Colors.white.withValues(alpha: 0.10) : const Color(0x1A15251B);

  /// Garis tepi sangat halus.
  Color get garisLembut =>
      gelap ? Colors.white.withValues(alpha: 0.06) : const Color(0x0F15251B);

  /// Latar kolom isian dan baris daftar.
  Color get isian =>
      gelap ? Colors.white.withValues(alpha: 0.055) : const Color(0xFFF3EEE2);

  /// Gradien kaca untuk header, kalender, dan panel melayang.
  Color get kacaAtas => gelap
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.75);
  Color get kacaBawah => gelap
      ? Colors.white.withValues(alpha: 0.015)
      : Colors.white.withValues(alpha: 0.42);

  /// Warna aksen yang aman dipakai sebagai teks atau ikon di atas kartu.
  /// Di mode gelap, aksen yang terlalu pekat dicerahkan agar tetap terbaca.
  Color get aksenTeks {
    if (!gelap) return aksenGelap;
    final aksenTerang =
        ThemeData.estimateBrightnessForColor(aksen) == Brightness.light;
    return aksenTerang ? aksen : Color.lerp(aksen, Colors.white, 0.55)!;
  }

  /// Warna cincin tanggal libur nasional.
  Color get liburNasional =>
      gelap ? const Color(0xFFF87171) : const Color(0xFFB91C1C);

  /// Warna cincin hari besar/peringatan nasional.
  Color get peringatanNasional =>
      gelap ? const Color(0xFFFBBF24) : const Color(0xFFB45309);

  /// Warna teks/ikon yang kontras di atas latar [aksen].
  Color get diAksen =>
      ThemeData.estimateBrightnessForColor(aksen) == Brightness.dark
      ? Colors.white
      : const Color(0xFF0B1220);

  /// Bayangan kartu. Di mode terang memakai cokelat hangat agar tidak terasa
  /// kotor di atas latar krem.
  Color get bayangan => gelap
      ? Colors.black.withValues(alpha: 0.30)
      : const Color(0xFF3B2F1E).withValues(alpha: 0.13);
  Color get bayanganLembut => gelap
      ? Colors.black.withValues(alpha: 0.20)
      : const Color(0xFF3B2F1E).withValues(alpha: 0.07);

  /// Warna peringatan yang tetap terbaca di kedua mode.
  Color get peringatan => gelap ? Colors.orangeAccent : const Color(0xFFB45309);

  /// Warna bahaya (hapus).
  Color get bahaya => gelap ? Colors.redAccent : const Color(0xFFDC2626);

  PengaturanWarna salin({
    Color? aksen,
    Color? aksenGelap,
    Color? sekunder,
    bool? gelap,
  }) {
    return PengaturanWarna(
      aksen: aksen ?? this.aksen,
      aksenGelap: aksenGelap ?? this.aksenGelap,
      sekunder: sekunder ?? this.sekunder,
      gelap: gelap ?? this.gelap,
    );
  }

  Map<String, dynamic> kePeta() => {
    'aksen': aksen.toARGB32(),
    'aksenGelap': aksenGelap.toARGB32(),
    'sekunder': sekunder.toARGB32(),
    'gelap': gelap,
  };

  static PengaturanWarna dariPeta(Map<String, dynamic> peta) {
    Color ambil(String kunci, Color cadangan) {
      final nilai = peta[kunci];
      return nilai is int ? Color(nilai) : cadangan;
    }

    final mode = peta['gelap'];

    return PengaturanWarna(
      aksen: ambil('aksen', bawaan.aksen),
      aksenGelap: ambil('aksenGelap', bawaan.aksenGelap),
      sekunder: ambil('sekunder', bawaan.sekunder),
      gelap: mode is bool ? mode : true,
    );
  }
}

/// Penyimpanan permanen untuk tema dan kustomisasi ormawa.
class PenyimpananPengaturan {
  static const _kunciTema = 'pengaturan_warna_tema_v1';
  static const _kunciOrmawa = 'pengaturan_ormawa_v1';

  Future<PengaturanWarna?> muatTema() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mentah = prefs.getString(_kunciTema);
      if (mentah == null) return null;
      final peta = jsonDecode(mentah);
      if (peta is! Map<String, dynamic>) return null;
      return PengaturanWarna.dariPeta(peta);
    } catch (_) {
      return null;
    }
  }

  Future<void> simpanTema(PengaturanWarna tema) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kunciTema, jsonEncode(tema.kePeta()));
    } catch (_) {
      // Penyimpanan gagal tidak boleh menghentikan aplikasi.
    }
  }

  Future<Map<String, Map<String, dynamic>>?> muatOrmawa() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mentah = prefs.getString(_kunciOrmawa);
      if (mentah == null) return null;
      final peta = jsonDecode(mentah);
      if (peta is! Map<String, dynamic>) return null;

      final hasil = <String, Map<String, dynamic>>{};
      peta.forEach((kunci, nilai) {
        if (nilai is Map) {
          hasil[kunci] = Map<String, dynamic>.from(nilai);
        }
      });
      return hasil;
    } catch (_) {
      return null;
    }
  }

  Future<void> simpanOrmawa(Map<String, Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kunciOrmawa, jsonEncode(data));
    } catch (_) {
      // Penyimpanan gagal tidak boleh menghentikan aplikasi.
    }
  }
}
