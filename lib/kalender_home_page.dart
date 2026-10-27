import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'model_agenda.dart';
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
  KategoriOrmawa? _selectedFilter;

  // Penyimpanan dinamis untuk Nama & Warna tiap Ormawa
  late final Map<KategoriOrmawa, String> _labelOrmawa;
  late final Map<KategoriOrmawa, Color> _warnaOrmawa;

  final PenyimpananPengaturan _penyimpanan = PenyimpananPengaturan();

  final List<AgendaAcara> _semuaAgenda = [
    AgendaAcara(
      id: '1',
      judul: 'Sidang Pleno Kemahasiswaan',
      deskripsi: 'Evaluasi program kerja dan anggaran ormawa triwulan berjalan',
      waktu: DateTime.now(),
      lokasi: 'Ruang Sidang Utama',
      ormawa: KategoriOrmawa.senat,
    ),
    AgendaAcara(
      id: '2',
      judul: 'Pekan Raya & Kreativitas BEM',
      deskripsi: 'Gebyar pameran inovasi dan bazar mahasiswa kampus',
      waktu: DateTime.now(),
      lokasi: 'Lapangan Utama Kampus',
      ormawa: KategoriOrmawa.bem,
    ),
    AgendaAcara(
      id: '3',
      judul: 'Kajian Manajemen & Kepemimpinan',
      deskripsi: 'Diskusi strategi manajemen SDM era transformasi digital',
      waktu: DateTime.now().add(const Duration(days: 1)),
      lokasi: 'Auditorium Gedung B',
      ormawa: KategoriOrmawa.hmpsMn,
    ),
    AgendaAcara(
      id: '4',
      judul: 'Turnamen Futsal & Badminton',
      deskripsi: 'Kompetisi olahraga persahabatan antar program studi',
      waktu: DateTime.now().add(const Duration(days: 2)),
      lokasi: 'GOR Kampus',
      ormawa: KategoriOrmawa.ukm1,
    ),
  ];

  PengaturanWarna get _tema => widget.tema;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _labelOrmawa = {
      for (final item in KategoriOrmawa.values) item: item.namaDefault,
    };
    _warnaOrmawa = {
      for (final item in KategoriOrmawa.values) item: item.warnaDefault,
    };
    _muatKustomisasiOrmawa();
  }

  Future<void> _muatKustomisasiOrmawa() async {
    final data = await _penyimpanan.muatOrmawa();
    if (data == null || !mounted) return;

    setState(() {
      for (final org in KategoriOrmawa.values) {
        final entri = data[org.id];
        if (entri == null) continue;

        final nama = entri['nama'];
        final warna = entri['warna'];
        if (nama is String && nama.trim().isNotEmpty) {
          _labelOrmawa[org] = nama;
        }
        if (warna is int) {
          _warnaOrmawa[org] = Color(warna);
        }
      }
    });
  }

  void _simpanKustomisasiOrmawa() {
    _penyimpanan.simpanOrmawa({
      for (final org in KategoriOrmawa.values)
        org.id: {'nama': _getNama(org), 'warna': _getWarna(org).toARGB32()},
    });
  }

  String _getNama(KategoriOrmawa org) => _labelOrmawa[org] ?? org.namaDefault;
  Color _getWarna(KategoriOrmawa org) => _warnaOrmawa[org] ?? org.warnaDefault;

  List<AgendaAcara> _getAgendasForDay(DateTime day) {
    return _semuaAgenda.where((agenda) {
      final isSameDate = isSameDay(agenda.waktu, day);
      if (_selectedFilter != null) {
        return isSameDate && agenda.ormawa == _selectedFilter;
      }
      return isSameDate;
    }).toList();
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kustomisasi Tampilan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Atur tema aplikasi serta nama dan warna tiap ormawa',
                                style: TextStyle(
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
                      itemCount: KategoriOrmawa.values.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _kartuTema(
                            tema,
                            onTap: () =>
                                _bukaDialogTema(() => setSheetState(() {})),
                          );
                        }

                        final org = KategoriOrmawa.values[index - 1];
                        final warna = _getWarna(org);
                        final nama = _getNama(org);

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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
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
                                nama,
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
                              trailing: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: warna,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                label: const Text(
                                  'Ubah',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  _dialogEditSatuOrmawa(org, () {
                                    setSheetState(() {});
                                  });
                                },
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

  void _dialogEditSatuOrmawa(KategoriOrmawa org, VoidCallback onUpdated) {
    final textCtrl = TextEditingController(text: _getNama(org));
    Color warnaSementara = _getWarna(org);
    final tema = _tema;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: tema.kartu,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: warnaSementara.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: warnaSementara,
                    radius: 14,
                    child: Icon(org.ikon, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Edit ${org.kategori}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: textCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nama Organisasi / UKM',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: warnaSementara,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Pilih Warna Identitas:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: warnaSementara,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            formatKodeHex(warnaSementara),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: warnaSementara,
                            side: BorderSide(
                              color: warnaSementara.withValues(alpha: 0.7),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.colorize_rounded, size: 16),
                          label: const Text(
                            'Warna Bebas',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            final hasil = await tampilkanPemilihWarna(
                              ctx,
                              warnaAwal: warnaSementara,
                              warnaKartu: tema.kartu,
                              judul: 'Warna ${_getNama(org)}',
                            );
                            if (hasil != null) {
                              setDialogState(() => warnaSementara = hasil);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: paletWarnaCepat.map((c) {
                        final isSelected =
                            c.toARGB32() == warnaSementara.toARGB32();
                        return GestureDetector(
                          onTap: () => setDialogState(() => warnaSementara = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: c.withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warnaSementara,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      if (textCtrl.text.trim().isNotEmpty) {
                        _labelOrmawa[org] = textCtrl.text.trim();
                      }
                      _warnaOrmawa[org] = warnaSementara;
                    });
                    _simpanKustomisasiOrmawa();
                    onUpdated();
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Simpan Perubahan',
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

  // Modal Form Tambah / Edit Agenda Kegiatan
  void _bukaDialogFormAgenda({AgendaAcara? agendaUntukDiedit}) {
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
    KategoriOrmawa ormawaTerpilih =
        agendaUntukDiedit?.ormawa ?? (_selectedFilter ?? KategoriOrmawa.senat);
    final tema = _tema;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final warnaAktif = _getWarna(ormawaTerpilih);
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
                      DropdownButtonFormField<KategoriOrmawa>(
                        initialValue: ormawaTerpilih,
                        dropdownColor: tema.latar2,
                        decoration: InputDecoration(
                          labelText: 'Penyelenggara / Ormawa',
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: KategoriOrmawa.values.map((org) {
                          final c = _getWarna(org);
                          return DropdownMenuItem(
                            value: org,
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
                                Text(
                                  _getNama(org),
                                  style: TextStyle(
                                    color: c,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => ormawaTerpilih = val);
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
                      setState(() {
                        if (agendaUntukDiedit == null) {
                          _semuaAgenda.add(
                            AgendaAcara(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              judul: judulCtrl.text.trim(),
                              deskripsi: deskripsiCtrl.text.trim(),
                              waktu: tanggalTerpilih,
                              lokasi: lokasiCtrl.text.trim(),
                              ormawa: ormawaTerpilih,
                            ),
                          );
                        } else {
                          agendaUntukDiedit.judul = judulCtrl.text.trim();
                          agendaUntukDiedit.deskripsi = deskripsiCtrl.text
                              .trim();
                          agendaUntukDiedit.waktu = tanggalTerpilih;
                          agendaUntukDiedit.lokasi = lokasiCtrl.text.trim();
                          agendaUntukDiedit.ormawa = ormawaTerpilih;
                        }
                      });
                      Navigator.pop(context);
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
                      Container(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KALENDER ORMAWA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'Senat • BEM • HMPS • 7 UKM • 2 UKK',
                              style: TextStyle(
                                color: tema.aksen,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tombol Kustomisasi Tema, Nama & Warna
                      InkWell(
                        onTap: _bukaPanelKustomisasi,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tema.aksen.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.palette_outlined,
                                color: tema.aksen,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Tampilan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Baris Chip Organisasi Berwarna Jelas
                _buildColoredFilterBar(tema),

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
                            final c = _getWarna(event.ormawa);
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
                    ],
                  ),
                ),

                // Daftar Kartu Agenda Berwarna
                Expanded(
                  child: agendaTerpilih.isEmpty
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
                              const Text(
                                'Belum ada jadwal kegiatan di tanggal ini.\nKetuk tombol + Agenda di bawah untuk membuat jadwal.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
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
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaDialogFormAgenda(),
        backgroundColor: tema.aksen,
        foregroundColor: tema.latar1,
        elevation: 6,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text(
          'Tambah Agenda',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  // Baris Filter Organisasi dengan Warna Menyala & Kontras Jelas
  Widget _buildColoredFilterBar(PengaturanWarna tema) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: KategoriOrmawa.values.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isAll = _selectedFilter == null;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = null),
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

          final org = KategoriOrmawa.values[index - 1];
          final isSelected = _selectedFilter == org;
          final warna = _getWarna(org);
          final nama = _getNama(org);

          return GestureDetector(
            onTap: () =>
                setState(() => _selectedFilter = isSelected ? null : org),
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
    final warna = _getWarna(item.ormawa);
    final namaOrmawa = _getNama(item.ormawa);

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
                                  item.ormawa.ikon,
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
                            item.ormawa.kategori,
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
                  InkWell(
                    onTap: () => _bukaDialogFormAgenda(agendaUntukDiedit: item),
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
