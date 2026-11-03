import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pengaturan_warna.dart';

/// Identitas aplikasi yang ditampilkan pada jendela "Tentang Aplikasi".
const String versiAplikasi = '1.1.0';
const String nomorBuildAplikasi = '2';
const String pembuatAplikasi = 'Senat Mahasiswa 2026/2027';

/// Membuka jendela informasi aplikasi bergaya macOS: kaca buram, deretan
/// lampu lalu lintas, dan dock yang bisa diketuk untuk berpindah bagian.
Future<void> tampilkanTentangAplikasi(
  BuildContext context,
  PengaturanWarna tema,
) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup tentang aplikasi',
    barrierColor: Colors.black.withValues(alpha: tema.gelap ? 0.62 : 0.42),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (ctx, _, _) => _TentangAplikasi(tema: tema),
    transitionBuilder: (ctx, animasi, _, anak) {
      final t = Curves.easeOutCubic.transform(animasi.value);
      return FadeTransition(
        opacity: animasi,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - t)),
          child: Transform.scale(scale: 0.9 + 0.1 * t, child: anak),
        ),
      );
    },
  );
}

class _TentangAplikasi extends StatefulWidget {
  const _TentangAplikasi({required this.tema});

  final PengaturanWarna tema;

  @override
  State<_TentangAplikasi> createState() => _TentangAplikasiState();
}

class _TentangAplikasiState extends State<_TentangAplikasi> {
  int _tab = 0;

