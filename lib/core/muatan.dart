import 'package:flutter_bloc/flutter_bloc.dart';

/// Keadaan data yang diambil dari backend: sedang dimuat, berisi, atau galat.
///
/// Sengaja tidak punya keadaan "memuat ulang": saat disegarkan, isi lama
/// tetap jadi keadaan sampai jawaban baru datang (lihat [MuatanCubit]).
class Muatan<T> {
  const Muatan.memuat()
    : _nilai = null,
      adaNilai = false,
      galat = null,
      jejak = null;

  const Muatan.data(T nilai)
    : _nilai = nilai,
      adaNilai = true,
      galat = null,
      jejak = null;

  const Muatan.galat(Object this.galat, [this.jejak])
    : _nilai = null,
      adaNilai = false;

  final T? _nilai;
  final bool adaNilai;
  final Object? galat;
  final StackTrace? jejak;

  /// Isi terakhir, atau null selama memuat / galat.
  T? get nilai => _nilai;

  R when<R>({
    required R Function() loading,
    required R Function(Object error, StackTrace? jejak) error,
    required R Function(T data) data,
  }) {
    if (galat != null) return error(galat!, jejak);
    if (adaNilai) return data(_nilai as T);

    return loading();
  }
}

/// Dasar cubit yang memuat satu sumber data dari backend.
///
/// Pemuatan pertama dan "Coba lagi" ([muat]) menampilkan kerangka.
/// [segarkan] sengaja TIDAK kembali ke keadaan memuat: isi lama bertahan di
/// layar selama permintaan berjalan, sehingga penambahan kecil tidak membuat
/// seluruh daftar berkedip jadi kerangka. Tombol yang menekan aksi sudah
/// menampilkan indikatornya sendiri.
abstract class MuatanCubit<T> extends Cubit<Muatan<T>> {
  MuatanCubit() : super(const Muatan.memuat()) {
    muat();
  }

  /// Nomor permintaan terakhir; jawaban dari permintaan yang sudah
  /// tersusul (mis. filter diganti cepat) dibuang.
  int _nomor = 0;

  Future<T> ambil();

  Future<void> muat() {
    emit(const Muatan.memuat());

    return _jalankan();
  }

  Future<void> segarkan() => _jalankan();

  Future<void> _jalankan() async {
    final nomor = ++_nomor;

    try {
      final nilai = await ambil();

      if (!isClosed && nomor == _nomor) emit(Muatan.data(nilai));
    } catch (error, jejak) {
      if (!isClosed && nomor == _nomor) emit(Muatan.galat(error, jejak));
    }
  }
}

/// Banyaknya baris per pemuatan pada daftar yang dimuat bertahap.
const ukuranHalaman = 10;

/// Daftar yang dimuat bertahap (gulir tanpa batas / *infinite scroll*):
/// pemuatan pertama mengambil [ukuranHalaman] baris, lalu setiap kali
/// pengguna menggulir mendekati ujung, [muatLagi] mengambil 10 berikutnya.
///
/// [ambil] memakai [kueriHalaman] dan mencatat sisa lewat [catatHalaman].
/// Menyegarkan (mis. setelah menambah data) meminta sebanyak yang sudah
/// tampil, supaya daftar tidak tiba-tiba memendek.
mixin MuatBertahap<T> on MuatanCubit<T> {
  bool _adaLagi = false;
  bool _memuatLagi = false;

  /// Masih ada baris di backend yang belum dimuat.
  bool get adaLagi => _adaLagi;

  /// Banyaknya baris yang sudah termuat di [nilai].
  int termuat(T nilai);

  /// Ambil potongan mulai [offset], lalu gabungkan ke [lama].
  Future<T> ambilLagi(T lama, int offset);

  /// Parameter `limit`/`offset` untuk permintaan daftar.
  Map<String, dynamic> kueriHalaman({int? offset}) {
    final lama = state.nilai;
    final batas = offset != null || lama == null
        ? ukuranHalaman
        : termuat(lama).clamp(ukuranHalaman, 100);

    return {'limit': batas, 'offset': offset ?? 0};
  }

  /// Baca `has_more` dari jawaban backend.
  void catatHalaman(Map<String, dynamic> json) =>
      _adaLagi = json['has_more'] as bool? ?? false;

  Future<void> muatLagi() async {
    final lama = state.nilai;

    if (_memuatLagi || !_adaLagi || lama == null) return;

    _memuatLagi = true;
    final nomor = _nomor;

    try {
      final baru = await ambilLagi(lama, termuat(lama));

      if (!isClosed && nomor == _nomor) emit(Muatan.data(baru));
    } catch (_) {
      // Dibiarkan: menggulir lagi akan mencoba ulang.
    } finally {
      _memuatLagi = false;
    }
  }
}
