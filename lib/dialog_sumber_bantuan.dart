import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'layanan_bantuan.dart';
import 'model_bantuan.dart';
import 'pengaturan_warna.dart';

/// Membuka pengelola sumber informasi Help Desk. Hanya dipanggil dari mode
/// admin. Mengembalikan daftar terbaru agar ruang chat langsung memakainya.
Future<List<SumberBantuan>?> tampilkanKelolaSumberBantuan(
  BuildContext context, {
  required PengaturanWarna tema,
  required LayananBantuan layanan,
  required List<SumberBantuan> sumberAwal,
}) {
  return showModalBottomSheet<List<SumberBantuan>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: tema.gelap ? 0.62 : 0.4),
    builder: (_) => _KelolaSumberBantuan(
      tema: tema,
      layanan: layanan,
      sumberAwal: sumberAwal,
    ),
  );
}

class _KelolaSumberBantuan extends StatefulWidget {
  const _KelolaSumberBantuan({
    required this.tema,
    required this.layanan,
    required this.sumberAwal,
  });

  final PengaturanWarna tema;
  final LayananBantuan layanan;
  final List<SumberBantuan> sumberAwal;

  @override
  State<_KelolaSumberBantuan> createState() => _KelolaSumberBantuanState();
}

class _KelolaSumberBantuanState extends State<_KelolaSumberBantuan> {
  late List<SumberBantuan> _daftar;
  bool _memuat = false;
  String? _pesan;
  bool _pesanBerhasil = true;

  @override
  void initState() {
    super.initState();
    _daftar = List.of(widget.sumberAwal);
    _muatUlang();
  }

  Future<void> _muatUlang() async {
    setState(() => _memuat = true);
    final hasil = await widget.layanan.muatSumber();
    if (!mounted) return;
    setState(() {
      _memuat = false;
      _daftar = hasil.daftar;
      if (hasil.galat != null) {
        _pesan = hasil.galat;
        _pesanBerhasil = false;
      }
    });
  }

  Future<void> _tambah() async {
    final urutan = _daftar.isEmpty
        ? 1
        : _daftar.map((s) => s.urutan).reduce((a, b) => a > b ? a : b) + 1;
    final hasil = await showDialog<SumberBantuan>(
      context: context,
      builder: (_) => _DialogSumberBantuan(tema: widget.tema, urutan: urutan),
    );
    if (hasil != null) await _simpan(hasil);
  }

  Future<void> _ubah(SumberBantuan sumber) async {
    final hasil = await showDialog<SumberBantuan>(
      context: context,
      builder: (_) => _DialogSumberBantuan(
        tema: widget.tema,
        awal: sumber,
        urutan: sumber.urutan,
      ),
    );
    if (hasil != null) await _simpan(hasil);
  }

  Future<void> _simpan(SumberBantuan sumber) async {
    final daftarBaru = List<SumberBantuan>.of(_daftar);
    final indeks = daftarBaru.indexWhere((item) => item.id == sumber.id);
    if (indeks >= 0) {
      daftarBaru[indeks] = sumber;
    } else {
      daftarBaru.add(sumber);
    }
    daftarBaru.sort((a, b) => a.urutan.compareTo(b.urutan));
    setState(() => _daftar = daftarBaru);

    final hasil = await widget.layanan.simpanSumber(sumber, daftarBaru);
    if (!mounted) return;
    setState(() {
      _pesan = hasil.pesan;
      _pesanBerhasil = hasil.berhasil;
    });
  }

