import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dialog_sumber_bantuan.dart';
import 'gaya_iphone.dart';
import 'ikon_helpdesk.dart';
import 'layanan_bantuan.dart';
import 'layanan_helpdesk.dart';
import 'model_bantuan.dart';
import 'model_ormawa.dart';
import 'pengaturan_warna.dart';

/// Membuka ruang chat Help Desk. Hanya memakai sumber informasi yang
/// ditambahkan admin, ditambah pengetahuan umum model AI.
Future<void> tampilkanHelpdesk(
  BuildContext context, {
  required PengaturanWarna tema,
  required bool modeAdmin,
  required List<Ormawa> daftarOrmawa,
  required LayananBantuan layananBantuan,
  LayananHelpdesk? layananHelpdesk,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: tema.gelap ? 0.66 : 0.44),
    builder: (_) => _RuangHelpdesk(
      tema: tema,
      modeAdmin: modeAdmin,
      daftarOrmawa: daftarOrmawa,
      layananBantuan: layananBantuan,
      layananHelpdesk: layananHelpdesk ?? LayananHelpdesk(),
    ),
  );
}

enum _JenisPesan { pengguna, asisten, galat }

class _Pesan {
  _Pesan(
    this.jenis,
    this.teks, {
    this.sumber = const [],
    this.mengetik = false,
  });

  _JenisPesan jenis;
  String teks;
  final List<String> sumber;
  bool mengetik;
}

class _RuangHelpdesk extends StatefulWidget {
  const _RuangHelpdesk({
    required this.tema,
    required this.modeAdmin,
    required this.daftarOrmawa,
    required this.layananBantuan,
    required this.layananHelpdesk,
  });

  final PengaturanWarna tema;
  final bool modeAdmin;
  final List<Ormawa> daftarOrmawa;
  final LayananBantuan layananBantuan;
  final LayananHelpdesk layananHelpdesk;

  @override
  State<_RuangHelpdesk> createState() => _RuangHelpdeskState();
}

class _RuangHelpdeskState extends State<_RuangHelpdesk> {
  final List<_Pesan> _pesan = [];
  final TextEditingController _tulis = TextEditingController();
  final ScrollController _gulir = ScrollController();
  final FocusNode _fokus = FocusNode();

  StreamSubscription<String>? _langganan;
  List<SumberBantuan> _sumber = const [];
  bool _memuatSumber = true;
  bool _sedangMengetik = false;
  String? _galatSumber;

  static const _saran = [
    'Apa itu BEM?',
    'Bagaimana cara bergabung dengan UKM?',
    'Agenda terdekat kapan?',
    'Apa tugas Senat Mahasiswa?',
  ];

  @override
  void initState() {
    super.initState();
    _muatSumber();
  }

  @override
  void dispose() {
    _langganan?.cancel();
    _tulis.dispose();
    _gulir.dispose();
    _fokus.dispose();
    super.dispose();
  }

  Future<void> _muatSumber() async {
    final hasil = await widget.layananBantuan.muatSumber();
    if (!mounted) return;
    setState(() {
      _sumber = hasil.daftar;
      _memuatSumber = false;
      _galatSumber = hasil.galat;
    });
  }

  List<PesanKonteks> get _riwayat {
    final daftar = <PesanKonteks>[];
    for (final pesan in _pesan) {
      if (pesan.jenis == _JenisPesan.pengguna) {
        daftar.add(PesanKonteks(peran: 'user', teks: pesan.teks));
      } else if (pesan.jenis == _JenisPesan.asisten &&
          pesan.teks.trim().isNotEmpty) {
        daftar.add(PesanKonteks(peran: 'assistant', teks: pesan.teks));
      }
    }
    return daftar;
  }

