import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../core/muatan.dart';
import '../../core/rupiah.dart';
import '../../widgets/berdua_widgets.dart';
import '../money/uang_cubit.dart';

/// Pilihan rentang rata-rata pengeluaran.
enum PeriodeRataRata {
  minggu('week', 'Mingguan', 'minggu'),
  bulan('month', 'Bulanan', 'bulan'),
  tahun('year', 'Tahunan', 'tahun');

  const PeriodeRataRata(this.kawat, this.label, this.satuan);

  final String kawat;

  /// "Mingguan", untuk segmen.
  final String label;

  /// "minggu", untuk kalimat: "per minggu", "minggu ini".
  final String satuan;

  /// "Minggu ini" / "Bulan ini" / "Tahun ini".
  String get yangBerjalan => '${kapitalAwal(satuan)} ini';
}

/// Satu minggu, bulan, atau tahun beserta total pengeluarannya.
class PeriodeUang {
  const PeriodeUang({
    required this.mulai,
    required this.akhir,
    required this.total,
    required this.jumlah,
    required this.berjalan,
  });

  factory PeriodeUang.fromJson(Map<String, dynamic> json) => PeriodeUang(
    mulai: DateTime.parse(json['start'] as String),
    akhir: DateTime.parse(json['end'] as String),
    total: (json['total'] as num).toInt(),
    jumlah: (json['count'] as num?)?.toInt() ?? 0,
    berjalan: json['is_current'] == true,
  );

  final DateTime mulai;
  final DateTime akhir;
  final int total;

  /// Jumlah transaksi pengeluaran di periode ini.
  final int jumlah;

  /// Periode yang masih berjalan: angkanya belum utuh.
  final bool berjalan;

  /// Label pendek untuk sumbu grafik: "9 Nov", "Nov", "2026".
  String labelSumbu(PeriodeRataRata periode) => switch (periode) {
    PeriodeRataRata.minggu => TanggalId.short(mulai),
    PeriodeRataRata.bulan => kapitalAwal(
      TanggalId.monthBadge(mulai).toLowerCase(),
    ),
    PeriodeRataRata.tahun => '${mulai.year}',
  };

  /// Label lengkap: "9–15 Nov", "November 2026", "2026".
  String labelPanjang(PeriodeRataRata periode) => switch (periode) {
    PeriodeRataRata.minggu =>
      mulai.month == akhir.month
          ? '${mulai.day}–${TanggalId.short(akhir)}'
          : '${TanggalId.short(mulai)} – ${TanggalId.short(akhir)}',
    PeriodeRataRata.bulan => TanggalId.monthYear(mulai),
    PeriodeRataRata.tahun => '${mulai.year}',
  };
}

/// Jawaban `GET /api/transactions/average`.
class RataRata {
  const RataRata({
    required this.periode,
    required this.rataRata,
    required this.jumlahPeriode,
    required this.tanpaBerjalan,
    required this.jumlahTransaksi,
    required this.tertinggi,
    required this.terendah,
    required this.daftar,
    required this.perKategori,
  });

  factory RataRata.fromJson(Map<String, dynamic> json) {
    PeriodeUang? satu(Object? nilai) =>
        nilai is Map ? PeriodeUang.fromJson(petaJson(nilai)) : null;

    return RataRata(
      periode: PeriodeRataRata.values.firstWhere(
        (p) => p.kawat == json['period'],
        orElse: () => PeriodeRataRata.bulan,
      ),
      rataRata: (json['average'] as num?)?.toInt() ?? 0,
      jumlahPeriode: (json['averaged_periods'] as num?)?.toInt() ?? 0,
      tanpaBerjalan: json['excludes_current'] == true,
      jumlahTransaksi: (json['transaction_count'] as num?)?.toInt() ?? 0,
      tertinggi: satu(json['highest']),
      terendah: satu(json['lowest']),
      daftar: (json['periods'] as List<dynamic>? ?? [])
          .map((e) => PeriodeUang.fromJson(petaJson(e)))
          .toList(),
      perKategori: petaJson(
        json['by_category'],
      ).map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  final PeriodeRataRata periode;
  final int rataRata;

  /// Banyaknya periode yang dirata-rata.
  final int jumlahPeriode;

  /// true = periode yang masih berjalan tidak ikut dirata-rata.
  final bool tanpaBerjalan;
  final int jumlahTransaksi;
  final PeriodeUang? tertinggi;
  final PeriodeUang? terendah;

  /// Urut dari yang terlama; yang terakhir adalah periode berjalan.
  final List<PeriodeUang> daftar;

  /// Rata-rata per periode untuk tiap kategori, terurut menurun.
  final Map<String, int> perKategori;

  bool get kosong => daftar.isEmpty;

  PeriodeUang? get berjalan =>
      daftar.isNotEmpty && daftar.last.berjalan ? daftar.last : null;
}

/// Rentang yang sedang dipilih; bawaannya bulanan.
class PeriodeRataRataCubit extends Cubit<PeriodeRataRata> {
  PeriodeRataRataCubit() : super(PeriodeRataRata.bulan);

  void pilih(PeriodeRataRata periode) => emit(periode);
}

/// Rata-rata untuk rentang di [PeriodeRataRataCubit]. Dimuat ulang saat
/// rentangnya berganti dan saat daftar transaksi berubah.
class RataRataCubit extends MuatanCubit<RataRata> {
  RataRataCubit(this._dio, this._periode, UangCubit uang) {
    _langganan = [
      _periode.stream.listen((_) => segarkan()),
      uang.stream.where((s) => s.adaNilai).listen((_) => segarkan()),
    ];
  }

  final Dio _dio;
  final PeriodeRataRataCubit _periode;
  late final List<StreamSubscription<Object?>> _langganan;

  @override
  Future<RataRata> ambil() async => RataRata.fromJson(
    await _dio.send(
      'GET',
      '/transactions/average',
      query: {'period': _periode.state.kawat},
    ),
  );

  @override
  Future<void> close() async {
    for (final l in _langganan) {
      await l.cancel();
    }

    return super.close();
  }
}
