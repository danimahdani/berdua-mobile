/// Sakelar fitur yang sengaja disembunyikan sementara.
abstract final class Fitur {
  /// Dompet bersama: saldonya belum bisa diisi, jadi hanya bisa minus.
  /// Disembunyikan sampai ada fitur "isi dompet". Transaksi dompet yang sudah
  /// tercatat tetap tampil dan tetap bisa diubah.
  static const dompetBersama = false;
}
