import 'package:flutter/material.dart';

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

/// Menampilkan dialog kalender satu tahun penuh. Mengembalikan tanggal yang
/// dipilih, atau `null` jika dialog ditutup tanpa memilih.
Future<DateTime?> tampilkanKalenderTahunan(
  BuildContext context, {
  required PengaturanWarna tema,
  required DateTime tanggalTerpilih,
  required DateTime hariIni,
  required Set<String> tanggalBeragenda,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _DialogKalenderTahunan(
      tema: tema,
      tanggalTerpilih: tanggalTerpilih,
      hariIni: hariIni,
      tanggalBeragenda: tanggalBeragenda,
    ),
  );
}

class _DialogKalenderTahunan extends StatefulWidget {
  const _DialogKalenderTahunan({
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
  State<_DialogKalenderTahunan> createState() => _DialogKalenderTahunanState();
}

class _DialogKalenderTahunanState extends State<_DialogKalenderTahunan> {
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
    if (baru != _tahun) setState(() => _tahun = baru);
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;
    final tinggi = MediaQuery.sizeOf(context).height * 0.72;

    return AlertDialog(
      backgroundColor: tema.kartu,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: tema.aksen.withValues(alpha: 0.6), width: 1.5),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [tema.aksen, tema.aksenGelap]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_view_month_rounded,
              color: tema.latar1,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Kalender Tahunan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: tinggi,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tombolTahun(
                  ikon: Icons.chevron_left_rounded,
                  aktif: _tahun > _tahunAwal,
                  onTap: () => _pindahTahun(-1),
                  tema: tema,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$_tahun',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Ketuk tanggal untuk membuka',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: tema.aksen,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, batasan) {
                  final kolom = batasan.maxWidth < 430 ? 2 : 3;
                  if (_kontroler == null) {
                    // Mulai dari baris yang memuat bulan terpilih.
                    const spasi = 8.0;
                    final lebarSel =
                        (batasan.maxWidth - spasi * (kolom - 1)) / kolom;
                    final tinggiSel = lebarSel / 0.82;
                    final baris = (widget.tanggalTerpilih.month - 1) ~/ kolom;
                    _kontroler = ScrollController(
                      initialScrollOffset: baris * (tinggiSel + spasi),
                    );
                  }

                  // Seluruh bulan dibangun sekaligus agar bulan yang sedang
                  // dipilih bisa langsung digulir ke layar saat dialog dibuka.
                  return GridView.count(
                    controller: _kontroler,
                    padding: const EdgeInsets.only(bottom: 8),
                    crossAxisCount: kolom,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.82,
                    children: List.generate(12, (index) {
                      return _BulanMini(
                        tahun: _tahun,
                        bulan: index + 1,
                        tema: tema,
                        tanggalTerpilih: widget.tanggalTerpilih,
                        hariIni: widget.hariIni,
                        tanggalBeragenda: widget.tanggalBeragenda,
                        onPilih: (tanggal) => Navigator.pop(context, tanggal),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup', style: TextStyle(color: Colors.white60)),
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
    return InkWell(
      onTap: aktif ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: aktif ? 0.1 : 0.03),
          shape: BoxShape.circle,
          border: Border.all(
            color: aktif ? tema.aksen.withValues(alpha: 0.5) : Colors.white12,
          ),
        ),
        child: Icon(ikon, size: 20, color: aktif ? tema.aksen : Colors.white24),
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

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            _namaBulan[bulan - 1],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tema.aksen,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: _singkatHari
                .map(
                  (hari) => Expanded(
                    child: Text(
                      hari,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
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
                  return Expanded(
                    child: _SelHari(
                      tanggal: DateTime(tahun, bulan, nomorHari),
                      tema: tema,
                      terpilih: _samaHari(
                        DateTime(tahun, bulan, nomorHari),
                        tanggalTerpilih,
                      ),
                      hariIni: _samaHari(
                        DateTime(tahun, bulan, nomorHari),
                        hariIni,
                      ),
                      adaAgenda: tanggalBeragenda.contains(
                        _kunciTanggal(DateTime(tahun, bulan, nomorHari)),
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
    final warnaTeks = terpilih
        ? tema.latar1
        : (hariIni ? tema.aksen : Colors.white70);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onPilih(tanggal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: terpilih ? tema.aksen : Colors.transparent,
              shape: BoxShape.circle,
              border: hariIni && !terpilih
                  ? Border.all(color: tema.aksen, width: 1)
                  : null,
            ),
            child: Text(
              '${tanggal.day}',
              style: TextStyle(
                color: warnaTeks,
                fontSize: 9.5,
                fontWeight: terpilih || hariIni
                    ? FontWeight.w900
                    : FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 4,
            child: adaAgenda
                ? Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: terpilih ? tema.latar1 : tema.aksen,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
