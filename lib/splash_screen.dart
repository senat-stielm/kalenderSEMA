import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pengaturan_warna.dart';

/// Logo ormawa/UKM/UKK yang ditampilkan di layar pembuka.
const List<(String, String)> _logoOrmawa = [
  ('logo_sema', 'Senat Mahasiswa'),
  ('bem', 'BEM'),
  ('hmps_kp', 'HMPS KP'),
  ('ec', 'English Club'),
  ('inteklam', 'Inteklam'),
  ('paduan_suara', 'Paduan Suara'),
  ('pramuka', 'Pramuka'),
  ('tari', 'Tari'),
  ('himalaya', 'Himalaya'),
  ('resimen', 'Resimen Mahasiswa'),
];

const Color _latar1 = Color(0xFF06110C);
const Color _latar2 = Color(0xFF0B2116);
const Color _latar3 = Color(0xFF07130E);
const Color _emas = Color(0xFFD9BC72);
const Color _teksTerang = Color(0xFFF5F1E6);
const Color _teksLembut = Color(0xFFA9C3B2);
const Color _teksSamar = Color(0xFF7E9987);

/// Layar pembuka selama tiga detik. Logo ormawa meluncur seperti bintang
/// berekor lalu berbaris rapi sebelum masuk ke beranda.
class LayarSplash extends StatefulWidget {
  const LayarSplash({super.key, required this.tema, required this.onSelesai});

  final PengaturanWarna tema;
  final VoidCallback onSelesai;

  @override
  State<LayarSplash> createState() => _LayarSplashState();
}

