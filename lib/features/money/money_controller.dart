import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';

/// Filter segmen pada layar 08: Semua / salah satu pihak.
class FilterUang {
  const FilterUang({this.payerId});

  final int? payerId;

  bool get semua => payerId == null;
}

/// Riverpod 3 tidak lagi menyediakan StateProvider, jadi filter disimpan
/// dalam Notifier kecil.
class FilterUangController extends Notifier<FilterUang> {
  @override
  FilterUang build() => const FilterUang();

  void pilih(int? payerId) => state = FilterUang(payerId: payerId);
}

final filterUangProvider =
    NotifierProvider<FilterUangController, FilterUang>(
  FilterUangController.new,
);

class UangController extends AsyncNotifier<RingkasanUang> {
  @override
  Future<RingkasanUang> build() async {
    final filter = ref.watch(filterUangProvider);

    final data = await ref.read(dioProvider).send(
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
    await ref.read(dioProvider).send(
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
    await ref.read(dioProvider).send(
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
    await ref.read(dioProvider).send('DELETE', '/transactions/$id');
    await _segarkan();
  }

  /// Tandai lunas (§5.2): backend yang membuat transaksi pelunasannya.
  Future<void> tandaiLunas() async {
    await ref.read(dioProvider).send('POST', '/transactions/settle');
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
      'date': '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
    };
  }

  /// Muat ulang daftar, lalu selaraskan saldo di beranda lewat profil.
  Future<void> _segarkan() async {
    // Sengaja TIDAK menyetel AsyncValue.loading() di sini: isi lama
    // bertahan di layar selama permintaan berjalan, sehingga penambahan
    // kecil tidak membuat seluruh daftar berkedip jadi kerangka.
    // Kerangka hanya untuk pemuatan pertama; tombol yang menekan aksi
    // sudah menampilkan indikatornya sendiri.
    state = await AsyncValue.guard(build);

    // Saldo juga tampil di layar 06; ambil ulang supaya tidak basi.
    await ref.read(sesiProvider.notifier).muatProfil();
  }
}

final uangProvider = AsyncNotifierProvider<UangController, RingkasanUang>(
  UangController.new,
);
