import '../theme/tokens.dart';
import 'package:flutter/material.dart';

/// Model data mengikuti §8 dokumen proyek. Parsing manual (tanpa codegen)
/// supaya tidak perlu menjalankan build_runner untuk setiap perubahan.
class Pengguna {
  const Pengguna({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.tracksCycle,
    required this.coupleId,
    required this.needsOnboarding,
  });

  factory Pengguna.fromJson(Map<String, dynamic> json) => Pengguna(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    phoneNumber: json['phone_number'] as String? ?? '',
    email: json['email'] as String? ?? '',
    tracksCycle: json['tracks_cycle'] as bool? ?? false,
    coupleId: json['couple_id'] as int?,
    needsOnboarding: json['needs_onboarding'] as bool? ?? false,
  );

  final int id;
  final String name;
  final String phoneNumber;
  final String email;
  final bool tracksCycle;
  final int? coupleId;
  final bool needsOnboarding;

  /// Huruf pertama untuk avatar (§16 kartu daftar).
  String get initial =>
      name.isEmpty ? '?' : name.characters.first.toUpperCase();
}

/// §12: biru langit selalu pencatat siklus, lavender selalu pasangannya.
/// Warna ditentukan oleh peran, bukan urutan id, supaya tidak pernah bertukar.
({Color fill, Color text}) warnaPengguna(Pengguna user) {
  return user.tracksCycle
      ? (fill: BerduaColors.dinda, text: BerduaColors.dindaText)
      : (fill: BerduaColors.raka, text: BerduaColors.rakaText);
}

class Pasangan {
  const Pasangan({
    required this.id,
    required this.inviteCode,
    required this.inviteValid,
    required this.walletBalance,
    required this.monthlyBudget,
    required this.since,
  });

  factory Pasangan.fromJson(Map<String, dynamic> json) => Pasangan(
    id: json['id'] as int,
    inviteCode: json['invite_code'] as String?,
    inviteValid: json['invite_valid'] as bool? ?? false,
    walletBalance: json['wallet_balance'] as int? ?? 0,
    monthlyBudget: json['monthly_budget'] as int?,
    since: json['since'] == null
        ? null
        : DateTime.parse(json['since'] as String),
  );

  final int id;
  final String? inviteCode;
  final bool inviteValid;
  final int walletBalance;
  final int? monthlyBudget;
  final DateTime? since;

  /// "3 tahun" di kartu beranda.
  String get durasi {
    if (since == null) return '';

    final hari = DateTime.now().difference(since!).inDays;
    final tahun = hari ~/ 365;

    if (tahun >= 1) return '$tahun tahun';

    final bulan = hari ~/ 30;

    return bulan >= 1 ? '$bulan bulan' : '$hari hari';
  }
}

/// Cara pembagian satu transaksi (§5.2).
enum CaraPembagian {
  equal('equal', '50/50'),
  custom('custom', 'Custom'),
  solo('solo', 'Sendiri'),
  wallet('wallet', 'Dompet bersama'),
  settlement('settlement', 'Pelunasan');

  const CaraPembagian(this.wire, this.label);

  final String wire;
  final String label;

  static CaraPembagian fromWire(String value) => values.firstWhere(
    (e) => e.wire == value,
    orElse: () => CaraPembagian.equal,
  );

  /// Hanya empat pilihan yang bisa dipilih pengguna; pelunasan dibuat backend.
  static List<CaraPembagian> get pilihan => [equal, custom, solo, wallet];
}

class Transaksi {
  const Transaksi({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.payerId,
    required this.payerName,
    required this.split,
    required this.payerSharePct,
    required this.date,
    required this.partnerDebt,
    required this.payerShare,
    required this.partnerShare,
  });

  factory Transaksi.fromJson(Map<String, dynamic> json) => Transaksi(
    id: json['id'] as int,
    title: json['title'] as String,
    category: json['category'] as String,
    amount: json['amount'] as int,
    payerId: json['payer_id'] as int?,
    payerName: json['payer_name'] as String?,
    split: CaraPembagian.fromWire(json['split'] as String),
    payerSharePct: json['payer_share_pct'] as int? ?? 50,
    date: DateTime.parse(json['date'] as String),
    partnerDebt: json['partner_debt'] as int? ?? 0,
    payerShare: json['payer_share'] as int? ?? 0,
    partnerShare: json['partner_share'] as int? ?? 0,
  );

  final int id;
  final String title;
  final String category;
  final int amount;
  final int? payerId;
  final String? payerName;
  final CaraPembagian split;
  final int payerSharePct;
  final DateTime date;
  final int partnerDebt;
  final int payerShare;
  final int partnerShare;

  bool get dariDompet => split == CaraPembagian.wallet;

  bool get pelunasan => split == CaraPembagian.settlement;

  /// "Dinda · 50/50" — baris keterangan pada kartu daftar (§16).
  String get keterangan {
    // Dompet bersama tidak punya pembayar, jadi cukup satu label.
    if (dariDompet) return split.label;

    final pembayar = payerName ?? '-';

    if (split == CaraPembagian.custom) {
      return '$pembayar · $payerSharePct/${100 - payerSharePct}';
    }

    return '$pembayar · ${split.label}';
  }

  String get initial {
    if (dariDompet) return 'D';

    final nama = payerName ?? '';

    return nama.isEmpty ? '?' : nama.characters.first.toUpperCase();
  }
}

/// Isi layar 08 (Uang bersama) dalam satu muatan.
class RingkasanUang {
  const RingkasanUang({
    required this.transaksi,
    required this.balance,
    required this.walletBalance,
    required this.monthTotal,
  });

  factory RingkasanUang.fromJson(Map<String, dynamic> json) => RingkasanUang(
    transaksi: (json['data'] as List<dynamic>)
        .map((e) => Transaksi.fromJson(e as Map<String, dynamic>))
        .toList(),
    balance: json['balance'] as int? ?? 0,
    walletBalance: json['wallet_balance'] as int? ?? 0,
    monthTotal: json['month_total'] as int? ?? 0,
  );

  final List<Transaksi> transaksi;

  /// Positif = pengguna ini berutang; negatif = pasangan yang berutang.
  final int balance;
  final int walletBalance;
  final int monthTotal;

  bool get lunas => balance == 0;

  /// §5.2: tampilan menyesuaikan siapa yang melihat.
  String get kalimatUtang {
    if (lunas) return 'Tidak ada utang';

    return balance > 0
        ? 'Kamu berutang ke pasangan'
        : 'Pasangan berutang ke kamu';
  }
}
