import 'package:flutter/material.dart';

/// Satu pilihan ikon yang bisa dipakai admin untuk ormawa.
class PilihanIkon {
  const PilihanIkon(this.kunci, this.ikon, this.label);

  final String kunci;
  final IconData ikon;
  final String label;
}

/// Kumpulan ikon yang tersedia di dialog tambah/ubah ormawa.
const List<PilihanIkon> daftarIkonOrmawa = [
  PilihanIkon('gavel', Icons.gavel_rounded, 'Palu sidang'),
  PilihanIkon('bank', Icons.account_balance_rounded, 'Gedung'),
  PilihanIkon('school', Icons.school_rounded, 'Sekolah'),
  PilihanIkon('business', Icons.business_center_rounded, 'Bisnis'),
  PilihanIkon('sports', Icons.sports_soccer_rounded, 'Olahraga'),
  PilihanIkon('music', Icons.music_note_rounded, 'Musik'),
  PilihanIkon('science', Icons.science_rounded, 'Riset'),
  PilihanIkon('news', Icons.newspaper_rounded, 'Pers'),
  PilihanIkon('terrain', Icons.terrain_rounded, 'Alam'),
  PilihanIkon('mosque', Icons.mosque_rounded, 'Kerohanian'),
  PilihanIkon('store', Icons.storefront_rounded, 'Wirausaha'),
  PilihanIkon('explore', Icons.explore_rounded, 'Pramuka'),
  PilihanIkon('medical', Icons.medical_services_rounded, 'Kesehatan'),
  PilihanIkon('groups', Icons.groups_rounded, 'Umum'),
  PilihanIkon('event', Icons.event_rounded, 'Acara'),
  PilihanIkon('palette', Icons.palette_rounded, 'Seni'),
  PilihanIkon('camera', Icons.photo_camera_rounded, 'Foto'),
  PilihanIkon('code', Icons.code_rounded, 'Teknologi'),
  PilihanIkon('volunteer', Icons.volunteer_activism_rounded, 'Sosial'),
  PilihanIkon('star', Icons.star_rounded, 'Bintang'),
];

/// Pilihan label jenis organisasi pada dialog ormawa.
const List<String> daftarKategoriOrmawa = [
  'Legislatif',
  'Eksekutif',
  'Prodi',
  'UKM',
  'UKK',
  'Lainnya',
];

IconData ikonDariKunci(String kunci) {
  for (final pilihan in daftarIkonOrmawa) {
    if (pilihan.kunci == kunci) return pilihan.ikon;
  }
  return Icons.groups_rounded;
}

/// Logo resmi ormawa/UKM/UKK (PNG dengan latar transparan) berdasarkan id.
const Map<String, String> asetLogoOrmawa = {
  'senat': 'assets/logo_ormawa/logo_sema.png',
  'bem': 'assets/logo_ormawa/bem.png',
  'hmpsKp': 'assets/logo_ormawa/hmps_kp.png',
  'hmpsMn': 'assets/logo_ormawa/hmps_manajemen.png',
  'ukm1': 'assets/logo_ormawa/ukm_olahraga.png',
  'ukm2': 'assets/logo_ormawa/ukm_musikala.png',
  'ukm3': 'assets/logo_ormawa/inteklam.png',
  'ukm4': 'assets/logo_ormawa/tari.png',
  'ukm5': 'assets/logo_ormawa/himalaya.png',
  'ukm6': 'assets/logo_ormawa/paduan_suara.png',
  'ukm7': 'assets/logo_ormawa/ukm_kewirausahaan.png',
  'ukk1': 'assets/logo_ormawa/pramuka.png',
  'ukk2': 'assets/logo_ormawa/resimen.png',
};

/// Cari berkas logo untuk sebuah ormawa. Ormawa baru tanpa logo tetap
/// memakai ikon pilihan admin.
String? cariAsetLogo(String id, String nama) {
  final langsung = asetLogoOrmawa[id];
  if (langsung != null) return langsung;

  final kunci = nama.toLowerCase();
  if (kunci.contains('english club')) return 'assets/logo_ormawa/ec.png';
  return null;
}

/// Organisasi/UKM/UKK yang bisa diatur admin. Disimpan di Supabase agar
/// semua perangkat memakai daftar yang sama.
@immutable
class Ormawa {
  const Ormawa({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.warna,
    required this.ikonKunci,
  });

  final String id;
  final String nama;
  final String kategori;
  final Color warna;
  final String ikonKunci;

  IconData get ikon => ikonDariKunci(ikonKunci);

  String? get asetLogo => cariAsetLogo(id, nama);

  Map<String, dynamic> kePeta() => {
    'id': id,
    'nama': nama,
    'kategori': kategori,
    'warna': warna.toARGB32(),
    'ikon': ikonKunci,
  };

