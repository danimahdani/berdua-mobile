import 'dart:convert';
import 'dart:typed_data';

import 'package:berdua/core/api_client.dart';
import 'package:berdua/features/auth/sesi_cubit.dart';
import 'package:berdua/features/auth/masuk_screen.dart';
import 'package:berdua/features/auth/onboarding_screen.dart';
import 'package:berdua/features/beranda/beranda_screen.dart';
import 'package:berdua/features/bersama/bersama_cubit.dart';
import 'package:berdua/features/bersama/bersama_screen.dart';
import 'package:berdua/features/bersama/tabungan_detail_screen.dart';
import 'package:berdua/features/laporan/laporan_screen.dart';
import 'package:berdua/features/money/tambah_pengeluaran_sheet.dart';
import 'package:berdua/features/money/uang_screen.dart';
import 'package:berdua/features/notifikasi/notifikasi_screen.dart';
import 'package:berdua/features/profil/profil_screen.dart';
import 'package:berdua/features/siklus/riwayat_screen.dart';
import 'package:berdua/features/siklus/siklus_screen.dart';
import 'package:berdua/models/models.dart';
import 'package:berdua/penyedia.dart';
import 'package:berdua/theme/berdua_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Tes asap: tiap layar dipasang dengan jawaban backend tiruan, di layar
/// biasa dan layar sempit, dan tidak boleh melempar galat tata letak.

