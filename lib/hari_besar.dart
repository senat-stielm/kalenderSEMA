import 'package:flutter/foundation.dart';

/// Jenis hari besar yang ditandai di kalender.
enum JenisHariBesar {
  /// Libur nasional resmi (SKB 3 Menteri).
  liburNasional,

  /// Hari besar/peringatan nasional yang bukan hari libur.
  peringatanNasional,
}

@immutable
class HariBesar {
  const HariBesar({
    required this.tanggal,
    required this.nama,
    required this.jenis,
  });

  final DateTime tanggal;
  final String nama;
  final JenisHariBesar jenis;

  bool get libur => jenis == JenisHariBesar.liburNasional;
}

/// Libur nasional resmi Indonesia 2025–2027 berdasarkan SKB 3 Menteri.
/// Tanggal hari raya yang dapat bergeser mengikuti ketetapan pemerintah.
final List<HariBesar> _liburKhusus = [
  // 2025
  HariBesar(
    tanggal: DateTime(2025, 1, 1),
    nama: 'Tahun Baru 2025 Masehi',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 1, 27),
    nama: 'Isra Mikraj Nabi Muhammad SAW',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 1, 29),
    nama: 'Tahun Baru Imlek 2576 Kongzili',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 3, 29),
    nama: 'Hari Suci Nyepi (Tahun Baru Saka 1947)',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 3, 31),
    nama: 'Idulfitri 1446 H',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 4, 1),
    nama: 'Idulfitri 1446 H',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 4, 18),
    nama: 'Wafat Yesus Kristus',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 4, 20),
    nama: 'Kebangkitan Yesus Kristus (Paskah)',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 5, 1),
    nama: 'Hari Buruh Internasional',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 5, 12),
    nama: 'Hari Raya Waisak 2569 BE',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 5, 29),
    nama: 'Kenaikan Yesus Kristus',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 6, 1),
    nama: 'Hari Lahir Pancasila',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 6, 6),
    nama: 'Iduladha 1446 H',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 6, 27),
    nama: 'Tahun Baru Islam 1447 H',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 8, 17),
    nama: 'Proklamasi Kemerdekaan RI',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 9, 5),
    nama: 'Maulid Nabi Muhammad SAW',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2025, 12, 25),
    nama: 'Kelahiran Yesus Kristus (Natal)',
    jenis: JenisHariBesar.liburNasional,
  ),

  // 2026
  HariBesar(
    tanggal: DateTime(2026, 1, 1),
    nama: 'Tahun Baru 2026 Masehi',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 1, 16),
    nama: 'Isra Mikraj Nabi Muhammad SAW',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 2, 17),
    nama: 'Tahun Baru Imlek 2577 Kongzili',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 3, 19),
    nama: 'Hari Suci Nyepi (Tahun Baru Saka 1948)',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 3, 21),
    nama: 'Idulfitri 1447 H',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 3, 22),
    nama: 'Idulfitri 1447 H',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 4, 3),
    nama: 'Wafat Yesus Kristus',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 4, 5),
    nama: 'Kebangkitan Yesus Kristus (Paskah)',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 5, 1),
    nama: 'Hari Buruh Internasional',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 5, 14),
    nama: 'Kenaikan Yesus Kristus',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 5, 27),
    nama: 'Iduladha 1447 H',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 5, 31),
    nama: 'Hari Raya Waisak 2570 BE',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 6, 1),
    nama: 'Hari Lahir Pancasila',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 6, 16),
    nama: 'Tahun Baru Islam 1448 H',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 8, 17),
    nama: 'Proklamasi Kemerdekaan RI',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 8, 25),
    nama: 'Maulid Nabi Muhammad SAW',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2026, 12, 25),
    nama: 'Kelahiran Yesus Kristus (Natal)',
    jenis: JenisHariBesar.liburNasional,
  ),

  // 2027
  HariBesar(
    tanggal: DateTime(2027, 1, 1),
    nama: 'Tahun Baru 2027 Masehi',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 1, 5),
    nama: 'Isra Mikraj Nabi Muhammad SAW',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 2, 6),
    nama: 'Tahun Baru Imlek 2578 Kongzili',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 3, 8),
    nama: 'Hari Suci Nyepi (Tahun Baru Saka 1949)',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 3, 10),
    nama: 'Idulfitri 1448 H',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 3, 11),
    nama: 'Idulfitri 1448 H',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 3, 26),
    nama: 'Wafat Yesus Kristus',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 3, 28),
    nama: 'Kebangkitan Yesus Kristus (Paskah)',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 5, 1),
    nama: 'Hari Buruh Internasional',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 5, 6),
    nama: 'Kenaikan Yesus Kristus',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 5, 17),
    nama: 'Iduladha 1448 H',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 5, 20),
    nama: 'Hari Raya Waisak 2571 BE',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 6, 1),
    nama: 'Hari Lahir Pancasila',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 6, 6),
    nama: 'Tahun Baru Islam 1449 H',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 8, 15),
    nama: 'Maulid Nabi Muhammad SAW',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 8, 17),
    nama: 'Proklamasi Kemerdekaan RI',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 12, 25),
    nama: 'Kelahiran Yesus Kristus (Natal)',
    jenis: JenisHariBesar.liburNasional,
  ),
  HariBesar(
    tanggal: DateTime(2027, 12, 26),
    nama: 'Isra Mikraj Nabi Muhammad SAW',
    jenis: JenisHariBesar.liburNasional,
  ),
];

