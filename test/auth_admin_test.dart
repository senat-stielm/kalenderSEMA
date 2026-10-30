import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kalender_kemahasiswaan/auth_admin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('login memakai password bawaan', () async {
    final auth = AuthAdmin();

    expect(await auth.masuk('admin', 'Widyanurdianasenat2627'), isTrue);
    expect(await auth.masuk(' Admin ', 'Widyanurdianasenat2627'), isTrue);
    expect(await auth.masuk('admin', 'salah'), isFalse);
    expect(await auth.masuk('anggota', 'Widyanurdianasenat2627'), isFalse);
  });

  test('password dapat diubah dan disimpan sebagai hash', () async {
    final auth = AuthAdmin();
    expect(await auth.punyaSandiKhusus(), isFalse);

    expect(
      await auth.ubahSandi(sandiLama: 'salah', sandiBaru: 'RahasiaBaru1'),
      isNotNull,
    );
    expect(
      await auth.ubahSandi(
        sandiLama: 'Widyanurdianasenat2627',
        sandiBaru: 'pendk',
      ),
      isNotNull,
    );

    expect(
      await auth.ubahSandi(
        sandiLama: 'Widyanurdianasenat2627',
        sandiBaru: 'RahasiaBaru1',
      ),
      isNull,
    );
    expect(await auth.punyaSandiKhusus(), isTrue);

    expect(await auth.masuk('admin', 'Widyanurdianasenat2627'), isFalse);
    expect(await auth.masuk('admin', 'RahasiaBaru1'), isTrue);

    final prefs = await SharedPreferences.getInstance();
    final tersimpan = prefs.getString('sandi_admin_v1');
    expect(tersimpan, isNotNull);
    expect(tersimpan, isNot(contains('RahasiaBaru1')));
  });

  test('password baru harus berbeda dari password lama', () async {
    final auth = AuthAdmin();

    final galat = await auth.ubahSandi(
      sandiLama: 'Widyanurdianasenat2627',
      sandiBaru: 'Widyanurdianasenat2627',
    );
    expect(galat, isNotNull);
  });
}
