import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'gaya_iphone.dart';
import 'kalender_hijriah.dart';
import 'pengaturan_warna.dart';

/// Satu kegiatan yang akan ditampilkan pada pop-up pengingat H-1.
class PengingatAgenda {
  const PengingatAgenda({
    required this.judul,
    required this.keterangan,
    required this.warna,
    required this.ikon,
  });

  final String judul;
  final String keterangan;
  final Color warna;
  final IconData ikon;
}

/// Menampilkan pengingat H-1 bergaya komik: karakter dari sudut kiri bawah
/// dengan gelembung bicara di sisi kanan. Bisa ditutup lewat tombol silang,
/// tombol "Oke, siap!", atau ketukan di area kosong.
Future<void> tampilkanPengingatH1(
  BuildContext context, {
  required PengaturanWarna tema,
  required DateTime tanggalBesok,
  required List<PengingatAgenda> agenda,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup pengingat H-1',
    barrierColor: Colors.black.withValues(alpha: tema.gelap ? 0.68 : 0.46),
    transitionDuration: Duration.zero,
    pageBuilder: (context, _, _) =>
        _PengingatH1(tema: tema, tanggalBesok: tanggalBesok, agenda: agenda),
  );
}

class _PengingatH1 extends StatefulWidget {
  const _PengingatH1({
    required this.tema,
    required this.tanggalBesok,
    required this.agenda,
  });

  final PengaturanWarna tema;
  final DateTime tanggalBesok;
  final List<PengingatAgenda> agenda;

  @override
  State<_PengingatH1> createState() => _PengingatH1State();
}

class _PengingatH1State extends State<_PengingatH1>
    with TickerProviderStateMixin {
  static const double _rasioWidya = 0.712;

  late final AnimationController _masuk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );
  late final AnimationController _apung = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  late final Animation<double> _animKarakter = CurvedAnimation(
    parent: _masuk,
    curve: const Interval(0, 0.62, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _animGelembung = CurvedAnimation(
    parent: _masuk,
    curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _skalaGelembung =
      Tween<double>(begin: 0.88, end: 1).animate(
        CurvedAnimation(
          parent: _masuk,
          curve: const Interval(0.3, 1, curve: Curves.easeOutBack),
        ),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final kurangiGerak =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (kurangiGerak) {
      _masuk.value = 1;
      if (_apung.isAnimating) _apung.stop();
    } else {
      if (_masuk.status == AnimationStatus.dismissed) _masuk.forward();
      if (!_apung.isAnimating) _apung.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _masuk.dispose();
    _apung.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;
    final atas = MediaQuery.viewPaddingOf(context).top;

    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, batas) {
          final lebar = batas.maxWidth;
          final tinggi = batas.maxHeight;
          final lebarKarakter = math.min(lebar * 0.92, 420.0);
          final tinggiKarakter = lebarKarakter / _rasioWidya;
          final lebarGelembung = math.min(lebar * 0.6, 272.0);

          return Stack(
            children: [
              // Cahaya hijau lembut di belakang karakter.
              Positioned(
                left: -lebar * 0.2,
                bottom: -tinggi * 0.08,
                child: IgnorePointer(
                  child: Container(
                    width: lebar * 0.85,
                    height: tinggi * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          tema.aksen.withValues(alpha: tema.gelap ? 0.4 : 0.32),
                          tema.aksen.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Karakter muncul dari sisi kiri bawah.
              Positioned(
                left: -lebar * 0.05,
                bottom: -12,
                width: lebarKarakter,
                height: tinggiKarakter,
                child: FadeTransition(
                  opacity: _animKarakter,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-0.15, 0.28),
                      end: Offset.zero,
                    ).animate(_animKarakter),
                    child: AnimatedBuilder(
                      animation: _apung,
                      builder: (context, child) {
                        final geser = math.sin(_apung.value * math.pi * 2) * 6;
                        return Transform.translate(
                          offset: Offset(0, geser),
                          child: child,
                        );
                      },
                      child: Image.asset(
                        'assets/widya_transparan.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              // Tombol tutup tanpa bingkai kartu.
              Positioned(
                top: atas + 10,
                right: 14,
                child: FadeTransition(
                  opacity: _animKarakter,
                  child: Tooltip(
                    message: 'Tutup pengingat',
                    child: TekanSkala(
                      onTap: () => Navigator.pop(context),
                      skala: 0.88,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: tema.kartu.withValues(alpha: 0.94),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: tema.teks,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Gelembung bicara.
              Positioned(
                top: math.max(atas + 62, tinggi * 0.13),
                right: 14,
                width: lebarGelembung,
                child: FadeTransition(
                  opacity: _animGelembung,
                  child: ScaleTransition(
                    scale: _skalaGelembung,
                    alignment: Alignment.bottomLeft,
                    child: _gelembung(tema),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _gelembung(PengaturanWarna tema) {
    final tanggalTeks = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(widget.tanggalBesok);
    final hijriahTeks = tanggalHijriah(widget.tanggalBesok);
    final tampil = widget.agenda.take(3).toList();
    final sisa = widget.agenda.length - tampil.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: tema.kartu,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: tema.gelap ? 0.42 : 0.24),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    size: 12,
                    color: tema.aksenTeks,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'PENGINGAT H-1',
                    style: TextStyle(
                      color: tema.aksenTeks,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Besok ada agenda!',
                style: TextStyle(
                  color: tema.teks,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                tanggalTeks,
                style: TextStyle(
                  color: tema.teksRedup,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              if (hijriahTeks.isNotEmpty)
                Text(
                  hijriahTeks,
                  style: TextStyle(
                    color: tema.teksSamar,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 10),
              for (final item in tampil) _barisAgenda(tema, item),
              if (sisa > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '+$sisa kegiatan lainnya besok',
                    style: TextStyle(
                      color: tema.teksRedup,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Oke, siap!'),
                ),
              ),
            ],
          ),
        ),
        // Ekor gelembung mengarah ke karakter.
        Positioned(
          left: 22,
          bottom: -8,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: tema.kartu,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _barisAgenda(PengaturanWarna tema, PengingatAgenda item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: item.warna,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tema.teks,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
                if (item.keterangan.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    item.keterangan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tema.teksRedup,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
