import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/muatan.dart';
import 'siklus_cubit.dart';

/// Isi catatan satu hari. Tidak berubah; ubahan dibuat lewat [salin].
class IsiCatatan {
  const IsiCatatan({
    this.aliran,
    this.catatan = '',
    this.intim,
    this.kaliIntim,
    this.puncak,
    this.pil = false,
    this.gejala = const {},
    this.suasana = const {},
    this.energi,
    this.sadari = const {},
    this.ujiOvulasi,
    this.tesHamil,
    this.lendir,
    this.berat,
    this.suhu,
  });

  factory IsiCatatan.fromJson(Map<String, dynamic> json) => IsiCatatan(
    aliran: json['flow'] as String?,
    catatan: json['note'] as String? ?? '',
    intim: json['intimacy'] as String?,
    kaliIntim: json['intimacy_count'] as int?,
    puncak: json['intimacy_climax'] as bool?,
    pil: json['pill_taken'] == true,
    gejala: _himpunan(json['symptoms']),
    suasana: _himpunan(json['moods']),
    energi: json['energy'] as String?,
    sadari: _himpunan(json['breast_exam']),
    ujiOvulasi: json['ovulation_test'] as String?,
    tesHamil: json['pregnancy_test'] as String?,
    lendir: json['cervical_mucus'] as String?,
    berat: (json['weight_kg'] as num?)?.toDouble(),
    suhu: (json['temperature_c'] as num?)?.toDouble(),
  );

  static Set<String> _himpunan(Object? nilai) =>
      nilai is List ? nilai.cast<String>().toSet() : const {};

  final String? aliran;
  final String catatan;
  final String? intim;
  final int? kaliIntim;

  /// Ada puncak (orgasme) atau tidak; null = tidak dicatat.
  final bool? puncak;
  final bool pil;
  final Set<String> gejala;
  final Set<String> suasana;
  final String? energi;
  final Set<String> sadari;
  final String? ujiOvulasi;
  final String? tesHamil;
  final String? lendir;
  final double? berat;
  final double? suhu;

  /// Fungsi, bukan nilai, untuk isian yang boleh dikosongkan kembali:
  /// `salin(aliran: () => null)` mengosongkan, sedangkan tidak menyebutnya
  /// membiarkan nilai lama.
  IsiCatatan salin({
    String? Function()? aliran,
    String? catatan,
    String? Function()? intim,
    int? Function()? kaliIntim,
    bool? Function()? puncak,
    bool? pil,
    Set<String>? gejala,
    Set<String>? suasana,
    String? Function()? energi,
    Set<String>? sadari,
    String? Function()? ujiOvulasi,
    String? Function()? tesHamil,
    String? Function()? lendir,
    double? Function()? berat,
    double? Function()? suhu,
  }) => IsiCatatan(
    aliran: aliran == null ? this.aliran : aliran(),
    catatan: catatan ?? this.catatan,
    intim: intim == null ? this.intim : intim(),
    kaliIntim: kaliIntim == null ? this.kaliIntim : kaliIntim(),
    puncak: puncak == null ? this.puncak : puncak(),
    pil: pil ?? this.pil,
    gejala: gejala ?? this.gejala,
    suasana: suasana ?? this.suasana,
    energi: energi == null ? this.energi : energi(),
    sadari: sadari ?? this.sadari,
    ujiOvulasi: ujiOvulasi == null ? this.ujiOvulasi : ujiOvulasi(),
    tesHamil: tesHamil == null ? this.tesHamil : tesHamil(),
    lendir: lendir == null ? this.lendir : lendir(),
    berat: berat == null ? this.berat : berat(),
    suhu: suhu == null ? this.suhu : suhu(),
  );

  /// Seluruh isian dikirim: backend mengganti catatan hari itu seutuhnya.
  Map<String, dynamic> toJson() => {
    'flow': aliran,
    'note': catatan.trim().isEmpty ? null : catatan.trim(),
    'intimacy': intim,
    'intimacy_count': intim == null || intim == 'tidak' ? null : kaliIntim,
    'intimacy_climax': intim == null || intim == 'tidak' ? null : puncak,
    'pill_taken': pil ? true : null,
    'symptoms': gejala.toList(),
    'moods': suasana.toList(),
    'energy': energi,
    'breast_exam': sadari.toList(),
    'ovulation_test': ujiOvulasi,
    'pregnancy_test': tesHamil,
    'cervical_mucus': lendir,
    'weight_kg': berat,
    'temperature_c': suhu,
  };
}

