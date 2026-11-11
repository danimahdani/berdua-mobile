import 'package:berdua/theme/tokens.dart';
import 'package:berdua/core/rupiah.dart';
import 'package:berdua/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('Rupiah', () {
    test('memakai titik sebagai pemisah ribuan (§7)', () {
      expect(Rupiah.format(512000), 'Rp 512.000');
      expect(Rupiah.format(51000), 'Rp 51.000');
      expect(Rupiah.format(0), 'Rp 0');
    });

    test('bentuk pendek untuk grafik dan kartu sempit', () {
      expect(Rupiah.short(512000), '512rb');
      expect(Rupiah.short(1200000), '1,2jt');
      expect(Rupiah.short(2000000), '2jt');
      expect(Rupiah.short(750), '750');
    });

    test('membaca angka yang diketik pengguna apa pun formatnya', () {
      expect(Rupiah.parse('512.000'), 512000);
      expect(Rupiah.parse('512000'), 512000);
      expect(Rupiah.parse('Rp 512.000'), 512000);
      expect(Rupiah.parse(''), isNull);
      expect(Rupiah.parse('abc'), isNull);
    });
  });

  group('TanggalId', () {
    test('menyebut tanggal dalam bahasa Indonesia', () {
      final tanggal = DateTime(2026, 11, 9);

      expect(TanggalId.full(tanggal), 'Senin, 9 November');
      expect(TanggalId.short(tanggal), '9 Nov');
      expect(TanggalId.monthBadge(tanggal), 'NOV');
    });

    test('jarak hari dibaca relatif', () {
      final hariIni = DateTime(2026, 11, 9);

      expect(TanggalId.relative(hariIni, from: hariIni), 'hari ini');
      expect(
        TanggalId.relative(DateTime(2026, 11, 10), from: hariIni),
        'besok',
      );
      expect(
        TanggalId.relative(DateTime(2026, 11, 16), from: hariIni),
        '7 hari lagi',
      );
    });
  });

  group('Transaksi', () {
    Transaksi buat({
      required String split,
      int pct = 50,
      String? payerName = 'Dinda',
    }) {
      return Transaksi.fromJson({
        'id': 1,
        'title': 'Belanja mingguan',
        'category': 'Belanja',
        'amount': 512000,
        'payer_id': payerName == null ? null : 2,
        'payer_name': payerName,
        'split': split,
        'payer_share_pct': pct,
        'date': '2026-11-09',
        'partner_debt': 256000,
        'payer_share': 256000,
        'partner_share': 256000,
      });
    }

    test('keterangan kartu daftar menyebut pembayar dan pembagian (§16)', () {
      expect(buat(split: 'equal').keterangan, 'Dinda · 50/50');
    });

    test('pembagian custom menampilkan kedua porsi', () {
      expect(buat(split: 'custom', pct: 70).keterangan, 'Dinda · 70/30');
    });

    test('transaksi dompet tidak punya pembayar', () {
      final transaksi = buat(split: 'wallet', payerName: null);

      expect(transaksi.dariDompet, isTrue);
      expect(transaksi.keterangan, 'Dompet bersama');
    });
  });

  group('RingkasanUang', () {
    RingkasanUang buat(int balance) => RingkasanUang.fromJson({
      'data': <dynamic>[],
      'balance': balance,
      'wallet_balance': 0,
      'month_total': 0,
    });

    test('kalimat utang menyesuaikan siapa yang melihat (§5.2)', () {
      expect(buat(256000).kalimatUtang, 'Kamu berutang ke pasangan');
      expect(buat(-256000).kalimatUtang, 'Pasangan berutang ke kamu');
      expect(buat(0).kalimatUtang, 'Tidak ada utang');
      expect(buat(0).lunas, isTrue);
    });
  });

  group('warnaPengguna', () {
    Pengguna buat({required bool catatSiklus}) => Pengguna.fromJson({
      'id': 1,
      'name': 'Dinda',
      'phone_number': '+628',
      'email': 'a@b.c',
      'tracks_cycle': catatSiklus,
      'couple_id': 1,
      'needs_onboarding': false,
    });

    test('warna ditentukan peran, bukan urutan id (§12)', () {
      // Biru langit selalu pencatat siklus, lavender selalu pasangannya.
      expect(warnaPengguna(buat(catatSiklus: true)).fill, BerduaColors.dinda);
      expect(warnaPengguna(buat(catatSiklus: false)).fill, BerduaColors.raka);
    });

    test('inisial avatar diambil dari nama', () {
      expect(buat(catatSiklus: true).initial, 'D');
    });
  });
}
