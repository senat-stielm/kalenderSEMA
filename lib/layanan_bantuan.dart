import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'konfigurasi_supabase.dart';
import 'layanan_agenda.dart';
import 'model_bantuan.dart';

/// Hasil pemuatan sumber informasi Help Desk.
class HasilMuatBantuan {
  const HasilMuatBantuan({
    required this.daftar,
    this.galat,
    this.dariServer = false,
  });

  final List<SumberBantuan> daftar;
  final String? galat;
  final bool dariServer;
}

/// Membaca dan menulis sumber informasi Help Desk ke Supabase, dengan
/// salinan lokal sebagai cadangan saat perangkat offline.
class LayananBantuan {
  static const String _kunciCache = 'bantuan_cache_v1';
  static const String _kunciPernahSinkron = 'bantuan_pernah_sinkron_v1';
  static const Duration _batasWaktu = Duration(seconds: 15);

  final http.Client _klien;
  final String _alamat;
  final String _kunciAnon;

  LayananBantuan({http.Client? klien, String? alamat, String? kunciAnon})
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

  Future<HasilMuatBantuan> muatSumber() async {
    if (!terkonfigurasi) {
      return HasilMuatBantuan(
        daftar: await _bacaCache() ?? const [],
        galat:
            'Supabase belum dikonfigurasi. Sumber informasi masih tersimpan '
            'di perangkat ini saja.',
      );
    }

    try {
      final respon = await _klien
          .get(
            Uri.parse(
              '$_alamat/rest/v1/sumber_bantuan'
              '?select=id,judul,kategori,isi,urutan'
              '&order=urutan.asc',
            ),
            headers: _header,
          )
          .timeout(_batasWaktu);

      if (respon.statusCode != 200) {
        final pesan = _tabelBelumAda(respon.statusCode, respon.body)
            ? 'Tabel sumber bantuan belum dibuat di Supabase. Jalankan file '
                  'supabase/helpdesk.sql di SQL Editor, lalu coba lagi.'
            : 'Gagal memuat sumber informasi (${respon.statusCode}). '
                  '${_pesanGalat(respon.body)}';
        return HasilMuatBantuan(
          daftar: await _bacaCache() ?? const [],
          galat: pesan,
        );
      }

      final data = jsonDecode(respon.body);
      if (data is! List) {
        return HasilMuatBantuan(
          daftar: await _bacaCache() ?? const [],
          galat: 'Format sumber informasi dari server tidak dikenali.',
        );
      }

      final daftar = <SumberBantuan>[];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final sumber = SumberBantuan.dariPeta(item);
          if (sumber != null) daftar.add(sumber);
        }
      }

      await _simpanCache(daftar);
      await _tandaiPernahSinkron();
      return HasilMuatBantuan(daftar: daftar, dariServer: true);
    } catch (_) {
      return HasilMuatBantuan(
        daftar: await _bacaCache() ?? const [],
        galat:
            'Gagal terhubung ke server. Menampilkan sumber informasi yang '
            'tersimpan di perangkat ini.',
      );
    }
  }

  Future<HasilSinkron> simpanSumber(
    SumberBantuan sumber,
    List<SumberBantuan> daftarTerbaru,
  ) async {
    await _simpanCache(daftarTerbaru);

    if (!terkonfigurasi) {
      return const HasilSinkron(
        berhasil: false,
        pesan:
            'Supabase belum dikonfigurasi. Sumber informasi hanya tersimpan '
            'di perangkat ini.',
      );
    }

    try {
      final respon = await _klien
          .post(
            Uri.parse('$_alamat/rest/v1/rpc/simpan_bantuan'),
            headers: _header,
            body: jsonEncode({
              'kunci': kunciTulisSupabase,
              'data': [sumber.kePeta()],
            }),
          )
          .timeout(_batasWaktu);

      if (_berhasil(respon.statusCode)) {
        return const HasilSinkron(
          berhasil: true,
          pesan: 'Sumber informasi tersimpan untuk semua perangkat.',
        );
      }
      if (_tabelBelumAda(respon.statusCode, respon.body)) {
        return const HasilSinkron(
          berhasil: false,
          pesan:
              'Tersimpan di perangkat ini. Agar tersinkron ke semua '
              'perangkat, jalankan supabase/helpdesk.sql di SQL Editor.',
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

  Future<HasilSinkron> hapusSumber(
    String id,
    List<SumberBantuan> daftarTerbaru,
  ) async {
    await _simpanCache(daftarTerbaru);

    if (!terkonfigurasi) {
      return const HasilSinkron(
        berhasil: false,
        pesan:
            'Supabase belum dikonfigurasi. Penghapusan hanya berlaku di '
            'perangkat ini.',
      );
    }

    try {
      final respon = await _klien
          .post(
            Uri.parse('$_alamat/rest/v1/rpc/hapus_bantuan'),
            headers: _header,
            body: jsonEncode({'kunci': kunciTulisSupabase, 'id_bantuan': id}),
          )
          .timeout(_batasWaktu);

      if (_berhasil(respon.statusCode)) {
        return const HasilSinkron(
          berhasil: true,
          pesan: 'Sumber informasi dihapus dari semua perangkat.',
        );
      }
      if (_tabelBelumAda(respon.statusCode, respon.body)) {
        return const HasilSinkron(
          berhasil: false,
          pesan:
              'Terhapus di perangkat ini. Jalankan supabase/helpdesk.sql '
              'agar penghapusan tersinkron ke semua perangkat.',
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

  Future<List<SumberBantuan>?> _bacaCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mentah = prefs.getString(_kunciCache);
      if (mentah == null) return null;

      final data = jsonDecode(mentah);
      if (data is! List) return null;

      final daftar = <SumberBantuan>[];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final sumber = SumberBantuan.dariPeta(item);
          if (sumber != null) daftar.add(sumber);
        }
      }
      return daftar;
    } catch (_) {
      return null;
    }
  }

  Future<void> _simpanCache(List<SumberBantuan> daftar) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kunciCache,
        jsonEncode(daftar.map((sumber) => sumber.kePeta()).toList()),
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

  /// Mendeteksi tabel/fungsi yang belum dibuat di Supabase (PGRST 404).
  static bool _tabelBelumAda(int status, String body) {
    final teks = body.toLowerCase();
    return status == 404 ||
        teks.contains('schema cache') ||
        teks.contains('could not find the table') ||
        teks.contains('could not find the function');
  }

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
