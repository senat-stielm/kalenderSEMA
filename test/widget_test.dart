import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kalender_kemahasiswaan/kalender_hijriah.dart';
import 'package:kalender_kemahasiswaan/main.dart';

Future<void> bukaMenu(WidgetTester tester) async {
  await tester.tap(find.text('Profil'));
  await tester.pumpAndSettle();
}

Future<void> bukaKustomisasi(WidgetTester tester) async {
  await bukaMenu(tester);
  await tester.tap(find.byTooltip('Kustomisasi tampilan'));
  await tester.pumpAndSettle();
}

Future<void> bukaAplikasi(WidgetTester tester) async {
  await tester.pumpWidget(const KalenderKemahasiswaanApp());
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Future<void> masukModeAdmin(WidgetTester tester) async {
  await bukaMenu(tester);
  await tester.tap(find.byTooltip('Masuk mode admin'));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byType(TextField).at(1),
    'Widyanurdianasenat2627',
  );
  await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });

  tearDownAll(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  testWidgets('anggota melihat kalender tanpa tombol edit', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'agenda_cache_v1': '[]'});

    await bukaAplikasi(tester);

    expect(find.byTooltip('Kalender tahunan'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/logo_ormakta.png')),
      findsOneWidget,
    );
    expect(find.text('Kegiatan Terdekat'), findsOneWidget);
    expect(find.text('Tambah Agenda'), findsNothing);
    expect(find.text('Mode admin aktif'), findsNothing);
    expect(find.byIcon(Icons.edit_note_rounded), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);

    // Anggota masih boleh mengubah tema, tetapi tidak bisa mengelola ormawa.
    await bukaKustomisasi(tester);

    expect(find.text('Tema Aplikasi'), findsOneWidget);
    expect(find.byTooltip('Ubah ormawa'), findsNothing);
    expect(find.text('Tambah Ormawa / UKM / UKK'), findsNothing);
  });

  testWidgets('admin dapat masuk dan membuka panel kustomisasi', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'agenda_cache_v1': '[]'});

    await bukaAplikasi(tester);

    await masukModeAdmin(tester);

    expect(find.text('Mode admin aktif'), findsOneWidget);

    // Tombol + di tengah navigasi membuka formulir agenda untuk admin.
    await tester.tap(find.byTooltip('Tambah agenda'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Agenda Kegiatan'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    await bukaKustomisasi(tester);

    expect(find.text('Kustomisasi Tampilan'), findsOneWidget);
    expect(find.text('Tema Aplikasi'), findsOneWidget);
    expect(find.text('Tambah Ormawa / UKM / UKK'), findsOneWidget);
  });

  testWidgets('logo kiri atas membuka kalender tahunan', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'agenda_cache_v1': '[]'});

    await bukaAplikasi(tester);

    await tester.tap(find.byTooltip('Kalender tahunan'));
    await tester.pumpAndSettle();

    const namaBulan = [
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
    final sekarang = DateTime.now();
    final tahun = sekarang.year.clamp(2025, 2030);
    expect(find.text('Kalender Tahunan'), findsOneWidget);
    expect(find.text('$tahun'), findsOneWidget);
    // Dialog langsung menggulir ke bulan yang sedang aktif.
    expect(find.text(namaBulan[sekarang.month - 1]), findsOneWidget);
  });

  testWidgets('warna bebas dapat dipilih dan tersimpan permanen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'agenda_cache_v1': '[]'});

    await bukaAplikasi(tester);

    await masukModeAdmin(tester);
    await bukaKustomisasi(tester);

    await tester.tap(find.text('Tema Aplikasi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Warna Aksen'));
    await tester.pumpAndSettle();

    expect(find.text('Kode Hex'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '12AB34');
    await tester.pump();
    await tester.tap(find.text('Pilih Warna'));
    await tester.pumpAndSettle();

    expect(find.text('#12AB34'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final tersimpan = prefs.getString('pengaturan_warna_tema_v1');
    expect(tersimpan, isNotNull);
    expect(jsonDecode(tersimpan!)['aksen'], 0xFF12AB34);
  });

  testWidgets('warna bebas tiap ormawa tersimpan', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'agenda_cache_v1': '[]'});

    await bukaAplikasi(tester);

    await masukModeAdmin(tester);
    await bukaKustomisasi(tester);

    await tester.tap(find.byTooltip('Ubah ormawa').first);
    await tester.pumpAndSettle();
    expect(find.text('Ubah Ormawa'), findsOneWidget);

    await tester.tap(find.text('Warna Bebas'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'FF00AA');
    await tester.pump();
    await tester.tap(find.text('Pilih Warna'));
    await tester.pumpAndSettle();

    expect(find.text('#FF00AA'), findsOneWidget);

    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    final prefs = await SharedPreferences.getInstance();
    final mentah = prefs.getString('ormawa_cache_v1');
    expect(mentah, isNotNull);
    final data = jsonDecode(mentah!) as List<dynamic>;
    final senat = data.first as Map<String, dynamic>;
    expect(senat['nama'], 'Senat Mahasiswa');
    expect(senat['warna'], 0xFFFF00AA);
  });

  testWidgets('admin dapat menambah ormawa baru', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'agenda_cache_v1': '[]'});

    await bukaAplikasi(tester);

    await masukModeAdmin(tester);
    await bukaKustomisasi(tester);

    await tester.tap(find.text('Tambah Ormawa / UKM / UKK'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Ormawa'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'UKM Uji Coba');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    final prefs = await SharedPreferences.getInstance();
    final mentah = prefs.getString('ormawa_cache_v1');
    expect(mentah, isNotNull);
    expect(mentah, contains('UKM Uji Coba'));
  });

  testWidgets('kalender Hijriah lengkap menampilkan 12 bulan', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'agenda_cache_v1': '[]'});

    await bukaAplikasi(tester);

    // Baris tanggal Hijriah di kartu kalender membuka lembar lengkap.
    await tester.tap(find.byTooltip('Buka kalender Hijriah'));
    await tester.pumpAndSettle();

    expect(find.text('Kalender Hijriah'), findsOneWidget);
    for (final bulan in namaBulanHijriah) {
      expect(find.text(bulan), findsWidgets);
    }
  });

  testWidgets('navigasi bawah membuka panel agenda dan notifikasi', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'agenda_cache_v1': '[]'});

    await bukaAplikasi(tester);

    expect(find.text('Kalender'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();
    expect(find.text('Semua Agenda'), findsOneWidget);
    expect(find.text('Semua Ormawa'), findsOneWidget);

    await tester.tapAt(const Offset(200, 80));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notifikasi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pengingat kegiatan dalam 14 hari ke depan'),
      findsOneWidget,
    );
  });

  testWidgets('pengingat H-1 muncul dan bisa ditutup', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final besok = DateTime.now().add(const Duration(days: 1));
    String iso(DateTime t) =>
        '${t.year.toString().padLeft(4, '0')}-'
        '${t.month.toString().padLeft(2, '0')}-'
        '${t.day.toString().padLeft(2, '0')}';
    SharedPreferences.setMockInitialValues({
      'agenda_cache_v1': jsonEncode([
        {
          'id': 'pengingat-1',
          'judul': 'Rapat Besok',
          'deskripsi': '',
          'tanggal': iso(besok),
          'lokasi': 'Ruang BEM',
          'ormawa': 'bem',
        },
      ]),
    });

    await bukaAplikasi(tester);

    expect(find.text('Besok ada agenda!'), findsOneWidget);
    expect(find.text('Rapat Besok'), findsOneWidget);
    expect(find.text('PENGINGAT H-1'), findsOneWidget);

    await tester.tap(find.byTooltip('Tutup pengingat'));
    await tester.pumpAndSettle();
    expect(find.text('Besok ada agenda!'), findsNothing);
  });

  testWidgets('splash menampilkan semua logo ormawa selama 3 detik', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'agenda_cache_v1': '[]'});

    await tester.pumpWidget(const KalenderKemahasiswaanApp());
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('OrmaKta'), findsOneWidget);
    expect(find.text('Kalender Ormawa'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(14));
    expect(find.text('Kegiatan Terdekat'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Kegiatan Terdekat'), findsOneWidget);
    // Logo OrmaKta tetap tampil di header setelah splash selesai.
    expect(find.byType(Image), findsOneWidget);
  });
}
