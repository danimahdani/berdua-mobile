import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

/// Laporan bulanan (layar 12), dari `GET /api/transactions/report`.
class Laporan {
  const Laporan({
    required this.year,
    required this.month,
    required this.total,
    required this.previousTotal,
    required this.delta,
    required this.budget,
    required this.budgetPct,
    required this.perKategori,
    required this.perPembayar,
    required this.perMinggu,
    required this.jumlahTransaksi,
  });

  factory Laporan.fromJson(Map<String, dynamic> json) {
    Map<String, int> angka(String key) =>
        (json[key] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        );

    return Laporan(
      year: json['year'] as int,
      month: json['month'] as int,
      total: json['total'] as int? ?? 0,
      previousTotal: json['previous_total'] as int? ?? 0,
      delta: json['delta'] as int? ?? 0,
      budget: json['budget'] as int?,
      budgetPct: json['budget_pct'] as int?,
      perKategori: angka('by_category'),
      perPembayar: angka('by_payer'),
      perMinggu: angka('by_week'),
      jumlahTransaksi: json['transaction_count'] as int? ?? 0,
    );
  }

  final int year;
  final int month;
  final int total;
  final int previousTotal;
  final int delta;
  final int? budget;
  final int? budgetPct;

  /// Kunci: nama kategori. Sudah terurut menurun dari backend.
  final Map<String, int> perKategori;

  /// Kunci: id pengguna sebagai teks, atau "wallet" untuk dompet bersama.
  final Map<String, int> perPembayar;

  /// Kunci: nomor minggu dalam bulan (1-5).
  final Map<String, int> perMinggu;

  final int jumlahTransaksi;

  bool get kosong => jumlahTransaksi == 0;

  bool get naik => delta > 0;

  /// Nilai terbesar, dipakai menskalakan panjang batang.
  int get kategoriTertinggi => perKategori.values.isEmpty
      ? 0
      : perKategori.values.reduce((a, b) => a > b ? a : b);
}

/// Bulan yang sedang dilihat pada layar 12.
class BulanLaporanController extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime(DateTime.now().year, DateTime.now().month);

  void mundur() => state = DateTime(state.year, state.month - 1);

  void maju() {
    final sekarang = DateTime.now();
    final berikutnya = DateTime(state.year, state.month + 1);

    // Tidak ada gunanya melihat bulan yang belum terjadi.
    if (berikutnya.isAfter(DateTime(sekarang.year, sekarang.month))) return;

    state = berikutnya;
  }

  bool get bisaMaju {
    final sekarang = DateTime.now();

    return state.isBefore(DateTime(sekarang.year, sekarang.month));
  }
}

final bulanLaporanProvider = NotifierProvider<BulanLaporanController, DateTime>(
  BulanLaporanController.new,
);

final laporanProvider = FutureProvider<Laporan>((ref) async {
  final bulan = ref.watch(bulanLaporanProvider);
  final kunci = '${bulan.year}-${bulan.month.toString().padLeft(2, '0')}';

  final data = await ref
      .read(dioProvider)
      .send('GET', '/transactions/report', query: {'month': kunci});

  return Laporan.fromJson(data);
});
