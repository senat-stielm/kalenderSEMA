import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gaya_iphone.dart';
import 'hari_besar.dart';
import 'pengaturan_warna.dart';

const List<String> _namaBulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> _singkatHari = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

const int _tahunAwal = 2025;
const int _tahunAkhir = 2030;

String _kunciTanggal(DateTime tanggal) {
  final bulan = tanggal.month.toString().padLeft(2, '0');
  final hari = tanggal.day.toString().padLeft(2, '0');
  return '${tanggal.year}-$bulan-$hari';
}

/// Menampilkan lembar kalender satu tahun penuh. Mengembalikan tanggal yang
/// dipilih, atau `null` jika lembar ditutup tanpa memilih.
Future<DateTime?> tampilkanKalenderTahunan(
  BuildContext context, {
  required PengaturanWarna tema,
  required DateTime tanggalTerpilih,
  required DateTime hariIni,
  required Set<String> tanggalBeragenda,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: tema.gelap ? 0.62 : 0.42),
    builder: (_) => _LembarKalenderTahunan(
      tema: tema,
      tanggalTerpilih: tanggalTerpilih,
      hariIni: hariIni,
      tanggalBeragenda: tanggalBeragenda,
    ),
  );
}

class _LembarKalenderTahunan extends StatefulWidget {
  const _LembarKalenderTahunan({
    required this.tema,
    required this.tanggalTerpilih,
    required this.hariIni,
    required this.tanggalBeragenda,
  });

  final PengaturanWarna tema;
  final DateTime tanggalTerpilih;
  final DateTime hariIni;
  final Set<String> tanggalBeragenda;

  @override
  State<_LembarKalenderTahunan> createState() => _LembarKalenderTahunanState();
}

class _LembarKalenderTahunanState extends State<_LembarKalenderTahunan> {
  late int _tahun;
  ScrollController? _kontroler;

  @override
  void initState() {
    super.initState();
    _tahun = widget.tanggalTerpilih.year.clamp(_tahunAwal, _tahunAkhir);
  }

  @override
  void dispose() {
    _kontroler?.dispose();
    super.dispose();
  }

