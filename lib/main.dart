import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'kalender_home_page.dart';
import 'pengaturan_warna.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';
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

  @override
  void initState() {
    super.initState();
    _muatTema();
  }

  Future<void> _muatTema() async {
    final tersimpan = await _penyimpanan.muatTema();
    if (!mounted || tersimpan == null) return;
    setState(() => _tema = tersimpan);
  }

  void _ubahTema(PengaturanWarna temaBaru) {
    setState(() => _tema = temaBaru);
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
      theme: _buatTema(_tema),
      home: KalenderHomePage(tema: _tema, onTemaBerubah: _ubahTema),
    );
  }

  ThemeData _buatTema(PengaturanWarna tema) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: tema.latar2,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tema.aksen,
        brightness: Brightness.dark,
        primary: tema.aksen,
        secondary: tema.sekunder,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: tema.kartu,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: tema.latar2,
        headerForegroundColor: Colors.white,
        dividerColor: Colors.white12,
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? tema.aksen : null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tema.latar1
              : Colors.white;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? tema.aksen : null;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tema.latar1
              : tema.aksen;
        }),
        todayBorder: BorderSide(color: tema.aksen),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: Colors.white60,
        ),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: tema.aksen),
      ),
    );
  }
}
