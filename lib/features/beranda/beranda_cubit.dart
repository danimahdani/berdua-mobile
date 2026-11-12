import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/muatan.dart';
import '../../models/models.dart';

/// Isi layar 06 dalam satu muatan, sesuai endpoint `GET /api/beranda`.
class Beranda {
  const Beranda({
    required this.user,
    required this.partner,
    required this.couple,
    required this.balance,
    required this.walletBalance,
    required this.monthTotal,
    required this.siklus,
    required this.belanjaBelumDibeli,
    required this.todoTerbuka,
    required this.jadwalTerdekat,
    required this.tabungan,
    required this.notifikasiBelumDibaca,
    this.kuis,
  });

  factory Beranda.fromJson(Map<String, dynamic> json) {
    final uang = json['uang'] as Map<String, dynamic>;

    return Beranda(
      user: Pengguna.fromJson(json['user'] as Map<String, dynamic>),
      partner: json['partner'] == null
          ? null
          : Pengguna.fromJson(json['partner'] as Map<String, dynamic>),
      couple: Pasangan.fromJson(json['couple'] as Map<String, dynamic>),
      balance: uang['balance'] as int? ?? 0,
      walletBalance: uang['wallet_balance'] as int? ?? 0,
      monthTotal: uang['month_total'] as int? ?? 0,
      siklus: json['siklus'] == null
          ? null
          : RingkasanSiklus.fromJson(json['siklus'] as Map<String, dynamic>),
      belanjaBelumDibeli:
          (json['belanja'] as Map<String, dynamic>)['belum_dibeli'] as int? ??
          0,
      todoTerbuka:
          (json['todo'] as Map<String, dynamic>)['terbuka'] as int? ?? 0,
      jadwalTerdekat: json['jadwal_terdekat'] == null
          ? null
          : Jadwal.fromJson(json['jadwal_terdekat'] as Map<String, dynamic>),
      tabungan: json['tabungan_utama'] == null
          ? null
          : Tabungan.fromJson(json['tabungan_utama'] as Map<String, dynamic>),
      notifikasiBelumDibaca: json['notifikasi_belum_dibaca'] as int? ?? 0,
      kuis: json['kuis'] == null
          ? null
          : RingkasanKuis.fromJson(json['kuis'] as Map<String, dynamic>),
    );
  }

  final Pengguna user;
  final Pengguna? partner;
  final Pasangan couple;

  /// Positif = pengguna ini berutang; negatif = pasangan yang berutang.
  final int balance;
  final int walletBalance;
  final int monthTotal;
  final RingkasanSiklus? siklus;
  final int belanjaBelumDibeli;
  final int todoTerbuka;
  final Jadwal? jadwalTerdekat;
  final Tabungan? tabungan;
  final int notifikasiBelumDibaca;

  /// Kuis hari ini; null kalau bank kuis di backend kosong.
  final RingkasanKuis? kuis;

  bool get lunas => balance == 0;

  String get kalimatUtang {
    if (lunas) return 'Tidak ada utang';

    return balance > 0
        ? 'Kamu berutang ke pasangan'
        : 'Pasangan berutang ke kamu';
  }
}

/// Ringkasan siklus yang boleh dilihat pengguna ini (§5.3).
class RingkasanSiklus {
  const RingkasanSiklus({
    required this.ownerName,
    required this.dibagikan,
    required this.hariKe,
    required this.fase,
    required this.hariSampaiHaid,
    required this.rataRataPanjang,
    required this.teratur,
    required this.gejalaHariIni,
    required this.disclaimer,
  });

  factory RingkasanSiklus.fromJson(Map<String, dynamic> json) {
    return RingkasanSiklus(
      ownerName: json['owner_name'] as String? ?? '',
      // Backend mengirim {shared:false} saat pasangan belum membagikan.
      dibagikan: json['shared'] as bool? ?? true,
      hariKe: json['day_of_cycle'] as int? ?? 0,
      fase: json['phase'] as String? ?? '',
      hariSampaiHaid: json['days_until_next_period'] as int? ?? 0,
      rataRataPanjang: (json['average_length'] as num?)?.toDouble() ?? 0,
      teratur: json['is_regular'] as bool?,
      gejalaHariIni: (json['symptoms_today'] as List<dynamic>? ?? [])
          .cast<String>(),
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }

  final String ownerName;
  final bool dibagikan;
  final int hariKe;
  final String fase;
  final int hariSampaiHaid;
  final double rataRataPanjang;
  final bool? teratur;
  final List<String> gejalaHariIni;
  final String disclaimer;

  /// "Fase luteal" — fase datang dari backend dalam huruf kecil.
  String get faseLabel =>
      fase.isEmpty ? '' : 'Fase ${fase[0].toUpperCase()}${fase.substring(1)}';
}

/// Keadaan kuis hari ini untuk kartu "Kuis berdua".
class RingkasanKuis {
  const RingkasanKuis({
    required this.title,
    required this.total,
    required this.done,
    required this.partnerDone,
    required this.same,
  });

  factory RingkasanKuis.fromJson(Map<String, dynamic> json) => RingkasanKuis(
    title: json['title'] as String? ?? '',
    total: json['total'] as int? ?? 5,
    done: json['done'] as bool? ?? false,
    partnerDone: json['partner_done'] as bool? ?? false,
    same: json['same'] as int?,
  );

  final String title;
  final int total;
  final bool done;
  final bool partnerDone;

  /// Jumlah jawaban yang sama; null selama salah satu belum selesai.
  final int? same;

  /// Kalimat pada kartu beranda. [pasangan] adalah nama pasangan.
  String catatan(String pasangan) {
    if (done) {
      return same == null
          ? 'Jawabanmu sudah masuk. Menunggu $pasangan menjawab.'
          : 'Kalian selaras di $same dari $total jawaban. '
                'Lihat hasilnya dan obrolkan.';
    }

    return partnerDone
        ? '$total pertanyaan ringan hari ini. $pasangan sudah menjawab, '
              'giliranmu.'
        : '$total pertanyaan ringan hari ini. Jawab dulu, lalu bandingkan '
              'dengan $pasangan.';
  }
}

class Jadwal {
  const Jadwal({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.hariLagi,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) => Jadwal(
    id: json['id'] as int,
    title: json['title'] as String,
    type: json['type'] as String,
    date: DateTime.parse(json['date'] as String),
    hariLagi: json['days_until'] as int? ?? 0,
  );

  final int id;
  final String title;
  final String type;
  final DateTime date;
  final int hariLagi;
}

class Tabungan {
  const Tabungan({
    required this.id,
    required this.title,
    required this.target,
    required this.collected,
    required this.remaining,
    required this.perMonth,
  });

  factory Tabungan.fromJson(Map<String, dynamic> json) => Tabungan(
    id: json['id'] as int,
    title: json['title'] as String,
    target: json['target'] as int,
    collected: json['collected'] as int? ?? 0,
    remaining: json['remaining'] as int? ?? 0,
    perMonth: json['per_month'] as int?,
  );

  final int id;
  final String title;
  final int target;
  final int collected;
  final int remaining;
  final int? perMonth;

  double get progres => target == 0 ? 0 : (collected / target).clamp(0.0, 1.0);
}

/// Muatan layar 06. Cubit lain memanggil [segarkan] sesudah mengubah data
/// yang ringkasannya tampil di beranda.
class BerandaCubit extends MuatanCubit<Beranda> {
  BerandaCubit(this._dio);

  final Dio _dio;

  @override
  Future<Beranda> ambil() async {
    final data = await _dio.send('GET', '/beranda');

    return Beranda.fromJson(data);
  }
}
