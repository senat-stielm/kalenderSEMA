import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kalender_kemahasiswaan/main.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('menampilkan kalender dan panel kustomisasi tampilan', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const KalenderKemahasiswaanApp());
    await tester.pumpAndSettle();

    expect(find.text('KALENDER ORMAWA'), findsOneWidget);

    await tester.tap(find.text('Tampilan'));
    await tester.pumpAndSettle();

    expect(find.text('Kustomisasi Tampilan'), findsOneWidget);
    expect(find.text('Tema Aplikasi'), findsOneWidget);
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

    await tester.tap(find.text('Tampilan'));
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

  testWidgets('warna bebas tiap ormawa tersimpan permanen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const KalenderKemahasiswaanApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tampilan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ubah').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit Legislatif'), findsOneWidget);

    await tester.tap(find.text('Warna Bebas'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'FF00AA');
    await tester.pump();
    await tester.tap(find.text('Pilih Warna'));
    await tester.pumpAndSettle();

    expect(find.text('#FF00AA'), findsOneWidget);

    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final mentah = prefs.getString('pengaturan_ormawa_v1');
    expect(mentah, isNotNull);
    final data = jsonDecode(mentah!) as Map<String, dynamic>;
    expect(data['senat']['nama'], 'Senat Mahasiswa');
    expect(data['senat']['warna'], 0xFFFF00AA);
  });
}
