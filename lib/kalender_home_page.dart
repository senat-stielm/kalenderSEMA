import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'auth_admin.dart';
import 'dialog_admin.dart';
import 'dialog_ormawa.dart';
import 'gaya_iphone.dart';
import 'hari_besar.dart';
import 'kalender_hijriah.dart';
import 'kalender_tahunan.dart';
import 'layanan_agenda.dart';
import 'layanan_ormawa.dart';
import 'model_agenda.dart';
import 'model_ormawa.dart';
import 'pemilih_warna.dart';
import 'pengaturan_warna.dart';
import 'pengingat_h1.dart';

class KalenderHomePage extends StatefulWidget {
  const KalenderHomePage({
    super.key,
    required this.tema,
    required this.onTemaBerubah,
  });

  final PengaturanWarna tema;
  final ValueChanged<PengaturanWarna> onTemaBerubah;

  @override
  State<KalenderHomePage> createState() => _KalenderHomePageState();
}

class _KalenderHomePageState extends State<KalenderHomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _filterOrmawaId;

  final LayananAgenda _layananAgenda = LayananAgenda();
  final LayananOrmawa _layananOrmawa = LayananOrmawa();
  final AuthAdmin _authAdmin = AuthAdmin();

  List<Ormawa> _daftarOrmawa = List.of(ormawaBawaan);
  List<AgendaAcara> _semuaAgenda = const [];
  bool _memuatAgenda = true;
  bool _sedangMenyinkron = false;
  bool _modeAdmin = false;
  bool _pengingatH1Ditampilkan = false;
  String? _galatSinkron;

  PengaturanWarna get _tema => widget.tema;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _muatOrmawa();
    _muatAgenda();
  }

  Future<void> _muatAgenda({bool tampilkanPesan = false}) async {
    if (_sedangMenyinkron) return;

    setState(() {
      _sedangMenyinkron = true;
      _memuatAgenda = _semuaAgenda.isEmpty;
      _galatSinkron = null;
    });

    final hasil = await _layananAgenda.muatAgenda();
    if (!mounted) return;

    setState(() {
      _semuaAgenda = hasil.daftar;
      _memuatAgenda = false;
      _sedangMenyinkron = false;
      _galatSinkron = hasil.galat;
    });

    // Tampilkan pengingat H-1 sekali setiap aplikasi dibuka.
    if (!_pengingatH1Ditampilkan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tampilkanPengingatH1();
      });
    }

    if (tampilkanPesan) {
      _tampilkanPesan(
        hasil.galat ?? 'Agenda berhasil diperbarui dari server.',
        berhasil: hasil.galat == null,
      );
    }
  }

  /// Pop-up pengingat H-1 untuk semua pengguna: muncul sekali setiap aplikasi
  /// dibuka bila ada kegiatan besok.
  Future<void> _tampilkanPengingatH1() async {
    if (_pengingatH1Ditampilkan || !mounted) return;

    final sekarang = DateTime.now();
    final besok = DateTime(
      sekarang.year,
      sekarang.month,
      sekarang.day,
    ).add(const Duration(days: 1));
    final agendaBesok =
        _semuaAgenda.where((agenda) => isSameDay(agenda.waktu, besok)).toList()
          ..sort((a, b) => a.waktu.compareTo(b.waktu));
    if (agendaBesok.isEmpty) return;

    _pengingatH1Ditampilkan = true;
    final daftar = <PengingatAgenda>[];
    for (final agenda in agendaBesok) {
      final ormawa = _ormawaUntuk(agenda.ormawaId);
      daftar.add(
        PengingatAgenda(
          judul: agenda.judul,
          keterangan: [
            agenda.rentangWaktuTeks,
            ormawa.kategori,
            if (agenda.lokasi.isNotEmpty) agenda.lokasi,
          ].join(' • '),
          warna: ormawa.warna,
          ikon: ormawa.ikon,
        ),
      );
    }

    await tampilkanPengingatH1(
      context,
      tema: _tema,
      tanggalBesok: besok,
      agenda: daftar,
    );
  }

  Future<void> _simpanAgendaKeServer(AgendaAcara agenda) async {
    final hasil = await _layananAgenda.simpanAgenda(
      agenda,
      List.of(_semuaAgenda),
    );
    if (!mounted) return;

    setState(() => _galatSinkron = hasil.berhasil ? null : hasil.pesan);
    _tampilkanPesan(hasil.pesan, berhasil: hasil.berhasil);
  }

  Future<void> _hapusAgendaDiServer(String id) async {
    final hasil = await _layananAgenda.hapusAgenda(id, List.of(_semuaAgenda));
    if (!mounted) return;

    setState(() => _galatSinkron = hasil.berhasil ? null : hasil.pesan);
    _tampilkanPesan(hasil.pesan, berhasil: hasil.berhasil);
  }

  void _tampilkanPesan(String pesan, {bool berhasil = true}) {
    if (!mounted) return;

    final warna = berhasil ? _tema.aksen : _tema.peringatan;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                berhasil
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: warna,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pesan,
                  style: TextStyle(
                    color: _tema.teks,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: _tema.kartu,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: warna.withValues(alpha: 0.35)),
          ),
        ),
      );
  }

  Future<void> _muatOrmawa() async {
    final hasil = await _layananOrmawa.muatOrmawa();
    if (!mounted) return;

    setState(() {
      _daftarOrmawa = hasil.daftar;
      if (hasil.galat != null) _galatSinkron = hasil.galat;
    });
  }

  Ormawa _ormawaUntuk(String id) {
    for (final ormawa in _daftarOrmawa) {
      if (ormawa.id == id) return ormawa;
    }
    return ormawaCadangan(id);
  }

  Future<void> _simpanOrmawa(Ormawa ormawa) async {
    final daftarBaru = List<Ormawa>.of(_daftarOrmawa);
    final indeks = daftarBaru.indexWhere((item) => item.id == ormawa.id);
    if (indeks >= 0) {
      daftarBaru[indeks] = ormawa;
    } else {
      daftarBaru.add(ormawa);
    }

    setState(() => _daftarOrmawa = daftarBaru);

    final hasil = await _layananOrmawa.simpanOrmawa(ormawa, daftarBaru);
    if (!mounted) return;

    setState(() => _galatSinkron = hasil.berhasil ? null : hasil.pesan);
    _tampilkanPesan(hasil.pesan, berhasil: hasil.berhasil);
  }

  Future<void> _hapusOrmawa(Ormawa ormawa) async {
    final daftarBaru = _daftarOrmawa
        .where((item) => item.id != ormawa.id)
        .toList();

    setState(() {
      _daftarOrmawa = daftarBaru;
      _semuaAgenda = _semuaAgenda
          .where((agenda) => agenda.ormawaId != ormawa.id)
          .toList();
      if (_filterOrmawaId == ormawa.id) _filterOrmawaId = null;
    });

    await _layananAgenda.simpanSalinanLokal(_semuaAgenda);
    final hasil = await _layananOrmawa.hapusOrmawa(ormawa.id, daftarBaru);
    if (!mounted) return;

    setState(() => _galatSinkron = hasil.berhasil ? null : hasil.pesan);
    _tampilkanPesan(hasil.pesan, berhasil: hasil.berhasil);

    if (hasil.berhasil) _muatAgenda();
  }

  List<AgendaAcara> _getAgendasForDay(DateTime day) {
    return _semuaAgenda.where((agenda) {
      return isSameDay(agenda.waktu, day);
    }).toList();
  }

  /// Semua agenda dengan urutan waktu naik. Penyaringan ormawa hanya
  /// diterapkan di panel "Semua Agenda" agar kalender tetap menampilkan
  /// seluruh kegiatan.
  List<AgendaAcara> get _agendaTerurut {
    final daftar = _filterOrmawaId == null
        ? List.of(_semuaAgenda)
        : _semuaAgenda
              .where((agenda) => agenda.ormawaId == _filterOrmawaId)
              .toList();
    daftar.sort((a, b) => a.waktu.compareTo(b.waktu));
    return daftar;
  }

  void _keHariIni() {
    final sekarang = DateTime.now();
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDay = sekarang;
      _focusedDay = sekarang;
    });
  }

  Future<void> _bukaKalenderTahunan() async {
    final tanggalTerpilih = _selectedDay ?? _focusedDay;
    final hasil = await tampilkanKalenderTahunan(
      context,
      tema: _tema,
      tanggalTerpilih: tanggalTerpilih,
      hariIni: DateTime.now(),
      tanggalBeragenda: {for (final agenda in _semuaAgenda) agenda.tanggalIso},
    );
    if (hasil == null || !mounted) return;

    setState(() {
      _selectedDay = hasil;
      _focusedDay = hasil;
    });
  }

  Future<void> _bukaKalenderHijriah() async {
    final tanggalTerpilih = _selectedDay ?? _focusedDay;
    final warnaAgenda = <String, List<Color>>{};
    for (final agenda in _semuaAgenda) {
      final warna = _ormawaUntuk(agenda.ormawaId).warna;
      final daftar = warnaAgenda.putIfAbsent(
        agenda.tanggalIso,
        () => <Color>[],
      );
      if (!daftar.contains(warna) && daftar.length < 3) daftar.add(warna);
    }
    final hasil = await tampilkanKalenderHijriah(
      context,
      tema: _tema,
      tanggalTerpilih: tanggalTerpilih,
      hariIni: DateTime.now(),
      warnaAgenda: warnaAgenda,
    );
    if (hasil == null || !mounted) return;

    setState(() {
      _selectedDay = hasil;
      _focusedDay = hasil;
    });
  }

  Future<void> _bukaDialogOrmawa({
    Ormawa? awal,
    required VoidCallback onUpdated,
  }) async {
    final hasil = await showDialog<Ormawa>(
      context: context,
      builder: (ctx) => DialogOrmawa(tema: _tema, awal: awal),
    );
    if (hasil == null || !mounted) return;

    final sinkron = _simpanOrmawa(hasil);
    onUpdated();
    await sinkron;
  }

  Future<void> _konfirmasiHapusOrmawa(
    Ormawa ormawa,
    VoidCallback onUpdated,
  ) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _tema.kartu,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(
          'Hapus ${ormawa.nama}?',
          style: TextStyle(color: _tema.teks, fontSize: 17),
        ),
        content: Text(
          'Semua agenda dari ormawa ini juga akan dihapus di semua perangkat. '
          'Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: _tema.teksLembut),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _tema.bahaya,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (setuju != true) return;

    final hapus = _hapusOrmawa(ormawa);
    onUpdated();
    await hapus;
  }

  // Mode admin: masuk, panel pengaturan, ubah sandi, dan keluar.
  Future<void> _bukaMenuAdmin() async {
    if (_modeAdmin) {
      _bukaPanelAdmin();
      return;
    }

    final berhasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => DialogMasukAdmin(authAdmin: _authAdmin, tema: _tema),
    );
    if (berhasil == true && mounted) {
      setState(() => _modeAdmin = true);
      _tampilkanPesan(
        'Mode admin aktif. Anda sekarang dapat menambah dan mengubah agenda.',
      );
    }
  }

  void _bukaPanelAdmin() {
    final tema = _tema;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: tema.kartu,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: tema.aksen.withValues(alpha: 0.35)),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: tema.aksen.withValues(alpha: 0.18),
                radius: 18,
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: tema.aksen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mode Admin',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: tema.teks,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anda masuk sebagai admin. Anggota lain hanya dapat melihat '
                'jadwal tanpa perlu login.',
                style: TextStyle(color: tema.teksLembut, fontSize: 12),
              ),
              const SizedBox(height: 14),
              _barisMenuAdmin(
                ctx,
                tema,
                ikon: Icons.password_rounded,
                judul: 'Ubah Password Admin',
                onTap: () {
                  Navigator.pop(ctx);
                  _bukaDialogUbahSandi();
                },
              ),
              _barisMenuAdmin(
                ctx,
                tema,
                ikon: Icons.sync_rounded,
                judul: 'Sinkronkan Agenda Sekarang',
                onTap: () {
                  Navigator.pop(ctx);
                  _muatAgenda(tampilkanPesan: true);
                },
              ),
              _barisMenuAdmin(
                ctx,
                tema,
                ikon: Icons.logout_rounded,
                judul: 'Keluar Mode Admin',
                warna: tema.peringatan,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _modeAdmin = false);
                  _tampilkanPesan('Anda keluar dari mode admin.');
                },
              ),
              if (_galatSinkron != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tema.peringatan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: tema.peringatan.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _galatSinkron!,
                    style: TextStyle(color: tema.peringatan, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tema.aksen,
                foregroundColor: tema.diAksen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Tutup',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _barisMenuAdmin(
    BuildContext ctx,
    PengaturanWarna tema, {
    required IconData ikon,
    required String judul,
    required VoidCallback onTap,
    Color? warna,
  }) {
    final c = warna ?? tema.aksen;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: tema.isian,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(ikon, color: c, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                judul,
                style: TextStyle(
                  color: tema.teks,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: c.withValues(alpha: 0.75),
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bukaDialogUbahSandi() async {
    final berhasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => DialogUbahSandi(authAdmin: _authAdmin, tema: _tema),
    );
    if (berhasil == true && mounted) {
      _tampilkanPesan('Password admin berhasil diubah.');
    }
  }

  // Modal Pengaturan Tema, Nama & Warna Organisasi
  void _bukaPanelKustomisasi() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final tema = _tema;
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.alphaBlend(
                      tema.aksen.withValues(alpha: 0.06),
                      tema.latar2,
                    ),
                    tema.latar1,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border.all(color: tema.garis, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: tema.bayangan,
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    width: 40,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: tema.teks.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [tema.aksen, tema.aksenGelap],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: tema.aksen.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.palette_rounded,
                            color: tema.diAksen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kustomisasi Tampilan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5,
                                  color: tema.teks,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _modeAdmin
                                    ? 'Atur tema aplikasi serta nama dan warna tiap ormawa'
                                    : 'Atur tema aplikasi. Nama dan warna ormawa hanya bisa diubah admin.',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: tema.teksRedup,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: tema.garisLembut, height: 1),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: _modeAdmin
                          ? _daftarOrmawa.length + 2
                          : _daftarOrmawa.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _kartuTema(
                            tema,
                            onTap: () =>
                                _bukaDialogTema(() => setSheetState(() {})),
                          );
                        }

                        if (_modeAdmin && index == 1) {
                          return _kartuTambahOrmawa(
                            tema,
                            () => setSheetState(() {}),
                          );
                        }

                        final org =
                            _daftarOrmawa[_modeAdmin ? index - 2 : index - 1];
                        final warna = org.warna;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: warna.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: warna.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: ListTile(
                              onTap: _modeAdmin
                                  ? () => _bukaDialogOrmawa(
                                      awal: org,
                                      onUpdated: () => setSheetState(() {}),
                                    )
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              contentPadding: const EdgeInsets.fromLTRB(
                                12,
                                4,
                                8,
                                4,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      warna,
                                      Color.lerp(warna, Colors.black, 0.28)!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                  boxShadow: [
                                    BoxShadow(
                                      color: warna.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  org.ikon,
                                  color: warnaDiAtas(warna),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                org.nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: tema.teks,
                                  fontSize: 13.5,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: warna.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      org.kategori,
                                      style: TextStyle(
                                        color: warnaTeksOrmawa(warna, tema),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: _modeAdmin
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _tombolAksiOrmawa(
                                          ikon: Icons.edit_rounded,
                                          tooltip: 'Ubah ormawa',
                                          warna: warna,
                                          onTap: () => _bukaDialogOrmawa(
                                            awal: org,
                                            onUpdated: () =>
                                                setSheetState(() {}),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        _tombolAksiOrmawa(
                                          ikon: Icons.delete_outline_rounded,
                                          tooltip: 'Hapus ormawa',
                                          warna: tema.bahaya,
                                          onTap: () => _konfirmasiHapusOrmawa(
                                            org,
                                            () => setSheetState(() {}),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Tooltip(
                                      message: 'Dikelola admin',
                                      child: Icon(
                                        Icons.lock_outline_rounded,
                                        size: 15,
                                        color: tema.teksSamar,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _kartuTema(PengaturanWarna tema, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tema.aksen.withValues(alpha: 0.2),
            tema.kartu.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tema.aksen.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: tema.aksen.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tema.aksen, tema.aksenGelap],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: tema.aksen.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.palette_rounded, color: tema.diAksen, size: 21),
          ),
          title: Text(
            'Tema Aplikasi',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: tema.teks,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Mode terang/gelap dan warna aksen',
              style: TextStyle(color: tema.teksRedup, fontSize: 10.5),
            ),
          ),
          trailing: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: tema.aksen,
              foregroundColor: tema.diAksen,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 15),
            label: const Text(
              'Atur',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  // Dialog untuk mengubah seluruh warna tema aplikasi
  void _bukaDialogTema([VoidCallback? onSelesai]) {
    var tema = _tema;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            void terapkan(PengaturanWarna baru) {
              tema = baru;
              widget.onTemaBerubah(baru);
              setDialogState(() {});
              onSelesai?.call();
            }

            final lebar = (MediaQuery.sizeOf(ctx).width - 112).clamp(
              200.0,
              340.0,
            );

            return AlertDialog(
              backgroundColor: tema.kartu,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: tema.garis),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [tema.aksen, tema.aksenGelap],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      color: tema.diAksen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tema Aplikasi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: tema.teks,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: lebar,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _pratinjauTema(tema),
                      const SizedBox(height: 16),
                      Text(
                        'MODE TAMPILAN',
                        style: TextStyle(
                          color: tema.teksRedup,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _pilMode(
                              tema,
                              aktif: !tema.gelap,
                              ikon: Icons.light_mode_rounded,
                              label: 'Terang',
                              onTap: () => terapkan(tema.salin(gelap: false)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _pilMode(
                              tema,
                              aktif: tema.gelap,
                              ikon: Icons.dark_mode_rounded,
                              label: 'Gelap',
                              onTap: () => terapkan(tema.salin(gelap: true)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'WARNA AKSEN',
                        style: TextStyle(
                          color: tema.teksRedup,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _barisWarnaTema(
                        ctx,
                        tema,
                        'Warna Aksen',
                        tema.aksen,
                        (warna) => terapkan(tema.salin(aksen: warna)),
                      ),
                      _barisWarnaTema(
                        ctx,
                        tema,
                        'Aksen Gelap',
                        tema.aksenGelap,
                        (warna) => terapkan(tema.salin(aksenGelap: warna)),
                      ),
                      _barisWarnaTema(
                        ctx,
                        tema,
                        'Warna Sekunder',
                        tema.sekunder,
                        (warna) => terapkan(tema.salin(sekunder: warna)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => terapkan(PengaturanWarna.bawaan),
                  child: const Text('Pulihkan Default'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: tema.aksen,
                    foregroundColor: tema.diAksen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _pilMode(
    PengaturanWarna tema, {
    required bool aktif,
    required IconData ikon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TekanSkala(
      onTap: onTap,
      skala: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: aktif
              ? LinearGradient(colors: [tema.aksen, tema.aksenGelap])
              : null,
          color: aktif ? null : tema.isian,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: aktif ? Colors.white.withValues(alpha: 0.45) : tema.garis,
          ),
          boxShadow: aktif
              ? [
                  BoxShadow(
                    color: tema.aksen.withValues(alpha: 0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, size: 16, color: aktif ? tema.diAksen : tema.teksRedup),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: aktif ? tema.diAksen : tema.teksLembut,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pratinjauTema(PengaturanWarna tema) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tema.latar1, tema.latar2, tema.latar3],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tema.garis),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tema.aksen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tema.aksen.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tema.sekunder,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tema.sekunder.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: tema.kartu,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tema.garis),
              ),
              alignment: Alignment.center,
              child: Text(
                'Contoh Kartu',
                style: TextStyle(
                  color: tema.aksen,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisWarnaTema(
    BuildContext ctx,
    PengaturanWarna tema,
    String label,
    Color warna,
    ValueChanged<Color> onPilih,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final hasil = await tampilkanPemilihWarna(
          ctx,
          warnaAwal: warna,
          tema: tema,
          judul: label,
        );
        if (hasil != null) onPilih(hasil);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: tema.isian,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tema.garisLembut),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: warna,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tema.garis),
                boxShadow: [
                  BoxShadow(
                    color: warna.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: tema.teks,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                  Text(
                    formatKodeHex(warna),
                    style: TextStyle(
                      color: tema.teksRedup,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_rounded,
              size: 15,
              color: tema.aksen.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuTambahOrmawa(PengaturanWarna tema, VoidCallback onUpdated) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tema.isian,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tema.garis),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: () => _bukaDialogOrmawa(onUpdated: onUpdated),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tema.aksen.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: tema.aksen.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.add_rounded, color: tema.aksen, size: 22),
          ),
          title: Text(
            'Tambah Ormawa / UKM / UKK',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: tema.teks,
              fontSize: 13,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              'Buat organisasi baru',
              style: TextStyle(color: tema.teksRedup, fontSize: 10.5),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: tema.aksen.withValues(alpha: 0.8),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _tombolAksiOrmawa({
    required IconData ikon,
    required String tooltip,
    required Color warna,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: warna.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: warna.withValues(alpha: 0.45)),
          ),
          child: Icon(ikon, size: 17, color: warna),
        ),
      ),
    );
  }

  Widget _kolomWaktu({
    required PengaturanWarna tema,
    required String label,
    required TimeOfDay waktu,
    required Color warna,
    required ValueChanged<TimeOfDay> onUbah,
  }) {
    final teks =
        '${waktu.hour.toString().padLeft(2, '0')}.'
        '${waktu.minute.toString().padLeft(2, '0')}';

    return TekanSkala(
      onTap: () async {
        final pilih = await showTimePicker(
          context: context,
          initialTime: waktu,
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (pilih != null) onUbah(pilih);
      },
      skala: 0.97,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: tema.kartu.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: warna.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: tema.teksRedup, fontSize: 9.5)),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: warna),
                const SizedBox(width: 6),
                Text(
                  teks,
                  style: TextStyle(
                    color: tema.teks,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Modal Form Tambah / Edit Agenda Kegiatan
  void _bukaDialogFormAgenda({
    AgendaAcara? agendaUntukDiedit,
    VoidCallback? onSelesai,
  }) {
    if (_daftarOrmawa.isEmpty) {
      _tampilkanPesan(
        'Belum ada ormawa. Tambahkan ormawa dulu lewat menu Tampilan.',
        berhasil: false,
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final judulCtrl = TextEditingController(
      text: agendaUntukDiedit?.judul ?? '',
    );
    final deskripsiCtrl = TextEditingController(
      text: agendaUntukDiedit?.deskripsi ?? '',
    );
    final lokasiCtrl = TextEditingController(
      text: agendaUntukDiedit?.lokasi ?? '',
    );

    DateTime tanggalTerpilih =
        agendaUntukDiedit?.waktu ?? (_selectedDay ?? DateTime.now());

    var sepanjangHari = agendaUntukDiedit == null
        ? false
        : agendaUntukDiedit.sepanjangHari;
    var jamMulai = agendaUntukDiedit != null && !agendaUntukDiedit.sepanjangHari
        ? TimeOfDay.fromDateTime(agendaUntukDiedit.waktu)
        : const TimeOfDay(hour: 8, minute: 0);
    var jamSelesai =
        agendaUntukDiedit != null && !agendaUntukDiedit.sepanjangHari
        ? TimeOfDay.fromDateTime(agendaUntukDiedit.waktuSelesai!)
        : const TimeOfDay(hour: 10, minute: 0);

    var ormawaTerpilihId = agendaUntukDiedit?.ormawaId ?? _filterOrmawaId ?? '';
    if (!_daftarOrmawa.any((org) => org.id == ormawaTerpilihId)) {
      ormawaTerpilihId = _daftarOrmawa.first.id;
    }

    final tema = _tema;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final warnaAktif = _ormawaUntuk(ormawaTerpilihId).warna;
            final menitMulai = jamMulai.hour * 60 + jamMulai.minute;
            final menitSelesai = jamSelesai.hour * 60 + jamSelesai.minute;
            final waktuValid = sepanjangHari || menitSelesai > menitMulai;
            return AlertDialog(
              backgroundColor: tema.kartu,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: warnaAktif.withValues(alpha: 0.35)),
              ),
              title: Text(
                agendaUntukDiedit == null
                    ? 'Tambah Agenda Kegiatan'
                    : 'Edit Agenda Kegiatan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: tema.teks,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: ormawaTerpilihId,
                        isExpanded: true,
                        dropdownColor: tema.latar2,
                        decoration: InputDecoration(
                          labelText: 'Penyelenggara / Ormawa',
                          filled: true,
                          fillColor: tema.isian,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _daftarOrmawa.map((org) {
                          final c = org.warna;
                          return DropdownMenuItem(
                            value: org.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    org.nama,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: c,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => ormawaTerpilihId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: judulCtrl,
                        style: TextStyle(color: tema.teks),
                        decoration: InputDecoration(
                          labelText: 'Nama Kegiatan',
                          filled: true,
                          fillColor: tema.isian,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lokasiCtrl,
                        style: TextStyle(color: tema.teks),
                        decoration: InputDecoration(
                          labelText: 'Lokasi Kegiatan',
                          filled: true,
                          fillColor: tema.isian,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: deskripsiCtrl,
                        maxLines: 2,
                        style: TextStyle(color: tema.teks),
                        decoration: InputDecoration(
                          labelText: 'Deskripsi / Catatan',
                          filled: true,
                          fillColor: tema.isian,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        tileColor: tema.isian,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: warnaAktif.withValues(alpha: 0.5),
                          ),
                        ),
                        leading: Icon(
                          Icons.calendar_month_rounded,
                          color: warnaAktif,
                        ),
                        title: Text(
                          'Tanggal Pelaksanaan',
                          style: TextStyle(
                            fontSize: 11,
                            color: tema.teksLembut,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('EEEE, d MMMM yyyy')
                              .format(tanggalTerpilih),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tema.teks,
                          ),
                        ),
                        onTap: () async {
                          final pilih = await showDatePicker(
                            context: context,
                            initialDate: tanggalTerpilih,
                            firstDate: DateTime(2025, 1, 1),
                            lastDate: DateTime(2030, 12, 31),
                          );
                          if (pilih != null) {
                            setDialogState(() => tanggalTerpilih = pilih);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: tema.isian,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: warnaAktif.withValues(alpha: 0.35),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: sepanjangHari,
                              onChanged: (nilai) =>
                                  setDialogState(() => sepanjangHari = nilai),
                              activeTrackColor: warnaAktif,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              secondary: Icon(
                                Icons.event_busy_rounded,
                                color: warnaAktif,
                                size: 20,
                              ),
                              title: Text(
                                'Sepanjang hari',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tema.teks,
                                ),
                              ),
                              subtitle: Text(
                                sepanjangHari
                                    ? 'Tanpa jam pelaksanaan'
                                    : 'Atur jam mulai dan selesai',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: tema.teksRedup,
                                ),
                              ),
                            ),
                            if (!sepanjangHari) ...[
                              Divider(height: 1, color: tema.garisLembut),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  12,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _kolomWaktu(
                                            tema: tema,
                                            label: 'Waktu Mulai',
                                            waktu: jamMulai,
                                            warna: warnaAktif,
                                            onUbah: (w) => setDialogState(
                                              () => jamMulai = w,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _kolomWaktu(
                                            tema: tema,
                                            label: 'Waktu Selesai',
                                            waktu: jamSelesai,
                                            warna: warnaAktif,
                                            onUbah: (w) => setDialogState(
                                              () => jamSelesai = w,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!waktuValid) ...[
                                      const SizedBox(height: 7),
                                      Text(
                                        'Waktu selesai harus setelah '
                                        'waktu mulai.',
                                        style: TextStyle(
                                          color: tema.peringatan,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal', style: TextStyle(color: tema.teksRedup)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warnaAktif,
                    foregroundColor:
                        ThemeData.estimateBrightnessForColor(warnaAktif) ==
                            Brightness.dark
                        ? Colors.white
                        : tema.diAksen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (!waktuValid) return;
                    if (formKey.currentState?.validate() ?? false) {
                      late AgendaAcara agendaTersimpan;
                      final tanggalSaja = DateTime(
                        tanggalTerpilih.year,
                        tanggalTerpilih.month,
                        tanggalTerpilih.day,
                      );
                      final waktuMulai = sepanjangHari
                          ? tanggalSaja
                          : DateTime(
                              tanggalTerpilih.year,
                              tanggalTerpilih.month,
                              tanggalTerpilih.day,
                              jamMulai.hour,
                              jamMulai.minute,
                            );
                      final waktuSelesai = sepanjangHari
                          ? null
                          : DateTime(
                              tanggalTerpilih.year,
                              tanggalTerpilih.month,
                              tanggalTerpilih.day,
                              jamSelesai.hour,
                              jamSelesai.minute,
                            );

                      setState(() {
                        if (agendaUntukDiedit == null) {
                          agendaTersimpan = AgendaAcara(
                            id: DateTime.now().microsecondsSinceEpoch
                                .toString(),
                            judul: judulCtrl.text.trim(),
                            deskripsi: deskripsiCtrl.text.trim(),
                            waktu: waktuMulai,
                            waktuSelesai: waktuSelesai,
                            lokasi: lokasiCtrl.text.trim(),
                            ormawaId: ormawaTerpilihId,
                          );
                          _semuaAgenda.add(agendaTersimpan);
                        } else {
                          agendaUntukDiedit.judul = judulCtrl.text.trim();
                          agendaUntukDiedit.deskripsi = deskripsiCtrl.text
                              .trim();
                          agendaUntukDiedit.waktu = waktuMulai;
                          agendaUntukDiedit.waktuSelesai = waktuSelesai;
                          agendaUntukDiedit.lokasi = lokasiCtrl.text.trim();
                          agendaUntukDiedit.ormawaId = ormawaTerpilihId;
                          agendaTersimpan = agendaUntukDiedit;
                        }
                        _semuaAgenda.sort((a, b) => a.waktu.compareTo(b.waktu));
                        _selectedDay = tanggalSaja;
                        _focusedDay = tanggalSaja;
                      });
                      Navigator.pop(context);
                      _simpanAgendaKeServer(agendaTersimpan);
                      onSelesai?.call();
                    }
                  },
                  child: Text(
                    agendaUntukDiedit == null ? 'Simpan' : 'Perbarui',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _tanyaHapus(AgendaAcara item) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _tema.kartu,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: _tema.bahaya.withValues(alpha: 0.45),
            width: 1.4,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _tema.bahaya.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: _tema.bahaya,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hapus Agenda?',
                style: TextStyle(
                  color: _tema.teks,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Kegiatan "${item.judul}" akan dihapus dari kalender dan semua '
          'perangkat. Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: _tema.teksLembut, fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _tema.bahaya,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return setuju == true;
  }

  void _hapusAgenda(AgendaAcara item) {
    setState(() => _semuaAgenda.removeWhere((x) => x.id == item.id));
    _hapusAgendaDiServer(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final tema = _tema;
    final tanggalAktif = _selectedDay ?? _focusedDay;
    final agendaTerpilih = _getAgendasForDay(tanggalAktif);
    final bawah = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: LatarHangat(
        tema: tema,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _muatAgenda,
            color: tema.aksen,
            backgroundColor: tema.kartu,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: AnimasiMuncul(
                    durasi: const Duration(milliseconds: 520),
                    child: _buildHeader(tema),
                  ),
                ),
                if (_galatSinkron != null)
                  SliverToBoxAdapter(child: _buildPeringatanSinkron(tema)),
                SliverToBoxAdapter(
                  child: AnimasiMuncul(
                    tunda: const Duration(milliseconds: 90),
                    durasi: const Duration(milliseconds: 560),
                    jarak: 0.04,
                    child: _buildKalender(tema),
                  ),
                ),
                SliverToBoxAdapter(
                  child: AnimasiMuncul(
                    tunda: const Duration(milliseconds: 150),
                    durasi: const Duration(milliseconds: 520),
                    child: _buildJudulKegiatan(tema, agendaTerpilih),
                  ),
                ),
                if (_memuatAgenda)
                  SliverToBoxAdapter(child: _buildMemuat(tema))
                else if (agendaTerpilih.isEmpty)
                  SliverToBoxAdapter(child: _buildKosong(tema))
                else
                  SliverList.builder(
                    itemCount: agendaTerpilih.length,
                    itemBuilder: (context, index) {
                      final item = agendaTerpilih[index];
                      return AnimasiMuncul(
                        key: ValueKey('muncul-${item.id}'),
                        tunda: Duration(
                          milliseconds: (index < 6 ? index : 6) * 55,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _kartuAgendaItem(item, tema),
                        ),
                      );
                    },
                  ),
                SliverToBoxAdapter(child: SizedBox(height: 120 + bawah)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildNavigasiBawah(tema),
    );
  }

  // Header: logo OrmaKta (ketuk untuk membuka kalender tahunan).
  Widget _buildHeader(PengaturanWarna tema) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: 'Kalender tahunan',
            child: TekanSkala(
              onTap: _bukaKalenderTahunan,
              skala: 0.96,
              child: const SizedBox(
                height: 50,
                child: Image(
                  image: AssetImage('assets/logo_ormakta.png'),
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              _modeAdmin ? 'Mode admin aktif' : 'Senat • BEM • HMPS • UKM',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tema.teksRedup,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeringatanSinkron(PengaturanWarna tema) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: tema.peringatan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: tema.peringatan.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 13, color: tema.peringatan),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _galatSinkron!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tema.peringatan.withValues(alpha: 0.9),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
            TekanSkala(
              onTap: () => _muatAgenda(tampilkanPesan: true),
              skala: 0.85,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: tema.peringatan,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kartu kalender putih dengan judul bulan dan tombol "Hari Ini".
  Widget _buildKalender(PengaturanWarna tema) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
        decoration: BoxDecoration(
          color: tema.kartu.withValues(alpha: tema.gelap ? 0.92 : 0.97),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: tema.garisLembut),
          boxShadow: [
            BoxShadow(
              color: tema.bayangan,
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animasi) =>
                              FadeTransition(opacity: animasi, child: child),
                          child: Text(
                            DateFormat(
                              'MMMM yyyy',
                              'id_ID',
                            ).format(_focusedDay),
                            key: ValueKey(
                              '${_focusedDay.year}-${_focusedDay.month}',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tema.teks,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TekanSkala(
                          onTap: _bukaKalenderHijriah,
                          skala: 0.98,
                          getar: false,
                          child: Tooltip(
                            message: 'Buka kalender Hijriah',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.nightlight_round,
                                  size: 11,
                                  color: tema.aksenTeks,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    tanggalHijriah(_selectedDay ?? _focusedDay),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: tema.teksRedup,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.05,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 13,
                                  color: tema.teksSamar,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _tombolHariIni(tema),
                ],
              ),
            ),
            _bannerHariBesar(tema),
            const SizedBox(height: 8),
            TableCalendar<AgendaAcara>(
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              headerVisible: false,
              rowHeight: 46,
              daysOfWeekHeight: 26,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getAgendasForDay,
              locale: 'id_ID',
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableGestures: AvailableGestures.horizontalSwipe,
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: tema.teksSamar,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                weekendStyle: TextStyle(
                  color: tema.aksenTeks.withValues(alpha: 0.9),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              calendarStyle: const CalendarStyle(markersMaxCount: 0),
              calendarBuilders: CalendarBuilders<AgendaAcara>(
                defaultBuilder: (context, day, focusedDay) =>
                    _selKalender(day, tema, terpilih: false, luarBulan: false),
                todayBuilder: (context, day, focusedDay) =>
                    _selKalender(day, tema, terpilih: false, luarBulan: false),
                selectedBuilder: (context, day, focusedDay) =>
                    _selKalender(day, tema, terpilih: true, luarBulan: false),
                outsideBuilder: (context, day, focusedDay) =>
                    _selKalender(day, tema, terpilih: false, luarBulan: true),
                markerBuilder: (context, day, events) => null,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                if (!isSameDay(_focusedDay, focusedDay)) {
                  setState(() => _focusedDay = focusedDay);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Keterangan hari besar untuk tanggal yang sedang dipilih.
  Widget _bannerHariBesar(PengaturanWarna tema) {
    final tanggal = _selectedDay ?? _focusedDay;
    if (tanggal.year != _focusedDay.year ||
        tanggal.month != _focusedDay.month) {
      return const SizedBox.shrink();
    }
    final hariBesar = hariBesarPada(tanggal);
    if (hariBesar == null) return const SizedBox.shrink();

    final warna = hariBesar.libur
        ? tema.liburNasional
        : tema.peringatanNasional;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: warna.withValues(alpha: tema.gelap ? 0.16 : 0.07),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: warna.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Icon(
              hariBesar.libur ? Icons.celebration_rounded : Icons.star_rounded,
              size: 13,
              color: warna,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hariBesar.nama,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tema.teks,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              hariBesar.libur ? 'Libur Nasional' : 'Hari Besar',
              style: TextStyle(
                color: warna,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tombolHariIni(PengaturanWarna tema) {
    return TekanSkala(
      onTap: _keHariIni,
      skala: 0.93,
      child: Tooltip(
        message: 'Kembali ke hari ini',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: tema.aksen.withValues(alpha: tema.gelap ? 0.2 : 0.09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: tema.aksen.withValues(alpha: tema.gelap ? 0.34 : 0.16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: tema.aksenTeks,
              ),
              const SizedBox(width: 6),
              Text(
                'Hari Ini',
                style: TextStyle(
                  color: tema.aksenTeks,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selKalender(
    DateTime hari,
    PengaturanWarna tema, {
    required bool terpilih,
    required bool luarBulan,
  }) {
    final hariIni = isSameDay(hari, DateTime.now());
    final agenda = luarBulan ? const <AgendaAcara>[] : _getAgendasForDay(hari);
    final akhirPekan =
        hari.weekday == DateTime.saturday || hari.weekday == DateTime.sunday;

    final Color warnaTeks;
    if (terpilih) {
      warnaTeks = tema.diAksen;
    } else if (luarBulan) {
      warnaTeks = tema.teks.withValues(alpha: 0.26);
    } else if (hariIni) {
      warnaTeks = tema.teks;
    } else if (akhirPekan) {
      warnaTeks = tema.aksenTeks.withValues(alpha: 0.9);
    } else {
      warnaTeks = tema.teks.withValues(alpha: 0.88);
    }

    // Angka Hijriah kecil di bawah tanggal Masehi.
    final nomorHijriah = nomorHariHijriah(hari);
    final Color warnaHijriah;
    if (terpilih) {
      warnaHijriah = tema.diAksen.withValues(alpha: 0.72);
    } else if (luarBulan) {
      warnaHijriah = tema.teks.withValues(alpha: 0.16);
    } else if (hariIni) {
      warnaHijriah = tema.teksRedup;
    } else if (akhirPekan) {
      warnaHijriah = tema.aksenTeks.withValues(alpha: 0.68);
    } else {
      warnaHijriah = tema.teksSamar;
    }

    BoxDecoration? dekorasi;
    if (terpilih) {
      dekorasi = BoxDecoration(
        color: tema.aksen,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: tema.aksen.withValues(alpha: 0.32),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (hariIni) {
      dekorasi = BoxDecoration(color: tema.isian, shape: BoxShape.circle);
    }

    // Garis bawah berwarna ormawa sebagai penanda ada kegiatan.
    final warnaAgenda = <Color>[];
    for (final item in agenda) {
      final warna = _ormawaUntuk(item.ormawaId).warna;
      if (!warnaAgenda.contains(warna)) warnaAgenda.add(warna);
      if (warnaAgenda.length == 3) break;
    }
    final tampilkanGaris = !luarBulan && warnaAgenda.isNotEmpty;

    // Hari besar Indonesia diberi cincin agar mudah dikenali.
    final hariBesar = luarBulan ? null : hariBesarPada(hari);
    final warnaCincin = hariBesar == null
        ? null
        : (hariBesar.libur ? tema.liburNasional : tema.peringatanNasional);

    Widget sel = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 38,
      height: 40,
      decoration: dekorasi,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${hari.day}',
                style: TextStyle(
                  color: warnaTeks,
                  fontSize: 12,
                  fontWeight: terpilih || hariIni
                      ? FontWeight.w700
                      : FontWeight.w500,
                  height: 1,
                ),
              ),
              const SizedBox(height: 1),
              if (nomorHijriah != null)
                Text(
                  '$nomorHijriah',
                  style: TextStyle(
                    color: warnaHijriah,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
            ],
          ),
          if (tampilkanGaris)
            Positioned(
              bottom: 3.5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < warnaAgenda.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    _garisWarna(
                      warnaAgenda[i],
                      lebar: warnaAgenda.length == 1
                          ? 16
                          : warnaAgenda.length == 2
                          ? 10
                          : 7,
                      terpilih: terpilih,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );

    if (warnaCincin != null) {
      sel = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: warnaCincin.withValues(alpha: 0.9),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: warnaCincin.withValues(alpha: 0.18),
              blurRadius: 5,
            ),
          ],
        ),
        child: Center(child: sel),
      );
    }

    return Center(child: sel);
  }

  /// Garis kecil penanda agenda dengan warna ormawa. Saat tanggal terpilih,
  /// warnanya dicerahkan agar tetap terlihat di atas kotak hijau.
  Widget _garisWarna(
    Color warna, {
    required double lebar,
    required bool terpilih,
  }) {
    final garis = terpilih ? Color.lerp(warna, Colors.white, 0.38)! : warna;
    return Container(
      width: lebar,
      height: 2.8,
      decoration: BoxDecoration(
        color: garis,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(color: garis.withValues(alpha: 0.55), blurRadius: 4),
        ],
      ),
    );
  }

  // Judul bagian daftar kegiatan dengan tautan "Lihat Semua".
  Widget _buildJudulKegiatan(PengaturanWarna tema, List<AgendaAcara> agenda) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Kegiatan Terdekat',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tema.teks,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          TekanSkala(
            onTap: _bukaPanelAgenda,
            skala: 0.92,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: tema.teks,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.chevron_right_rounded, size: 15, color: tema.teks),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemuat(PengaturanWarna tema) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: tema.aksen),
        ),
      ),
    );
  }

  Widget _kartuAgendaItem(AgendaAcara item, PengaturanWarna tema) {
    final kartu = TekanSkala(
      onTap: () => _bukaDetailAgenda(item),
      skala: 0.985,
      child: _buildColorfulAgendaCard(item, tema),
    );
    if (!_modeAdmin) return kartu;

    return Dismissible(
      key: ValueKey('hapus-${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _tanyaHapus(item),
      onDismissed: (_) => _hapusAgenda(item),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tema.bahaya.withValues(alpha: 0.06),
              tema.bahaya.withValues(alpha: 0.26),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _tema.bahaya.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: tema.bahaya, size: 23),
            const SizedBox(height: 3),
            Text(
              'Hapus',
              style: TextStyle(
                color: tema.bahaya,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: kartu,
    );
  }

  Widget _buildKosong(PengaturanWarna tema) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          color: tema.kartu.withValues(alpha: tema.gelap ? 0.8 : 0.68),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tema.garisLembut),
        ),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: tema.aksen.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: tema.aksen.withValues(alpha: 0.14)),
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 24,
                color: tema.aksenTeks,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada agenda',
              style: TextStyle(
                color: tema.teks,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _modeAdmin
                  ? 'Ketuk tombol + untuk menambahkan kegiatan baru.'
                  : 'Tidak ada kegiatan pada tanggal ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tema.teksRedup,
                fontSize: 10.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigasi bawah melayang dengan tombol tambah di tengah, sesuai desain.
  Widget _buildNavigasiBawah(PengaturanWarna tema) {
    final bawah = MediaQuery.viewPaddingOf(context).bottom;
    const tinggiBar = 68.0;
    const ukuranTombol = 58.0;

    Widget item({
      required IconData ikon,
      required IconData ikonAktif,
      required String label,
      required bool aktif,
      required VoidCallback onTap,
    }) {
      final warna = aktif ? tema.aksenTeks : tema.teksSamar;
      return TekanSkala(
        onTap: onTap,
        skala: 0.9,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(aktif ? ikonAktif : ikon, size: 21, color: warna),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: warna,
                fontSize: 9,
                fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: tinggiBar + bawah + 12,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 14,
            right: 14,
            bottom: bawah + 8,
            child: Container(
              height: tinggiBar,
              decoration: BoxDecoration(
                color: tema.kartu.withValues(alpha: tema.gelap ? 0.94 : 0.97),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: tema.garisLembut),
                boxShadow: [
                  BoxShadow(
                    color: tema.bayangan,
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: item(
                      ikon: Icons.home_outlined,
                      ikonAktif: Icons.home_rounded,
                      label: 'Kalender',
                      aktif: true,
                      onTap: () => HapticFeedback.selectionClick(),
                    ),
                  ),
                  Expanded(
                    child: item(
                      ikon: Icons.calendar_today_outlined,
                      ikonAktif: Icons.calendar_today_rounded,
                      label: 'Agenda',
                      aktif: false,
                      onTap: _bukaPanelAgenda,
                    ),
                  ),
                  const SizedBox(width: 66),
                  Expanded(
                    child: item(
                      ikon: Icons.notifications_none_rounded,
                      ikonAktif: Icons.notifications_rounded,
                      label: 'Notifikasi',
                      aktif: false,
                      onTap: _bukaPanelNotifikasi,
                    ),
                  ),
                  Expanded(
                    child: item(
                      ikon: Icons.person_outline_rounded,
                      ikonAktif: Icons.person_rounded,
                      label: 'Profil',
                      aktif: false,
                      onTap: _bukaPanelProfil,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: bawah + 8 + tinggiBar - ukuranTombol / 2,
            child: Tooltip(
              message: 'Tambah agenda',
              child: TekanSkala(
                onTap: _bukaTambahAgenda,
                skala: 0.9,
                child: Container(
                  width: ukuranTombol,
                  height: ukuranTombol,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [tema.aksen, tema.aksenGelap],
                    ),
                    border: Border.all(color: tema.kartu, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: tema.bayangan,
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: tema.aksen.withValues(alpha: 0.42),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(Icons.add_rounded, color: tema.diAksen, size: 30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tombol + selalu tampil; anggota diarahkan masuk mode admin dulu.
  void _bukaTambahAgenda() {
    HapticFeedback.selectionClick();
    if (_modeAdmin) {
      _bukaDialogFormAgenda();
      return;
    }
    _tampilkanPesan('Masuk mode admin untuk menambah agenda.', berhasil: false);
    _bukaMenuAdmin();
  }

  // Baris filter organisasi dengan lencana ikon dan animasi lembut.
  Widget _buildColoredFilterBar(
    PengaturanWarna tema, {
    VoidCallback? onBerubah,
  }) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _daftarOrmawa.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isAll = _filterOrmawaId == null;
            return _pilOrmawa(
              tema: tema,
              label: 'Semua Ormawa',
              ikon: Icons.grid_view_rounded,
              warna: tema.aksen,
              terpilih: isAll,
              onTap: () {
                if (isAll) return;
                HapticFeedback.selectionClick();
                setState(() => _filterOrmawaId = null);
                onBerubah?.call();
              },
            );
          }

          final org = _daftarOrmawa[index - 1];
          final isSelected = _filterOrmawaId == org.id;

          return _pilOrmawa(
            tema: tema,
            label: org.nama,
            ikon: org.ikon,
            warna: org.warna,
            terpilih: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _filterOrmawaId = isSelected ? null : org.id);
              onBerubah?.call();
            },
          );
        },
      ),
    );
  }

  /// Pil filter dengan lencana ikon ormawa di depannya.
  Widget _pilOrmawa({
    required PengaturanWarna tema,
    required String label,
    required IconData ikon,
    required Color warna,
    required bool terpilih,
    required VoidCallback onTap,
  }) {
    final warnaTeks = terpilih ? warnaDiAtas(warna) : tema.teksLembut;
    final warnaGelap = Color.lerp(warna, Colors.black, 0.34)!;

    return TekanSkala(
      onTap: onTap,
      skala: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: 42,
        padding: const EdgeInsets.only(left: 6, right: 14),
        decoration: BoxDecoration(
          gradient: terpilih
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [warna, warnaGelap],
                )
              : null,
          color: terpilih ? null : tema.isian,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: terpilih ? Colors.white.withValues(alpha: 0.5) : tema.garis,
            width: terpilih ? 1.2 : 1,
          ),
          boxShadow: terpilih
              ? [
                  BoxShadow(
                    color: warna.withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: terpilih
                      ? [
                          Colors.white.withValues(alpha: 0.32),
                          Colors.white.withValues(alpha: 0.14),
                        ]
                      : [warna, warnaGelap],
                ),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: terpilih
                      ? Colors.white.withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.24),
                ),
                boxShadow: terpilih
                    ? null
                    : [
                        BoxShadow(
                          color: warna.withValues(alpha: 0.34),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Icon(ikon, size: 16, color: warnaDiAtas(warna)),
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: TextStyle(
                color: warnaTeks,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kartu kegiatan putih dengan lencana ikon ormawa dan pil waktu.
  Widget _buildColorfulAgendaCard(
    AgendaAcara item,
    PengaturanWarna tema, {
    VoidCallback? onBerubah,
  }) {
    final ormawa = _ormawaUntuk(item.ormawaId);
    final warna = ormawa.warna;
    final warnaGelap = Color.lerp(warna, Colors.black, 0.3)!;
    final jam = item.rentangWaktuTeks;
    final keterangan = [
      ormawa.kategori,
      if (item.lokasi.isNotEmpty) item.lokasi,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: tema.kartu.withValues(alpha: tema.gelap ? 0.92 : 0.97),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tema.garisLembut),
        boxShadow: [
          BoxShadow(
            color: tema.bayangan,
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [warna, warnaGelap],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: warna.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(ormawa.ikon, color: warnaDiAtas(warna), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tema.teks,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  keterangan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tema.teksRedup,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 5, 6),
            decoration: BoxDecoration(
              color: tema.isian.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tema.garisLembut),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, size: 11, color: tema.teksLembut),
                const SizedBox(width: 4),
                Text(
                  jam,
                  style: TextStyle(
                    color: tema.teks,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 1),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 12,
                  color: tema.teksSamar,
                ),
              ],
            ),
          ),
          if (_modeAdmin) ...[
            const SizedBox(width: 5),
            _tombolAksiAgenda(
              ikon: Icons.more_horiz_rounded,
              tooltip: 'Opsi agenda',
              warna: tema.teksLembut,
              onTap: () => _bukaMenuKartu(item, onSelesai: onBerubah),
            ),
          ],
        ],
      ),
    );
  }

  // Menu singkat untuk admin saat mengetuk tombol opsi pada kartu kegiatan.
  void _bukaMenuKartu(AgendaAcara item, {VoidCallback? onSelesai}) {
    final tema = _tema;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tema.kartu,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: tema.garis),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _barisLembar(
                    tema,
                    ikon: Icons.edit_note_rounded,
                    label: 'Ubah agenda',
                    warna: tema.aksenTeks,
                    onTap: () {
                      Navigator.pop(ctx);
                      _bukaDialogFormAgenda(
                        agendaUntukDiedit: item,
                        onSelesai: onSelesai,
                      );
                    },
                  ),
                  _barisLembar(
                    tema,
                    ikon: Icons.delete_outline_rounded,
                    label: 'Hapus agenda',
                    warna: tema.bahaya,
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (await _tanyaHapus(item)) {
                        _hapusAgenda(item);
                        onSelesai?.call();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Lembar bawah: panel Agenda, Notifikasi, dan Profil & Pengaturan.
  // -------------------------------------------------------------------------

  Widget _peganganLembar(PengaturanWarna tema) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      width: 40,
      height: 4.5,
      decoration: BoxDecoration(
        color: tema.teks.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _kotakLembar(
    PengaturanWarna tema, {
    double? tinggi,
    required Widget child,
  }) {
    return Container(
      height: tinggi,
      decoration: BoxDecoration(
        color: tema.latar1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: tema.garis),
        boxShadow: [
          BoxShadow(
            color: tema.bayangan,
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _kepalaLembar(
    PengaturanWarna tema, {
    required IconData ikon,
    required String judul,
    required String subjudul,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tema.aksen, tema.aksenGelap],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(ikon, color: tema.diAksen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  judul,
                  style: TextStyle(
                    color: tema.teks,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.45,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subjudul,
                  style: TextStyle(
                    color: tema.teksRedup,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisLembar(
    PengaturanWarna tema, {
    required IconData ikon,
    required String label,
    required Color warna,
    required VoidCallback onTap,
    String? tooltip,
    String? keterangan,
    Widget? trailing,
  }) {
    final isi = TekanSkala(
      onTap: onTap,
      skala: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tema.kartu.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tema.garisLembut),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(ikon, size: 18, color: warna),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: tema.teks,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (keterangan != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      keterangan,
                      style: TextStyle(color: tema.teksRedup, fontSize: 9.5),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: tema.teksSamar,
                ),
          ],
        ),
      ),
    );

    if (tooltip == null) return isi;
    return Tooltip(message: tooltip, child: isi);
  }

  void _bukaPanelAgenda() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final tema = _tema;
            final bawah = MediaQuery.viewPaddingOf(ctx).bottom;
            final daftar = _agendaTerurut;
            final kelompok = <DateTime, List<AgendaAcara>>{};
            for (final agenda in daftar) {
              final kunci = DateTime(
                agenda.waktu.year,
                agenda.waktu.month,
                agenda.waktu.day,
              );
              kelompok.putIfAbsent(kunci, () => []).add(agenda);
            }

            return _kotakLembar(
              tema,
              tinggi: MediaQuery.sizeOf(ctx).height * 0.88,
              child: Column(
                children: [
                  _peganganLembar(tema),
                  _kepalaLembar(
                    tema,
                    ikon: Icons.calendar_today_rounded,
                    judul: 'Semua Agenda',
                    subjudul:
                        '${daftar.length} kegiatan • ${_daftarOrmawa.length} ormawa',
                  ),
                  _buildColoredFilterBar(
                    tema,
                    onBerubah: () => setSheet(() {}),
                  ),
                  Divider(color: tema.garisLembut, height: 1),
                  Expanded(
                    child: daftar.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(30),
                              child: Text(
                                'Belum ada kegiatan yang cocok dengan '
                                'filter ini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: tema.teksRedup,
                                  fontSize: 11.5,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.fromLTRB(14, 4, 14, 22 + bawah),
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            children: [
                              for (final entri in kelompok.entries) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    12,
                                    4,
                                    8,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        DateFormat(
                                          'EEEE, d MMMM yyyy',
                                          'id_ID',
                                        ).format(entri.key),
                                        style: TextStyle(
                                          color: tema.teksLembut,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: tema.garisLembut,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                for (final item in entri.value)
                                  TekanSkala(
                                    onTap: () => _bukaDetailAgenda(item),
                                    skala: 0.985,
                                    child: _buildColorfulAgendaCard(
                                      item,
                                      tema,
                                      onBerubah: () => setSheet(() {}),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _bukaPanelNotifikasi() {
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final batas = hariIni.add(const Duration(days: 14));
    final daftar = _semuaAgenda.where((agenda) {
      final tanggal = DateTime(
        agenda.waktu.year,
        agenda.waktu.month,
        agenda.waktu.day,
      );
      return !tanggal.isBefore(hariIni) && !tanggal.isAfter(batas);
    }).toList()..sort((a, b) => a.waktu.compareTo(b.waktu));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final tema = _tema;
        final bawah = MediaQuery.viewPaddingOf(ctx).bottom;
        return _kotakLembar(
          tema,
          tinggi: MediaQuery.sizeOf(ctx).height * (daftar.isEmpty ? 0.5 : 0.72),
          child: Column(
            children: [
              _peganganLembar(tema),
              _kepalaLembar(
                tema,
                ikon: Icons.notifications_active_rounded,
                judul: 'Notifikasi',
                subjudul: 'Pengingat kegiatan dalam 14 hari ke depan',
              ),
              if (_galatSinkron != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tema.peringatan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tema.peringatan.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 14,
                          color: tema.peringatan,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _galatSinkron!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tema.peringatan,
                              fontSize: 9.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: daftar.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: tema.aksen.withValues(alpha: 0.09),
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                child: Icon(
                                  Icons.notifications_paused_rounded,
                                  size: 24,
                                  color: tema.aksenTeks,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada pengingat',
                                style: TextStyle(
                                  color: tema.teks,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kegiatan baru dalam 14 hari ke depan '
                                'akan muncul di sini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: tema.teksRedup,
                                  fontSize: 10.5,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 20 + bawah),
                        physics: const BouncingScrollPhysics(),
                        itemCount: daftar.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = daftar[index];
                          final ormawa = _ormawaUntuk(item.ormawaId);
                          final tanggal = DateTime(
                            item.waktu.year,
                            item.waktu.month,
                            item.waktu.day,
                          );
                          final selisih = tanggal.difference(hariIni).inDays;
                          final label = selisih == 0
                              ? 'Hari ini'
                              : selisih == 1
                              ? 'Besok'
                              : DateFormat(
                                  'EEEE, d MMMM',
                                  'id_ID',
                                ).format(tanggal);
                          return TekanSkala(
                            onTap: () {
                              Navigator.pop(ctx);
                              _bukaDetailAgenda(item);
                            },
                            skala: 0.98,
                            child: Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: tema.kartu.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: tema.garisLembut),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: ormawa.warna.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: ormawa.warna.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      ormawa.ikon,
                                      size: 18,
                                      color: warnaTeksOrmawa(
                                        ormawa.warna,
                                        tema,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.judul,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: tema.teks,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$label • ${item.rentangWaktuTeks} • '
                                          '${ormawa.kategori}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: tema.teksRedup,
                                            fontSize: 9.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: tema.teksSamar,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _bukaPanelProfil() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final tema = _tema;
            final bawah = MediaQuery.viewPaddingOf(ctx).bottom;

            void ubahTema(PengaturanWarna baru) {
              widget.onTemaBerubah(baru);
              setSheet(() {});
            }

            return Padding(
              padding: EdgeInsets.only(bottom: bawah),
              child: _kotakLembar(
                tema,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _peganganLembar(tema),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 2, 4, 14),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [tema.aksen, tema.aksenGelap],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: tema.aksen.withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.calendar_month_rounded,
                                    size: 18,
                                    color: tema.aksen,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Profil & Pengaturan',
                                    style: TextStyle(
                                      color: tema.teks,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.45,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _modeAdmin
                                        ? 'Masuk sebagai admin'
                                        : 'Anggota • hanya melihat jadwal',
                                    style: TextStyle(
                                      color: tema.teksRedup,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _barisLembar(
                        tema,
                        ikon: Icons.palette_outlined,
                        label: 'Kustomisasi tampilan',
                        tooltip: 'Kustomisasi tampilan',
                        warna: tema.aksenTeks,
                        onTap: () {
                          Navigator.pop(ctx);
                          _bukaPanelKustomisasi();
                        },
                      ),
                      _barisLembar(
                        tema,
                        ikon: _modeAdmin
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                        label: _modeAdmin
                            ? 'Pengaturan admin'
                            : 'Masuk mode admin',
                        tooltip: _modeAdmin
                            ? 'Pengaturan admin'
                            : 'Masuk mode admin',
                        warna: tema.aksenTeks,
                        onTap: () {
                          Navigator.pop(ctx);
                          _bukaMenuAdmin();
                        },
                      ),
                      _barisLembar(
                        tema,
                        ikon: Icons.nightlight_round,
                        label: 'Kalender Hijriah',
                        warna: tema.aksenTeks,
                        onTap: () {
                          Navigator.pop(ctx);
                          _bukaKalenderHijriah();
                        },
                      ),
                      _barisLembar(
                        tema,
                        ikon: Icons.calendar_month_rounded,
                        label: 'Kalender tahunan',
                        warna: tema.aksenTeks,
                        onTap: () {
                          Navigator.pop(ctx);
                          _bukaKalenderTahunan();
                        },
                      ),
                      _barisLembar(
                        tema,
                        ikon: Icons.sync_rounded,
                        label: 'Sinkronkan agenda',
                        keterangan: _sedangMenyinkron
                            ? 'Sedang menyinkronkan…'
                            : null,
                        warna: tema.aksenTeks,
                        onTap: _sedangMenyinkron
                            ? () {}
                            : () {
                                Navigator.pop(ctx);
                                _muatAgenda(tampilkanPesan: true);
                              },
                      ),
                      _barisLembar(
                        tema,
                        ikon: Icons.dark_mode_outlined,
                        label: 'Mode gelap',
                        warna: tema.teksLembut,
                        onTap: () => ubahTema(tema.salin(gelap: !tema.gelap)),
                        trailing: Transform.scale(
                          scale: 0.78,
                          child: Switch.adaptive(
                            value: tema.gelap,
                            activeTrackColor: tema.aksen,
                            onChanged: (_) =>
                                ubahTema(tema.salin(gelap: !tema.gelap)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Pop-up detail lengkap kegiatan. Dibuka saat kartu agenda diketuk.
  void _bukaDetailAgenda(AgendaAcara item) {
    final tema = _tema;
    final ormawa = _ormawaUntuk(item.ormawaId);
    final warna = ormawa.warna;
    final bawah = MediaQuery.viewPaddingOf(context).bottom;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          child: Kaca(
            radius: 30,
            blur: 24,
            padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bawah),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  warna.withValues(alpha: tema.gelap ? 0.12 : 0.08),
                  tema.kartu,
                ).withValues(alpha: 0.96),
                tema.kartu.withValues(alpha: 0.92),
              ],
            ),
            borderColor: tema.garis,
            shadow: [
              BoxShadow(
                color: tema.bayangan,
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: tema.teks.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              warna,
                              Color.lerp(warna, Colors.black, 0.28)!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: warna.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          ormawa.ikon,
                          color: warnaDiAtas(warna),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ormawa.nama.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: warnaTeksOrmawa(warna, tema),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              ormawa.kategori,
                              style: TextStyle(
                                color: tema.teksRedup,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TekanSkala(
                        onTap: () => Navigator.pop(ctx),
                        skala: 0.88,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: tema.isian,
                            shape: BoxShape.circle,
                            border: Border.all(color: tema.garis),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: tema.teksLembut,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    item.judul,
                    style: TextStyle(
                      color: tema.teks,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.25,
                    ),
                  ),
                  if (item.deskripsi.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.deskripsi,
                      style: TextStyle(
                        color: tema.teksRedup,
                        fontSize: 12.5,
                        height: 1.55,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _barisInfoDetail(
                    tema,
                    ikon: Icons.calendar_month_rounded,
                    label: 'TANGGAL',
                    nilai:
                        '${DateFormat('EEEE, d MMMM yyyy').format(item.waktu)}\n'
                        '${tanggalHijriah(item.waktu)}',
                    warna: warna,
                  ),
                  const SizedBox(height: 9),
                  _barisInfoDetail(
                    tema,
                    ikon: Icons.schedule_rounded,
                    label: 'WAKTU',
                    nilai: item.rentangWaktuTeks,
                    warna: warna,
                  ),
                  const SizedBox(height: 9),
                  _barisInfoDetail(
                    tema,
                    ikon: Icons.location_on_rounded,
                    label: 'LOKASI',
                    nilai: item.lokasi.isEmpty ? '-' : item.lokasi,
                    warna: warna,
                  ),
                  const SizedBox(height: 9),
                  _barisInfoDetail(
                    tema,
                    ikon: Icons.groups_rounded,
                    label: 'PENYELENGGARA',
                    nilai: ormawa.nama,
                    warna: warna,
                  ),
                  const SizedBox(height: 20),
                  if (_modeAdmin)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: warna,
                              side: BorderSide(
                                color: warna.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _bukaDialogFormAgenda(agendaUntukDiedit: item);
                            },
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Ubah'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: tema.bahaya,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              if (await _tanyaHapus(item)) {
                                _hapusAgenda(item);
                              }
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                            ),
                            label: const Text('Hapus'),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Tutup'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _barisInfoDetail(
    PengaturanWarna tema, {
    required IconData ikon,
    required String label,
    required String nilai,
    required Color warna,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: tema.isian,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tema.garisLembut),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(ikon, size: 15, color: warnaTeksOrmawa(warna, tema)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: tema.teksSamar,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nilai,
                  style: TextStyle(
                    color: tema.teks,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tombolAksiAgenda({
    required IconData ikon,
    required String tooltip,
    required Color warna,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: TekanSkala(
        onTap: onTap,
        skala: 0.86,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: warna.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: warna.withValues(alpha: 0.3)),
          ),
          child: Icon(ikon, size: 16, color: warna),
        ),
      ),
    );
  }
}
