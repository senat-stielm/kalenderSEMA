import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'konfigurasi_supabase.dart';
import 'model_agenda.dart';

/// Hasil pemuatan daftar agenda.
class HasilMuatAgenda {
  const HasilMuatAgenda({
    required this.daftar,
    this.galat,
    this.dariServer = false,
  });

  final List<AgendaAcara> daftar;
  final String? galat;
  final bool dariServer;
}

/// Hasil penyimpanan/penghapusan agenda ke server.
class HasilSinkron {
  const HasilSinkron({required this.berhasil, required this.pesan});

  final bool berhasil;
  final String pesan;
}

/// Membaca dan menulis agenda ke Supabase, dengan salinan lokal sebagai
/// cadangan saat perangkat sedang offline.
class LayananAgenda {
  static const String _kunciCache = 'agenda_cache_v1';
  static const String _kunciPernahSinkron = 'agenda_pernah_sinkron_v1';
  static const Duration _batasWaktu = Duration(seconds: 15);

  final http.Client _klien;
  final String _alamat;
  final String _kunciAnon;

  LayananAgenda({http.Client? klien, String? alamat, String? kunciAnon})
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

  /// Agenda contoh yang dipakai saat aplikasi belum pernah tersambung ke
  /// server. Tanggalnya tetap sehingga sama di semua perangkat.
  static List<AgendaAcara> contohAwal() => [
    AgendaAcara(
      id: 'contoh-1',
      judul: 'Sidang Pleno Kemahasiswaan',
      deskripsi: 'Evaluasi program kerja dan anggaran ormawa triwulan berjalan',
      waktu: DateTime(2026, 11, 2),
      lokasi: 'Ruang Sidang Utama',
      ormawaId: 'senat',
    ),
    AgendaAcara(
      id: 'contoh-2',
      judul: 'Pekan Raya & Kreativitas BEM',
      deskripsi: 'Gebyar pameran inovasi dan bazar mahasiswa kampus',
      waktu: DateTime(2026, 11, 5),
      lokasi: 'Lapangan Utama Kampus',
      ormawaId: 'bem',
    ),
    AgendaAcara(
      id: 'contoh-3',
      judul: 'Kajian Manajemen & Kepemimpinan',
      deskripsi: 'Diskusi strategi manajemen SDM era transformasi digital',
      waktu: DateTime(2026, 11, 9),
      lokasi: 'Auditorium Gedung B',
      ormawaId: 'hmpsMn',
    ),
    AgendaAcara(
      id: 'contoh-4',
      judul: 'Turnamen Futsal & Badminton',
      deskripsi: 'Kompetisi olahraga persahabatan antar program studi',
      waktu: DateTime(2026, 11, 12),
      lokasi: 'GOR Kampus',
      ormawaId: 'ukm1',
    ),
  ];

  /// Memuat agenda dari server. Jika gagal, memakai salinan lokal.
  Future<HasilMuatAgenda> muatAgenda() async {
    if (!terkonfigurasi) {
      return HasilMuatAgenda(
        daftar: await _dariCacheAtauContoh(),
        galat:
            'Supabase belum dikonfigurasi. Data masih tersimpan di perangkat '
            'ini saja.',
      );
    }

    try {
      final respon = await _klien
          .get(
            Uri.parse(
              '$_alamat/rest/v1/agenda'
              '?select=id,judul,deskripsi,tanggal,lokasi,ormawa'
              '&order=tanggal.asc',
            ),
            headers: _header,
          )
          .timeout(_batasWaktu);

      if (respon.statusCode != 200) {
        return HasilMuatAgenda(
          daftar: await _dariCacheAtauContoh(),
          galat:
              'Gagal memuat dari server (${respon.statusCode}). '
              '${_pesanGalat(respon.body)}',
        );
      }

      final data = jsonDecode(respon.body);
      if (data is! List) {
        return HasilMuatAgenda(
          daftar: await _dariCacheAtauContoh(),
          galat: 'Format data dari server tidak dikenali.',
        );
      }

      final daftar = <AgendaAcara>[];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final agenda = AgendaAcara.dariPeta(item);
          if (agenda != null) daftar.add(agenda);
        }
      }
      daftar.sort((a, b) => a.waktu.compareTo(b.waktu));