class _LayarSplashState extends State<LayarSplash>
    with TickerProviderStateMixin {
  static const Duration _durasi = Duration(seconds: 3);

  late final AnimationController _terbang = AnimationController(
    vsync: this,
    duration: _durasi,
  );
  late final AnimationController _bintang = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    // Mulai animasi dan hitungan tiga detik setelah frame pertama benar-benar
    // tampil, agar splash tidak terlewat saat proses awal perangkat lambat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final kurangiGerak =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (kurangiGerak) {
        _terbang.value = 1;
        _bintang.value = 0.5;
      } else {
        _terbang.forward();
        _bintang.forward();
      }
      _timer = Timer(_durasi, () {
        if (mounted) widget.onSelesai();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _terbang.dispose();
    _bintang.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _latar1,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_latar1, _latar2, _latar3],
              ),
            ),
          ),
          // Awan cahaya hijau di kanan atas.
          Positioned(
            top: -170,
            right: -150,
            child: IgnorePointer(
              child: Container(
                width: 460,
                height: 460,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.tema.aksen.withValues(alpha: 0.34),
                      widget.tema.aksen.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Cahaya keemasan di kiri bawah.
          Positioned(
            bottom: -200,
            left: -170,
            child: IgnorePointer(
              child: Container(
                width: 460,
                height: 460,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _emas.withValues(alpha: 0.14),
                      _emas.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Taburan bintang.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _bintang,
                builder: (context, _) =>
                    CustomPaint(painter: _LukisBintang(_bintang.value)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  _brand(),
                  const SizedBox(height: 26),
                  _labelOrmawa(),
                  const SizedBox(height: 12),
                  _gridTerbang(),
                  const Spacer(flex: 3),
                  _progresBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brand() {
    final anim = CurvedAnimation(
      parent: _terbang,
      curve: const Interval(0, 0.2, curve: Curves.easeOutCubic),
    );
    final aksen = widget.tema.aksen;
    final aksenGelap = widget.tema.aksenGelap;

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [aksen, aksenGelap],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                boxShadow: [
                  BoxShadow(
                    color: _emas.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: aksen.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: aksen,
                    size: 27,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'OrmaKta',
              style: TextStyle(
                color: _teksTerang,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Kalender Ormawa',
              style: TextStyle(
                color: _teksLembut,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Senat • BEM • HMPS • UKM • UKK',
              style: TextStyle(
                color: _teksSamar,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labelOrmawa() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _terbang,
        curve: const Interval(0.55, 0.72, curve: Curves.easeOut),
      ),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'ORMAWA • UKM • UKK',
              style: TextStyle(
                color: _teksSamar,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
        ],
      ),
    );
  }

  Widget _gridTerbang() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _terbang,
        curve: const Interval(0, 0.06, curve: Curves.easeOut),
      ),
      child: LayoutBuilder(
        builder: (context, batas) {
          final lebar = batas.maxWidth;
          final tile = math.min(60.0, (lebar - 40) / 5);
          final jarak = 10.0;
          final total = 5 * tile + 4 * jarak;
          final kiri = (lebar - total) / 2;
          final tinggi = 2 * tile + jarak;

          return SizedBox(
            width: lebar,
            height: tinggi,
            child: AnimatedBuilder(
              animation: _terbang,
              builder: (context, _) {
                final kepala = <_Kepala>[];
                for (int i = 0; i < _logoOrmawa.length; i++) {
                  final akhir = Offset(
                    kiri + (i % 5) * (tile + jarak) + tile / 2,
                    (i ~/ 5) * (tile + jarak) + tile / 2,
                  );
                  final awal = Offset(
                    akhir.dx - (lebar * 0.95 + 80 + i * 8),
                    tinggi + 90 + (i % 3) * 18,
                  );
                  final kontrol = Offset(
                    (awal.dx + akhir.dx) / 2 + 70,
                    math.min(awal.dy, akhir.dy) - 90,
                  );
                  final mulai = 0.03 + i * 0.028;
                  final t = ((_terbang.value - mulai) / 0.42).clamp(0.0, 1.0);
                  kepala.add(
                    _Kepala(
                      i: i,
                      t: t,
                      awal: awal,
                      kontrol: kontrol,
                      akhir: akhir,
                      ukuran: tile,
                    ),
                  );
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _LukisEkor(kepala)),
                      ),
                    ),
                    for (final k in kepala)
                      Positioned(
                        left: k.posisi.dx - k.ukuran / 2,
                        top: k.posisi.dy - k.ukuran / 2,
                        width: k.ukuran,
                        height: k.ukuran,
                        child: IgnorePointer(child: _kepalaLogo(k)),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _kepalaLogo(_Kepala k) {
    final tileT = ((k.t - 0.12) / 0.88).clamp(0.0, 1.0);
    final skala =
        0.5 + 0.5 * Curves.easeOutBack.transform(tileT).clamp(0.0, 1.0);
    final logo = _logoOrmawa[k.i];

    return Stack(
      alignment: Alignment.center,
      children: [
        // Aura bintang di belakang logo selama meluncur.
        Opacity(
          opacity: (1 - k.t).clamp(0.0, 1.0),
          child: Container(
            width: k.ukuran * 1.05,
            height: k.ukuran * 1.05,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _emas.withValues(alpha: 0.75),
                  _emas.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        // Kartu logo yang tumbuh dari bintang.
        Opacity(
          opacity: tileT,
          child: Transform.scale(
            scale: skala,
            child: Container(
              width: k.ukuran,
              height: k.ukuran,
              padding: EdgeInsets.all(k.ukuran * 0.115),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F5EB),
                borderRadius: BorderRadius.circular(k.ukuran * 0.3),
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: _emas.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  const BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/splash_logo/${logo.$1}.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _progresBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 168,
            height: 4,
            child: AnimatedBuilder(
              animation: _terbang,
              builder: (context, _) {
                return LinearProgressIndicator(
                  value: _terbang.value,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  color: _emas,
                  minHeight: 4,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Menyiapkan kalender…',
          style: TextStyle(
            color: _teksSamar,
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Data posisi satu logo selama animasi.
class _Kepala {
  const _Kepala({
    required this.i,
    required this.t,
    required this.awal,
    required this.kontrol,
    required this.akhir,
    required this.ukuran,
  });

  final int i;
  final double t;
  final Offset awal;
  final Offset kontrol;
  final Offset akhir;
  final double ukuran;

  Offset get posisi {
    final p = Curves.easeOutCubic.transform(t);
    final sisa = 1 - p;
    return Offset(
      sisa * sisa * awal.dx + 2 * sisa * p * kontrol.dx + p * p * akhir.dx,
      sisa * sisa * awal.dy + 2 * sisa * p * kontrol.dy + p * p * akhir.dy,
    );
  }

  Offset posisiPada(double nilai) {
    final p = Curves.easeOutCubic.transform(nilai.clamp(0.0, 1.0));
    final sisa = 1 - p;
    return Offset(
      sisa * sisa * awal.dx + 2 * sisa * p * kontrol.dx + p * p * akhir.dx,
      sisa * sisa * awal.dy + 2 * sisa * p * kontrol.dy + p * p * akhir.dy,
    );
  }
}

/// Menggambar ekor bintang di belakang logo yang sedang meluncur.
class _LukisEkor extends CustomPainter {
  _LukisEkor(this.kepala);

  final List<_Kepala> kepala;

  @override
  void paint(Canvas canvas, Size size) {
    for (final k in kepala) {
      if (k.t <= 0.015 || k.t >= 0.999) continue;
      final redup = (1 - k.t * 0.5).clamp(0.0, 1.0);
      for (int j = 1; j <= 22; j++) {
        final tt = k.t - j * 0.016;
        if (tt <= 0) break;
        final f = 1 - j / 22;
        final cat = Paint()
          ..color = _emas.withValues(alpha: 0.6 * f * redup)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2);
        canvas.drawCircle(k.posisiPada(tt), 1.4 + 5.6 * f, cat);
      }
      // Inti ekor yang lebih terang tepat di belakang logo.
      final ekor = Paint()
        ..color = const Color(0xFFFFF2C8).withValues(alpha: 0.55 * redup)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
      canvas.drawLine(k.posisiPada(k.t - 0.03), k.posisiPada(k.t), ekor);
    }
  }

  @override
  bool shouldRepaint(covariant _LukisEkor oldDelegate) => true;
}

/// Taburan bintang latar belakang.
class _LukisBintang extends CustomPainter {
  _LukisBintang(this.fase);

  final double fase;

  @override
  void paint(Canvas canvas, Size size) {
    final acak = math.Random(17);
    final cat = Paint();
    for (int i = 0; i < 90; i++) {
      final x = acak.nextDouble() * size.width;
      final y = acak.nextDouble() * size.height;
      final r = 0.4 + acak.nextDouble() * 1.15;
      final geser = acak.nextDouble() * math.pi * 2;
      final kedip = 0.5 + 0.5 * math.sin(fase * math.pi * 2 + geser);
      cat.color = Colors.white.withValues(alpha: 0.14 + 0.4 * kedip);
      canvas.drawCircle(Offset(x, y), r, cat);
    }

    // Beberapa bintang keemasan yang lebih menonjol.
    for (final titik in const [
      Offset(0.16, 0.16),
      Offset(0.82, 0.28),
      Offset(0.72, 0.74),
      Offset(0.24, 0.82),
    ]) {
      final p = Offset(titik.dx * size.width, titik.dy * size.height);
      final kilau = Paint()
        ..color = _emas.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(p, 2.2, kilau);
      canvas.drawCircle(p, 1.1, Paint()..color = const Color(0xFFFFF2C8));
    }
  }

  @override
  bool shouldRepaint(covariant _LukisBintang oldDelegate) =>
      oldDelegate.fase != fase;
}
