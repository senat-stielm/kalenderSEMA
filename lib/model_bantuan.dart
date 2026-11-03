import 'package:flutter/foundation.dart';

/// Pilihan kategori untuk sumber informasi Help Desk.
const List<String> daftarKategoriBantuan = [
  'Organisasi',
  'Agenda',
  'Keanggotaan',
  'Layanan',
  'Keuangan',
  'Umum',
];

/// Satu informasi resmi yang diisi admin dan dipakai sebagai bahan jawaban
/// Help Desk. Disimpan di Supabase agar tersedia untuk semua perangkat.
@immutable
class SumberBantuan {
  const SumberBantuan({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.isi,
    required this.urutan,
  });

  final String id;
  final String judul;
  final String kategori;
  final String isi;
  final int urutan;

  Map<String, dynamic> kePeta() => {
    'id': id,
    'judul': judul,
    'kategori': kategori,
    'isi': isi,
    'urutan': urutan,
  };

  static SumberBantuan? dariPeta(Map<String, dynamic> peta) {
    final id = peta['id'];
    final judul = peta['judul'];
    final isi = peta['isi'];
    if (id is! String || id.isEmpty || judul is! String || judul.isEmpty) {
      return null;
    }
    if (isi is! String || isi.isEmpty) return null;

    final kategori = peta['kategori'];
    final urutan = peta['urutan'];

    return SumberBantuan(
      id: id,
      judul: judul,
      kategori: kategori is String && kategori.trim().isNotEmpty
          ? kategori
          : 'Umum',
      isi: isi,
      urutan: urutan is num ? urutan.toInt() : 0,
    );
  }

  SumberBantuan salin({
    String? judul,
    String? kategori,
    String? isi,
    int? urutan,
  }) {
    return SumberBantuan(
      id: id,
      judul: judul ?? this.judul,
      kategori: kategori ?? this.kategori,
      isi: isi ?? this.isi,
      urutan: urutan ?? this.urutan,
    );
  }
}
