import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kalender_kemahasiswaan/main.dart';

Future<void> masukModeAdmin(WidgetTester tester) async {
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
  });

  testWidgets('anggota melihat kalender tanpa tombol edit', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const KalenderKemahasiswaanApp());
    await tester.pumpAndSettle();

    expect(find.text('KALENDER ORMAWA'), findsOneWidget);
    expect(find.text('Tambah Agenda'), findsNothing);
    expect(find.byIcon(Icons.edit_note_rounded), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);

    // Anggota masih boleh mengubah tema, tetapi tidak bisa mengelola ormawa.
    await tester.tap(find.byTooltip('Kustomisasi tampilan'));
    await tester.pumpAndSettle();

    expect(find.text('Tema Aplikasi'), findsOneWidget);
    expect(find.byTooltip('Ubah ormawa'), findsNothing);
    expect(find.text('Tambah Ormawa / UKM / UKK'), findsNothing);
  });

  testWidgets('admin dapat masuk dan membuka panel kustomisasi', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const KalenderKemahasiswaanApp());
    await tester.pumpAndSettle();

    await masukModeAdmin(tester);

    expect(find.text('Tambah Agenda'), findsOneWidget);

    await tester.tap(find.byTooltip('Kustomisasi tampilan'));
    await tester.pumpAndSettle();

    expect(find.text('Kustomisasi Tampilan'), findsOneWidget);
    expect(find.text('Tema Aplikasi'), findsOneWidget);
    expect(find.text('Tambah Ormawa / UKM / UKK'), findsOneWidget);
  });

  testWidgets('logo kiri atas membuka kalender tahunan', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const KalenderKemahasiswaanApp());
    await tester.pumpAndSettle();

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
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const KalenderKemahasiswaanApp());
    await tester.pumpAndSettle();

    await masukModeAdmin(tester);
    await tester.tap(find.byTooltip('Kustomisasi tampilan'));
    await tester.pumpAndSettle();

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
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const KalenderKemahasiswaanApp());
    await tester.pumpAndSettle();

    await masukModeAdmin(tester);
    await tester.tap(find.byTooltip('Kustomisasi tampilan'));
    await tester.pumpAndSettle();

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
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const KalenderKemahasiswaanApp());
    await tester.pumpAndSettle();

    await masukModeAdmin(tester);
    await tester.tap(find.byTooltip('Kustomisasi tampilan'));
    await tester.pumpAndSettle();

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
}
