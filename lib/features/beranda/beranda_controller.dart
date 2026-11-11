import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
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
          (json['belanja'] as Map<String, dynamic>)['belum_dibeli'] as int? ?? 0,
      todoTerbuka:
          (json['todo'] as Map<String, dynamic>)['terbuka'] as int? ?? 0,
      jadwalTerdekat: json['jadwal_terdekat'] == null
          ? null
          : Jadwal.fromJson(json['jadwal_terdekat'] as Map<String, dynamic>),
      tabungan: json['tabungan_utama'] == null
          ? null
          : Tabungan.fromJson(json['tabungan_utama'] as Map<String, dynamic>),
      notifikasiBelumDibaca: json['notifikasi_belum_dibaca'] as int? ?? 0,
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

  bool get lunas => balance == 0;

  String get kalimatUtang {
    if (lunas) return 'Tidak ada utang';

    return balance > 0 ? 'Kamu berutang ke pasangan' : 'Pasangan berutang ke kamu';
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
      gejalaHariIni:
          (json['symptoms_today'] as List<dynamic>? ?? []).cast<String>(),
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

class BerandaController extends AsyncNotifier<Beranda> {
  @override
  Future<Beranda> build() async {
    final data = await ref.read(dioProvider).send('GET', '/beranda');

    return Beranda.fromJson(data);
  }

  Future<void> segarkan() async {
    // Sengaja TIDAK menyetel AsyncValue.loading() di sini: isi lama
    // bertahan di layar selama permintaan berjalan, sehingga penambahan
    // kecil tidak membuat seluruh daftar berkedip jadi kerangka.
    // Kerangka hanya untuk pemuatan pertama; tombol yang menekan aksi
    // sudah menampilkan indikatornya sendiri.
    state = await AsyncValue.guard(build);
  }
}

final berandaProvider = AsyncNotifierProvider<BerandaController, Beranda>(
  BerandaController.new,
);
