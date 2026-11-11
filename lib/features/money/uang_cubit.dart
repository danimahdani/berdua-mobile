import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../core/muatan.dart';
import '../../models/models.dart';
import '../auth/sesi_cubit.dart';

/// Filter segmen pada layar 08: Semua / salah satu pihak.
class FilterUang {
  const FilterUang({this.payerId});

  final int? payerId;

  bool get semua => payerId == null;
}

class FilterUangCubit extends Cubit<FilterUang> {
  FilterUangCubit() : super(const FilterUang());

  void pilih(int? payerId) => emit(FilterUang(payerId: payerId));
}

/// Daftar transaksi layar 08. Dimuat ulang tiap filter berganti; isi lama
/// bertahan sampai jawaban baru datang.
class UangCubit extends MuatanCubit<RingkasanUang> {
  UangCubit(this._dio, this._filter, this._sesi) {
    _langganan = _filter.stream.listen((_) => segarkan());
  }

  final Dio _dio;
  final FilterUangCubit _filter;
  final SesiCubit _sesi;
  late final StreamSubscription<FilterUang> _langganan;

  @override
  Future<void> close() async {
    await _langganan.cancel();

    return super.close();
  }

  @override
  Future<RingkasanUang> ambil() async {
    final filter = _filter.state;

    final data = await _dio.send(
      'GET',
      '/transactions',
      query: filter.payerId == null ? null : {'payer_id': filter.payerId},
    );

    return RingkasanUang.fromJson(data);
  }

  /// Layar 09: tambah pengeluaran.
  Future<void> tambah({
    required String judul,
    required String kategori,
    required int jumlah,
    required int? payerId,
    required CaraPembagian split,
    int? porsiCustom,
    DateTime? tanggal,
  }) async {
    await _dio.send(
      'POST',
      '/transactions',
      body: _payload(
        judul: judul,
        kategori: kategori,
        jumlah: jumlah,
        payerId: payerId,
        split: split,
        porsiCustom: porsiCustom,
        tanggal: tanggal,
      ),
    );

    await _segarkan();
  }

  /// Layar 11: ubah transaksi.
  Future<void> ubah({
    required int id,
    required String judul,
    required String kategori,
    required int jumlah,
    required int? payerId,
    required CaraPembagian split,
    int? porsiCustom,
    DateTime? tanggal,
  }) async {
    await _dio.send(
      'PATCH',
      '/transactions/$id',
      body: _payload(
        judul: judul,
        kategori: kategori,
        jumlah: jumlah,
        payerId: payerId,
        split: split,
        porsiCustom: porsiCustom,
        tanggal: tanggal,
      ),
    );

    await _segarkan();
  }

  Future<void> hapus(int id) async {
    await _dio.send('DELETE', '/transactions/$id');
    await _segarkan();
  }

  /// Tandai lunas (§5.2): backend yang membuat transaksi pelunasannya.
  Future<void> tandaiLunas() async {
    await _dio.send('POST', '/transactions/settle');
    await _segarkan();
  }

  Map<String, dynamic> _payload({
    required String judul,
    required String kategori,
    required int jumlah,
    required int? payerId,
    required CaraPembagian split,
    int? porsiCustom,
    DateTime? tanggal,
  }) {
    final date = tanggal ?? DateTime.now();

    return {
      'title': judul,
      'category': kategori,
      'amount': jumlah,
      // Dompet bersama tidak punya pembayar.
      'payer_id': split == CaraPembagian.wallet ? null : payerId,
      'split': split.wire,
      if (split == CaraPembagian.custom) 'payer_share_pct': porsiCustom,
      'date':
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
    };
  }

  /// Muat ulang daftar, lalu selaraskan saldo di beranda lewat profil.
  Future<void> _segarkan() async {
    await segarkan();

    // Saldo juga tampil di layar 06; ambil ulang supaya tidak basi.
    await _sesi.muatProfil();
  }
}
