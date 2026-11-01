import 'package:flutter/material.dart';

import 'pengaturan_warna.dart';

/// Palet warna cepat yang tersedia di seluruh aplikasi.
const List<Color> paletWarnaCepat = [
  Color(0xFFEF4444), // Red
  Color(0xFFF43F5E), // Rose
  Color(0xFFEC4899), // Pink
  Color(0xFFD946EF), // Fuchsia
  Color(0xFFA855F7), // Purple
  Color(0xFF8B5CF6), // Violet
  Color(0xFF6366F1), // Indigo
  Color(0xFF3B82F6), // Blue
  Color(0xFF0EA5E9), // Sky
  Color(0xFF06B6D4), // Cyan
  Color(0xFF14B8A6), // Teal
  Color(0xFF10B981), // Emerald
  Color(0xFF22C55E), // Green
  Color(0xFF84CC16), // Lime
  Color(0xFFEAB308), // Yellow
  Color(0xFFF59E0B), // Amber / Gold
  Color(0xFFF97316), // Orange
  Color(0xFF64748B), // Slate
];

String formatKodeHex(Color warna) {
  final rgb = warna.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Color? uraiKodeHex(String teks) {
  var bersih = teks.trim().replaceAll('#', '');
  if (bersih.length == 8) bersih = bersih.substring(2);
  if (bersih.length != 6) return null;
  final nilai = int.tryParse(bersih, radix: 16);
  if (nilai == null) return null;
  return Color(0xFF000000 | nilai);
}

/// Menampilkan dialog pemilih warna bebas (kotak HSV, slider hue, dan kode hex).
Future<Color?> tampilkanPemilihWarna(
  BuildContext context, {
  required Color warnaAwal,
  required PengaturanWarna tema,
  String judul = 'Pilih Warna',
}) {
  return showDialog<Color>(
    context: context,
    builder: (_) => _DialogPemilihWarna(
      warnaAwal: warnaAwal,
      tema: tema,
      judul: judul,
    ),
  );
}

class _DialogPemilihWarna extends StatefulWidget {
  const _DialogPemilihWarna({
    required this.warnaAwal,
    required this.tema,
    required this.judul,
  });

  final Color warnaAwal;
  final PengaturanWarna tema;
  final String judul;

  @override
  State<_DialogPemilihWarna> createState() => _DialogPemilihWarnaState();
}

class _DialogPemilihWarnaState extends State<_DialogPemilihWarna> {
  late HSVColor _hsv;
  late final TextEditingController _hexCtrl;
  final FocusNode _fokusHex = FocusNode();
  bool _hexTidakValid = false;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.warnaAwal);
    _hexCtrl = TextEditingController(text: formatKodeHex(_warna));
    _fokusHex.addListener(_saatFokusHexBerubah);
  }

  @override
  void dispose() {
    _fokusHex.removeListener(_saatFokusHexBerubah);
    _fokusHex.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  Color get _warna => _hsv.toColor();

  void _saatFokusHexBerubah() {
    if (!_fokusHex.hasFocus && mounted) {
      setState(() {
        _hexCtrl.text = formatKodeHex(_warna);
        _hexTidakValid = false;
      });
    }
  }

  void _aturWarna(HSVColor baru) {
    setState(() {
      _hsv = baru;
      _hexTidakValid = false;
      _hexCtrl.text = formatKodeHex(_warna);
    });
  }

  void _ubahHex(String teks) {
    final hasil = uraiKodeHex(teks);
    setState(() {
      _hexTidakValid = hasil == null;
      if (hasil != null) _hsv = HSVColor.fromColor(hasil);
    });
  }

  void _aturDariKotakSV(Offset posisi, Size ukuran) {
    final saturasi = (posisi.dx / ukuran.width).clamp(0.0, 1.0);
    final nilai = (1 - posisi.dy / ukuran.height).clamp(0.0, 1.0);
    _aturWarna(_hsv.withSaturation(saturasi).withValue(nilai));
  }

  void _aturDariBarHue(Offset posisi, double lebar) {
    final hue = (posisi.dx / lebar).clamp(0.0, 0.999) * 360;
    _aturWarna(_hsv.withHue(hue));
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;
    final lebar = (MediaQuery.sizeOf(context).width - 112).clamp(200.0, 320.0);
    final tinggiSV = lebar / 2.4;
    final warnaTeksTombol =
        ThemeData.estimateBrightnessForColor(_warna) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);

    return AlertDialog(
      backgroundColor: tema.kartu,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: _warna.withValues(alpha: 0.6), width: 1.5),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _warna,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _warna.withValues(alpha: 0.5), blurRadius: 10),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.judul,
              style: TextStyle(
                color: tema.teks,
                fontSize: 17,
                fontWeight: FontWeight.bold,
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
              SizedBox(
                width: lebar,
                height: tinggiSV,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (detail) => _aturDariKotakSV(
                    detail.localPosition,
                    Size(lebar, tinggiSV),
                  ),
                  onPanUpdate: (detail) => _aturDariKotakSV(
                    detail.localPosition,
                    Size(lebar, tinggiSV),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CustomPaint(
                      painter: _LukisKotakSV(
                        hue: _hsv.hue,
                        saturasi: _hsv.saturation,
                        nilai: _hsv.value,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: lebar,
                height: 26,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (detail) =>
                      _aturDariBarHue(detail.localPosition, lebar),
                  onPanUpdate: (detail) =>
                      _aturDariBarHue(detail.localPosition, lebar),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: CustomPaint(painter: _LukisBarHue(hue: _hsv.hue)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hexCtrl,
                focusNode: _fokusHex,
                style: TextStyle(
                  color: tema.teks,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Kode Hex',
                  labelStyle: TextStyle(color: tema.teksLembut),
                  helperText: 'Contoh: #F59E0B',
                  helperStyle: TextStyle(
                    color: tema.teksRedup,
                    fontSize: 11,
                  ),
                  errorText: _hexTidakValid ? 'Format harus #RRGGBB' : null,
                  filled: true,
                  fillColor: tema.isian,
                  prefixIcon: Icon(
                    Icons.tag_rounded,
                    size: 18,
                    color: tema.teksRedup,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: tema.garis),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _warna, width: 2),
                  ),
                ),
                onChanged: _ubahHex,
              ),
              const SizedBox(height: 18),
              Text(
                'Palet cepat',
                style: TextStyle(
                  color: tema.teksLembut,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: paletWarnaCepat.map((warna) {
                  final terpilih = warna.toARGB32() == _warna.toARGB32();
                  return GestureDetector(
                    onTap: () => _aturWarna(HSVColor.fromColor(warna)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: warna,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: terpilih ? Colors.white : tema.garis,
                          width: terpilih ? 2.5 : 1,
                        ),
                      ),
                      child: terpilih
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
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
            backgroundColor: _warna,
            foregroundColor: warnaTeksTombol,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(context, _warna),
          child: const Text(
            'Pilih Warna',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _LukisKotakSV extends CustomPainter {
  _LukisKotakSV({
    required this.hue,
    required this.saturasi,
    required this.nilai,
  });

  final double hue;
  final double saturasi;
  final double nilai;

  @override
  void paint(Canvas canvas, Size size) {
    final kotak = Offset.zero & size;
    final warnaHue = HSVColor.fromAHSV(1, hue, 1, 1).toColor();

    canvas.drawRect(
      kotak,
      Paint()
        ..shader = LinearGradient(colors: [Colors.white, warnaHue])
            .createShader(kotak),
    );
    canvas.drawRect(
      kotak,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(kotak),
    );

    final posisi = Offset(saturasi * size.width, (1 - nilai) * size.height);
    canvas.drawCircle(
      posisi,
      10,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      posisi,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _LukisKotakSV lama) {
    return lama.hue != hue || lama.saturasi != saturasi || lama.nilai != nilai;
  }
}

class _LukisBarHue extends CustomPainter {
  _LukisBarHue({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    const jumlahGaris = 60;
    final lebarGaris = size.width / jumlahGaris;

    for (var i = 0; i < jumlahGaris; i++) {
      final warna = HSVColor.fromAHSV(1, i * 360 / jumlahGaris, 1, 1).toColor();
      canvas.drawRect(
        Rect.fromLTWH(i * lebarGaris, 0, lebarGaris + 0.6, size.height),
        Paint()..color = warna,
      );
    }

    final x = (hue / 360).clamp(0.0, 0.999) * size.width;
    final pusat = Offset(x, size.height / 2);
    canvas.drawCircle(
      pusat,
      10,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      pusat,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _LukisBarHue lama) => lama.hue != hue;
}
