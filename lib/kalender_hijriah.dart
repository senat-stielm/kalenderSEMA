import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import 'gaya_iphone.dart';
import 'hari_besar.dart';
import 'pengaturan_warna.dart';

/// Nama bulan Hijriah dalam ejaan Indonesia.
const List<String> namaBulanHijriah = [
  'Muharram',
  'Safar',
  'Rabiul Awal',
  'Rabiul Akhir',
  'Jumadil Awal',
  'Jumadil Akhir',
  'Rajab',
  'Syaban',
  'Ramadan',
  'Syawal',
  'Zulkaidah',
  'Zulhijah',
];

const List<String> _namaHari = [
  'Sen',
  'Sel',
  'Rab',
  'Kam',
  'Jum',
  'Sab',
  'Min',
];

/// Rentang tahun Hijriah yang ditampilkan. Data Umm al-Qura pada paket
/// `hijri` mencakup 1356–1500 H, jadi rentang ini aman.
const int _tahunAwal = 1440;
const int _tahunAkhir = 1460;

String _kunciTanggal(DateTime tanggal) {
  final bulan = tanggal.month.toString().padLeft(2, '0');
  final hari = tanggal.day.toString().padLeft(2, '0');
  return '${tanggal.year}-$bulan-$hari';
}

bool _tanggalSama(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Tanggal Hijriah dalam format "21 Jumadil Awal 1448 H".
String tanggalHijriah(DateTime tanggal) {
  try {
    final h = HijriCalendar.fromDate(tanggal);
    return '${h.hDay} ${namaBulanHijriah[h.hMonth - 1]} ${h.hYear} H';
  } catch (_) {
    return '';
  }
}

/// Nomor hari Hijriah untuk sebuah tanggal Masehi, atau `null` bila tanggal
/// berada di luar rentang data Umm al-Qura.
int? nomorHariHijriah(DateTime tanggal) {
  try {
    return HijriCalendar.fromDate(tanggal).hDay;
  } catch (_) {
    return null;
  }
}

/// Menampilkan kalender Hijriah satu tahun penuh (12 bulan). Mengembalikan
/// tanggal Masehi yang dipilih, atau `null` bila ditutup tanpa memilih.
Future<DateTime?> tampilkanKalenderHijriah(
  BuildContext context, {
  required PengaturanWarna tema,
  required DateTime tanggalTerpilih,
  required DateTime hariIni,
  required Map<String, List<Color>> warnaAgenda,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: tema.gelap ? 0.62 : 0.42),
    builder: (_) => _LembarKalenderHijriah(
      tema: tema,
      tanggalTerpilih: tanggalTerpilih,
      hariIni: hariIni,
      warnaAgenda: warnaAgenda,
    ),
  );
}

class _LembarKalenderHijriah extends StatefulWidget {
  const _LembarKalenderHijriah({
    required this.tema,
    required this.tanggalTerpilih,
    required this.hariIni,
    required this.warnaAgenda,
  });

  final PengaturanWarna tema;
  final DateTime tanggalTerpilih;
  final DateTime hariIni;
  final Map<String, List<Color>> warnaAgenda;

  @override
  State<_LembarKalenderHijriah> createState() => _LembarKalenderHijriahState();
}

