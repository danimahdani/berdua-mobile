import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../core/muatan.dart';
import '../auth/sesi_cubit.dart';

/// Tab Uang menampilkan uang bersama (false) atau uang pribadi (true).
class ModeUangCubit extends Cubit<bool> {
  ModeUangCubit() : super(false);

  void pilih({required bool pribadi}) => emit(pribadi);
}

/// Satu pengeluaran pribadi. Hanya pemilik akunnya yang pernah menerimanya.
class PengeluaranPribadi {
  const PengeluaranPribadi({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.jumlah,
    required this.tanggal,
  });

  factory PengeluaranPribadi.fromJson(Map<String, dynamic> json) =>
      PengeluaranPribadi(
        id: json['id'] as int,
        judul: json['title'] as String? ?? '',
        kategori: json['category'] as String? ?? 'Lainnya',
        jumlah: (json['amount'] as num).toInt(),
        tanggal: DateTime.parse(json['date'] as String),
      );

  final int id;
  final String judul;
  final String kategori;
  final int jumlah;
  final DateTime tanggal;
}

/// Jawaban `GET /api/personal-expenses?month=YYYY-MM`.
class RingkasanPribadi {
  const RingkasanPribadi({
    required this.bulan,
    required this.daftar,
    required this.total,
    required this.totalBulanLalu,
    required this.perKategori,
    required this.rataRataBulanan,
    required this.jumlahBulanRataRata,
  });

  factory RingkasanPribadi.fromJson(Map<String, dynamic> json) {
    final bulan = DateTime.parse('${json['month']}-01');

    return RingkasanPribadi(
      bulan: DateTime(bulan.year, bulan.month),
      daftar: (json['data'] as List<dynamic>? ?? [])
          .map((e) => PengeluaranPribadi.fromJson(petaJson(e)))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalBulanLalu: (json['previous_total'] as num?)?.toInt() ?? 0,
      perKategori: petaJson(
        json['by_category'],
      ).map((k, v) => MapEntry(k, (v as num).toInt())),
      rataRataBulanan: (json['monthly_average'] as num?)?.toInt(),
      jumlahBulanRataRata: (json['averaged_months'] as num?)?.toInt() ?? 0,
    );
  }

  final DateTime bulan;

  /// Terbaru lebih dulu.
  final List<PengeluaranPribadi> daftar;
  final int total;
  final int totalBulanLalu;

  /// Terurut menurun.
  final Map<String, int> perKategori;

  /// null selama belum ada satu bulan utuh yang tercatat.
  final int? rataRataBulanan;
  final int jumlahBulanRataRata;
}

/// Bulan yang sedang dilihat di uang pribadi; tidak bisa melewati bulan ini.
class BulanPribadiCubit extends Cubit<DateTime> {
  BulanPribadiCubit()
    : super(DateTime(DateTime.now().year, DateTime.now().month));

  void mundur() => emit(DateTime(state.year, state.month - 1));

  void maju() {
    if (bisaMaju) emit(DateTime(state.year, state.month + 1));
  }

  bool get bisaMaju {
    final kini = DateTime.now();

    return state.isBefore(DateTime(kini.year, kini.month));
  }
}

/// Pengeluaran pribadi untuk bulan di [BulanPribadiCubit].
///
/// Begitu akun berganti (keluar lalu masuk dengan akun lain di perangkat
/// yang sama), isi lama dibuang dan dimuat ulang dari awal, supaya catatan
/// pribadi satu akun tidak pernah tampil untuk akun lain.
class PribadiCubit extends MuatanCubit<RingkasanPribadi> {
  PribadiCubit(this._dio, this._bulan, SesiCubit sesi)
    : _pemilik = sesi.state.user?.id {
    _langganan = [
      _bulan.stream.listen((_) => segarkan()),
      sesi.stream.listen((s) {
        final id = s.user?.id;

        if (id == _pemilik) return;

        _pemilik = id;

        if (id != null) muat();
      }),
    ];
  }

  final Dio _dio;
  final BulanPribadiCubit _bulan;
  int? _pemilik;
  late final List<StreamSubscription<Object?>> _langganan;

  @override
  Future<RingkasanPribadi> ambil() async {
    final b = _bulan.state;

    return RingkasanPribadi.fromJson(
      await _dio.send(
        'GET',
        '/personal-expenses',
        query: {'month': '${b.year}-${b.month.toString().padLeft(2, '0')}'},
      ),
    );
  }

  Map<String, dynamic> _isi({
    required String judul,
    required String kategori,
    required int jumlah,
    required DateTime tanggal,
  }) => {
    'title': judul,
    'category': kategori,
    'amount': jumlah,
    'date':
        '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-'
        '${tanggal.day.toString().padLeft(2, '0')}',
  };

  Future<void> tambah({
    required String judul,
    required String kategori,
    required int jumlah,
    required DateTime tanggal,
  }) async {
    await _dio.send(
      'POST',
      '/personal-expenses',
      body: _isi(
        judul: judul,
        kategori: kategori,
        jumlah: jumlah,
        tanggal: tanggal,
      ),
    );
    await segarkan();
  }

  Future<void> ubah({
    required int id,
    required String judul,
    required String kategori,
    required int jumlah,
    required DateTime tanggal,
  }) async {
    await _dio.send(
      'PUT',
      '/personal-expenses/$id',
      body: _isi(
        judul: judul,
        kategori: kategori,
        jumlah: jumlah,
        tanggal: tanggal,
      ),
    );
    await segarkan();
  }

  Future<void> hapus(int id) async {
    await _dio.send('DELETE', '/personal-expenses/$id');
    await segarkan();
  }

  @override
  Future<void> close() async {
    for (final l in _langganan) {
      await l.cancel();
    }

    return super.close();
  }
}
