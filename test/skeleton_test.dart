import 'package:berdua/theme/berdua_theme.dart';
import 'package:berdua/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kerangka dipakai di setiap perpindahan yang menunggu proses, jadi ia harus
/// aman di layar sempit maupun lebar dan tidak pernah melempar overflow.
void main() {
  Future<void> pasang(
    WidgetTester tester,
    Widget skeleton, {
    Size ukuran = const Size(411, 891),
    bool kurangiGerak = false,
  }) async {
    tester.view.physicalSize = ukuran;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: BerduaTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: ukuran,
            disableAnimations: kurangiGerak,
          ),
          child: Scaffold(body: skeleton),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
  }

  final semua = <String, Widget>{
    'beranda': const SkeletonBeranda(),
    'uang': const SkeletonUang(),
    'siklus': const SkeletonSiklus(),
    'riwayat': const SkeletonRiwayat(),
    'notifikasi': const SkeletonNotifikasi(),
    'laporan': const SkeletonLaporan(),
    'detail tabungan': const SkeletonTabunganDetail(),
    'daftar bersama': const SkeletonDaftar(),
    'pembuka': const SkeletonPembuka(),
  };

  group('kerangka terpasang tanpa galat', () {
    for (final entry in semua.entries) {
      testWidgets(entry.key, (tester) async {
        await pasang(tester, entry.value);

        expect(tester.takeException(), isNull);
        // Tidak boleh ada spinner bundar lagi di jalur pemuatan.
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    }
  });

  group('aman di layar sempit', () {
    for (final entry in semua.entries) {
      testWidgets('${entry.key} pada 320x568', (tester) async {
        await pasang(tester, entry.value, ukuran: const Size(320, 568));

        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('kilau berhenti saat pengguna meminta gerak dikurangi', (
    tester,
  ) async {
    // §7 aksesibilitas. Dengan gerak dikurangi, kerangkanya tetap tampil
    // tetapi tidak ada ShaderMask yang beranimasi.
    await pasang(tester, const SkeletonBeranda(), kurangiGerak: true);

    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byType(SkeletonBox), findsWidgets);
  });

  testWidgets('kilau berjalan saat gerak diizinkan', (tester) async {
    await pasang(tester, const SkeletonBeranda());

    expect(find.byType(ShaderMask), findsOneWidget);
  });

  testWidgets('kerangka tidak bisa digulir', (tester) async {
    // Belum ada isi apa pun di sana; menggulir kerangka hanya membingungkan.
    await pasang(tester, const SkeletonUang());

    final daftar = tester.widget<ListView>(find.byType(ListView));

    expect(daftar.physics, isA<NeverScrollableScrollPhysics>());
  });

  testWidgets('SkeletonDaftar menghormati jumlah dan tinggi baris', (
    tester,
  ) async {
    await pasang(
      tester,
      const SkeletonDaftar(baris: 3, tinggiBaris: 120),
    );

    final kartu = tester
        .widgetList<SkeletonKartu>(find.byType(SkeletonKartu))
        .toList();

    expect(kartu, hasLength(3));
    expect(kartu.every((k) => k.tinggi == 120), isTrue);
  });

  testWidgets('bagian dengan input membawa ruang input di kerangkanya', (
    tester,
  ) async {
    await pasang(tester, const SkeletonDaftar(atas: 54, baris: 2));

    // Satu kotak setinggi 54 untuk input, di atas dua kartu baris.
    final kotak = tester
        .widgetList<SkeletonBox>(find.byType(SkeletonBox))
        .where((b) => b.height == 54);

    expect(kotak, hasLength(1));
  });
}