class _LembarKalenderHijriahState extends State<_LembarKalenderHijriah> {
  late int _tahun;
  final ScrollController _kontroler = ScrollController();
  final List<GlobalKey> _kunciBulan = List.generate(12, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    final h = HijriCalendar.fromDate(widget.tanggalTerpilih);
    _tahun = h.hYear.clamp(_tahunAwal, _tahunAkhir);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lompatKeBulan(h.hMonth, langsung: true);
    });
  }

  @override
  void dispose() {
    _kontroler.dispose();
    super.dispose();
  }

  void _lompatKeBulan(int bulan, {bool langsung = false}) {
    final konteks = _kunciBulan[bulan - 1].currentContext;
    if (konteks == null) return;
    Scrollable.ensureVisible(
      konteks,
      duration: langsung ? Duration.zero : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  void _pindahTahun(int selisih) {
    final baru = (_tahun + selisih).clamp(_tahunAwal, _tahunAkhir);
    if (baru == _tahun) return;
    HapticFeedback.selectionClick();
    setState(() => _tahun = baru);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_kontroler.hasClients) _kontroler.jumpTo(0);
    });
  }

  void _keHariIni() {
    final h = HijriCalendar.fromDate(widget.hariIni);
    HapticFeedback.selectionClick();
    if (h.hYear != _tahun) {
      setState(() => _tahun = h.hYear.clamp(_tahunAwal, _tahunAkhir));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lompatKeBulan(h.hMonth);
    });
  }

  DateTime _awalTahun() => HijriCalendar().hijriToGregorian(_tahun, 1, 1);

  DateTime _akhirTahun() {
    final jumlah = HijriCalendar().getDaysInMonth(_tahun, 12);
    return HijriCalendar().hijriToGregorian(_tahun, 12, jumlah);
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;
    final tinggiLayar = MediaQuery.sizeOf(context).height;
    final bawah = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      height: tinggiLayar * 0.92,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(
              tema.aksen.withValues(alpha: tema.gelap ? 0.1 : 0.05),
              tema.latar1,
            ),
            tema.latar1,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        border: Border(top: BorderSide(color: tema.garis)),
        boxShadow: [
          BoxShadow(
            color: tema.bayangan,
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4.5,
            decoration: BoxDecoration(
              color: tema.teks.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [tema.aksen, tema.aksenGelap],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: tema.aksen.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.nightlight_round,
                    color: tema.diAksen,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kalender Hijriah',
                        style: TextStyle(
                          color: tema.teks,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '12 bulan • ketuk tanggal untuk membuka',
                        style: TextStyle(
                          color: tema.teksRedup,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Tutup',
                  child: TekanSkala(
                    onTap: () => Navigator.pop(context),
                    skala: 0.9,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tema.isian,
                        shape: BoxShape.circle,
                        border: Border.all(color: tema.garis),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: tema.teksLembut,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: tema.kartu.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: tema.garisLembut),
                boxShadow: [
                  BoxShadow(
                    color: tema.bayangan,
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _tombolTahun(
                    ikon: Icons.chevron_left_rounded,
                    aktif: _tahun > _tahunAwal,
                    onTap: () => _pindahTahun(-1),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animasi) =>
                              FadeTransition(opacity: animasi, child: child),
                          child: Text(
                            '$_tahun H',
                            key: ValueKey(_tahun),
                            style: TextStyle(
                              color: tema.teks,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _rentangTahunMasehi(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tema.teksRedup,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _tombolTahun(
                    ikon: Icons.chevron_right_rounded,
                    aktif: _tahun < _tahunAkhir,
                    onTap: () => _pindahTahun(1),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _legenda(tema, tema.aksen, 'Dipilih', terisi: true),
                      _legenda(tema, tema.aksen, 'Hari ini'),
                      _legenda(tema, tema.aksen, 'Ada agenda', garis: true),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TekanSkala(
                  onTap: _keHariIni,
                  skala: 0.93,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: tema.aksen.withValues(
                        alpha: tema.gelap ? 0.2 : 0.09,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tema.aksen.withValues(
                          alpha: tema.gelap ? 0.34 : 0.16,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          size: 11,
                          color: tema.aksenTeks,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Hari Ini',
                          style: TextStyle(
                            color: tema.aksenTeks,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _kontroler,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(14, 6, 14, 12 + bawah),
              child: Column(
                children: [
                  for (int bulan = 1; bulan <= 12; bulan++)
                    Padding(
                      key: _kunciBulan[bulan - 1],
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _kartuBulan(tema: tema, bulan: bulan),
                    ),
                  _catatanSumber(tema),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _rentangTahunMasehi() {
    final awal = _awalTahun();
    final akhir = _akhirTahun();
    return '${DateFormat('d MMM yyyy', 'id_ID').format(awal)} – '
        '${DateFormat('d MMM yyyy', 'id_ID').format(akhir)}';
  }

  String _rentangBulan(DateTime awal, DateTime akhir) {
    final awalTeks = DateFormat('d MMM', 'id_ID').format(awal);
    final akhirTeks = DateFormat('d MMM yyyy', 'id_ID').format(akhir);
    return '$awalTeks – $akhirTeks';
  }

  Widget _kartuBulan({required PengaturanWarna tema, required int bulan}) {
    final mulai = HijriCalendar().hijriToGregorian(_tahun, bulan, 1);
    final jumlahHari = HijriCalendar().getDaysInMonth(_tahun, bulan);
    final akhir = mulai.add(Duration(days: jumlahHari - 1));
    final offset = mulai.weekday - 1;

    final sel = <Widget>[
      for (int i = 0; i < offset; i++) const SizedBox.shrink(),
      for (int hari = 1; hari <= jumlahHari; hari++)
        _selHari(
          tema: tema,
          tanggal: mulai.add(Duration(days: hari - 1)),
          hariHijriah: hari,
        ),
    ];

    final baris = <Widget>[];
    for (int i = 0; i < sel.length; i += 7) {
      baris.add(
        Row(
          children: [
            for (int kolom = 0; kolom < 7; kolom++)
              Expanded(
                child: i + kolom < sel.length
                    ? sel[i + kolom]
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: tema.kartu.withValues(alpha: tema.gelap ? 0.9 : 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tema.garisLembut),
        boxShadow: [
          BoxShadow(
            color: tema.bayangan,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    namaBulanHijriah[bulan - 1],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tema.teks,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.35,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_tahun H',
                  style: TextStyle(
                    color: tema.teksRedup,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    _rentangBulan(mulai, akhir),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: tema.teksSamar,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < _namaHari.length; i++)
                Expanded(
                  child: Text(
                    _namaHari[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i >= 5
                          ? tema.aksenTeks.withValues(alpha: 0.85)
                          : tema.teksSamar,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (final r in baris) r,
        ],
      ),
    );
  }

  Widget _selHari({
    required PengaturanWarna tema,
    required DateTime tanggal,
    required int hariHijriah,
  }) {
    final terpilih = _tanggalSama(tanggal, widget.tanggalTerpilih);
    final hariIni = _tanggalSama(tanggal, widget.hariIni);
    final warnaAgenda =
        widget.warnaAgenda[_kunciTanggal(tanggal)] ?? const <Color>[];
    final akhirPekan =
        tanggal.weekday == DateTime.saturday ||
        tanggal.weekday == DateTime.sunday;
    final hariBesar = hariBesarPada(tanggal);
    final warnaCincin = hariBesar == null
        ? null
        : (hariBesar.libur ? tema.liburNasional : tema.peringatanNasional);

    final Color warnaHijriah;
    final Color warnaMasehi;
    if (terpilih) {
      warnaHijriah = tema.diAksen;
      warnaMasehi = tema.diAksen.withValues(alpha: 0.7);
    } else if (hariIni) {
      warnaHijriah = tema.aksenTeks;
      warnaMasehi = tema.teksRedup;
    } else if (akhirPekan) {
      warnaHijriah = tema.aksenTeks.withValues(alpha: 0.9);
      warnaMasehi = tema.teksSamar;
    } else {
      warnaHijriah = tema.teks.withValues(alpha: 0.88);
      warnaMasehi = tema.teksSamar;
    }

    final BoxDecoration? dekorasi;
    if (terpilih) {
      dekorasi = BoxDecoration(
        color: tema.aksen,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: tema.aksen.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );
    } else if (hariIni) {
      dekorasi = BoxDecoration(
        color: tema.aksen.withValues(alpha: tema.gelap ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tema.aksen.withValues(alpha: 0.35)),
      );
    } else {
      dekorasi = null;
    }

    final Widget isi = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 38,
      height: 42,
      decoration: dekorasi,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$hariHijriah',
                style: TextStyle(
                  color: warnaHijriah,
                  fontSize: 12.5,
                  fontWeight: terpilih || hariIni
                      ? FontWeight.w700
                      : FontWeight.w500,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '${tanggal.day}',
                style: TextStyle(
                  color: warnaMasehi,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
          if (warnaAgenda.isNotEmpty)
            Positioned(
              bottom: 3.5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < warnaAgenda.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Container(
                      width: warnaAgenda.length == 1
                          ? 14
                          : warnaAgenda.length == 2
                          ? 9
                          : 6,
                      height: 2.6,
                      decoration: BoxDecoration(
                        color: terpilih
                            ? Color.lerp(warnaAgenda[i], Colors.white, 0.38)!
                            : warnaAgenda[i],
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (terpilih
                                        ? Color.lerp(
                                            warnaAgenda[i],
                                            Colors.white,
                                            0.38,
                                          )!
                                        : warnaAgenda[i])
                                    .withValues(alpha: 0.5),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );

    Widget sel = isi;
    if (warnaCincin != null) {
      sel = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: warnaCincin.withValues(alpha: 0.9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: warnaCincin.withValues(alpha: 0.16),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(child: sel),
      );
    }

    return TekanSkala(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context, tanggal);
      },
      skala: 0.88,
      getar: false,
      child: SizedBox(height: 44, child: Center(child: sel)),
    );
  }

  Widget _catatanSumber(PengaturanWarna tema) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 12, color: tema.teksSamar),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Tanggal Hijriah memakai kalender Umm al-Qura dan dapat '
              'berbeda satu hari dari ketetapan pemerintah.',
              style: TextStyle(
                color: tema.teksSamar,
                fontSize: 9,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legenda(
    PengaturanWarna tema,
    Color warna,
    String label, {
    bool terisi = false,
    bool garis = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (garis)
          Container(
            width: 13,
            height: 2.6,
            decoration: BoxDecoration(
              color: warna,
              borderRadius: BorderRadius.circular(3),
            ),
          )
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: terisi ? warna : Colors.transparent,
              shape: BoxShape.circle,
              border: terisi ? null : Border.all(color: warna, width: 1.3),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: tema.teksSamar,
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _tombolTahun({
    required IconData ikon,
    required bool aktif,
    required VoidCallback onTap,
  }) {
    final tema = widget.tema;
    return TekanSkala(
      onTap: aktif ? onTap : null,
      skala: 0.9,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: aktif
              ? tema.aksen.withValues(alpha: 0.14)
              : tema.isian.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: aktif ? tema.aksen.withValues(alpha: 0.42) : tema.garis,
          ),
        ),
        child: Icon(
          ikon,
          size: 21,
          color: aktif ? tema.aksenTeks : tema.teksSamar,
        ),
      ),
    );
  }
}