      await _simpanCache(daftar);
      await _tandaiPernahSinkron();

      return HasilMuatAgenda(daftar: daftar, dariServer: true);
    } catch (_) {
      return HasilMuatAgenda(
        daftar: await _dariCacheAtauContoh(),
        galat:
            'Gagal terhubung ke server. Menampilkan data yang tersimpan '
            'di perangkat ini.',
      );
    }
  }

  /// Menyimpan satu agenda ke server. [daftarTerbaru] adalah seluruh agenda
  /// setelah perubahan, dipakai sebagai salinan lokal.
  Future<HasilSinkron> simpanAgenda(
    AgendaAcara agenda,
    List<AgendaAcara> daftarTerbaru,
  ) async {
    await _simpanCache(daftarTerbaru);

    if (!terkonfigurasi) {
      return const HasilSinkron(
        berhasil: false,
        pesan:
            'Supabase belum dikonfigurasi. Perubahan hanya tersimpan '
            'di perangkat ini.',
      );
    }

    try {
      final respon = await _klien
          .post(
            Uri.parse('$_alamat/rest/v1/rpc/simpan_agenda'),
            headers: _header,
            body: jsonEncode({
              'kunci': kunciTulisSupabase,
              'data': [agenda.kePeta()],
            }),
          )
          .timeout(_batasWaktu);

      if (_berhasil(respon.statusCode)) {
        return const HasilSinkron(
          berhasil: true,
          pesan: 'Agenda tersimpan dan tersinkron ke semua perangkat.',
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
        pesan:
            'Tersimpan di perangkat, tetapi gagal sinkron ke server. '
            'Data akan tampil di perangkat lain setelah sinkron berhasil.',
      );
    }
  }

  /// Menghapus agenda di server. [daftarTerbaru] dipakai sebagai salinan lokal.
  Future<HasilSinkron> hapusAgenda(
    String id,
    List<AgendaAcara> daftarTerbaru,
  ) async {
    await _simpanCache(daftarTerbaru);

    if (!terkonfigurasi) {
      return const HasilSinkron(
        berhasil: false,
        pesan:
            'Supabase belum dikonfigurasi. Penghapusan hanya berlaku '
            'di perangkat ini.',
      );
    }

    try {
      final respon = await _klien
          .post(
            Uri.parse('$_alamat/rest/v1/rpc/hapus_agenda'),
            headers: _header,
            body: jsonEncode({'kunci': kunciTulisSupabase, 'id_agenda': id}),
          )
          .timeout(_batasWaktu);

      if (_berhasil(respon.statusCode)) {
        return const HasilSinkron(
          berhasil: true,
          pesan: 'Agenda dihapus dari semua perangkat.',
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

  /// Menyimpan salinan lokal tanpa mengirim apa pun ke server. Dipakai saat
  /// agenda ikut terhapus karena ormawanya dihapus.
  Future<void> simpanSalinanLokal(List<AgendaAcara> daftar) =>
      _simpanCache(daftar);

  Future<List<AgendaAcara>> _dariCacheAtauContoh() async {
    final cache = await _bacaCache();
    if (cache != null) return cache;

    final prefs = await SharedPreferences.getInstance();
    final pernahSinkron = prefs.getBool(_kunciPernahSinkron) ?? false;
    if (pernahSinkron) return [];
    return contohAwal();
  }

  Future<List<AgendaAcara>?> _bacaCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mentah = prefs.getString(_kunciCache);
      if (mentah == null) return null;

      final data = jsonDecode(mentah);
      if (data is! List) return null;

      final daftar = <AgendaAcara>[];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final agenda = AgendaAcara.dariPeta(item);
          if (agenda != null) daftar.add(agenda);
        }
      }
      daftar.sort((a, b) => a.waktu.compareTo(b.waktu));
      return daftar;
    } catch (_) {
      return null;
    }
  }

  Future<void> _simpanCache(List<AgendaAcara> daftar) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kunciCache,
        jsonEncode(daftar.map((agenda) => agenda.kePeta()).toList()),
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
