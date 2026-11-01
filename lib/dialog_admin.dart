import 'package:flutter/material.dart';

import 'auth_admin.dart';
import 'pengaturan_warna.dart';

/// Dialog untuk masuk ke mode admin.
class DialogMasukAdmin extends StatefulWidget {
  const DialogMasukAdmin({
    super.key,
    required this.authAdmin,
    required this.tema,
  });

  final AuthAdmin authAdmin;
  final PengaturanWarna tema;

  @override
  State<DialogMasukAdmin> createState() => _DialogMasukAdminState();
}

class _DialogMasukAdminState extends State<DialogMasukAdmin> {
  final TextEditingController _penggunaCtrl = TextEditingController(
    text: AuthAdmin.namaPengguna,
  );
  final TextEditingController _sandiCtrl = TextEditingController();

  bool _sandiTersembunyi = true;
  bool _memproses = false;
  String? _galat;

  @override
  void dispose() {
    _penggunaCtrl.dispose();
    _sandiCtrl.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (_memproses) return;

    setState(() {
      _memproses = true;
      _galat = null;
    });

    final berhasil = await widget.authAdmin.masuk(
      _penggunaCtrl.text,
      _sandiCtrl.text,
    );
    if (!mounted) return;

    if (berhasil) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _memproses = false;
      _galat = 'Nama pengguna atau password salah.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;

    return AlertDialog(
      backgroundColor: tema.kartu,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: tema.aksen.withValues(alpha: 0.6), width: 1.5),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [tema.aksen, tema.aksenGelap]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: tema.diAksen,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Masuk Mode Admin',
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
            'Hanya admin yang perlu masuk. Anggota lain dapat langsung melihat '
            'kalender.',
            style: TextStyle(color: tema.teksLembut, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _penggunaCtrl,
            style: TextStyle(color: tema.teks),
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: dekorasiFieldAdmin(tema, 'Nama pengguna', Icons.person),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sandiCtrl,
            obscureText: _sandiTersembunyi,
            style: TextStyle(color: tema.teks),
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => _masuk(),
            decoration: dekorasiFieldAdmin(tema, 'Password', Icons.key)
                .copyWith(
                  suffixIcon: IconButton(
                    tooltip: _sandiTersembunyi
                        ? 'Tampilkan password'
                        : 'Sembunyikan password',
                    icon: Icon(
                      _sandiTersembunyi
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: tema.teksRedup,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _sandiTersembunyi = !_sandiTersembunyi);
                    },
                  ),
                ),
          ),
          if (_galat != null) ...[
            const SizedBox(height: 12),
            Text(
              _galat!,
              style: TextStyle(
                color: tema.peringatan,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _memproses ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: tema.aksen,
            foregroundColor: tema.diAksen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _memproses ? null : _masuk,
          child: _memproses
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tema.diAksen,
                  ),
                )
              : const Text(
                  'Masuk',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}

/// Dialog untuk mengganti password admin.
class DialogUbahSandi extends StatefulWidget {
  const DialogUbahSandi({
    super.key,
    required this.authAdmin,
    required this.tema,
  });

  final AuthAdmin authAdmin;
  final PengaturanWarna tema;

  @override
  State<DialogUbahSandi> createState() => _DialogUbahSandiState();
}

class _DialogUbahSandiState extends State<DialogUbahSandi> {
  final TextEditingController _lamaCtrl = TextEditingController();
  final TextEditingController _baruCtrl = TextEditingController();
  final TextEditingController _ulangCtrl = TextEditingController();

  bool _memproses = false;
  String? _galat;

  @override
  void dispose() {
    _lamaCtrl.dispose();
    _baruCtrl.dispose();
    _ulangCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_memproses) return;

    if (_baruCtrl.text != _ulangCtrl.text) {
      setState(() => _galat = 'Konfirmasi password baru tidak sama.');
      return;
    }

    setState(() {
      _memproses = true;
      _galat = null;
    });

    final galat = await widget.authAdmin.ubahSandi(
      sandiLama: _lamaCtrl.text,
      sandiBaru: _baruCtrl.text,
    );
    if (!mounted) return;

    if (galat == null) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _memproses = false;
      _galat = galat;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.tema;

    return AlertDialog(
      backgroundColor: tema.kartu,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: tema.aksen.withValues(alpha: 0.6), width: 1.5),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [tema.aksen, tema.aksenGelap]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.password_rounded, color: tema.diAksen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ubah Password Admin',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: tema.teks,
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
              controller: _lamaCtrl,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(color: tema.teks),
              decoration: dekorasiFieldAdmin(tema, 'Password lama', Icons.key),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _baruCtrl,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(color: tema.teks),
              decoration:
                  dekorasiFieldAdmin(
                    tema,
                    'Password baru',
                    Icons.lock_reset_rounded,
                  ).copyWith(
                    helperText:
                        'Minimal ${AuthAdmin.panjangSandiMinimum} karakter',
                    helperStyle: TextStyle(
                      color: tema.teksRedup,
                      fontSize: 10,
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ulangCtrl,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => _simpan(),
              style: TextStyle(color: tema.teks),
              decoration: dekorasiFieldAdmin(
                tema,
                'Ulangi password',
                Icons.lock_reset_rounded,
              ),
            ),
            if (_galat != null) ...[
              const SizedBox(height: 12),
              Text(
                _galat!,
                style: TextStyle(
                  color: tema.peringatan,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _memproses ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: tema.aksen,
            foregroundColor: tema.diAksen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _memproses ? null : _simpan,
          child: _memproses
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tema.diAksen,
                  ),
                )
              : const Text(
                  'Simpan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}

InputDecoration dekorasiFieldAdmin(
  PengaturanWarna tema,
  String label,
  IconData ikon,
) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: tema.teksLembut),
    prefixIcon: Icon(ikon, color: tema.teksRedup, size: 20),
    filled: true,
    fillColor: tema.isian,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: tema.garis),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: tema.garis),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: tema.aksen, width: 1.6),
    ),
  );
}
