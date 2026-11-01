import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'gaya_iphone.dart';
import 'kalender_home_page.dart';
import 'pengaturan_warna.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const KalenderKemahasiswaanApp());
}

class KalenderKemahasiswaanApp extends StatefulWidget {
  const KalenderKemahasiswaanApp({super.key});

  @override
  State<KalenderKemahasiswaanApp> createState() =>
      _KalenderKemahasiswaanAppState();
}

class _KalenderKemahasiswaanAppState extends State<KalenderKemahasiswaanApp> {
  final PenyimpananPengaturan _penyimpanan = PenyimpananPengaturan();
  PengaturanWarna _tema = PengaturanWarna.bawaan;
  bool _splashSelesai = false;

  @override
  void initState() {
    super.initState();
    _aturBilahSistem();
    _muatTema();
  }

  /// Menyesuaikan ikon status bar dan navigasi dengan mode terang/gelap.
  void _aturBilahSistem() {
    final terang = _tema.gelap ? Brightness.light : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: terang,
        statusBarBrightness: _tema.gelap ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: terang,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  Future<void> _muatTema() async {
    final tersimpan = await _penyimpanan.muatTema();
    if (!mounted || tersimpan == null) return;
    setState(() => _tema = tersimpan);
    _aturBilahSistem();
  }

  void _ubahTema(PengaturanWarna temaBaru) {
    setState(() => _tema = temaBaru);
    _aturBilahSistem();
    _penyimpanan.simpanTema(temaBaru);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalender Kemahasiswaan',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scrollBehavior: const PerilakuGulirIphone(),
      theme: _buatTema(_tema),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 480),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _splashSelesai
            ? KalenderHomePage(
                key: const ValueKey('beranda'),
                tema: _tema,
                onTemaBerubah: _ubahTema,
              )
            : LayarSplash(
                key: const ValueKey('splash'),
                tema: _tema,
                onSelesai: () {
                  setState(() => _splashSelesai = true);
                  _aturBilahSistem();
                },
              ),
      ),
    );
  }

  ThemeData _buatTema(PengaturanWarna tema) {
    return buatTemaIphone(tema).copyWith(
      datePickerTheme: DatePickerThemeData(
        backgroundColor: tema.kartu,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: tema.latar2,
        headerForegroundColor: tema.teks,
        dividerColor: tema.garis,
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? tema.aksen : null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tema.diAksen
              : tema.teks;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? tema.aksen : null;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tema.diAksen
              : tema.aksen;
        }),
        todayBorder: BorderSide(color: tema.aksen),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: tema.teksRedup,
        ),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: tema.aksen),
      ),
    );
  }
}