/// Libur nasional yang tanggalnya tetap setiap tahun, dipakai untuk tahun
/// yang belum memiliki SKB (2028 dan seterusnya).
const Map<String, String> _liburTetap = {
  '01-01': 'Tahun Baru Masehi',
  '05-01': 'Hari Buruh Internasional',
  '06-01': 'Hari Lahir Pancasila',
  '08-17': 'Proklamasi Kemerdekaan RI',
  '12-25': 'Kelahiran Yesus Kristus (Natal)',
};

/// Hari besar nasional yang bukan hari libur dan berulang setiap tahun.
const Map<String, String> _peringatanTetap = {
  '04-21': 'Hari Kartini',
  '05-02': 'Hari Pendidikan Nasional',
  '05-20': 'Hari Kebangkitan Nasional',
  '07-23': 'Hari Anak Nasional',
  '10-01': 'Hari Kesaktian Pancasila',
  '10-02': 'Hari Batik Nasional',
  '10-28': 'Hari Sumpah Pemuda',
  '11-10': 'Hari Pahlawan',
  '11-25': 'Hari Guru Nasional',
  '12-22': 'Hari Ibu',
};

String _dua(int nilai) => nilai.toString().padLeft(2, '0');

/// Mencari hari besar pada [tanggal], atau `null` bila tidak ada.
HariBesar? hariBesarPada(DateTime tanggal) {
  for (final hari in _liburKhusus) {
    if (hari.tanggal.year == tanggal.year &&
        hari.tanggal.month == tanggal.month &&
        hari.tanggal.day == tanggal.day) {
      return hari;
    }
  }

  final kunci = '${_dua(tanggal.month)}-${_dua(tanggal.day)}';
  final libur = _liburTetap[kunci];
  if (libur != null) {
    return HariBesar(
      tanggal: DateTime(tanggal.year, tanggal.month, tanggal.day),
      nama: libur,
      jenis: JenisHariBesar.liburNasional,
    );
  }

  final peringatan = _peringatanTetap[kunci];
  if (peringatan != null) {
    return HariBesar(
      tanggal: DateTime(tanggal.year, tanggal.month, tanggal.day),
      nama: peringatan,
      jenis: JenisHariBesar.peringatanNasional,
    );
  }

  return null;
}
