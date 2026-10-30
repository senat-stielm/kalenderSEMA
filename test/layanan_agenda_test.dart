import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kalender_kemahasiswaan/layanan_agenda.dart';
import 'package:kalender_kemahasiswaan/model_agenda.dart';

LayananAgenda buatLayanan(http.Client klien) => LayananAgenda(
  klien: klien,
  alamat: 'https://contoh.supabase.co',
  kunciAnon: 'kunci-anon',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('memuat agenda dari server', () async {
    final klien = MockClient((permintaan) async {
      expect(permintaan.method, 'GET');
      expect(permintaan.headers['apikey'], 'kunci-anon');
      expect(permintaan.url.queryParameters['order'], 'tanggal.asc');
      return http.Response(
        jsonEncode([
          {
            'id': 'a1',
            'judul': 'Rapat',
            'deskripsi': 'Deskripsi',
            'tanggal': '2026-11-02',
            'lokasi': 'Aula',
            'ormawa': 'bem',
          },
          {
            'id': 'a2',
            'judul': 'Lomba',
            'deskripsi': '',
            'tanggal': '2026-11-05',
            'lokasi': 'Lapangan',
            'ormawa': 'ukm1',
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final hasil = await buatLayanan(klien).muatAgenda();

    expect(hasil.galat, isNull);
    expect(hasil.dariServer, isTrue);
    expect(hasil.daftar, hasLength(2));
    expect(hasil.daftar.first.id, 'a1');
    expect(hasil.daftar.first.waktu, DateTime(2026, 11, 2));
    expect(hasil.daftar.first.ormawaId, 'bem');
    expect(hasil.daftar.last.ormawaId, 'ukm1');
  });

  test('menyimpan agenda mengirim RPC dan menyimpan salinan lokal', () async {
    String? badanPermintaan;
    final klien = MockClient((permintaan) async {
      expect(permintaan.method, 'POST');
      expect(permintaan.url.path, '/rest/v1/rpc/simpan_agenda');
      badanPermintaan = permintaan.body;
      return http.Response('', 204);
    });

    final agenda = AgendaAcara(
      id: 'x1',
      judul: 'Rapat',
      deskripsi: '',
      waktu: DateTime(2026, 11, 3),
      lokasi: 'Aula',
      ormawaId: 'senat',
    );

    final hasil = await buatLayanan(klien).simpanAgenda(agenda, [agenda]);

    expect(hasil.berhasil, isTrue);
    final badan = jsonDecode(badanPermintaan!) as Map<String, dynamic>;
    expect(badan['kunci'], isNotEmpty);
    final data = badan['data'] as List<dynamic>;
    expect((data.first as Map<String, dynamic>)['tanggal'], '2026-11-03');
    expect((data.first as Map<String, dynamic>)['ormawa'], 'senat');

    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getString('agenda_cache_v1');
    expect(cache, isNotNull);
    expect(cache, contains('x1'));
  });

  test('menghapus agenda mengirim RPC hapus', () async {
    String? badanPermintaan;
    final klien = MockClient((permintaan) async {
      expect(permintaan.method, 'POST');
      expect(permintaan.url.path, '/rest/v1/rpc/hapus_agenda');
      badanPermintaan = permintaan.body;
      return http.Response('', 204);
    });

    final hasil = await buatLayanan(klien).hapusAgenda('x1', []);

    expect(hasil.berhasil, isTrue);
    final badan = jsonDecode(badanPermintaan!) as Map<String, dynamic>;
    expect(badan['id_agenda'], 'x1');
  });

  test('server menolak kunci ditampilkan sebagai pesan galat', () async {
    final klien = MockClient((permintaan) async {
      return http.Response(
        jsonEncode({'message': 'Kunci tidak valid'}),
        400,
        headers: {'content-type': 'application/json'},
      );
    });

    final agenda = AgendaAcara(
      id: 'x1',
      judul: 'Rapat',
      deskripsi: '',
      waktu: DateTime(2026, 11, 3),
      lokasi: 'Aula',
      ormawaId: 'senat',
    );

    final hasil = await buatLayanan(klien).simpanAgenda(agenda, [agenda]);

    expect(hasil.berhasil, isFalse);
    expect(hasil.pesan, contains('Kunci tidak valid'));
  });

  test('saat offline memakai salinan lokal terakhir', () async {
    var offline = false;
    final klien = MockClient((permintaan) async {
      if (offline) throw Exception('tidak ada internet');
      return http.Response(
        jsonEncode([
          {
            'id': 'a1',
            'judul': 'Rapat',
            'deskripsi': '',
            'tanggal': '2026-11-02',
            'lokasi': 'Aula',
            'ormawa': 'senat',
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final layanan = buatLayanan(klien);
    await layanan.muatAgenda();

    offline = true;
    final hasil = await layanan.muatAgenda();

    expect(hasil.dariServer, isFalse);
    expect(hasil.galat, isNotNull);
    expect(hasil.daftar, hasLength(1));
    expect(hasil.daftar.single.id, 'a1');
  });

  test(
    'tanpa konfigurasi memakai agenda contoh dengan tanggal tetap',
    () async {
      var dipanggil = false;
      final klien = MockClient((permintaan) async {
        dipanggil = true;
        return http.Response('[]', 200);
      });

      final layanan = LayananAgenda(
        klien: klien,
        alamat: 'https://GANTI-PROJECT.supabase.co',
        kunciAnon: 'GANTI_ANON_KEY',
      );
      final hasil = await layanan.muatAgenda();

      expect(dipanggil, isFalse);
      expect(hasil.galat, isNotNull);
      expect(hasil.daftar, hasLength(4));
      expect(hasil.daftar.first.waktu, DateTime(2026, 11, 2));
    },
  );
}