  Future<void> _hapus(SumberBantuan sumber) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.tema.kartu,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus sumber ini?',
          style: TextStyle(
            color: widget.tema.teks,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          '"${sumber.judul}" tidak akan dipakai lagi sebagai bahan jawaban '
          'Help Desk.',
          style: TextStyle(color: widget.tema.teksLembut, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: widget.tema.bahaya),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (setuju != true) return;

    final daftarBaru = _daftar.where((item) => item.id != sumber.id).toList();
    setState(() => _daftar = daftarBaru);
    final hasil = await widget.layanan.hapusSumber(sumber.id, daftarBaru);
    if (!mounted) return;
    setState(() {
      _pesan = hasil.pesan;
      _pesanBerhasil = hasil.berhasil;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;
    final tinggi = MediaQuery.sizeOf(context).height;
    final bawah = MediaQuery.viewPaddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        height: tinggi * 0.9,
        margin: EdgeInsets.only(bottom: bawah > 0 ? 0 : 8),
        decoration: BoxDecoration(
          color: tema.latar1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: tema.garis),
          boxShadow: [
            BoxShadow(
              color: tema.bayangan,
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            _pegangan(tema),
            _kepala(tema),
            if (_pesan != null) _banner(tema),
            Expanded(
              child: _memuat
                  ? Center(child: CircularProgressIndicator(color: tema.aksen))
                  : _daftar.isEmpty
                  ? _kosong(tema)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: _daftar.length,
                      itemBuilder: (context, index) =>
                          _kartuSumber(tema, _daftar[index]),
                    ),
            ),
            _tombolTutup(tema),
          ],
        ),
      ),
    );
  }

  Widget _pegangan(PengaturanWarna tema) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 8),
      width: 40,
      height: 4.5,
      decoration: BoxDecoration(
        color: tema.teks.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _kepala(PengaturanWarna tema) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5138), Color(0xFF0C2A1C)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: tema.aksen.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFFE7D6A8),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sumber Informasi Help Desk',
                  style: TextStyle(
                    color: Color(0xFFF7F2E6),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_daftar.length} informasi • hanya admin',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE7D6A8),
              foregroundColor: const Color(0xFF123F2B),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _tambah,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              'Tambah',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner(PengaturanWarna tema) {
    final warna = _pesanBerhasil ? tema.aksenTeks : tema.peringatan;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warna.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _pesanBerhasil
                ? Icons.cloud_done_rounded
                : Icons.info_outline_rounded,
            size: 15,
            color: warna,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              _pesan!,
              style: TextStyle(color: warna, fontSize: 10.5, height: 1.3),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Tutup pesan',
            onPressed: () => setState(() => _pesan = null),
            icon: Icon(Icons.close_rounded, size: 15, color: warna),
          ),
        ],
      ),
    );
  }

  Widget _kosong(PengaturanWarna tema) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 46, color: tema.teksSamar),
            const SizedBox(height: 12),
            Text(
              'Belum ada sumber informasi',
              style: TextStyle(
                color: tema.teks,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Tambahkan info resmi tentang ormawa, UKM, UKK, agenda, atau '
              'layanan kampus. Semakin lengkap, semakin akurat jawaban AI.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tema.teksRedup,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuSumber(PengaturanWarna tema, SumberBantuan sumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(13, 12, 6, 12),
      decoration: BoxDecoration(
        color: tema.kartu,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tema.garisLembut),
        boxShadow: [
          BoxShadow(
            color: tema.bayanganLembut,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tema.aksen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.description_rounded,
              size: 18,
              color: tema.aksenTeks,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        sumber.judul,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tema.teks,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tema.aksen.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sumber.kategori,
                        style: TextStyle(
                          color: tema.aksenTeks,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sumber.isi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tema.teksRedup,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tombolIkon(
                tema,
                Icons.edit_outlined,
                'Ubah',
                tema.aksenTeks,
                () => _ubah(sumber),
              ),
              _tombolIkon(
                tema,
                Icons.delete_outline_rounded,
                'Hapus',
                tema.bahaya,
                () => _hapus(sumber),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tombolIkon(
    PengaturanWarna tema,
    IconData ikon,
    String tooltip,
    Color warna,
    VoidCallback onTap,
  ) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(ikon, size: 17, color: warna),
    );
  }

  Widget _tombolTutup(PengaturanWarna tema) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tema.aksen,
              foregroundColor: tema.diAksen,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context, _daftar);
            },
            child: const Text(
              'Selesai',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Form tambah/ubah sumber
// -----------------------------------------------------------------------------

class _DialogSumberBantuan extends StatefulWidget {
  const _DialogSumberBantuan({
    required this.tema,
    required this.urutan,
    this.awal,
  });

  final PengaturanWarna tema;
  final int urutan;
  final SumberBantuan? awal;

  @override
  State<_DialogSumberBantuan> createState() => _DialogSumberBantuanState();
}

class _DialogSumberBantuanState extends State<_DialogSumberBantuan> {
  late final TextEditingController _judulCtrl;
  late final TextEditingController _isiCtrl;
  late String _kategori;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _judulCtrl = TextEditingController(text: widget.awal?.judul ?? '');
    _isiCtrl = TextEditingController(text: widget.awal?.isi ?? '');
    _kategori = widget.awal?.kategori ?? 'Umum';
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    final judul = _judulCtrl.text.trim();
    final isi = _isiCtrl.text.trim();
    if (judul.isEmpty) {
      setState(() => _galat = 'Judul informasi wajib diisi.');
      return;
    }
    if (isi.length < 10) {
      setState(() => _galat = 'Isi informasi minimal 10 karakter.');
      return;
    }

    Navigator.pop(
      context,
      SumberBantuan(
        id:
            widget.awal?.id ??
            'bantuan-${DateTime.now().microsecondsSinceEpoch}',
        judul: judul,
        kategori: _kategori,
        isi: isi,
        urutan: widget.urutan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;
    return AlertDialog(
      backgroundColor: tema.kartu,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: tema.aksen.withValues(alpha: 0.5)),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [tema.aksen, tema.aksenGelap]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.menu_book_rounded, color: tema.diAksen, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              widget.awal == null ? 'Tambah Informasi' : 'Ubah Informasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tema.teks,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _judulCtrl,
                style: TextStyle(color: tema.teks),
                textCapitalization: TextCapitalization.sentences,
                decoration: _dekorasi(
                  tema,
                  'Judul informasi',
                  Icons.title_rounded,
                ),
                onChanged: (_) {
                  if (_galat != null) setState(() => _galat = null);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: daftarKategoriBantuan.contains(_kategori)
                    ? _kategori
                    : 'Umum',
                dropdownColor: tema.latar2,
                style: TextStyle(color: tema.teks, fontSize: 13),
                decoration: _dekorasi(tema, 'Kategori', Icons.category_rounded),
                items: daftarKategoriBantuan
                    .map(
                      (kategori) => DropdownMenuItem(
                        value: kategori,
                        child: Text(
                          kategori,
                          style: TextStyle(color: tema.teks),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (nilai) {
                  if (nilai != null) setState(() => _kategori = nilai);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _isiCtrl,
                style: TextStyle(color: tema.teks, height: 1.45),
                minLines: 6,
                maxLines: 12,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dekorasi(
                  tema,
                  'Isi informasi',
                  Icons.notes_rounded,
                  alignLabelWithHint: true,
                  petunjuk: 'Tulis fakta yang bisa dipakai AI untuk menjawab…',
                ),
                onChanged: (_) {
                  if (_galat != null) setState(() => _galat = null);
                },
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 14,
                    color: tema.teksRedup,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tulis fakta yang jelas: nama, syarat, tanggal, kontak, '
                      'atau alur layanan. Hindari singkatan yang tidak umum.',
                      style: TextStyle(
                        color: tema.teksRedup,
                        fontSize: 9.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (_galat != null) ...[
                const SizedBox(height: 10),
                Text(
                  _galat!,
                  style: TextStyle(
                    color: tema.peringatan,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: tema.aksen,
            foregroundColor: tema.diAksen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _simpan,
          child: Text(
            widget.awal == null ? 'Tambahkan' : 'Simpan',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  InputDecoration _dekorasi(
    PengaturanWarna tema,
    String label,
    IconData ikon, {
    bool alignLabelWithHint = false,
    String? petunjuk,
  }) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: alignLabelWithHint,
      hintText: petunjuk,
      hintStyle: TextStyle(color: tema.teksSamar, fontSize: 11.5),
      labelStyle: TextStyle(color: tema.teksLembut),
      prefixIcon: Icon(ikon, color: tema.teksRedup, size: 19),
      filled: true,
      fillColor: tema.isian,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: tema.garis),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: tema.garis),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: tema.aksen, width: 1.6),
      ),
    );
  }
}
