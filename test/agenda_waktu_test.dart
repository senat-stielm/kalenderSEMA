import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_kemahasiswaan/model_agenda.dart';

void main() {
  test('waktu mulai dan selesai tersimpan lewat penanda deskripsi', () {
    final agenda = AgendaAcara(
      id: 'uji',
      judul: 'Rapat',
      deskripsi: 'Koordinasi program kerja',
      waktu: DateTime(2026, 11, 2, 8, 0),
      waktuSelesai: DateTime(2026, 11, 2, 10, 30),
      lokasi: 'Ruang BEM',
      ormawaId: 'bem',
    );

    final peta = agenda.kePeta();
    expect(peta['tanggal'], '2026-11-02');
    expect(peta['deskripsi'], contains('[[waktu:08:00-10:30]]'));

    final hasil = AgendaAcara.dariPeta(peta)!;
    expect(hasil.deskripsi, 'Koordinasi program kerja');
    expect(hasil.waktu, DateTime(2026, 11, 2, 8, 0));
    expect(hasil.waktuSelesai, DateTime(2026, 11, 2, 10, 30));
    expect(hasil.rentangWaktuTeks, '08.00–10.30');
    expect(hasil.sepanjangHari, isFalse);
  });

  test('agenda sepanjang hari tidak memakai penanda waktu', () {
    final agenda = AgendaAcara(
      id: 'uji-2',
      judul: 'Lomba',
      deskripsi: '',
      waktu: DateTime(2026, 11, 3),
      lokasi: 'Lapangan',
      ormawaId: 'ukm1',
    );

    final peta = agenda.kePeta();
    expect(peta['deskripsi'], '');

    final hasil = AgendaAcara.dariPeta(peta)!;
    expect(hasil.sepanjangHari, isTrue);
    expect(hasil.rentangWaktuTeks, 'Seharian');
  });
}
