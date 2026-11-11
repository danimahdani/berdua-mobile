import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/muatan.dart';
import '../beranda/beranda_cubit.dart';

/// Satu sel kalender siklus (§16: sel 40 dp dengan warna fase).
class HariSiklus {
  const HariSiklus({
    required this.tanggal,
    required this.fase,
    required this.hariKe,
    required this.perkiraan,
    required this.hariIni,
  });

  factory HariSiklus.fromJson(Map<String, dynamic> json) => HariSiklus(
    tanggal: DateTime.parse(json['date'] as String),
    fase: json['phase'] as String,
    hariKe: json['day_of_cycle'] as int? ?? 0,
    perkiraan: json['predicted'] as bool? ?? false,
    hariIni: json['is_today'] as bool? ?? false,
  );

  final DateTime tanggal;
  final String fase;
  final int hariKe;

  /// true = siklus hasil perkiraan, bukan yang sudah dicatat.
  final bool perkiraan;
  final bool hariIni;
}

class TipsDukungan {
  const TipsDukungan({
    required this.ringkasan,
    required this.tips,
    required this.perluDitinjau,
  });

  factory TipsDukungan.fromJson(Map<String, dynamic> json) => TipsDukungan(
    ringkasan: json['ringkasan'] as String? ?? '',
    tips: (json['tips'] as List<dynamic>? ?? []).cast<String>(),
    perluDitinjau: json['perlu_ditinjau'] as bool? ?? false,
  );

  final String ringkasan;
  final List<String> tips;

  /// §11 dokumen: tips belum ditinjau tenaga kesehatan.
  final bool perluDitinjau;
}

/// Keadaan layar 13/14. Tiga bentuk: belum ada catatan, belum dibagikan,
/// atau data lengkap.
class Siklus {
  const Siklus({
    required this.tercatat,
    required this.dibagikan,
    required this.ownerName,
    this.bisaUbah = false,
    this.hariKe = 0,
    this.fase = '',
    this.hariSampaiHaid = 0,
    this.rataRataPanjang = 0,
    this.rataRataLamaHaid = 0,
    this.teratur,
    this.siklusTercatat = 0,
    this.gejalaHariIni = const [],
    this.kalender = const [],
    this.tips,
    this.pesan = '',
    this.disclaimer = '',
  });

  factory Siklus.fromJson(Map<String, dynamic> json) {
    final tercatat = json['tracked'] as bool? ?? false;
    final dibagikan = json['shared'] as bool? ?? false;

    if (!tercatat || !dibagikan) {
      return Siklus(
        tercatat: tercatat,
        dibagikan: dibagikan,
        ownerName: json['owner_name'] as String? ?? '',
        pesan: json['message'] as String? ?? '',
      );
    }

    return Siklus(
      tercatat: true,
      dibagikan: true,
      ownerName: json['owner_name'] as String? ?? '',
      bisaUbah: json['can_edit'] as bool? ?? false,
      hariKe: json['day_of_cycle'] as int? ?? 0,
      fase: json['phase'] as String? ?? '',
      hariSampaiHaid: json['days_until_next_period'] as int? ?? 0,
      rataRataPanjang: (json['average_length'] as num?)?.toDouble() ?? 0,
      rataRataLamaHaid:
          (json['average_period_length'] as num?)?.toDouble() ?? 0,
      teratur: json['is_regular'] as bool?,
      siklusTercatat: json['cycles_recorded'] as int? ?? 0,
      gejalaHariIni: (json['symptoms_today'] as List<dynamic>? ?? [])
          .cast<String>(),
      kalender: (json['calendar'] as List<dynamic>? ?? [])
          .map((e) => HariSiklus.fromJson(e as Map<String, dynamic>))
          .toList(),
      tips: json['tips'] == null
          ? null
          : TipsDukungan.fromJson(json['tips'] as Map<String, dynamic>),
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }

  final bool tercatat;
  final bool dibagikan;
  final String ownerName;
  final bool bisaUbah;
  final int hariKe;
  final String fase;
  final int hariSampaiHaid;
  final double rataRataPanjang;
  final double rataRataLamaHaid;
  final bool? teratur;
  final int siklusTercatat;
  final List<String> gejalaHariIni;
  final List<HariSiklus> kalender;
  final TipsDukungan? tips;
  final String pesan;
  final String disclaimer;

  String get faseLabel =>
      fase.isEmpty ? '' : 'Fase ${fase[0].toUpperCase()}${fase.substring(1)}';
}

/// Satu baris riwayat pada layar 15.
class SiklusLalu {
  const SiklusLalu({
    required this.mulai,
    required this.panjangSiklus,
    required this.lamaHaid,
  });

  factory SiklusLalu.fromJson(Map<String, dynamic> json) => SiklusLalu(
    mulai: DateTime.parse(json['period_start'] as String),
    panjangSiklus: json['cycle_length'] as int?,
    lamaHaid: json['period_length'] as int?,
  );

  final DateTime mulai;

  /// null untuk siklus terbaru: panjangnya baru diketahui setelah haid berikutnya.
  final int? panjangSiklus;
  final int? lamaHaid;
}

class RiwayatSiklus {
  const RiwayatSiklus({
    required this.siklus,
    required this.rataRataPanjang,
    required this.rataRataLamaHaid,
    required this.teratur,
    required this.jumlahTercatat,
    required this.gejalaSering,
  });

  factory RiwayatSiklus.fromJson(Map<String, dynamic> json) => RiwayatSiklus(
    siklus: (json['cycles'] as List<dynamic>? ?? [])
        .map((e) => SiklusLalu.fromJson(e as Map<String, dynamic>))
        .toList(),
    rataRataPanjang: (json['average_length'] as num?)?.toDouble() ?? 0,
    rataRataLamaHaid: (json['average_period_length'] as num?)?.toDouble() ?? 0,
    teratur: json['is_regular'] as bool?,
    jumlahTercatat: json['cycles_recorded'] as int? ?? 0,
    gejalaSering: (json['frequent_symptoms'] as Map<String, dynamic>? ?? {})
        .map((key, value) => MapEntry(key, value as int)),
  );

  final List<SiklusLalu> siklus;
  final double rataRataPanjang;
  final double rataRataLamaHaid;
  final bool? teratur;
  final int jumlahTercatat;
  final Map<String, int> gejalaSering;
}

class SiklusCubit extends MuatanCubit<Siklus> {
  SiklusCubit(this._dio, this._beranda);

  final Dio _dio;
  final BerandaCubit _beranda;

  @override
  Future<Siklus> ambil() async {
    final data = await _dio.send('GET', '/cycle');

    return Siklus.fromJson(data);
  }

  /// "Haid mulai hari ini" di layar 13.
  Future<void> tandaiHaidMulai() async {
    await _dio.send('POST', '/cycle/period');
    await _segarkan();
  }

  /// "Bagaimana rasanya hari ini?" — mengirim daftar lengkap, bukan selisih.
  Future<void> simpanGejala(List<String> gejala) async {
    await _dio.send('PUT', '/cycle/symptoms', body: {'symptoms': gejala});

    await _segarkan();
  }

  Future<void> _segarkan() async {
    await segarkan();

    // Kartu siklus di layar 06 ikut berubah.
    _beranda.segarkan();
  }
}

/// Layar 15.
class RiwayatSiklusCubit extends MuatanCubit<RiwayatSiklus> {
  RiwayatSiklusCubit(this._dio);

  final Dio _dio;

  @override
  Future<RiwayatSiklus> ambil() async {
    final data = await _dio.send('GET', '/cycle/history');

    return RiwayatSiklus.fromJson(data);
  }
}
