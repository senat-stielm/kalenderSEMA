import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'auth_admin.dart';
import 'dialog_admin.dart';
import 'dialog_ormawa.dart';
import 'kalender_tahunan.dart';
import 'layanan_agenda.dart';
import 'layanan_ormawa.dart';
import 'model_agenda.dart';
import 'model_ormawa.dart';
import 'pemilih_warna.dart';
import 'pengaturan_warna.dart';

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
  CalendarFormat _calendarFormat = CalendarFormat.month;
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

    if (tampilkanPesan) {
      _tampilkanPesan(
        hasil.galat ?? 'Agenda berhasil diperbarui dari server.',
        berhasil: hasil.galat == null,
      );
    }
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

    final warna = berhasil ? _tema.aksen : Colors.orangeAccent;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            pesan,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: _tema.kartu,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: warna.withValues(alpha: 0.7)),
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
      final isSameDate = isSameDay(agenda.waktu, day);
      if (_filterOrmawaId != null) {
        return isSameDate && agenda.ormawaId == _filterOrmawaId;
      }
      return isSameDate;
    }).toList();
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
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Text(
          'Semua agenda dari ormawa ini juga akan dihapus di semua perangkat. '
          'Tindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
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
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: tema.aksen.withValues(alpha: 0.6),
              width: 1.5,
            ),
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
              const Expanded(
                child: Text(
                  'Mode Admin',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                warna: Colors.orangeAccent,
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
                    color: Colors.orangeAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orangeAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _galatSinkron!,
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tema.aksen,
                foregroundColor: tema.latar1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(ikon, color: c, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                judul,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c, size: 18),
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
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: tema.latar2,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: tema.aksen.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tema.aksen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.palette_rounded, color: tema.aksen),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kustomisasi Tampilan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _modeAdmin
                                    ? 'Atur tema aplikasi serta nama dan warna tiap ormawa'
                                    : 'Atur tema aplikasi. Nama dan warna ormawa hanya bisa diubah admin.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: _modeAdmin ? _daftarOrmawa.length + 2 : 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _kartuTema(
                            tema,
                            onTap: () =>
                                _bukaDialogTema(() => setSheetState(() {})),
                          );
                        }

                        if (index == 1) {
                          return _kartuTambahOrmawa(
                            tema,
                            () => setSheetState(() {}),
                          );
                        }

                        final org = _daftarOrmawa[index - 2];
                        final warna = org.warna;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: warna.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: warna.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: ListTile(
                              contentPadding: const EdgeInsets.fromLTRB(
                                14,
                                4,
                                8,
                                4,
                              ),
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: warna,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: warna.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  org.ikon,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                org.nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      org.kategori,
                                      style: TextStyle(
                                        color: warna,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _tombolAksiOrmawa(
                                    ikon: Icons.edit_rounded,
                                    tooltip: 'Ubah ormawa',
                                    warna: warna,
                                    onTap: () => _bukaDialogOrmawa(
                                      awal: org,
                                      onUpdated: () => setSheetState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  _tombolAksiOrmawa(
                                    ikon: Icons.delete_outline_rounded,
                                    tooltip: 'Hapus ormawa',
                                    warna: Colors.redAccent,
                                    onTap: () => _konfirmasiHapusOrmawa(
                                      org,
                                      () => setSheetState(() {}),
                                    ),
                                  ),
                                ],
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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            tema.aksen.withValues(alpha: 0.22),
            tema.kartu.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tema.aksen.withValues(alpha: 0.6),
          width: 1.4,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [tema.aksen, tema.aksenGelap]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.palette_rounded, color: tema.latar1, size: 22),
          ),
          title: const Text(
            'Tema Aplikasi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          subtitle: const Text(
            'Warna aksen, latar, dan kartu',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          trailing: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: tema.aksen,
              foregroundColor: tema.latar1,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: const Text(
              'Atur',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(
                  color: tema.aksen.withValues(alpha: 0.6),
                  width: 1.5,
                ),
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
                      color: tema.latar1,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tema Aplikasi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                      _barisWarnaTema(
                        ctx,
                        tema,
                        'Latar Atas',
                        tema.latar1,
                        (warna) => terapkan(tema.salin(latar1: warna)),
                      ),
                      _barisWarnaTema(
                        ctx,
                        tema,
                        'Latar Tengah',
                        tema.latar2,
                        (warna) => terapkan(tema.salin(latar2: warna)),
                      ),
                      _barisWarnaTema(
                        ctx,
                        tema,
                        'Latar Bawah',
                        tema.latar3,
                        (warna) => terapkan(tema.salin(latar3: warna)),
                      ),
                      _barisWarnaTema(
                        ctx,
                        tema,
                        'Warna Kartu',
                        tema.kartu,
                        (warna) => terapkan(tema.salin(kartu: warna)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => terapkan(PengaturanWarna.bawaan),
                  child: const Text(
                    'Pulihkan Default',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: tema.aksen,
                    foregroundColor: tema.latar1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  Widget _pratinjauTema(PengaturanWarna tema) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tema.latar1, tema.latar2, tema.latar3],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
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
                border: Border.all(color: Colors.white12),
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
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final hasil = await tampilkanPemilihWarna(
          ctx,
          warnaAwal: warna,
          warnaKartu: tema.kartu,
          judul: label,
        );
        if (hasil != null) onPilih(hasil);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: warna,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formatKodeHex(warna),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, size: 16, color: tema.aksen),
          ],
        ),
      ),
    );
  }

  Widget _kartuTambahOrmawa(PengaturanWarna tema, VoidCallback onUpdated) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tema.aksen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tema.aksen.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: () => _bukaDialogOrmawa(onUpdated: onUpdated),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tema.aksen.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.add_rounded, color: tema.aksen, size: 24),
          ),
          title: const Text(
            'Tambah Ormawa / UKM / UKK',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          subtitle: const Text(
            'Buat organisasi baru',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: tema.aksen),
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

  // Modal Form Tambah / Edit Agenda Kegiatan
  void _bukaDialogFormAgenda({AgendaAcara? agendaUntukDiedit}) {
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
            return AlertDialog(
              backgroundColor: tema.kartu,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(
                  color: warnaAktif.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              title: Text(
                agendaUntukDiedit == null
                    ? 'Tambah Agenda Kegiatan'
                    : 'Edit Agenda Kegiatan',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
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
                          fillColor: Colors.black26,
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
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nama Kegiatan',
                          filled: true,
                          fillColor: Colors.black26,
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
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Lokasi Kegiatan',
                          filled: true,
                          fillColor: Colors.black26,
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
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Deskripsi / Catatan',
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        tileColor: Colors.black26,
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
                        title: const Text(
                          'Tanggal Pelaksanaan',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                        subtitle: Text(
                          DateFormat('EEEE, d MMMM yyyy')
                              .format(tanggalTerpilih),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warnaAktif,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      late AgendaAcara agendaTersimpan;

                      setState(() {
                        if (agendaUntukDiedit == null) {
                          agendaTersimpan = AgendaAcara(
                            id: DateTime.now().microsecondsSinceEpoch
                                .toString(),
                            judul: judulCtrl.text.trim(),
                            deskripsi: deskripsiCtrl.text.trim(),
                            waktu: tanggalTerpilih,
                            lokasi: lokasiCtrl.text.trim(),
                            ormawaId: ormawaTerpilihId,
                          );
                          _semuaAgenda.add(agendaTersimpan);
                        } else {
                          agendaUntukDiedit.judul = judulCtrl.text.trim();
                          agendaUntukDiedit.deskripsi = deskripsiCtrl.text
                              .trim();
                          agendaUntukDiedit.waktu = tanggalTerpilih;
                          agendaUntukDiedit.lokasi = lokasiCtrl.text.trim();
                          agendaUntukDiedit.ormawaId = ormawaTerpilihId;
                          agendaTersimpan = agendaUntukDiedit;
                        }
                        _semuaAgenda.sort((a, b) => a.waktu.compareTo(b.waktu));
                        _selectedDay = tanggalTerpilih;
                        _focusedDay = tanggalTerpilih;
                      });
                      Navigator.pop(context);
                      _simpanAgendaKeServer(agendaTersimpan);
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

  void _konfirmasiHapus(AgendaAcara item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _tema.kartu,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: const Text(
          'Hapus Agenda?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Hapus kegiatan "${item.judul}" dari kalender?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() => _semuaAgenda.removeWhere((x) => x.id == item.id));
              Navigator.pop(ctx);
              _hapusAgendaDiServer(item.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = _tema;
    final agendaTerpilih = _getAgendasForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Multi-Layer dengan warna tema
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tema.latar1, tema.latar2, tema.latar3],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    tema.aksen.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    tema.sekunder.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Konten Antarmuka Utama
          SafeArea(
            child: Column(
              children: [
                // Header AppBar Glass
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      // Ketuk logo untuk membuka kalender tahunan
                      Tooltip(
                        message: 'Kalender tahunan',
                        child: GestureDetector(
                          onTap: _bukaKalenderTahunan,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [tema.aksen, tema.aksenGelap],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: tema.aksen.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.event_note_rounded,
                              color: tema.latar1,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KALENDER ORMAWA',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              _modeAdmin
                                  ? 'Mode admin aktif'
                                  : 'Senat • BEM • HMPS • 7 UKM • 2 UKK',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tema.aksen,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tombol kustomisasi tampilan (tema bisa diubah semua
                      // anggota; nama & warna ormawa hanya oleh admin)
                      Tooltip(
                        message: 'Kustomisasi tampilan',
                        child: InkWell(
                          onTap: _bukaPanelKustomisasi,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: tema.aksen.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Icon(
                              Icons.palette_outlined,
                              color: tema.aksen,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol masuk / keluar mode admin
                      Tooltip(
                        message: _modeAdmin
                            ? 'Pengaturan admin'
                            : 'Masuk mode admin',
                        child: InkWell(
                          onTap: _bukaMenuAdmin,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: _modeAdmin
                                  ? tema.aksen
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _modeAdmin
                                    ? Colors.white
                                    : tema.aksen.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Icon(
                              _modeAdmin
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_outline_rounded,
                              color: _modeAdmin ? tema.latar1 : tema.aksen,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Baris Chip Organisasi Berwarna Jelas
                _buildColoredFilterBar(tema),

                // Pemberitahuan singkat jika sinkronisasi bermasalah
                if (_galatSinkron != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 14,
                          color: Colors.orangeAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _galatSinkron!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _muatAgenda(tampilkanPesan: true),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.refresh_rounded,
                              size: 14,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Kalender Utama dengan Efek Kaca Gelap
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tema.kartu.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TableCalendar<AgendaAcara>(
                    firstDay: DateTime.utc(2025, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Bulan',
                      CalendarFormat.twoWeeks: '2 Minggu',
                      CalendarFormat.week: 'Minggu',
                    },
                    rowHeight: 42,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getAgendasForDay,
                    locale: 'id_ID',
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonDecoration: BoxDecoration(
                        color: tema.aksen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tema.aksen),
                      ),
                      formatButtonTextStyle: TextStyle(
                        color: tema.aksen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      titleTextStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      leftChevronIcon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                      ),
                      rightChevronIcon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      weekendStyle: TextStyle(
                        color: tema.aksen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: const TextStyle(color: Colors.white),
                      weekendTextStyle: TextStyle(color: tema.aksen),
                      outsideTextStyle: const TextStyle(color: Colors.white24),
                      todayDecoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: tema.aksen, width: 1.5),
                      ),
                      selectedDecoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [tema.aksen, tema.aksenGelap],
                        ),
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(
                        color: tema.latar1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return const SizedBox();
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: events.take(4).map((event) {
                            final c = _ormawaUntuk(event.ormawaId).warna;
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c,
                                boxShadow: [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.8),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      }
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() => _calendarFormat = format);
                      }
                    },
                    onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                  ),
                ),

                // Sub-Header Tanggal Aktif
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.today_rounded,
                              color: tema.aksen,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                DateFormat('EEEE, d MMMM yyyy')
                                    .format(_selectedDay ?? _focusedDay),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: tema.aksen.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tema.aksen.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '${agendaTerpilih.length} Kegiatan',
                          style: TextStyle(
                            color: tema.aksen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Tombol sinkron manual (bisa dipakai semua anggota)
                      Tooltip(
                        message: 'Sinkronkan agenda',
                        child: InkWell(
                          onTap: _sedangMenyinkron
                              ? null
                              : () => _muatAgenda(tampilkanPesan: true),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _sedangMenyinkron
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: tema.aksen,
                                    ),
                                  )
                                : Icon(
                                    Icons.sync_rounded,
                                    size: 18,
                                    color: tema.aksen,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Daftar Kartu Agenda Berwarna
                Expanded(
                  child: _memuatAgenda
                      ? Center(
                          child: CircularProgressIndicator(color: tema.aksen),
                        )
                      : agendaTerpilih.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_busy_rounded,
                                size: 42,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _modeAdmin
                                    ? 'Belum ada jadwal kegiatan di tanggal ini.\nKetuk tombol + Agenda di bawah untuk membuat jadwal.'
                                    : 'Belum ada jadwal kegiatan di tanggal ini.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _muatAgenda,
                          color: tema.aksen,
                          backgroundColor: tema.kartu,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                            itemCount: agendaTerpilih.length,
                            itemBuilder: (context, index) {
                              return _buildColorfulAgendaCard(
                                agendaTerpilih[index],
                                tema,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _modeAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _bukaDialogFormAgenda(),
              backgroundColor: tema.aksen,
              foregroundColor: tema.latar1,
              elevation: 6,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text(
                'Tambah Agenda',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
    );
  }

  // Baris Filter Organisasi dengan Warna Menyala & Kontras Jelas
  Widget _buildColoredFilterBar(PengaturanWarna tema) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: _daftarOrmawa.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isAll = _filterOrmawaId == null;
            return GestureDetector(
              onTap: () => setState(() => _filterOrmawaId = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isAll
                      ? tema.aksen
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAll ? Colors.white : Colors.white24,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  'Semua Ormawa',
                  style: TextStyle(
                    color: isAll ? tema.latar1 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }

          final org = _daftarOrmawa[index - 1];
          final isSelected = _filterOrmawaId == org.id;
          final warna = org.warna;
          final nama = org.nama;

          return GestureDetector(
            onTap: () =>
                setState(() => _filterOrmawaId = isSelected ? null : org.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? warna : warna.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.white : warna,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: warna.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : warna,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    nama,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Kartu Agenda Berwarna Penuh & Sangat Jelas
  Widget _buildColorfulAgendaCard(AgendaAcara item, PengaturanWarna tema) {
    final ormawa = _ormawaUntuk(item.ormawaId);
    final warna = ormawa.warna;
    final namaOrmawa = ormawa.nama;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            warna.withValues(alpha: 0.28),
            tema.kartu.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: warna.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: warna.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: warna, width: 8)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Badge Nama Organisasi Berwarna Jelas + Tombol Aksi
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: warna,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: warna.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  ormawa.ikon,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    namaOrmawa,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ormawa.kategori,
                            style: TextStyle(
                              color: warna,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_modeAdmin) ...[
                    InkWell(
                      onTap: () =>
                          _bukaDialogFormAgenda(agendaUntukDiedit: item),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _konfirmasiHapus(item),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.judul,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (item.deskripsi.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.deskripsi,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: warna),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.lokasi,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
