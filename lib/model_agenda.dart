class AgendaAcara {
  String id;
  String judul;
  String deskripsi;
  DateTime waktu;
  DateTime? waktuSelesai;
  String lokasi;
  String ormawaId;

  AgendaAcara({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.waktu,
    required this.lokasi,
    required this.ormawaId,
    this.waktuSelesai,
  });

  bool get sepanjangHari => waktuSelesai == null;

  String get jamMulaiTeks => _formatJam(waktu);

  String get jamSelesaiTeks =>
      waktuSelesai == null ? '' : _formatJam(waktuSelesai!);

  /// Contoh: "08.00–10.00" atau "Seharian".
  String get rentangWaktuTeks =>
      sepanjangHari ? 'Seharian' : '$jamMulaiTeks–$jamSelesaiTeks';

  static String _formatJam(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}.'
      '${t.minute.toString().padLeft(2, '0')}';

  /// Tanggal tanpa jam dalam format `yyyy-MM-dd`.
  ///
  /// Disimpan sebagai tanggal saja agar semua perangkat menampilkan tanggal
  /// yang sama, terlepas dari zona waktu masing-masing.
  String get tanggalIso {
    final bulan = waktu.month.toString().padLeft(2, '0');
    final hari = waktu.day.toString().padLeft(2, '0');
    return '${waktu.year.toString().padLeft(4, '0')}-$bulan-$hari';
  }

  /// Penanda jam disimpan di akhir deskripsi agar tetap tersinkron lewat
  /// kolom yang sudah ada di Supabase tanpa mengubah skema database.
  static final RegExp _polaPenandaWaktu = RegExp(
    r'\s*\[\[waktu:(\d{2}):(\d{2})-(\d{2}):(\d{2})\]\]\s*$',
  );

  String get deskripsiTersimpan {
    if (waktuSelesai == null) return deskripsi;
    final mulai =
        '${waktu.hour.toString().padLeft(2, '0')}:'
        '${waktu.minute.toString().padLeft(2, '0')}';
    final selesai =
        '${waktuSelesai!.hour.toString().padLeft(2, '0')}:'
        '${waktuSelesai!.minute.toString().padLeft(2, '0')}';
    final penanda = '[[waktu:$mulai-$selesai]]';
    final isi = deskripsi.trimRight();
    return isi.isEmpty ? penanda : '$isi\n$penanda';
  }

  Map<String, dynamic> kePeta() => {
    'id': id,
    'judul': judul,
    'deskripsi': deskripsiTersimpan,
    'tanggal': tanggalIso,
    'lokasi': lokasi,
    'ormawa': ormawaId,
  };

  static AgendaAcara? dariPeta(Map<String, dynamic> peta) {
    final id = peta['id'];
    final judul = peta['judul'];
    final tanggal = peta['tanggal'];
    if (id is! String || judul is! String || tanggal is! String) return null;

    final parsedTanggal = DateTime.tryParse(tanggal);
    if (parsedTanggal == null) return null;

    var deskripsi = peta['deskripsi'] is String
        ? peta['deskripsi'] as String
        : '';
    var waktu = DateTime(
      parsedTanggal.year,
      parsedTanggal.month,
      parsedTanggal.day,
    );
    DateTime? selesai;

    final cocok = _polaPenandaWaktu.firstMatch(deskripsi);
    if (cocok != null) {
      final jamMulai = int.tryParse(cocok.group(1)!);
      final menitMulai = int.tryParse(cocok.group(2)!);
      final jamSelesai = int.tryParse(cocok.group(3)!);
      final menitSelesai = int.tryParse(cocok.group(4)!);
      if (jamMulai != null &&
          menitMulai != null &&
          jamSelesai != null &&
          menitSelesai != null &&
          jamMulai < 24 &&
          jamSelesai < 24 &&
          menitMulai < 60 &&
          menitSelesai < 60) {
        waktu = DateTime(
          parsedTanggal.year,
          parsedTanggal.month,
          parsedTanggal.day,
          jamMulai,
          menitMulai,
        );
        selesai = DateTime(
          parsedTanggal.year,
          parsedTanggal.month,
          parsedTanggal.day,
          jamSelesai,
          menitSelesai,
        );
        deskripsi = deskripsi.replaceFirst(_polaPenandaWaktu, '').trimRight();
      }
    }

    final idOrmawa = peta['ormawa'];

    return AgendaAcara(
      id: id,
      judul: judul,
      deskripsi: deskripsi,
      waktu: waktu,
      waktuSelesai: selesai,
      lokasi: peta['lokasi'] is String ? peta['lokasi'] as String : '',
      ormawaId: idOrmawa is String && idOrmawa.isNotEmpty ? idOrmawa : 'senat',
    );
  }
}
