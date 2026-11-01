import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pengaturan_warna.dart';

/// Warna ormawa yang tetap terbaca saat dipakai sebagai teks di atas latar
/// terang; di mode gelap warna aslinya dipakai.
Color warnaTeksOrmawa(Color dasar, PengaturanWarna tema) =>
    tema.gelap ? dasar : Color.lerp(dasar, Colors.black, 0.3)!;

/// Warna teks/ikon yang kontras di atas blok warna [dasar].
Color warnaDiAtas(Color dasar) =>
    ThemeData.estimateBrightnessForColor(dasar) == Brightness.dark
    ? Colors.white
    : const Color(0xFF0B1220);

/// Keluarga font tunggal aplikasi.
const String fontUtama = 'Poppins';

const Duration _durasiSedang = Duration(milliseconds: 280);
const Curve _kurvaLembut = Curves.easeOutCubic;

/// Perilaku gulir bergaya iOS: memantul di ujung dan bisa diseret dengan
/// mouse/trackpad di web.
class PerilakuGulirIphone extends MaterialScrollBehavior {
  const PerilakuGulirIphone();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

/// Tema global bergaya iOS dengan font Poppins.
ThemeData buatTemaIphone(PengaturanWarna tema) {
  final kecerahan = tema.gelap ? Brightness.dark : Brightness.light;
  final skema = ColorScheme.fromSeed(
    seedColor: tema.aksen,
    brightness: kecerahan,
  ).copyWith(
    primary: tema.aksen,
    secondary: tema.sekunder,
    surface: tema.kartu,
    onSurface: tema.teks,
    onPrimary: tema.diAksen,
    surfaceContainerHighest: Color.alphaBlend(tema.isian, tema.kartu),
  );

  final dasar = ThemeData(
    useMaterial3: true,
    brightness: kecerahan,
    fontFamily: fontUtama,
    scaffoldBackgroundColor: tema.latar1,
    colorScheme: skema,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: tema.teks.withValues(alpha: 0.04),
    visualDensity: VisualDensity.standard,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  final teks = dasar.textTheme.apply(
    fontFamily: fontUtama,
    bodyColor: tema.teks,
    displayColor: tema.teks,
  );

  return dasar.copyWith(
    textTheme: teks.copyWith(
      displayLarge: teks.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.6,
      ),
      displayMedium: teks.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      headlineLarge: teks.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineMedium: teks.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineSmall: teks.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleLarge: teks.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: teks.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleSmall: teks.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: teks.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodyMedium: teks.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodySmall: teks.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: teks.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: teks.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      labelSmall: teks.labelSmall?.copyWith(fontWeight: FontWeight.w500),
    ),
    iconTheme: IconThemeData(color: tema.teksLembut),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tema.isian,
      labelStyle: TextStyle(color: tema.teksLembut, fontSize: 13),
      hintStyle: TextStyle(color: tema.teksSamar, fontSize: 13),
      helperStyle: TextStyle(color: tema.teksRedup, fontSize: 11),
      errorStyle: TextStyle(color: tema.peringatan, fontSize: 11),
      prefixIconColor: tema.teksRedup,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tema.garis),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tema.garis),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tema.aksen, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tema.peringatan),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tema.peringatan, width: 1.6),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tema.kartu,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      titleTextStyle: TextStyle(
        fontFamily: fontUtama,
        color: tema.teks,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      contentTextStyle: TextStyle(
        fontFamily: fontUtama,
        color: tema.teksLembut,
        fontSize: 13,
        height: 1.5,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      modalBackgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tema.kartu,
      contentTextStyle: TextStyle(
        fontFamily: fontUtama,
        color: tema.teks,
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tema.aksen,
        foregroundColor: tema.diAksen,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: fontUtama,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tema.aksen,
        foregroundColor: tema.diAksen,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: fontUtama,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tema.teksLembut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: fontUtama,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tema.aksen,
        side: BorderSide(color: tema.aksen.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: fontUtama,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: tema.aksen,
      foregroundColor: tema.diAksen,
      elevation: 0,
      highlightElevation: 0,
      shape: const StadiumBorder(),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: tema.aksen,
      linearTrackColor: tema.garis,
    ),
    dividerTheme: DividerThemeData(
      color: tema.garisLembut,
      thickness: 1,
      space: 1,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tema.kartu.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tema.garis),
      ),
      textStyle: TextStyle(
        fontFamily: fontUtama,
        color: tema.teks,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

/// Latar belakang dinamis: gradien tema dengan cahaya lembut yang bergerak
/// perlahan, memberi kesan hidup tanpa membebani perangkat.
class LatarAurora extends StatefulWidget {
  const LatarAurora({super.key, required this.tema, required this.child});

  final PengaturanWarna tema;
  final Widget child;

  @override
  State<LatarAurora> createState() => _LatarAuroraState();
}

class _LatarAuroraState extends State<LatarAurora>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gerak = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hormati pengaturan "kurangi gerak" perangkat. Ini juga membuat animasi
    // latar berhenti saat pengujian sehingga antarmuka bisa stabil.
    final kurangiGerak =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (kurangiGerak) {
      if (_gerak.isAnimating) _gerak.stop();
    } else if (!_gerak.isAnimating) {
      _gerak.repeat();
    }
  }

  @override
  void dispose() {
    _gerak.dispose();
    super.dispose();
  }

  Widget _cahaya(double ukuran, Color warna) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [warna, warna.withValues(alpha: 0)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tema.latar1, tema.latar2, tema.latar3],
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gerak,
              builder: (context, _) {
                final a = _gerak.value * math.pi * 2;
                return Stack(
                  children: [
                    Positioned(
                      top: -170 + math.sin(a) * 26,
                      right: -110 + math.cos(a) * 30,
                      child: _cahaya(
                        400,
                        (tema.gelap ? tema.sekunder : tema.aksen).withValues(
                          alpha: tema.gelap ? 0.13 : 0.16,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20 + math.cos(a) * 34,
                      left: -170 + math.sin(a) * 28,
                      child: _cahaya(
                        440,
                        tema.gelap
                            ? const Color(0xFF6366F1).withValues(alpha: 0.10)
                            : tema.sekunder.withValues(alpha: 0.13),
                      ),
                    ),
                    Positioned(
                      top: 260 + math.sin(a + 1.4) * 22,
                      right: -190 + math.cos(a + 0.8) * 24,
                      child: _cahaya(
                        340,
                        tema.gelap
                            ? tema.sekunder.withValues(alpha: 0.05)
                            : tema.aksenGelap.withValues(alpha: 0.09),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Vignette halus agar konten tetap terbaca.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.25,
                colors: [
                  Colors.transparent,
                  tema.gelap
                      ? Colors.black.withValues(alpha: 0.46)
                      : Colors.white.withValues(alpha: 0.22),
                ],
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// Latar krem hangat dengan bentuk organik hijau-kuning di sudut kanan atas,
/// sesuai desain "Kalender Ormawa". Tetap menyesuaikan diri saat pengguna
/// memilih warna aksen lain atau mode gelap.
class LatarHangat extends StatelessWidget {
  const LatarHangat({super.key, required this.tema, required this.child});

  final PengaturanWarna tema;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final terang = !tema.gelap;
    final hijau = tema.aksen;
    final limau = tema.sekunder;
    final emas = Color.lerp(tema.aksen, const Color(0xFFF0D57F), 0.68)!;

    Widget gumpalan({
      required double lebar,
      required double tinggi,
      required List<Color> warna,
    }) {
      return Container(
        width: lebar,
        height: tinggi,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.elliptical(lebar / 2, tinggi / 2),
          ),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: warna,
          ),
        ),
      );
    }

    Widget cahaya(double ukuran, Color warna) {
      return Container(
        width: ukuran,
        height: ukuran,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [warna, warna.withValues(alpha: 0)],
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: terang
                    ? [tema.latar1, tema.latar2, tema.latar3]
                    : const [
                        Color(0xFF070C09),
                        Color(0xFF0A110C),
                        Color(0xFF0E1711),
                      ],
              ),
            ),
          ),
          // Bentuk organik hijau-kuning yang tumpah dari sudut kanan atas.
          Positioned(
            top: -172,
            right: -124,
            child: Transform.rotate(
              angle: 0.42,
              child: Opacity(
                opacity: terang ? 0.62 : 0.16,
                child: gumpalan(
                  lebar: 330,
                  tinggi: 280,
                  warna: [emas, limau, hijau],
                ),
              ),
            ),
          ),
          Positioned(
            top: -86,
            right: -46,
            child: Transform.rotate(
              angle: -0.3,
              child: Opacity(
                opacity: terang ? 0.5 : 0.1,
                child: gumpalan(
                  lebar: 170,
                  tinggi: 150,
                  warna: [const Color(0xFFF8EDC8), limau],
                ),
              ),
            ),
          ),
          // Cahaya hijau lembut di kiri bawah.
          Positioned(
            bottom: -190,
            left: -170,
            child: cahaya(
              400,
              hijau.withValues(alpha: terang ? 0.14 : 0.16),
            ),
          ),
          // Sentuhan keemasan hangat di kanan bawah.
          Positioned(
            bottom: -120,
            right: -160,
            child: cahaya(
              380,
              emas.withValues(alpha: terang ? 0.2 : 0.05),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Panel kaca (glassmorphism) dengan blur latar, garis tepi tipis, dan
/// bayangan lembut.
class Kaca extends StatelessWidget {
  const Kaca({
    super.key,
    required this.child,
    this.radius = 26,
    this.blur = 18,
    this.padding,
    this.color,
    this.gradient,
    this.borderColor,
    this.shadow,
    this.borderWidth = 1,
  });

  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return Container(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color,
              gradient: gradient,
              borderRadius: borderRadius,
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.12),
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Membungkus anak dengan animasi membesar/mengecil saat ditekan, lengkap
/// dengan getaran halus seperti tombol iOS.
class TekanSkala extends StatefulWidget {
  const TekanSkala({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.skala = 0.94,
    this.getar = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double skala;
  final bool getar;

  @override
  State<TekanSkala> createState() => _TekanSkalaState();
}

class _TekanSkalaState extends State<TekanSkala> {
  bool _ditekan = false;

  bool get _aktif => widget.onTap != null || widget.onLongPress != null;

  void _ubahTekan(bool nilai) {
    if (!_aktif || _ditekan == nilai) return;
    setState(() => _ditekan = nilai);
    if (nilai && widget.getar) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _aktif ? (_) => _ubahTekan(true) : null,
      onTapUp: _aktif ? (_) => _ubahTekan(false) : null,
      onTapCancel: _aktif ? () => _ubahTekan(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.getar) HapticFeedback.mediumImpact();
              widget.onLongPress!();
            },
      child: AnimatedScale(
        scale: _ditekan ? widget.skala : 1,
        duration: const Duration(milliseconds: 150),
        curve: _kurvaLembut,
        child: widget.child,
      ),
    );
  }
}

/// Animasi masuk: memudar sambil naik perlahan.
class AnimasiMuncul extends StatefulWidget {
  const AnimasiMuncul({
    super.key,
    required this.child,
    this.tunda = Duration.zero,
    this.durasi = const Duration(milliseconds: 460),
    this.jarak = 0.07,
  });

  final Widget child;
  final Duration tunda;
  final Duration durasi;

  /// Pergeseran awal sebagai pecahan tinggi anak.
  final double jarak;

  @override
  State<AnimasiMuncul> createState() => _AnimasiMunculState();
}

class _AnimasiMunculState extends State<AnimasiMuncul> {
  bool _tampil = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.tunda == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _tampil = true);
      });
    } else {
      _timer = Timer(widget.tunda, () {
        if (mounted) setState(() => _tampil = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _tampil ? 1 : 0,
      duration: widget.durasi,
      curve: _kurvaLembut,
      child: AnimatedSlide(
        offset: _tampil ? Offset.zero : Offset(0, widget.jarak),
        duration: widget.durasi,
        curve: _kurvaLembut,
        child: widget.child,
      ),
    );
  }
}

/// Teks dengan gradien warna.
class TeksGradien extends StatelessWidget {
  const TeksGradien({
    super.key,
    required this.teks,
    required this.gaya,
    required this.warna,
  });

  final String teks;
  final TextStyle gaya;
  final List<Color> warna;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (batas) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: warna,
      ).createShader(batas),
      child: Text(
        teks,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: gaya.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Tombol ikon berbentuk squircle dengan efek kaca.
class TombolIkonKaca extends StatelessWidget {
  const TombolIkonKaca({
    super.key,
    required this.ikon,
    required this.tema,
    this.tooltip,
    this.onTap,
    this.aktif = false,
    this.ukuran = 38,
  });

  final IconData ikon;
  final PengaturanWarna tema;
  final String? tooltip;
  final VoidCallback? onTap;
  final bool aktif;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    final tombol = TekanSkala(
      onTap: onTap,
      skala: 0.9,
      child: AnimatedContainer(
        duration: _durasiSedang,
        curve: _kurvaLembut,
        width: ukuran,
        height: ukuran,
        decoration: BoxDecoration(
          color: aktif ? tema.aksen : tema.isian,
          borderRadius: BorderRadius.circular(ukuran * 0.34),
          border: Border.all(
            color: aktif
                ? Colors.white.withValues(alpha: 0.85)
                : tema.garis,
          ),
          boxShadow: aktif
              ? [
                  BoxShadow(
                    color: tema.aksen.withValues(alpha: 0.55),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          ikon,
          size: ukuran * 0.5,
          color: aktif ? tema.diAksen : tema.teksLembut,
        ),
      ),
    );

    if (tooltip == null) return tombol;
    return Tooltip(message: tooltip, child: tombol);
  }
}

/// Segmented control bergaya iOS.
class KontrolSegmen extends StatelessWidget {
  const KontrolSegmen({
    super.key,
    required this.pilihan,
    required this.indeks,
    required this.onChanged,
    required this.tema,
  });

  final List<String> pilihan;
  final int indeks;
  final ValueChanged<int> onChanged;
  final PengaturanWarna tema;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tema.isian,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: tema.garis),
      ),
      child: Row(
        children: List.generate(pilihan.length, (i) {
          final terpilih = i == indeks;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!terpilih) {
                  HapticFeedback.selectionClick();
                  onChanged(i);
                }
              },
              child: AnimatedContainer(
                duration: _durasiSedang,
                curve: _kurvaLembut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: terpilih
                      ? (tema.gelap
                            ? Colors.white.withValues(alpha: 0.16)
                            : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: terpilih ? tema.garis : Colors.transparent,
                  ),
                  boxShadow: terpilih
                      ? [
                          BoxShadow(
                            color: tema.bayangan,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  pilihan[i],
                  style: TextStyle(
                    color: terpilih ? tema.teks : tema.teksSamar,
                    fontSize: 11.5,
                    fontWeight: terpilih ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Kartu informasi kecil dengan ikon berwarna.
class PilInfo extends StatelessWidget {
  const PilInfo({
    super.key,
    required this.ikon,
    required this.teks,
    required this.warna,
    this.ukuranFont = 10.5,
  });

  final IconData ikon;
  final String teks;
  final Color warna;
  final double ukuranFont;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: warna.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: ukuranFont + 2, color: warna),
          const SizedBox(width: 5),
          Text(
            teks,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: warna,
              fontSize: ukuranFont,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
