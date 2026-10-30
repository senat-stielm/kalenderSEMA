import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengelola sandi mode admin.
///
/// Sandi tidak pernah disimpan apa adanya; yang disimpan hanya hash SHA-256
/// dengan salt acak. Selama admin belum pernah mengganti sandi, sandi bawaan
/// [sandiBawaan] yang dipakai.
class AuthAdmin {
  static const String namaPengguna = 'admin';
  static const String sandiBawaan = 'Widyanurdianasenat2627';
  static const int panjangSandiMinimum = 6;
  static const String _kunciSandi = 'sandi_admin_v1';

  /// True jika admin sudah pernah mengganti sandi dari sandi bawaan.
  Future<bool> punyaSandiKhusus() async => (await _bacaSandi()) != null;

  Future<bool> masuk(String pengguna, String sandi) async {
    if (pengguna.trim().toLowerCase() != namaPengguna) return false;

    final tersimpan = await _bacaSandi();
    if (tersimpan == null) return sandi == sandiBawaan;

    final bagian = tersimpan.split(':');
    if (bagian.length != 2) return false;
    final salt = bagian[0];
    final hash = bagian[1];
    return _hash(salt, sandi) == hash;
  }

  /// Mengembalikan pesan kesalahan, atau `null` jika berhasil.
  Future<String?> ubahSandi({
    required String sandiLama,
    required String sandiBaru,
  }) async {
    if (sandiBaru.length < panjangSandiMinimum) {
      return 'Password baru minimal $panjangSandiMinimum karakter.';
    }
    if (sandiBaru == sandiLama) {
      return 'Password baru harus berbeda dari password lama.';
    }
    if (!await masuk(namaPengguna, sandiLama)) {
      return 'Password lama salah.';
    }

    final salt = _buatSalt();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kunciSandi, '$salt:${_hash(salt, sandiBaru)}');
    return null;
  }

  Future<String?> _bacaSandi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kunciSandi);
  }

  static String _buatSalt() {
    final acak = Random.secure();
    final bytes = List<int>.generate(16, (_) => acak.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hash(String salt, String sandi) {
    return sha256.convert(utf8.encode('$salt:$sandi')).toString();
  }
}