  static const _tabs = <_TabTentang>[
    _TabTentang(
      label: 'Info',
      judul: 'Informasi Aplikasi',
      ikon: Icons.info_rounded,
      warna: Color(0xFF3B82F6),
      baris: [
        (
          Icons.badge_rounded,
          'Nama aplikasi',
          'OrmaKta — Kalender Kemahasiswaan',
        ),
        (Icons.person_rounded, 'Pembuat', 'Senat Mahasiswa 2026/2027'),
        (
          Icons.school_rounded,
          'Institusi',
          'STIE Latifah Mubarokiyah Suryalaya',
        ),
        (
          Icons.calendar_month_rounded,
          'Fungsi',
          'Kalender kegiatan ormawa, UKM, dan UKK',
        ),
        (
          Icons.new_releases_rounded,
          'Rilis',
          '2026 • Versi $versiAplikasi ($nomorBuildAplikasi)',
        ),
      ],
    ),
    _TabTentang(
      label: 'Lisensi',
      judul: 'Lisensi & Hak Cipta',
      ikon: Icons.verified_user_rounded,
      warna: Color(0xFFF59E0B),
      baris: [
        (
          Icons.copyright_rounded,
          'Hak cipta',
          '© 2026 Senat Mahasiswa 2026/2027',
        ),
        (
          Icons.verified_rounded,
          'Status lisensi',
          'Licensed to Senat Mahasiswa 2026/2027',
        ),
        (
          Icons.block_rounded,
          'Penggunaan',
          'Aplikasi internal kampus, tidak untuk diperjualbelikan',
        ),
        (
          Icons.code_rounded,
          'Komponen',
          'Flutter, Supabase, dan pustaka open source',
        ),
        (
          Icons.description_rounded,
          'Izin',
          'Untuk kegiatan kemahasiswaan STIE-LM Suryalaya',
        ),
      ],
    ),
    _TabTentang(
      label: 'Privasi',
      judul: 'Privasi & Data',
      ikon: Icons.shield_rounded,
      warna: Color(0xFF14B8A6),
      baris: [
        (
          Icons.cloud_sync_rounded,
          'Agenda & ormawa',
          'Disinkronkan lewat Supabase untuk semua perangkat',
        ),
        (
          Icons.phone_android_rounded,
          'Pengaturan tampilan',
          'Disimpan di perangkat ini',
        ),
        (
          Icons.person_off_rounded,
          'Data pribadi',
          'Tidak ada data pribadi yang dikumpulkan',
        ),
        (
          Icons.lock_rounded,
          'Mode admin',
          'Dilindungi sandi lokal pada perangkat',
        ),
      ],
    ),
    _TabTentang(
      label: 'Kredit',
      judul: 'Kredit & Apresiasi',
      ikon: Icons.auto_awesome_rounded,
      warna: Color(0xFF8B5CF6),
      baris: [
        (
          Icons.workspace_premium_rounded,
          'Pemrakarsa',
          'Senat Mahasiswa 2026/2027',
        ),
        (Icons.flutter_dash_rounded, 'Pengembangan', 'Tim OrmaKta'),
        (Icons.brush_rounded, 'Desain', 'Nuansa iPhone & macOS'),
        (Icons.favorite_rounded, 'Dukungan', 'Mahasiswa STIE-LM Suryalaya'),
      ],
    ),
    _TabTentang(
      label: 'Kontak',
      judul: 'Kontak & Layanan',
      ikon: Icons.support_agent_rounded,
      warna: Color(0xFF22C55E),
      baris: [
        (
          Icons.location_on_rounded,
          'Sekretariat',
          'Kampus STIE Latifah Mubarokiyah Suryalaya',
        ),
        (
          Icons.support_agent_rounded,
          'Saran & laporan',
          'Sampaikan langsung ke pengurus Senat Mahasiswa',
        ),
        (
          Icons.campaign_rounded,
          'Informasi resmi',
          'Ikuti kanal pengumuman Senat Mahasiswa',
        ),
        (Icons.schedule_rounded, 'Layanan', 'Sesuai jam sekretariat kampus'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;
    final ukuran = MediaQuery.sizeOf(context);
    final lebar = math.min(ukuran.width - 32, 420.0);

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: lebar,
              maxHeight: ukuran.height * 0.9,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: Container(
                  decoration: BoxDecoration(
                    color: tema.kartu.withValues(
                      alpha: tema.gelap ? 0.82 : 0.9,
                    ),
                    border: Border.all(
                      color: tema.gelap
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _bilahJudul(tema),
                        _panggungAplikasi(tema),
                        _isiTab(tema),
                        _dock(tema),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Jendela macOS
  // ---------------------------------------------------------------------------

  Widget _bilahJudul(PengaturanWarna tema) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: tema.kartu.withValues(alpha: tema.gelap ? 0.5 : 0.66),
        border: Border(bottom: BorderSide(color: tema.garisLembut)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _lampuLaluLintas(
                  const Color(0xFFFF5F57),
                  onTap: () => Navigator.pop(context),
                  tooltip: 'Tutup',
                ),
                const SizedBox(width: 7),
                _lampuLaluLintas(const Color(0xFFFEBC2E)),
                const SizedBox(width: 7),
                _lampuLaluLintas(const Color(0xFF28C840)),
              ],
            ),
          ),
          Text(
            'Tentang Aplikasi',
            style: TextStyle(
              color: tema.teksLembut,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lampuLaluLintas(Color warna, {VoidCallback? onTap, String? tooltip}) {
    final titik = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: warna,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: warna.withValues(alpha: 0.45),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );

    if (onTap == null) return titik;

    final tombol = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 20, height: 20, child: Center(child: titik)),
    );
    return tooltip == null ? tombol : Tooltip(message: tooltip, child: tombol);
  }

  /// Bagian atas bergaya wallpaper macOS dengan ikon aplikasi melayang.
  Widget _panggungAplikasi(PengaturanWarna tema) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C2A1C), Color(0xFF061710), Color(0xFF102E20)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -64,
            right: -44,
            child: _cahaya(const Color(0xFFD9BC72), 0.30, 180),
          ),
          Positioned(
            bottom: -70,
            left: -50,
            child: _cahaya(const Color(0xFFA8C46B), 0.24, 200),
          ),
          Positioned(top: 26, left: 34, child: _bintang(3, 0.22)),
          Positioned(top: 58, right: 46, child: _bintang(2.2, 0.16)),
          Positioned(bottom: 26, right: 88, child: _bintang(1.8, 0.12)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.44),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: const Color(0xFFD9BC72).withValues(alpha: 0.24),
                      blurRadius: 30,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFF1E5B40),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'OrmaKta',
                style: TextStyle(
                  color: Color(0xFFF7F2E6),
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Kalender Kemahasiswaan',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.66),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'oleh $pembuatAplikasi',
                style: const TextStyle(
                  color: Color(0xFFE7D6A8),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 11),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 7,
                runSpacing: 7,
                children: [
                  _lencana(
                    Icons.auto_awesome_rounded,
                    'v$versiAplikasi ($nomorBuildAplikasi)',
                  ),
                  _lencana(
                    Icons.verified_user_rounded,
                    'Licensed to Senat Mahasiswa',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cahaya(Color warna, double alfa, double ukuran) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            warna.withValues(alpha: alfa),
            warna.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  Widget _bintang(double ukuran, double alfa) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alfa),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _lencana(IconData ikon, String teks) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 11, color: const Color(0xFFE7D6A8)),
          const SizedBox(width: 5),
          Text(
            teks,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Isi tab
  // ---------------------------------------------------------------------------

  Widget _isiTab(PengaturanWarna tema) {
    final tab = _tabs[_tab];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      constraints: const BoxConstraints(minHeight: 248),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (anak, animasi) {
          final t = Curves.easeOutCubic.transform(animasi.value);
          return FadeTransition(
            opacity: animasi,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - t)),
              child: anak,
            ),
          );
        },
        child: Column(
          key: ValueKey(_tab),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: tab.warna.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(tab.ikon, size: 15, color: tab.warna),
                ),
                const SizedBox(width: 9),
                Text(
                  tab.judul,
                  style: TextStyle(
                    color: tema.teks,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.25,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_tab + 1}/${_tabs.length}',
                  style: TextStyle(
                    color: tema.teksSamar,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final baris in tab.baris) _barisInfo(tema, tab.warna, baris),
          ],
        ),
      ),
    );
  }

  Widget _barisInfo(
    PengaturanWarna tema,
    Color warna,
    (IconData, String, String) baris,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tema.isian,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tema.garisLembut),
            ),
            child: Icon(baris.$1, size: 15, color: warna),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  baris.$2,
                  style: TextStyle(
                    color: tema.teksRedup,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  baris.$3,
                  style: TextStyle(
                    color: tema.teks,
                    fontSize: 11.5,
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

  // ---------------------------------------------------------------------------
  // Dock bawah
  // ---------------------------------------------------------------------------

  Widget _dock(PengaturanWarna tema) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 2, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: tema.kartu.withValues(alpha: tema.gelap ? 0.58 : 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tema.garis),
        boxShadow: [
          BoxShadow(
            color: tema.bayanganLembut,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: 7),
              _ItemDock(
                tab: _tabs[i],
                terpilih: _tab == i,
                onTap: () {
                  if (_tab == i) return;
                  HapticFeedback.selectionClick();
                  setState(() => _tab = i);
                },
              ),
            ],
            Container(
              width: 1,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 9),
              color: tema.garis,
            ),
            _ItemDockTutup(onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Model tab dan komponen dock
// -----------------------------------------------------------------------------

class _TabTentang {
  const _TabTentang({
    required this.label,
    required this.judul,
    required this.ikon,
    required this.warna,
    required this.baris,
  });

  final String label;
  final String judul;
  final IconData ikon;
  final Color warna;
  final List<(IconData, String, String)> baris;
}

class _ItemDock extends StatefulWidget {
  const _ItemDock({
    required this.tab,
    required this.terpilih,
    required this.onTap,
  });

  final _TabTentang tab;
  final bool terpilih;
  final VoidCallback onTap;

  @override
  State<_ItemDock> createState() => _ItemDockState();
}

class _ItemDockState extends State<_ItemDock> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final naik = _hover ? 1.0 : (widget.terpilih ? 0.45 : 0.0);

    return Tooltip(
      message: widget.tab.label,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSlide(
                duration: const Duration(milliseconds: 190),
                curve: Curves.easeOutBack,
                offset: Offset(0, -0.10 * naik),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 190),
                  curve: Curves.easeOutBack,
                  scale: _hover ? 1.12 : (widget.terpilih ? 1.04 : 1),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.tab.warna,
                          Color.lerp(widget.tab.warna, Colors.black, 0.28)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.tab.warna.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(widget.tab.ikon, size: 20, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: widget.terpilih ? 1 : 0,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.tab.warna,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemDockTutup extends StatefulWidget {
  const _ItemDockTutup({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ItemDockTutup> createState() => _ItemDockTutupState();
}

class _ItemDockTutupState extends State<_ItemDockTutup> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tutup',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 190),
            curve: Curves.easeOutBack,
            scale: _hover ? 1.12 : 1,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF87171), Color(0xFFB91C1C)],
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
