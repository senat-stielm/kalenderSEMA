import 'package:flutter/material.dart';

enum KategoriOrmawa {
  senat(
    'senat',
    'Senat Mahasiswa',
    'Legislatif',
    Color(0xFFA855F7),
    Icons.gavel_rounded,
  ),
  bem(
    'bem',
    'BEM',
    'Eksekutif',
    Color(0xFFEF4444),
    Icons.account_balance_rounded,
  ),
  hmpsKp('hmpsKp', 'HMPS KP', 'Prodi', Color(0xFF3B82F6), Icons.school_rounded),
  hmpsMn(
    'hmpsMn',
    'HMPS MN',
    'Prodi',
    Color(0xFF06B6D4),
    Icons.business_center_rounded,
  ),
  ukm1(
    'ukm1',
    'UKM Olahraga',
    'UKM',
    Color(0xFF10B981),
    Icons.sports_soccer_rounded,
  ),
  ukm2(
    'ukm2',
    'UKM Seni & Musik',
    'UKM',
    Color(0xFFF59E0B),
    Icons.music_note_rounded,
  ),
  ukm3(
    'ukm3',
    'UKM Penalaran & Riset',
    'UKM',
    Color(0xFF14B8A6),
    Icons.science_rounded,
  ),
  ukm4(
    'ukm4',
    'UKM Pers Kampus',
    'UKM',
    Color(0xFFEC4899),
    Icons.newspaper_rounded,
  ),
  ukm5('ukm5', 'UKM Mapala', 'UKM', Color(0xFF84CC16), Icons.terrain_rounded),
  ukm6(
    'ukm6',
    'UKM Kerohanian Islam',
    'UKM',
    Color(0xFF22C55E),
    Icons.mosque_rounded,
  ),
  ukm7(
    'ukm7',
    'UKM Kewirausahaan',
    'UKM',
    Color(0xFF6366F1),
    Icons.storefront_rounded,
  ),
  ukk1('ukk1', 'UKK Pramuka', 'UKK', Color(0xFFD97706), Icons.explore_rounded),
  ukk2(
    'ukk2',
    'UKK KSR PMI',
    'UKK',
    Color(0xFFF43F5E),
    Icons.medical_services_rounded,
  );

  final String id;
  final String namaDefault;
  final String kategori;
  final Color warnaDefault;
  final IconData ikon;

  const KategoriOrmawa(
    this.id,
    this.namaDefault,
    this.kategori,
    this.warnaDefault,
    this.ikon,
  );
}

class AgendaAcara {
  String id;
  String judul;
  String deskripsi;
  DateTime waktu;
  String lokasi;
  KategoriOrmawa ormawa;

  AgendaAcara({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.waktu,
    required this.lokasi,
    required this.ormawa,
  });
}
