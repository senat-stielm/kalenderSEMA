import 'package:flutter/material.dart';

import 'dialog_admin.dart';
import 'model_ormawa.dart';
import 'pemilih_warna.dart';
import 'pengaturan_warna.dart';

/// Dialog tambah/ubah ormawa, UKM, atau UKK.
class DialogOrmawa extends StatefulWidget {
  const DialogOrmawa({super.key, required this.tema, this.awal});

  final PengaturanWarna tema;
  final Ormawa? awal;

  @override
  State<DialogOrmawa> createState() => _DialogOrmawaState();
}

class _DialogOrmawaState extends State<DialogOrmawa> {
  late final TextEditingController _namaCtrl;
  late String _kategori;
  late Color _warna;
  late String _ikonKunci;
  String? _galat;

  bool get _modeUbah => widget.awal != null;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.awal?.nama ?? '');
    _kategori = widget.awal?.kategori ?? 'UKM';
    _warna = widget.awal?.warna ?? const Color(0xFF3B82F6);
    _ikonKunci = widget.awal?.ikonKunci ?? 'groups';
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) {
      setState(() => _galat = 'Nama organisasi wajib diisi.');
      return;
    }

    final hasil = Ormawa(
      id: widget.awal?.id ?? 'ormawa-${DateTime.now().microsecondsSinceEpoch}',
      nama: nama,
      kategori: _kategori,
      warna: _warna,
      ikonKunci: _ikonKunci,
    );
    Navigator.pop(context, hasil);
  }

  Future<void> _pilihWarnaBebas() async {
    final hasil = await tampilkanPemilihWarna(
      context,
      warnaAwal: _warna,
      warnaKartu: widget.tema.kartu,
      judul:
          'Warna ${_namaCtrl.text.trim().isEmpty ? 'Ormawa' : _namaCtrl.text.trim()}',
    );
    if (hasil != null && mounted) {
      setState(() => _warna = hasil);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;
    final lebar = (MediaQuery.sizeOf(context).width - 96).clamp(240.0, 360.0);

    return AlertDialog(
      backgroundColor: tema.kartu,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: _warna.withValues(alpha: 0.6), width: 1.5),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: _warna,
            radius: 18,
            child: Icon(
              ikonDariKunci(_ikonKunci),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _modeUbah ? 'Ubah Ormawa' : 'Tambah Ormawa',
              style: const TextStyle(
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
              TextField(
                controller: _namaCtrl,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                decoration: dekorasiFieldAdmin(
                  tema,
                  'Nama Organisasi',
                  Icons.badge_rounded,
                ),
                onChanged: (_) {
                  if (_galat != null) setState(() => _galat = null);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: daftarKategoriOrmawa.contains(_kategori)
                    ? _kategori
                    : 'Lainnya',
                dropdownColor: tema.latar2,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: dekorasiFieldAdmin(
                  tema,
                  'Jenis Organisasi',
                  Icons.category_rounded,
                ),
                items: daftarKategoriOrmawa
                    .map(
                      (kategori) => DropdownMenuItem(
                        value: kategori,
                        child: Text(
                          kategori,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (nilai) {
                  if (nilai != null) setState(() => _kategori = nilai);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Warna Identitas',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _warna,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      formatKodeHex(_warna),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _warna,
                      side: BorderSide(color: _warna.withValues(alpha: 0.7)),
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
                    onPressed: _pilihWarnaBebas,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: paletWarnaCepat.map((warna) {
                  final terpilih = warna.toARGB32() == _warna.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _warna = warna),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: warna,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: terpilih ? Colors.white : Colors.transparent,
                          width: 2.5,
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
              const SizedBox(height: 16),
              const Text(
                'Ikon',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: daftarIkonOrmawa.map((pilihan) {
                  final terpilih = pilihan.kunci == _ikonKunci;
                  return Tooltip(
                    message: pilihan.label,
                    child: GestureDetector(
                      onTap: () => setState(() => _ikonKunci = pilihan.kunci),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: terpilih
                              ? _warna
                              : Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: terpilih ? Colors.white : Colors.white24,
                            width: terpilih ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          pilihan.ikon,
                          size: 20,
                          color: terpilih ? Colors.white : Colors.white60,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_galat != null) ...[
                const SizedBox(height: 12),
                Text(
                  _galat!,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
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
          child: const Text('Batal', style: TextStyle(color: Colors.white60)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _warna,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _simpan,
          child: Text(
            _modeUbah ? 'Simpan Perubahan' : 'Tambah',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
