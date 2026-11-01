import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_kemahasiswaan/kalender_hijriah.dart';

void main() {
  test('tanggal Hijriah memakai kalender Umm al-Qura', () {
    expect(tanggalHijriah(DateTime(2025, 6, 26)), '1 Muharram 1447 H');
    expect(tanggalHijriah(DateTime(2026, 3, 20)), '1 Syawal 1447 H');
    expect(tanggalHijriah(DateTime(2026, 6, 16)), '1 Muharram 1448 H');
    expect(tanggalHijriah(DateTime(2026, 11, 2)), '22 Jumadil Awal 1448 H');
  });
}