String _tgl(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

final _hariIni = DateTime.now();

const _dinda = {
  'id': 1,
  'name': 'Dinda',
  'phone_number': '+62811',
  'email': 'd@x.id',
  'tracks_cycle': true,
  'couple_id': 1,
  'needs_onboarding': false,
};

const _raka = {
  'id': 2,
  'name': 'Raka',
  'phone_number': '+62812',
  'email': 'r@x.id',
  'tracks_cycle': false,
  'couple_id': 1,
  'needs_onboarding': false,
};

const _pasangan = {
  'id': 1,
  'invite_code': 'BRD-4821',
  'invite_valid': true,
  'wallet_balance': 1250000,
  'monthly_budget': 6000000,
  'since': '2023-12-14',
};

Map<String, dynamic> _goal(int id) => {
  'id': id,
  'title': 'Liburan ke Labuan Bajo',
  'target': 12000000,
  'collected': 8400000,
  'remaining': 3600000,
  'per_month': 900000,
  'percent': 70,
  'due_date': '2027-03-01',
  'kontribusi': [
    {'user_id': 1, 'name': 'Dinda', 'amount': 4400000},
    {'user_id': 2, 'name': 'Raka', 'amount': 4000000},
  ],
  'riwayat': [
    {'id': 1, 'name': 'Dinda', 'amount': 500000, 'date': '2026-11-02'},
    {'id': 2, 'name': 'Raka', 'amount': 250000, 'date': '2026-10-28'},
  ],
};

Map<String, dynamic> _transaksi(int id, String split, int? payer) => {
  'id': id,
  'title': 'Belanja mingguan di pasar swalayan dekat rumah',
  'category': 'Belanja',
  'amount': 1512000,
  'payer_id': payer,
  'payer_name': payer == null ? null : (payer == 1 ? 'Dinda' : 'Raka'),
  'split': split,
  'payer_share_pct': 60,
  'date': '2026-11-08',
  'partner_debt': 604800,
  'payer_share': 907200,
  'partner_share': 604800,
};

Map<String, dynamic> _jawaban(String path, {bool siklusPasangan = false}) {
  if (path.endsWith('/beranda')) {
    return {
      'user': _dinda,
      'partner': _raka,
      'couple': _pasangan,
      'uang': {
        'balance': -51000,
        'wallet_balance': 1250000,
        'month_total': 12345678,
      },
      'siklus': {
        'owner_name': 'Dinda',
        'shared': true,
        'day_of_cycle': 22,
        'phase': 'luteal',
        'days_until_next_period': 7,
        'average_length': 28.7,
        'is_regular': true,
        'symptoms_today': ['lelah', 'ngidam manis', 'sakit kepala'],
        'disclaimer': '',
      },
      'belanja': {'belum_dibeli': 12},
      'todo': {'terbuka': 3},
      'jadwal_terdekat': {
        'id': 1,
        'title': 'Makan malam anniversary di tempat biasa',
        'type': 'Anniversary',
        'date': _tgl(_hariIni.add(const Duration(days: 12))),
        'days_until': 12,
      },
      'tabungan_utama': _goal(1),
      'notifikasi_belum_dibaca': 120,
    };
  }

  if (path.endsWith('/transactions/report')) {
    return {
      'year': _hariIni.year,
      'month': _hariIni.month,
      'total': 12345678,
      'previous_total': 10000000,
      'delta': 2345678,
      'budget': 15000000,
      'budget_pct': 82,
      'by_category': {
        'Makan': 4200000,
        'Belanja': 3100000,
        'Tagihan': 2500000,
        'Transport': 1500000,
        'Hiburan': 800000,
        'Lainnya': 245678,
      },
      'by_payer': {'1': 6000000, '2': 4345678, 'wallet': 2000000},
      'by_week': {'1': 3000000, '2': 4500000, '3': 2000000, '4': 2845678},
      'transaction_count': 42,
    };
  }

  if (path.endsWith('/transactions')) {
    return {
      'data': [
        _transaksi(1, 'custom', 1),
        _transaksi(2, 'equal', 2),
        _transaksi(3, 'wallet', null),
        _transaksi(4, 'settlement', 2),
      ],
      'balance': 51000,
      'wallet_balance': 1250000,
      'month_total': 12345678,
    };
  }

  if (path.endsWith('/cycle/history')) {
    return {
      'cycles': [
        {
          'period_start': _tgl(_hariIni.subtract(const Duration(days: 21))),
          'cycle_length': null,
          'period_length': null,
        },
        for (var i = 1; i <= 5; i++)
          {
            'period_start': _tgl(
              _hariIni.subtract(Duration(days: 21 + 29 * i)),
            ),
            'cycle_length': 27 + i,
            'period_length': 5,
          },
      ],
      'average_length': 28.7,
      'average_period_length': 5,
      'is_regular': true,
      'cycles_recorded': 6,
      'frequent_symptoms': {
        'kram': 9,
        'lelah': 7,
        'sakit kepala': 4,
        'ngidam manis': 3,
        'kembung': 1,
      },
    };
  }

  if (path.endsWith('/cycle')) {
    final awal = DateTime(_hariIni.year, _hariIni.month);
    final akhir = DateTime(_hariIni.year, _hariIni.month + 1, 0).day;

    return {
      'tracked': true,
      'shared': true,
      'owner_name': 'Dinda',
      'can_edit': !siklusPasangan,
      'day_of_cycle': 22,
      'phase': 'luteal',
      'days_until_next_period': 7,
      'average_length': 28.7,
      'average_period_length': 5,
      'is_regular': true,
      'cycles_recorded': 6,
      'symptoms_today': ['lelah', 'kram'],
      'calendar': [
        for (var i = 0; i < akhir; i++)
          {
            'date': _tgl(awal.add(Duration(days: i))),
            'phase': const ['haid', 'folikular', 'subur', 'luteal'][i ~/ 8],
            'day_of_cycle': i + 1,
            'predicted': i > 20,
            'is_today': i + 1 == _hariIni.day,
          },
      ],
      'tips': siklusPasangan
          ? {
              'ringkasan':
                  'Di fase luteal energi bisa menurun dan perasaan lebih '
                  'sensitif menjelang haid.',
              'tips': [
                'Tawarkan masak atau pesan makanan hangat malam ini.',
                'Kurangi rencana yang padat di akhir pekan.',
                'Stok pembalut dan cokelat sebelum haid datang.',
              ],
              'perlu_ditinjau': true,
            }
          : null,
      'disclaimer': 'Perkiraan, bukan saran medis.',
    };
  }

  if (path.endsWith('/shopping')) {
    return {
      'data': [
        {
          'id': 1,
          'title': 'Beras 5 kg',
          'added_by_name': 'Dinda',
          'done': false,
        },
        {
          'id': 2,
          'title': 'Sabun cuci piring isi ulang ukuran besar sekali',
          'added_by_name': 'Raka',
          'done': true,
        },
      ],
    };
  }

  if (path.endsWith('/todos')) {
    return {
      'data': [
        {
          'id': 1,
          'title': 'Bayar listrik dan internet bulan ini sebelum telat',
          'assignee_id': 2,
          'assignee_name': 'Raka',
          'due_date': _tgl(_hariIni.add(const Duration(days: 2))),
          'done': false,
        },
        {
          'id': 2,
          'title': 'Servis motor',
          'assignee_id': null,
          'assignee_name': null,
          'due_date': null,
          'done': true,
        },
      ],
    };
  }

  if (path.endsWith('/goals')) {
    return {
      'data': [_goal(1), _goal(2)],
    };
  }

  if (path.contains('/goals/')) return {'data': _goal(1)};

  if (path.endsWith('/events')) {
    return {
      'data': [
        {
          'id': 1,
          'title': 'Makan malam anniversary di tempat biasa',
          'type': 'Anniversary',
          'next_occurrence': _tgl(_hariIni.add(const Duration(days: 12))),
          'days_until': 12,
          'remind_before': 3,
          'yearly': true,
        },
      ],
    };
  }

  if (path.endsWith('/journal')) {
    return {
      'data': [
        {
          'id': 1,
          'author_id': 1,
          'author_name': 'Dinda',
          'text': 'Hari ini jalan sore ke taman, lalu makan bakso. ' * 3,
          'date': '2026-11-09',
        },
      ],
    };
  }

  if (path.endsWith('/notifications')) {
    return {
      'data': [
        for (final (i, jenis) in const [
          'transaction_new',
          'settlement',
          'period_forecast',
          'todo_due',
          'event_reminder',
          'shopping_new',
          'saving_milestone',
        ].indexed)
          {
            'id': i,
            'type': jenis,
            'text': 'Raka menambahkan sesuatu yang cukup panjang untuk dibaca.',
            'read': i.isOdd,
            'created_at': _hariIni
                .subtract(Duration(days: i))
                .toIso8601String(),
          },
      ],
    };
  }

  return {};
}

class _Adaptor implements HttpClientAdapter {
  _Adaptor({this.siklusPasangan = false});

  final bool siklusPasangan;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(_jawaban(options.uri.path, siklusPasangan: siklusPasangan)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Sesi yang sudah masuk, tanpa memeriksa token di penyimpanan.
SesiCubit _sesiPalsu(Dio dio, {bool sebagaiPasangan = false}) => SesiCubit(
  dio,
  TokenStore(),
  pulihkanSaatMulai: false,
  awal: SesiState(
    user: Pengguna.fromJson(sebagaiPasangan ? _raka : _dinda),
    partner: Pengguna.fromJson(sebagaiPasangan ? _dinda : _raka),
    couple: Pasangan.fromJson(_pasangan),
    memuat: false,
    pengaturan: const {'share_cycle': true, 'remind_period': true},
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pasang(
    WidgetTester tester,
    Widget layar, {
    Size ukuran = const Size(411, 891),
    bool sebagaiPasangan = false,
  }) async {
    tester.view.physicalSize = ukuran;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final dio = Dio(BaseOptions(baseUrl: 'http://uji.lokal/api'))
      ..httpClientAdapter = _Adaptor(siklusPasangan: sebagaiPasangan);

    await tester.pumpWidget(
      PenyediaBerdua(
        dio: dio,
        sesi: (_) => _sesiPalsu(dio, sebagaiPasangan: sebagaiPasangan),
        child: MaterialApp(theme: BerduaTheme.light(), home: layar),
      ),
    );

    // Jawaban tiruan datang lewat beberapa putaran mikrotask; sesudahnya
    // kartu memantul masuk dengan jeda sampai 550 ms.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    await tester.pump(const Duration(seconds: 2));
  }

  /// Menggulir sampai bawah supaya kartu yang dibangun malas ikut diperiksa.
  Future<void> gulirSampaiBawah(WidgetTester tester) async {
    final daftar = find.byType(Scrollable);

    if (daftar.evaluate().isEmpty) return;

    for (var i = 0; i < 6; i++) {
      await tester.drag(daftar.first, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 300));
    }

    await tester.pump(const Duration(seconds: 2));
  }

  final layar = <String, Widget Function()>{
    'masuk': () => const MasukScreen(),
    'onboarding': () => const OnboardingScreen(),
    'beranda': () => const BerandaScreen(),
    'uang': () => const UangScreen(),
    'laporan': () => const LaporanScreen(),
    'siklus': () => const SiklusScreen(),
    'riwayat siklus': () => const RiwayatSiklusScreen(),
    'bersama': () => const BersamaScreen(),
    'detail tabungan': () => const TabunganDetailScreen(goalId: 1),
    'notifikasi': () => const NotifikasiScreen(),
    'profil': () => const ProfilScreen(),
    'sheet tambah pengeluaran': () =>
        const Scaffold(body: TambahPengeluaranSheet()),
  };

  for (final ukuran in const [Size(411, 891), Size(320, 568)]) {
    group('layar ${ukuran.width.round()}x${ukuran.height.round()}', () {
      for (final entry in layar.entries) {
        testWidgets(entry.key, (tester) async {
          await pasang(tester, entry.value(), ukuran: ukuran);
          expect(tester.takeException(), isNull);

          await gulirSampaiBawah(tester);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('siklus dilihat pasangan', (tester) async {
        await pasang(
          tester,
          const SiklusScreen(),
          ukuran: ukuran,
          sebagaiPasangan: true,
        );
        expect(tester.takeException(), isNull);

        // Kartu tips ada di bawah lipatan; daftar membangunnya saat digulir.
        await gulirSampaiBawah(tester);
        expect(find.textContaining('Cara mendukung'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('tiap bagian Bersama', (tester) async {
        await pasang(tester, const BersamaScreen(), ukuran: ukuran);

        final bagianCubit = tester
            .element(find.byType(BersamaScreen))
            .read<BagianBersamaCubit>();

        for (final bagian in BagianBersama.values) {
          bagianCubit.pilih(bagian);

          for (var i = 0; i < 8; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }

          await tester.pump(const Duration(seconds: 2));
          expect(tester.takeException(), isNull, reason: bagian.label);
        }
      });

      testWidgets('onboarding sampai langkah profil', (tester) async {
        await pasang(tester, const OnboardingScreen(), ukuran: ukuran);

        await tester.ensureVisible(find.text('MULAI'));
        await tester.tap(find.text('MULAI'));
        // Bingkai pertama membangun langkah baru; yang kedua menghabiskan
        // jeda pantulannya.
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        expect(find.text('Kenalan dulu'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('beranda menampilkan data dari backend', (tester) async {
    await pasang(tester, const BerandaScreen());

    expect(find.text('Hai, Dinda'), findsOneWidget);
    expect(find.text('Rp 51.000'), findsOneWidget);
    expect(find.text('Raka berutang ke kamu'), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('uang: mengetuk transaksi membuka detail', (tester) async {
    await pasang(tester, const UangScreen());

    expect(find.text('TANDAI LUNAS'), findsOneWidget);

    await tester.ensureVisible(find.textContaining('Belanja mingguan').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.textContaining('Belanja mingguan').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Bagian Dinda'), findsOneWidget);
    expect(find.text('Bagian Raka'), findsOneWidget);
    expect(find.text('Ubah'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