/// Satu tanggal di layar catatan harian.
class CatatanHari {
  const CatatanHari({
    required this.tanggal,
    required this.belumTiba,
    required this.hariKe,
    required this.fase,
    required this.peluangHamil,
    required this.perkiraan,
    required this.awalDiSini,
    required this.akhirDiSini,
    required this.bisaAkhiri,
    required this.isi,
  });

  factory CatatanHari.fromJson(Map<String, dynamic> json) {
    final haid = json['period'] as Map<String, dynamic>? ?? const {};

    return CatatanHari(
      tanggal: DateTime.parse(json['date'] as String),
      belumTiba: json['is_future'] == true,
      hariKe: json['day_of_cycle'] as int?,
      fase: json['phase'] as String?,
      peluangHamil: PeluangHamil.dariKawat(json['pregnancy_chance']),
      perkiraan: json['predicted'] == true,
      awalDiSini: haid['is_start'] == true,
      akhirDiSini: haid['is_end'] == true,
      bisaAkhiri: haid['can_end'] == true,
      isi: IsiCatatan.fromJson(
        json['log'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final DateTime tanggal;

  /// Hari yang belum tiba hanya bisa dilihat, belum bisa dicatat.
  final bool belumTiba;

  /// null selama belum ada haid yang tercatat sebelum tanggal ini.
  final int? hariKe;
  final String? fase;
  final PeluangHamil? peluangHamil;
  final bool perkiraan;

  final bool awalDiSini;
  final bool akhirDiSini;

  /// Ada haid berjalan yang bisa ditutup pada tanggal ini.
  final bool bisaAkhiri;

  final IsiCatatan isi;
}

/// "2026-11-12" untuk alamat API dan rute.
String tanggalKawat(DateTime tanggal) =>
    '${tanggal.year.toString().padLeft(4, '0')}-'
    '${tanggal.month.toString().padLeft(2, '0')}-'
    '${tanggal.day.toString().padLeft(2, '0')}';

/// Catatan harian satu tanggal. Hanya dipakai pencatat siklus.
class CatatanHariCubit extends MuatanCubit<CatatanHari> {
  CatatanHariCubit(this._dio, this._siklus, this.tanggal);

  final Dio _dio;
  final SiklusCubit _siklus;
  final DateTime tanggal;

  String get _alamat => '/cycle/days/${tanggalKawat(tanggal)}';

  @override
  Future<CatatanHari> ambil() async =>
      CatatanHari.fromJson(await _dio.send('GET', _alamat));

  Future<CatatanHari> simpan(IsiCatatan isi) =>
      _ubah(() => _dio.send('PUT', _alamat, body: isi.toJson()));

  Future<void> tandaiAwal() async {
    await _dio.send(
      'POST',
      '/cycle/period',
      body: {'period_start': tanggalKawat(tanggal)},
    );
    await _ubah(() => _dio.send('GET', _alamat));
  }

  Future<void> batalAwal() =>
      _ubah(() => _dio.send('DELETE', '$_alamat/period-start'));

  Future<void> tandaiAkhir() =>
      _ubah(() => _dio.send('PUT', '$_alamat/period-end'));

  Future<void> batalAkhir() =>
      _ubah(() => _dio.send('DELETE', '$_alamat/period-end'));

  /// Jawaban setiap ubahan adalah keadaan terbaru tanggal ini; kalender dan
  /// kartu siklus di beranda ikut diperbarui.
  Future<CatatanHari> _ubah(
    Future<Map<String, dynamic>> Function() kirim,
  ) async {
    final hasil = CatatanHari.fromJson(await kirim());

    if (!isClosed) emit(Muatan.data(hasil));

    _siklus.perbarui();

    return hasil;
  }
}
