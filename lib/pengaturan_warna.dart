import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kumpulan warna tema aplikasi yang bisa diubah pengguna.
@immutable
class PengaturanWarna {
  const PengaturanWarna({
    required this.aksen,
    required this.aksenGelap,
    required this.sekunder,
    required this.latar1,
    required this.latar2,
    required this.latar3,
    required this.kartu,
  });

  /// Warna utama: tombol, sorotan, hari terpilih.
  final Color aksen;

  /// Pasangan lebih gelap dari [aksen] untuk gradien.
  final Color aksenGelap;

  /// Warna pendukung untuk glow dan elemen sekunder.
  final Color sekunder;

  /// Tiga warna gradien latar belakang (atas, tengah, bawah).
  final Color latar1;
  final Color latar2;
  final Color latar3;

  /// Warna dasar kartu, panel, dan dialog.
  final Color kartu;

  static const bawaan = PengaturanWarna(
    aksen: Color(0xFFF59E0B),
    aksenGelap: Color(0xFFD97706),
    sekunder: Color(0xFF38BDF8),
    latar1: Color(0xFF070B19),
    latar2: Color(0xFF0F172A),
    latar3: Color(0xFF1E1B4B),
    kartu: Color(0xFF1E293B),
  );

  PengaturanWarna salin({
    Color? aksen,
    Color? aksenGelap,
    Color? sekunder,
    Color? latar1,
    Color? latar2,
    Color? latar3,
    Color? kartu,
  }) {
    return PengaturanWarna(
      aksen: aksen ?? this.aksen,
      aksenGelap: aksenGelap ?? this.aksenGelap,
      sekunder: sekunder ?? this.sekunder,
      latar1: latar1 ?? this.latar1,
      latar2: latar2 ?? this.latar2,
      latar3: latar3 ?? this.latar3,
      kartu: kartu ?? this.kartu,
    );
  }

  Map<String, int> kePeta() => {
    'aksen': aksen.toARGB32(),
    'aksenGelap': aksenGelap.toARGB32(),
    'sekunder': sekunder.toARGB32(),
    'latar1': latar1.toARGB32(),
    'latar2': latar2.toARGB32(),
    'latar3': latar3.toARGB32(),
    'kartu': kartu.toARGB32(),
  };

  static PengaturanWarna dariPeta(Map<String, dynamic> peta) {
    Color ambil(String kunci, Color cadangan) {
      final nilai = peta[kunci];
      return nilai is int ? Color(nilai) : cadangan;
    }

    return PengaturanWarna(
      aksen: ambil('aksen', bawaan.aksen),
      aksenGelap: ambil('aksenGelap', bawaan.aksenGelap),
      sekunder: ambil('sekunder', bawaan.sekunder),
      latar1: ambil('latar1', bawaan.latar1),
      latar2: ambil('latar2', bawaan.latar2),
      latar3: ambil('latar3', bawaan.latar3),
      kartu: ambil('kartu', bawaan.kartu),
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
