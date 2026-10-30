import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'konfigurasi_supabase.dart';
import 'layanan_agenda.dart';
import 'model_ormawa.dart';

/// Hasil pemuatan daftar ormawa.
class HasilMuatOrmawa {
  const HasilMuatOrmawa({
    required this.daftar,
    this.galat,
    this.dariServer = false,
  });

  final List<Ormawa> daftar;
  final String? galat;
  final bool dariServer;
}

/// Membaca dan menulis daftar ormawa/UKM/UKK ke Supabase, dengan salinan
/// lokal sebagai cadangan saat perangkat offline.
class LayananOrmawa {
  static const String _kunciCache = 'ormawa_cache_v1';
  static const String _kunciPernahSinkron = 'ormawa_pernah_sinkron_v1';
  static const Duration _batasWaktu = Duration(seconds: 15);

  final http.Client _klien;
  final String _alamat;
  final String _kunciAnon;

  LayananOrmawa({http.Client? klien, String? alamat, String? kunciAnon})
    : _klien = klien ?? http.Client(),
      _alamat = alamat ?? alamatSupabase,
      _kunciAnon = kunciAnon ?? kunciAnonSupabase;

  bool get terkonfigurasi =>
      _alamat.startsWith('https://') &&
      !_alamat.contains('GANTI') &&
      _kunciAnon.isNotEmpty &&
      !_kunciAnon.contains('GANTI');

  Map<String, String> get _header => {
    'apikey': _kunciAnon,
    'Authorization': 'Bearer $_kunciAnon',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<HasilMuatOrmawa> muatOrmawa() async {
    if (!terkonfigurasi) {
      return HasilMuatOrmawa(
        daftar: await _dariCacheAtauBawaan(),
        galat:
            'Supabase belum dikonfigurasi. Daftar ormawa masih tersimpan '
            'di perangkat ini saja.',
      );
    }

    try {
      final respon = await _klien
          .get(
            Uri.parse(
              '$_alamat/rest/v1/ormawa'
              '?select=id,nama,kategori,warna,ikon'
              '&order=urutan.asc',
            ),
            headers: _header,
          )
          .timeout(_batasWaktu);

      if (respon.statusCode != 200) {
        return HasilMuatOrmawa(
          daftar: await _dariCacheAtauBawaan(),
          galat:
              'Gagal memuat daftar ormawa (${respon.statusCode}). '
              '${_pesanGalat(respon.body)}',
        );
      }

      final data = jsonDecode(respon.body);
      if (data is! List) {
        return HasilMuatOrmawa(
          daftar: await _dariCacheAtauBawaan(),
          galat: 'Format daftar ormawa dari server tidak dikenali.',
        );
      }

      final daftar = <Ormawa>[];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final ormawa = Ormawa.dariPeta(item);
          if (ormawa != null) daftar.add(ormawa);
        }
      }

      await _simpanCache(daftar);
      await _tandaiPernahSinkron();

      return HasilMuatOrmawa(daftar: daftar, dariServer: true);
    } catch (_) {
      return HasilMuatOrmawa(
        daftar: await _dariCacheAtauBawaan(),
        galat:
            'Gagal terhubung ke server. Menampilkan daftar ormawa yang '
            'tersimpan di perangkat ini.',
      );
    }
  }

  Future<HasilSinkron> simpanOrmawa(
    Ormawa ormawa,
    List<Ormawa> daftarTerbaru,
  ) async {
    await _simpanCache(daftarTerbaru);

    if (!terkonfigurasi) {
      return const HasilSinkron(
        berhasil: false,
        pesan:
            'Supabase belum dikonfigurasi. Perubahan ormawa hanya '
            'tersimpan di perangkat ini.',
      );
    }

    try {
      final respon = await _klien
          .post(
            Uri.parse('$_alamat/rest/v1/rpc/simpan_ormawa'),
            headers: _header,
            body: jsonEncode({
              'kunci': kunciTulisSupabase,
              'data': [ormawa.kePeta()],
            }),
          )
          .timeout(_batasWaktu);

      if (_berhasil(respon.statusCode)) {
        return const HasilSinkron(
          berhasil: true,
          pesan: 'Ormawa tersimpan dan tersinkron ke semua perangkat.',
        );
      }
      return HasilSinkron(
        berhasil: false,
        pesan:
            'Tersimpan di perangkat, tetapi server menolak '
            '(${respon.statusCode}). ${_pesanGalat(respon.body)}',
      );
    } catch (_) {
      return const HasilSinkron(
        berhasil: false,
        pesan: 'Tersimpan di perangkat, tetapi gagal sinkron ke server.',
      );
    }
  }

  Future<HasilSinkron> hapusOrmawa(
    String id,
    List<Ormawa> daftarTerbaru,
  ) async {
    await _simpanCache(daftarTerbaru);

    if (!terkonfigurasi) {
      return const HasilSinkron(
        berhasil: false,
        pesan:
            'Supabase belum dikonfigurasi. Penghapusan ormawa hanya '
            'berlaku di perangkat ini.',
      );
    }

    try {
      final respon = await _klien
          .post(
            Uri.parse('$_alamat/rest/v1/rpc/hapus_ormawa'),
            headers: _header,
            body: jsonEncode({'kunci': kunciTulisSupabase, 'id_ormawa': id}),
          )
          .timeout(_batasWaktu);

      if (_berhasil(respon.statusCode)) {
        return const HasilSinkron(
          berhasil: true,
          pesan: 'Ormawa beserta agendanya dihapus dari semua perangkat.',
        );
      }
      return HasilSinkron(
        berhasil: false,
        pesan:
            'Terhapus di perangkat, tetapi server menolak '
            '(${respon.statusCode}). ${_pesanGalat(respon.body)}',
      );
    } catch (_) {
      return const HasilSinkron(
        berhasil: false,
        pesan: 'Terhapus di perangkat, tetapi gagal sinkron ke server.',
      );
    }
  }

  Future<List<Ormawa>> _dariCacheAtauBawaan() async {
    final cache = await _bacaCache();
    if (cache != null) return cache;

    final prefs = await SharedPreferences.getInstance();
    final pernahSinkron = prefs.getBool(_kunciPernahSinkron) ?? false;
    if (pernahSinkron) return [];
    return List.of(ormawaBawaan);
  }

  Future<List<Ormawa>?> _bacaCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mentah = prefs.getString(_kunciCache);
      if (mentah == null) return null;

      final data = jsonDecode(mentah);
      if (data is! List) return null;

      final daftar = <Ormawa>[];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final ormawa = Ormawa.dariPeta(item);
          if (ormawa != null) daftar.add(ormawa);
        }
      }
      return daftar;
    } catch (_) {
      return null;
    }
  }

  Future<void> _simpanCache(List<Ormawa> daftar) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kunciCache,
        jsonEncode(daftar.map((ormawa) => ormawa.kePeta()).toList()),
      );
    } catch (_) {
      // Gagal menulis cache tidak boleh menghentikan aplikasi.
    }
  }

  Future<void> _tandaiPernahSinkron() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kunciPernahSinkron, true);
    } catch (_) {
      // Diabaikan.
    }
  }

  static bool _berhasil(int status) => status >= 200 && status < 300;

  static String _pesanGalat(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final pesan = data['message'] ?? data['error'] ?? data['hint'];
        if (pesan is String && pesan.trim().isNotEmpty) return pesan;
      }
    } catch (_) {
      // Bukan JSON; pakai pesan umum.
    }
    return 'Periksa koneksi internet dan konfigurasi Supabase.';
  }
}
