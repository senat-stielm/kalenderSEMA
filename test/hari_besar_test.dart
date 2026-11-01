import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_kemahasiswaan/hari_besar.dart';

void main() {
  test('libur nasional resmi dikenali', () {
    final kemerdekaan = hariBesarPada(DateTime(2026, 8, 17));
    expect(kemerdekaan?.nama, 'Proklamasi Kemerdekaan RI');
    expect(kemerdekaan?.jenis, JenisHariBesar.liburNasional);
    expect(hariBesarPada(DateTime(2027, 12, 25))?.libur, isTrue);
    expect(hariBesarPada(DateTime(2026, 3, 21))?.nama, 'Idulfitri 1447 H');
  });

  test('hari besar nasional berulang setiap tahun', () {
    final pahlawan = hariBesarPada(DateTime(2026, 11, 10));
    expect(pahlawan?.nama, 'Hari Pahlawan');
    expect(pahlawan?.jenis, JenisHariBesar.peringatanNasional);
    expect(hariBesarPada(DateTime(2030, 11, 25))?.nama, 'Hari Guru Nasional');
  });

  test('tanggal biasa tidak ditandai', () {
    expect(hariBesarPada(DateTime(2026, 11, 3)), isNull);
  });

  test('libur tetap berlaku setelah tahun SKB', () {
    expect(hariBesarPada(DateTime(2029, 1, 1))?.nama, 'Tahun Baru Masehi');
    expect(hariBesarPada(DateTime(2029, 8, 17))?.libur, isTrue);
  });
}
