import 'dart:convert';

import 'package:berdua/features/laporan/laporan_cubit.dart';
import 'package:berdua/features/siklus/siklus_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Backend PHP menuliskan peta kosong sebagai `[]`. Dulu itu membuat laporan
  // bulan tanpa pengeluaran gagal dimuat.
  test('laporan bulan tanpa pengeluaran terbaca sebagai kosong', () {
    final json =
        jsonDecode(
              '{"year":2026,"month":10,"total":0,"previous_total":0,"delta":0,'
              '"budget":null,"budget_pct":null,"by_category":[],"by_payer":[],'
              '"by_week":[],"largest":[],"transaction_count":0}',
            )
            as Map<String, dynamic>;

    final laporan = Laporan.fromJson(json);

    expect(laporan.kosong, isTrue);
    expect(laporan.perKategori, isEmpty);
    expect(laporan.perPembayar, isEmpty);
    expect(laporan.perMinggu, isEmpty);
  });

  test('riwayat siklus tanpa gejala terbaca sebagai kosong', () {
    final json =
        jsonDecode('{"cycles":[],"frequent_symptoms":[]}')
            as Map<String, dynamic>;

    expect(RiwayatSiklus.fromJson(json).gejalaSering, isEmpty);
  });
}
