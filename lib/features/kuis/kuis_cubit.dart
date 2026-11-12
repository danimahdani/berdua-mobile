import 'dart:ui';

import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/muatan.dart';
import '../../theme/tokens.dart';
import '../beranda/beranda_cubit.dart';

/// Warna kartu soal menurut urutannya, dipakai kalau backend tidak mengirim
/// warna yang bisa dibaca.
const _warnaSoal = <Color>[
  BerduaColors.dinda,
  BerduaColors.raka,
  BerduaColors.mintCerah,
  BerduaColors.kuning,
  BerduaColors.period,
];

Color _warna(Object? hex, int posisi) {
  final cadangan = _warnaSoal[(posisi - 1).clamp(0, 99) % _warnaSoal.length];

  if (hex is! String) return cadangan;

  final bersih = hex.replaceFirst('#', '');
  final nilai = bersih.length == 6 ? int.tryParse(bersih, radix: 16) : null;

  return nilai == null ? cadangan : Color(0xFF000000 | nilai);
}

/// Satu pertanyaan kuis beserta jawaban yang sudah boleh dilihat.
class SoalKuis {
  const SoalKuis({
    required this.id,
    required this.position,
    required this.category,
    required this.warna,
    required this.text,
    required this.options,
    required this.talk,
    required this.myChoice,
    required this.partnerChoice,
    required this.same,
  });

  factory SoalKuis.fromJson(Map<String, dynamic> json) {
    final posisi = json['position'] as int? ?? 1;

    return SoalKuis(
      id: json['id'] as int,
      position: posisi,
      category: json['category'] as String? ?? '',
      warna: _warna(json['color'], posisi),
      text: json['text'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? []).cast<String>(),
      talk: json['talk'] as String? ?? '',
      myChoice: json['my_choice'] as int?,
      partnerChoice: json['partner_choice'] as int?,
      same: json['same'] as bool?,
    );
  }

  final int id;
  final int position;
  final String category;
  final Color warna;
  final String text;
  final List<String> options;

  /// Bahan obrolan sesudah jawaban dibandingkan.
  final String talk;
  final int? myChoice;

  /// null selama pengguna ini belum selesai, atau pasangan belum menjawab.
  final int? partnerChoice;

  /// null selama salah satu belum selesai.
  final bool? same;

  String? _pilihan(int? indeks) =>
      indeks == null || indeks < 0 || indeks >= options.length
      ? null
      : options[indeks];

  String? get jawabanSaya => _pilihan(myChoice);
  String? get jawabanPasangan => _pilihan(partnerChoice);
}

/// Satu sesi kuis: kuis hari ini atau satu kuis dari riwayat.
class Kuis {
  const Kuis({
    required this.id,
    required this.date,
    required this.title,
    required this.total,
    required this.done,
    required this.partnerDone,
    required this.partnerName,
    required this.same,
    required this.questions,
  });

  factory Kuis.fromJson(Map<String, dynamic> json) => Kuis(
    id: json['id'] as int,
    date: DateTime.parse(json['date'] as String),
    title: json['title'] as String? ?? '',
    total: json['total'] as int? ?? 5,
    done: json['done'] as bool? ?? false,
    partnerDone: json['partner_done'] as bool? ?? false,
    partnerName: json['partner_name'] as String?,
    same: json['same'] as int?,
    questions: (json['questions'] as List<dynamic>? ?? [])
        .map((e) => SoalKuis.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final int id;
  final DateTime date;
  final String title;
  final int total;

  /// Pengguna ini sudah menjawab semua pertanyaan.
  final bool done;
  final bool partnerDone;
  final String? partnerName;

  /// Jumlah jawaban yang sama; null selama salah satu belum selesai.
  final int? same;
  final List<SoalKuis> questions;

  String get namaPasangan =>
      partnerName == null || partnerName!.isEmpty ? 'Pasangan' : partnerName!;
}

/// Judul kartu hasil menurut jumlah jawaban yang sama.
String judulHasilKuis(int sama) => sama >= 4
    ? 'Kalian sangat selaras'
    : (sama >= 2
          ? 'Banyak yang sama, ada yang baru'
          : 'Banyak hal baru untuk diobrolkan');

/// Satu baris pada layar riwayat.
class KuisSelesai {
  const KuisSelesai({
    required this.id,
    required this.date,
    required this.title,
    required this.total,
    required this.partnerDone,
    required this.same,
  });

  factory KuisSelesai.fromJson(Map<String, dynamic> json) => KuisSelesai(
    id: json['id'] as int,
    date: DateTime.parse(json['date'] as String),
    title: json['title'] as String? ?? '',
    total: json['total'] as int? ?? 5,
    partnerDone: json['partner_done'] as bool? ?? false,
    same: json['same'] as int?,
  );

  final int id;
  final DateTime date;
  final String title;
  final int total;
  final bool partnerDone;
  final int? same;
}

class RiwayatKuis {
  const RiwayatKuis({
    required this.count,
    required this.average,
    required this.data,
  });

  factory RiwayatKuis.fromJson(Map<String, dynamic> json) => RiwayatKuis(
    count: json['count'] as int? ?? 0,
    average: (json['average'] as num?)?.toDouble(),
    data: (json['data'] as List<dynamic>? ?? [])
        .map((e) => KuisSelesai.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final int count;

  /// Rata-rata jawaban yang sama; null kalau belum ada kuis yang dijawab
  /// berdua.
  final double? average;
  final List<KuisSelesai> data;
}

/// Riwayat kuis yang sudah diselesaikan pengguna ini.
class RiwayatKuisCubit extends MuatanCubit<RiwayatKuis> {
  RiwayatKuisCubit(this._dio);

  final Dio _dio;

  @override
  Future<RiwayatKuis> ambil() async =>
      RiwayatKuis.fromJson(await _dio.send('GET', '/quiz/history'));
}

/// Kuis hari ini. Backend memilihkan satu kuis per pasangan per tanggal.
class KuisCubit extends MuatanCubit<Kuis> {
  KuisCubit(this._dio, this._beranda, this._riwayat);

  final Dio _dio;
  final BerandaCubit _beranda;
  final RiwayatKuisCubit _riwayat;

  @override
  Future<Kuis> ambil() async {
    final data = await _dio.send('GET', '/quiz/today');

    return Kuis.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Mengirim kelima jawaban sekaligus; bermain lagi menimpa yang lama.
  Future<void> kirim(List<int> jawaban) async {
    await _dio.send('PUT', '/quiz/today/answers', body: {'answers': jawaban});
    await segarkan();

    // Kartu kuis di beranda dan daftar riwayat ikut diperbarui.
    await Future.wait([_beranda.segarkan(), _riwayat.segarkan()]);
  }
}

/// Hasil satu kuis dari riwayat; hidup selama layarnya terbuka.
class HasilKuisCubit extends MuatanCubit<Kuis> {
  HasilKuisCubit(this._dio, this.sessionId);

  final Dio _dio;
  final int sessionId;

  @override
  Future<Kuis> ambil() async {
    final data = await _dio.send('GET', '/quiz/sessions/$sessionId');

    return Kuis.fromJson(data['data'] as Map<String, dynamic>);
  }
}
