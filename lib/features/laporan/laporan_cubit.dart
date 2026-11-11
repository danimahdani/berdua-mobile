import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../core/muatan.dart';

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
class BulanLaporanCubit extends Cubit<DateTime> {
  BulanLaporanCubit()
    : super(DateTime(DateTime.now().year, DateTime.now().month));

  void mundur() => emit(DateTime(state.year, state.month - 1));

  void maju() {
    final sekarang = DateTime.now();
    final berikutnya = DateTime(state.year, state.month + 1);

    // Tidak ada gunanya melihat bulan yang belum terjadi.
    if (berikutnya.isAfter(DateTime(sekarang.year, sekarang.month))) return;

    emit(berikutnya);
  }

  bool get bisaMaju {
    final sekarang = DateTime.now();

    return state.isBefore(DateTime(sekarang.year, sekarang.month));
  }
}

/// Laporan untuk bulan di [BulanLaporanCubit]; dimuat ulang tiap bulannya
/// berganti, dengan isi bulan sebelumnya bertahan selama bulan baru dimuat.
class LaporanCubit extends MuatanCubit<Laporan> {
  LaporanCubit(this._dio, this._bulan) {
    _langganan = _bulan.stream.listen((_) => segarkan());
  }

  final Dio _dio;
  final BulanLaporanCubit _bulan;
  late final StreamSubscription<DateTime> _langganan;

  @override
  Future<Laporan> ambil() async {
    final bulan = _bulan.state;
    final kunci = '${bulan.year}-${bulan.month.toString().padLeft(2, '0')}';

    final data = await _dio.send(
      'GET',
      '/transactions/report',
      query: {'month': kunci},
    );

    return Laporan.fromJson(data);
  }

  @override
  Future<void> close() async {
    await _langganan.cancel();

    return super.close();
  }
}