  void _pindahTahun(int selisih) {
    final baru = (_tahun + selisih).clamp(_tahunAwal, _tahunAkhir);
    if (baru == _tahun) return;
    HapticFeedback.selectionClick();
    setState(() => _tahun = baru);
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;
    final tinggiLayar = MediaQuery.sizeOf(context).height;
    final bawah = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      height: tinggiLayar * 0.9,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: tema.gelap
              ? [const Color(0xFF171922), const Color(0xFF0A0B11)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF2F6FD)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: tema.gelap ? 0.14 : 0.7),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: tema.gelap ? 0.6 : 0.18),
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
              color: tema.gelap
                  ? Colors.white.withValues(alpha: 0.22)
                  : const Color(0x33101828),
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
                    Icons.calendar_view_month_rounded,
                    color: tema.diAksen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kalender Tahunan',
                        style: TextStyle(
                          color: tema.teks,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ketuk tanggal untuk membuka',
                        style: TextStyle(
                          color: tema.teksRedup,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                TekanSkala(
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: tema.gelap
                      ? [
                          Colors.white.withValues(alpha: 0.09),
                          Colors.white.withValues(alpha: 0.03),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          Colors.white.withValues(alpha: 0.6),
                        ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: tema.garis),
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
                    tema: tema,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animasi) => FadeTransition(
                        opacity: animasi,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.94,
                            end: 1,
                          ).animate(animasi),
                          child: child,
                        ),
                      ),
                      child: Text(
                        '$_tahun',
                        key: ValueKey(_tahun),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: tema.teks,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                  ),
                  _tombolTahun(
                    ikon: Icons.chevron_right_rounded,
                    aktif: _tahun < _tahunAkhir,
                    onTap: () => _pindahTahun(1),
                    tema: tema,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _legenda(tema, tema.aksen, 'Dipilih', terisi: true),
                _legenda(tema, tema.aksen, 'Hari ini', terisi: false),
                _legenda(tema, tema.aksen, 'Ada agenda', titik: true),
                _legenda(tema, tema.liburNasional, 'Hari besar'),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, batasan) {
                final lebarIsi = batasan.maxWidth - 32;
                final kolom = lebarIsi < 430 ? 2 : 3;
                const spasi = 10.0;
                final lebarKartu = (lebarIsi - spasi * (kolom - 1)) / kolom;
                // Ruang untuk nama bulan, baris hari, dan enam baris tanggal.
                final tinggiKartu = lebarKartu * 1.08;

                if (_kontroler == null) {
                  // Mulai dari baris yang memuat bulan terpilih.
                  final baris = (widget.tanggalTerpilih.month - 1) ~/ kolom;
                  final lompat =
                      baris * (tinggiKartu + spasi) - batasan.maxHeight * 0.12;
                  _kontroler = ScrollController(
                    initialScrollOffset: lompat < 0 ? 0 : lompat,
                  );
                }

                return GridView.builder(
                  controller: _kontroler,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: kolom,
                    crossAxisSpacing: spasi,
                    mainAxisSpacing: spasi,
                    childAspectRatio: lebarKartu / tinggiKartu,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    return _BulanMini(
                      tahun: _tahun,
                      bulan: index + 1,
                      tema: tema,
                      tanggalTerpilih: widget.tanggalTerpilih,
                      hariIni: widget.hariIni,
                      tanggalBeragenda: widget.tanggalBeragenda,
                      onPilih: (tanggal) => Navigator.pop(context, tanggal),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: 6 + bawah),
        ],
      ),
    );
  }

  Widget _legenda(
    PengaturanWarna tema,
    Color warna,
    String label, {
    bool terisi = false,
    bool titik = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (titik)
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
          )
        else
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: terisi ? warna : Colors.transparent,
              shape: BoxShape.circle,
              border: terisi ? null : Border.all(color: warna, width: 1.3),
            ),
          ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: tema.teksSamar,
            fontSize: 9.5,
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
    required PengaturanWarna tema,
  }) {
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

class _BulanMini extends StatelessWidget {
  const _BulanMini({
    required this.tahun,
    required this.bulan,
    required this.tema,
    required this.tanggalTerpilih,
    required this.hariIni,
    required this.tanggalBeragenda,
    required this.onPilih,
  });

  final int tahun;
  final int bulan;
  final PengaturanWarna tema;
  final DateTime tanggalTerpilih;
  final DateTime hariIni;
  final Set<String> tanggalBeragenda;
  final ValueChanged<DateTime> onPilih;

  @override
  Widget build(BuildContext context) {
    final hariPertama = DateTime(tahun, bulan, 1);
    final jumlahHari = DateTime(tahun, bulan + 1, 0).day;
    final offset = hariPertama.weekday - 1;
    final jumlahBaris = ((offset + jumlahHari) / 7).ceil();

    final bulanTerpilih =
        tanggalTerpilih.year == tahun && tanggalTerpilih.month == bulan;
    final awalanBulan = '$tahun-${bulan.toString().padLeft(2, '0')}-';
    final adaAgendaBulan = tanggalBeragenda.any(
      (kunci) => kunci.startsWith(awalanBulan),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(9, 9, 9, 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tema.gelap
              ? [
                  Colors.white.withValues(alpha: bulanTerpilih ? 0.11 : 0.06),
                  Colors.white.withValues(alpha: bulanTerpilih ? 0.04 : 0.015),
                ]
              : [
                  Colors.white,
                  bulanTerpilih
                      ? tema.aksen.withValues(alpha: 0.07)
                      : const Color(0xFFF7FAFF),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: bulanTerpilih
              ? tema.aksen.withValues(alpha: 0.45)
              : tema.garisLembut,
          width: bulanTerpilih ? 1.2 : 1,
        ),
        boxShadow: tema.gelap
            ? null
            : [
                BoxShadow(
                  color: tema.bayanganLembut,
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _namaBulan[bulan - 1],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: bulanTerpilih ? tema.aksenTeks : tema.teks,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (adaAgendaBulan)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tema.aksen,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: _singkatHari
                .map(
                  (hari) => Expanded(
                    child: Text(
                      hari,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tema.teksSamar,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 1),
          ...List.generate(jumlahBaris, (baris) {
            return Expanded(
              child: Row(
                children: List.generate(7, (kolom) {
                  final indeks = baris * 7 + kolom;
                  final nomorHari = indeks - offset + 1;
                  if (nomorHari < 1 || nomorHari > jumlahHari) {
                    return const Expanded(child: SizedBox());
                  }
                  final tanggal = DateTime(tahun, bulan, nomorHari);
                  return Expanded(
                    child: _SelHari(
                      tanggal: tanggal,
                      tema: tema,
                      terpilih: _samaHari(tanggal, tanggalTerpilih),
                      hariIni: _samaHari(tanggal, hariIni),
                      adaAgenda: tanggalBeragenda.contains(
                        _kunciTanggal(tanggal),
                      ),
                      onPilih: onPilih,
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  static bool _samaHari(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _SelHari extends StatelessWidget {
  const _SelHari({
    required this.tanggal,
    required this.tema,
    required this.terpilih,
    required this.hariIni,
    required this.adaAgenda,
    required this.onPilih,
  });

  final DateTime tanggal;
  final PengaturanWarna tema;
  final bool terpilih;
  final bool hariIni;
  final bool adaAgenda;
  final ValueChanged<DateTime> onPilih;

  @override
  Widget build(BuildContext context) {
    final hariBesar = hariBesarPada(tanggal);
    final warnaCincin = hariBesar == null
        ? null
        : (hariBesar.libur ? tema.liburNasional : tema.peringatanNasional);
    final warnaTeks = terpilih
        ? tema.diAksen
        : (warnaCincin ?? (hariIni ? tema.aksenTeks : tema.teksLembut));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onPilih(tanggal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 19,
            height: 19,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: terpilih
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [tema.aksen, tema.aksenGelap],
                    )
                  : null,
              color: terpilih ? null : Colors.transparent,
              shape: BoxShape.circle,
              border: warnaCincin != null
                  ? Border.all(color: warnaCincin.withValues(alpha: 0.9))
                  : (hariIni && !terpilih
                        ? Border.all(color: tema.aksen, width: 1.2)
                        : null),
              boxShadow: terpilih
                  ? [
                      BoxShadow(
                        color: tema.aksen.withValues(alpha: 0.4),
                        blurRadius: 7,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '${tanggal.day}',
              style: TextStyle(
                color: warnaTeks,
                fontSize: 9,
                height: 1.1,
                fontWeight: terpilih || hariIni
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: adaAgenda
                  ? (terpilih ? tema.diAksen : tema.aksen)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
