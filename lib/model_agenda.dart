class AgendaAcara {
  String id;
  String judul;
  String deskripsi;
  DateTime waktu;
  String lokasi;
  String ormawaId;

  AgendaAcara({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.waktu,
    required this.lokasi,
    required this.ormawaId,
  });

  /// Tanggal tanpa jam dalam format `yyyy-MM-dd`.
  ///
  /// Disimpan sebagai tanggal saja agar semua perangkat menampilkan tanggal
  /// yang sama, terlepas dari zona waktu masing-masing.
  String get tanggalIso {
    final bulan = waktu.month.toString().padLeft(2, '0');
    final hari = waktu.day.toString().padLeft(2, '0');
    return '${waktu.year.toString().padLeft(4, '0')}-$bulan-$hari';
  }

  Map<String, dynamic> kePeta() => {
    'id': id,
    'judul': judul,
    'deskripsi': deskripsi,
    'tanggal': tanggalIso,
    'lokasi': lokasi,
    'ormawa': ormawaId,
  };

  static AgendaAcara? dariPeta(Map<String, dynamic> peta) {
    final id = peta['id'];
    final judul = peta['judul'];
    final tanggal = peta['tanggal'];
    if (id is! String || judul is! String || tanggal is! String) return null;

    final waktu = DateTime.tryParse(tanggal);
    if (waktu == null) return null;

    final idOrmawa = peta['ormawa'];

    return AgendaAcara(
      id: id,
      judul: judul,
      deskripsi: peta['deskripsi'] is String ? peta['deskripsi'] as String : '',
      waktu: DateTime(waktu.year, waktu.month, waktu.day),
      lokasi: peta['lokasi'] is String ? peta['lokasi'] as String : '',
      ormawaId: idOrmawa is String && idOrmawa.isNotEmpty ? idOrmawa : 'senat',
    );
  }
}
