import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kalender_kemahasiswaan/layanan_ormawa.dart';
import 'package:kalender_kemahasiswaan/model_ormawa.dart';

LayananOrmawa buatLayanan(http.Client klien) => LayananOrmawa(
  klien: klien,
  alamat: 'https://contoh.supabase.co',
  kunciAnon: 'kunci-anon',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('memuat daftar ormawa dari server', () async {
    final klien = MockClient((permintaan) async {
      expect(permintaan.method, 'GET');
      expect(permintaan.headers['apikey'], 'kunci-anon');
      expect(permintaan.url.queryParameters['order'], 'urutan.asc');
      return http.Response(
        jsonEncode([
          {
            'id': 'senat',
            'nama': 'Senat Mahasiswa',
            'kategori': 'Legislatif',
            'warna': 0xFFA855F7,
            'ikon': 'gavel',
          },
          {
            'id': 'bem',
            'nama': 'BEM',
            'kategori': 'Eksekutif',
            'warna': 0xFFEF4444,
            'ikon': 'bank',
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final hasil = await buatLayanan(klien).muatOrmawa();

    expect(hasil.galat, isNull);
    expect(hasil.dariServer, isTrue);
    expect(hasil.daftar, hasLength(2));
    expect(hasil.daftar.first.id, 'senat');
    expect(hasil.daftar.first.nama, 'Senat Mahasiswa');
    expect(hasil.daftar.first.warna.toARGB32(), 0xFFA855F7);
    expect(hasil.daftar.first.ikonKunci, 'gavel');
  });

  test('menyimpan ormawa mengirim RPC dan salinan lokal', () async {
    String? badanPermintaan;
    final klien = MockClient((permintaan) async {
      expect(permintaan.method, 'POST');
      expect(permintaan.url.path, '/rest/v1/rpc/simpan_ormawa');
      badanPermintaan = permintaan.body;
      return http.Response('', 204);
    });

    const ormawa = Ormawa(
      id: 'ukm-baru',
      nama: 'UKM Baru',
      kategori: 'UKM',
      warna: Color(0xFF123456),
      ikonKunci: 'star',
    );

    final hasil = await buatLayanan(klien).simpanOrmawa(ormawa, [ormawa]);

    expect(hasil.berhasil, isTrue);
    final badan = jsonDecode(badanPermintaan!) as Map<String, dynamic>;
    expect(badan['kunci'], isNotEmpty);
    final data = badan['data'] as List<dynamic>;
    final pertama = data.first as Map<String, dynamic>;
    expect(pertama['id'], 'ukm-baru');
    expect(pertama['nama'], 'UKM Baru');
    expect(pertama['ikon'], 'star');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ormawa_cache_v1'), contains('UKM Baru'));
  });

  test('menghapus ormawa mengirim RPC hapus', () async {
    String? badanPermintaan;
    final klien = MockClient((permintaan) async {
      expect(permintaan.url.path, '/rest/v1/rpc/hapus_ormawa');
      badanPermintaan = permintaan.body;
      return http.Response('', 204);
    });

    final hasil = await buatLayanan(klien).hapusOrmawa('ukm-baru', []);

    expect(hasil.berhasil, isTrue);
    final badan = jsonDecode(badanPermintaan!) as Map<String, dynamic>;
    expect(badan['id_ormawa'], 'ukm-baru');
  });

  test('tanpa konfigurasi memakai daftar bawaan', () async {
    var dipanggil = false;
    final klien = MockClient((permintaan) async {
      dipanggil = true;
      return http.Response('[]', 200);
    });

    final layanan = LayananOrmawa(
      klien: klien,
      alamat: 'https://GANTI-PROJECT.supabase.co',
      kunciAnon: 'GANTI_ANON_KEY',
    );
    final hasil = await layanan.muatOrmawa();

    expect(dipanggil, isFalse);
    expect(hasil.galat, isNotNull);
    expect(hasil.daftar, hasLength(ormawaBawaan.length));
    expect(hasil.daftar.first.id, 'senat');
  });

  test('saat offline memakai salinan lokal', () async {
    var offline = false;
    final klien = MockClient((permintaan) async {
      if (offline) throw Exception('tidak ada internet');
      return http.Response(
        jsonEncode([
          {
            'id': 'senat',
            'nama': 'Senat Mahasiswa',
            'kategori': 'Legislatif',
            'warna': 0xFFA855F7,
            'ikon': 'gavel',
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final layanan = buatLayanan(klien);
    await layanan.muatOrmawa();

    offline = true;
    final hasil = await layanan.muatOrmawa();

    expect(hasil.dariServer, isFalse);
    expect(hasil.galat, isNotNull);
    expect(hasil.daftar.single.nama, 'Senat Mahasiswa');
  });
}