  void _gulirKeBawah({bool animasi = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_gulir.hasClients) return;
      final tujuan = _gulir.position.maxScrollExtent;
      if (animasi) {
        _gulir.animateTo(
          tujuan,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      } else {
        _gulir.jumpTo(tujuan);
      }
    });
  }

  Future<void> _kirim([String? teksSaran]) async {
    if (_sedangMengetik) return;

    final isi = (teksSaran ?? _tulis.text).trim();
    if (isi.isEmpty) return;

    if (isi.length > 1200) {
      setState(() {
        _pesan.add(
          _Pesan(
            _JenisPesan.galat,
            'Pertanyaan terlalu panjang. Ringkas menjadi maksimal '
            '1.200 karakter agar AI bisa menjawab dengan baik.',
          ),
        );
      });
      _gulirKeBawah();
      return;
    }

    if (teksSaran == null) _tulis.clear();
    HapticFeedback.lightImpact();

    final riwayat = _riwayat;
    final judulSumber = LayananHelpdesk.pilihSumber(
      isi,
      _sumber,
    ).map((sumber) => sumber.judul).toList();
    final pengguna = _Pesan(_JenisPesan.pengguna, isi);
    final jawaban = _Pesan(
      _JenisPesan.asisten,
      '',
      sumber: judulSumber,
      mengetik: true,
    );

    setState(() {
      _pesan
        ..add(pengguna)
        ..add(jawaban);
      _sedangMengetik = true;
    });
    _gulirKeBawah();

    _langganan = widget.layananHelpdesk
        .tanya(
          pertanyaan: isi,
          riwayat: riwayat,
          sumber: _sumber,
          daftarOrmawa: widget.daftarOrmawa,
        )
        .listen(
          (potongan) {
            if (!mounted) return;
            setState(() {
              jawaban.mengetik = false;
              jawaban.teks += potongan;
            });
            _gulirKeBawah(animasi: false);
          },
          onError: (Object galat, StackTrace _) {
            if (!mounted) return;
            setState(() {
              jawaban.jenis = _JenisPesan.galat;
              jawaban.mengetik = false;
              jawaban.teks = galat is HelpdeskException
                  ? galat.pesan
                  : 'Maaf, Help Desk sedang tidak bisa menjawab. Coba lagi.';
              _sedangMengetik = false;
            });
            _langganan = null;
            _gulirKeBawah();
          },
          onDone: () {
            if (!mounted) return;
            setState(() {
              jawaban.mengetik = false;
              if (jawaban.teks.trim().isEmpty &&
                  jawaban.jenis != _JenisPesan.galat) {
                jawaban.jenis = _JenisPesan.galat;
                jawaban.teks =
                    'Maaf, jawaban kosong. Silakan ulangi pertanyaan dengan '
                    'kalimat lain.';
              }
              _sedangMengetik = false;
            });
            _langganan = null;
            _gulirKeBawah();
          },
          cancelOnError: true,
        );
  }

  Future<void> _hentikan() async {
    final langganan = _langganan;
    _langganan = null;
    await langganan?.cancel();
    if (!mounted) return;
    setState(() {
      _sedangMengetik = false;
      if (_pesan.isNotEmpty) {
        final terakhir = _pesan.last;
        if (terakhir.mengetik) {
          terakhir.mengetik = false;
          if (terakhir.teks.trim().isEmpty) {
            terakhir.jenis = _JenisPesan.galat;
            terakhir.teks = 'Jawaban dihentikan.';
          }
        }
      }
    });
  }

  void _mulaiUlang() {
    _hentikan();
    setState(() {
      _pesan.clear();
      _sedangMengetik = false;
    });
    _tulis.clear();
    HapticFeedback.selectionClick();
  }

  Future<void> _kelolaSumber() async {
    _fokus.unfocus();
    final hasil = await tampilkanKelolaSumberBantuan(
      context,
      tema: widget.tema,
      layanan: widget.layananBantuan,
      sumberAwal: _sumber,
    );
    if (!mounted || hasil == null) return;
    setState(() {
      _sumber = hasil;
      _galatSumber = null;
      _memuatSumber = false;
    });
  }

  String get _statusTeks {
    if (!widget.layananHelpdesk.terkonfigurasi) {
      return 'Belum aktif • API key belum dipasang';
    }
    if (_memuatSumber) return 'Asisten AI • memuat sumber…';
    if (_sumber.isNotEmpty) {
      return 'Asisten AI • ${_sumber.length} sumber resmi';
    }
    return 'Asisten AI • siap membantu';
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final tinggiTersedia =
        media.size.height -
        media.padding.top -
        media.padding.bottom -
        keyboard -
        8;
    final tinggi = math.min(media.size.height * 0.92, tinggiTersedia);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: tinggi,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Container(
            decoration: BoxDecoration(
              color: tema.latar1,
              border: Border.all(color: tema.garis),
            ),
            child: Column(
              children: [
                _kepala(tema),
                if (!widget.layananHelpdesk.terkonfigurasi) _bannerKunci(tema),
                Expanded(child: _ruangObrolan(tema)),
                _areaTulis(tema),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kepala(PengaturanWarna tema) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2719), Color(0xFF175239), Color(0xFF0A2719)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFD9BC72).withValues(alpha: 0.20),
                      const Color(0xFFD9BC72).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 9, bottom: 6),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 8, 12),
                child: Row(
                  children: [
                    const IkonHelpdesk(ukuran: 44),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Help Desk OrmaKta',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFF7F2E6),
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: widget.layananHelpdesk.terkonfigurasi
                                      ? const Color(0xFF6EE7A8)
                                      : const Color(0xFFFBBF24),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  _statusTeks,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.62),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.modeAdmin)
                      _tombolKepala(
                        ikon: Icons.menu_book_rounded,
                        tooltip: 'Kelola sumber jawaban',
                        warna: const Color(0xFFE7D6A8),
                        onTap: _kelolaSumber,
                      ),
                    _tombolKepala(
                      ikon: Icons.refresh_rounded,
                      tooltip: 'Mulai obrolan baru',
                      warna: Colors.white.withValues(
                        alpha: _pesan.isEmpty ? 0.25 : 0.82,
                      ),
                      onTap: _pesan.isEmpty ? null : _mulaiUlang,
                    ),
                    _tombolKepala(
                      ikon: Icons.close_rounded,
                      tooltip: 'Tutup',
                      warna: Colors.white,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tombolKepala({
    required IconData ikon,
    required String tooltip,
    required Color warna,
    required VoidCallback? onTap,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      icon: Icon(ikon, size: 19, color: warna),
    );
  }

  Widget _bannerKunci(PengaturanWarna tema) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.key_off_rounded, size: 15, color: Color(0xFFB45309)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Help Desk belum aktif. Admin perlu memasang API key DeepSeek.',
              style: TextStyle(
                color: tema.peringatan,
                fontSize: 10.5,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruangObrolan(PengaturanWarna tema) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tema.latar1, tema.latar2],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      tema.aksen.withValues(alpha: 0.07),
                      tema.aksen.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ListView(
            controller: _gulir,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            children: [
              _kartuSambutan(tema),
              for (final pesan in _pesan) _gelembung(tema, pesan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kartuSambutan(PengaturanWarna tema) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: tema.kartu.withValues(alpha: tema.gelap ? 0.72 : 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tema.garisLembut),
        boxShadow: [
          BoxShadow(
            color: tema.bayanganLembut,
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const IkonHelpdesk(ukuran: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Halo, saya asisten OrmaKta',
                      style: TextStyle(
                        color: tema.teks,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Siap membantu seputar ormawa, UKM, UKK, dan agenda '
                      'kampus.',
                      style: TextStyle(
                        color: tema.teksRedup,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: tema.isian,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: tema.garisLembut),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _sumber.isEmpty
                      ? Icons.info_outline_rounded
                      : Icons.menu_book_rounded,
                  size: 11,
                  color: tema.teksRedup,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _memuatSumber
                        ? 'Memuat sumber resmi…'
                        : _sumber.isEmpty
                        ? 'Belum ada sumber resmi dari admin'
                        : '${_sumber.length} sumber resmi dari admin',
                    style: TextStyle(
                      color: tema.teksRedup,
                      fontSize: 8.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_pesan.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Coba tanyakan',
              style: TextStyle(
                color: tema.teksLembut,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final saran in _saran)
                  TekanSkala(
                    onTap: () => _kirim(saran),
                    skala: 0.96,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: tema.kartu,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tema.garis),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.north_east_rounded,
                            size: 11,
                            color: tema.aksenTeks,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            saran,
                            style: TextStyle(
                              color: tema.teks,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _gelembung(PengaturanWarna tema, _Pesan pesan) {
    final dariPengguna = pesan.jenis == _JenisPesan.pengguna;
    final galat = pesan.jenis == _JenisPesan.galat;
    final lebarMaks = MediaQuery.sizeOf(context).width * 0.76;

    if (dariPengguna) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: lebarMaks),
                padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [tema.aksen, tema.aksenGelap],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tema.aksen.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  pesan.teks,
                  style: TextStyle(
                    color: tema.diAksen,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: IkonHelpdesk(ukuran: 27),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: lebarMaks),
                  padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                  decoration: BoxDecoration(
                    color: galat
                        ? tema.bahaya.withValues(alpha: 0.10)
                        : tema.kartu,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: galat
                          ? tema.bahaya.withValues(alpha: 0.30)
                          : tema.garisLembut,
                    ),
                    boxShadow: galat
                        ? null
                        : [
                            BoxShadow(
                              color: tema.bayanganLembut,
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  child: pesan.mengetik
                      ? _IndikatorMengetik(warna: tema.teksRedup)
                      : SelectableText(
                          pesan.teks,
                          style: TextStyle(
                            color: galat ? tema.bahaya : tema.teks,
                            fontSize: 12,
                            height: 1.48,
                          ),
                        ),
                ),
                if (!pesan.mengetik && pesan.sumber.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Tooltip(
                    message: pesan.sumber.join('\n'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tema.isian,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: tema.garisLembut),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 10,
                            color: tema.teksRedup,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${pesan.sumber.length} sumber resmi',
                            style: TextStyle(
                              color: tema.teksRedup,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _areaTulis(PengaturanWarna tema) {
    return Container(
      decoration: BoxDecoration(
        color: tema.kartu.withValues(alpha: tema.gelap ? 0.92 : 0.96),
        border: Border(top: BorderSide(color: tema.garisLembut)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_pesan.isNotEmpty) ...[
                Text(
                  'Jawaban AI dapat keliru • sumber resmi dari admin',
                  style: TextStyle(
                    color: tema.teksSamar,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: tema.isian,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: tema.garis),
                      ),
                      child: TextField(
                        controller: _tulis,
                        focusNode: _fokus,
                        style: TextStyle(color: tema.teks, fontSize: 12.5),
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _kirim(),
                        decoration: InputDecoration(
                          hintText: widget.layananHelpdesk.terkonfigurasi
                              ? 'Tanyakan sesuatu tentang ormawa…'
                              : 'Help Desk belum aktif',
                          hintStyle: TextStyle(
                            color: tema.teksSamar,
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          prefixIcon: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 17,
                            color: tema.teksRedup,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 38,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _tombolKirim(tema),
                ],
              ),
              if (_galatSumber != null && widget.modeAdmin)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _galatSumber!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tema.peringatan, fontSize: 8.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tombolKirim(PengaturanWarna tema) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _tulis,
      builder: (context, nilai, _) {
        final berhenti = _sedangMengetik;
        final aktif = berhenti || nilai.text.trim().isNotEmpty;
        return Tooltip(
          message: berhenti ? 'Hentikan jawaban' : 'Kirim',
          child: GestureDetector(
            onTap: !aktif
                ? null
                : berhenti
                ? _hentikan
                : () => _kirim(),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: berhenti
                      ? [tema.bahaya, const Color(0xFF7F1D1D)]
                      : aktif
                      ? [tema.aksen, tema.aksenGelap]
                      : [tema.isian, tema.isian],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: aktif
                      ? Colors.white.withValues(alpha: 0.25)
                      : tema.garis,
                ),
                boxShadow: aktif
                    ? [
                        BoxShadow(
                          color: (berhenti ? tema.bahaya : tema.aksen)
                              .withValues(alpha: 0.32),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                berhenti ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                size: 21,
                color: aktif
                    ? (berhenti ? Colors.white : tema.diAksen)
                    : tema.teksSamar,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IndikatorMengetik extends StatefulWidget {
  const _IndikatorMengetik({required this.warna});

  final Color warna;

  @override
  State<_IndikatorMengetik> createState() => _IndikatorMengetikState();
}

class _IndikatorMengetikState extends State<_IndikatorMengetik>
    with SingleTickerProviderStateMixin {
  late final AnimationController _kontrol = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: AnimatedBuilder(
        animation: _kontrol,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Transform.translate(
                  offset: Offset(
                    0,
                    -1.4 *
                        math.sin(
                          ((_kontrol.value + i * 0.16) % 1.0) * math.pi * 2,
                        ),
                  ),
                  child: Opacity(
                    opacity:
                        0.35 +
                        0.65 *
                            ((math.sin(
                                      ((_kontrol.value + i * 0.16) % 1.0) *
                                          math.pi *
                                          2,
                                    ) +
                                    1) /
                                2),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: widget.warna,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