  static Ormawa? dariPeta(Map<String, dynamic> peta) {
    final id = peta['id'];
    final nama = peta['nama'];
    if (id is! String || id.isEmpty || nama is! String || nama.isEmpty) {
      return null;
    }

    final warna = peta['warna'];
    final ikon = peta['ikon'];
    final kategori = peta['kategori'];

    return Ormawa(
      id: id,
      nama: nama,
      kategori: kategori is String && kategori.trim().isNotEmpty
          ? kategori
          : 'Lainnya',
      warna: warna is num ? Color(warna.toInt()) : const Color(0xFF64748B),
      ikonKunci: ikon is String && ikon.isNotEmpty ? ikon : 'groups',
    );
  }

  Ormawa salin({
    String? nama,
    String? kategori,
    Color? warna,
    String? ikonKunci,
  }) {
    return Ormawa(
      id: id,
      nama: nama ?? this.nama,
      kategori: kategori ?? this.kategori,
      warna: warna ?? this.warna,
      ikonKunci: ikonKunci ?? this.ikonKunci,
    );
  }
}

/// Menampilkan logo resmi ormawa bila tersedia, atau ikon pilihannya bila
/// belum ada logo. [ukuran] adalah sisi kotak logo dalam piksel logis.
class IkonOrmawa extends StatelessWidget {
  const IkonOrmawa(
    this.ormawa, {
    super.key,
    required this.ukuran,
    this.warna,
    this.radius,
  });

  final Ormawa ormawa;
  final double ukuran;
  final Color? warna;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final aset = ormawa.asetLogo;
    final ikonCadangan = Icon(
      ormawa.ikon,
      size: ukuran * 0.5,
      color: warna,
    );

    if (aset == null) return ikonCadangan;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? ukuran * 0.32),
      child: Image.asset(
        aset,
        width: ukuran,
        height: ukuran,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => ikonCadangan,
      ),
    );
  }
}

/// Dipakai bila ada agenda yang ormawanya sudah dihapus.
Ormawa ormawaCadangan(String id) => Ormawa(
  id: id,
  nama: 'Tanpa Ormawa',
  kategori: 'Lainnya',
  warna: const Color(0xFF64748B),
  ikonKunci: 'groups',
);

/// Daftar awal saat database belum berisi data ormawa.
const List<Ormawa> ormawaBawaan = [
  Ormawa(
    id: 'senat',
    nama: 'Senat Mahasiswa',
    kategori: 'Legislatif',
    warna: Color(0xFFA855F7),
    ikonKunci: 'gavel',
  ),
  Ormawa(
    id: 'bem',
    nama: 'BEM',
    kategori: 'Eksekutif',
    warna: Color(0xFFFFCF3C),
    ikonKunci: 'bank',
  ),
  Ormawa(
    id: 'hmpsKp',
    nama: 'HMPS KP',
    kategori: 'Prodi',
    warna: Color(0xFFC50404),
    ikonKunci: 'school',
  ),
  Ormawa(
    id: 'hmpsMn',
    nama: 'HMPS MN',
    kategori: 'Prodi',
    warna: Color(0xFF0A0A87),
    ikonKunci: 'business',
  ),
  Ormawa(
    id: 'ukm1',
    nama: 'UKM Olahraga',
    kategori: 'UKM',
    warna: Color(0xFF10B981),
    ikonKunci: 'sports',
  ),
  Ormawa(
    id: 'ukm2',
    nama: 'UKM Musikala',
    kategori: 'UKM',
    warna: Color(0xFF6366F1),
    ikonKunci: 'music',
  ),
  Ormawa(
    id: 'ukm3',
    nama: 'UKM Inteklam',
    kategori: 'UKM',
    warna: Color(0xFF14B8A6),
    ikonKunci: 'science',
  ),
  Ormawa(
    id: 'ukm4',
    nama: 'UKM Tari',
    kategori: 'UKM',
    warna: Color(0xFFEC4899),
    ikonKunci: 'news',
  ),
  Ormawa(
    id: 'ukm5',
    nama: 'UKM Himalaya',
    kategori: 'UKM',
    warna: Color(0xFF84CC16),
    ikonKunci: 'terrain',
  ),
  Ormawa(
    id: 'ukm6',
    nama: 'UKM Paduan Suara',
    kategori: 'UKM',
    warna: Color(0xFF22C55E),
    ikonKunci: 'mosque',
  ),
  Ormawa(
    id: 'ukm7',
    nama: 'UKM Kewirausahaan',
    kategori: 'UKM',
    warna: Color(0xFF6366F1),
    ikonKunci: 'store',
  ),
  Ormawa(
    id: 'ukk1',
    nama: 'UKK Pramuka',
    kategori: 'UKK',
    warna: Color(0xFF402504),
    ikonKunci: 'explore',
  ),
  Ormawa(
    id: 'ukk2',
    nama: 'UKK Resimen Mahasiswa',
    kategori: 'UKK',
    warna: Color(0xFFF97316),
    ikonKunci: 'medical',
  ),
  Ormawa(
    id: 'ormawa-1793709126563381',
    nama: 'UKM English Club',
    kategori: 'UKM',
    warna: Color(0xFF3B82F6),
    ikonKunci: 'groups',
  ),
];
