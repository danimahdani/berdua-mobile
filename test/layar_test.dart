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
import 'package:berdua/features/kuis/kuis_screen.dart';
import 'package:berdua/features/kuis/riwayat_kuis_screen.dart';
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

/// Satu sesi kuis. [selesai] = pengguna ini sudah menjawab; [pasangan] =
/// pasangannya juga sudah, sehingga jawaban bisa dibandingkan.
Map<String, dynamic> _kuis({
  int id = 7,
  bool selesai = false,
  bool pasangan = true,
  DateTime? tanggal,
}) {
  const milikku = [1, 0, 0, 1, 2];
  const miliknya = [1, 0, 2, 1, 0];
  final terbuka = selesai && pasangan;

  return {
    'id': id,
    'date': _tgl(tanggal ?? _hariIni),
    'title': 'Hal-hal kecil tentang kita',
    'total': 5,
    'done': selesai,
    'partner_done': pasangan,
    'partner_name': 'Raka',
    'same': terbuka ? 3 : null,
    'questions': [
      for (var i = 0; i < 5; i++)
        {
          'id': 100 + i,
          'position': i + 1,
          'category': 'Kebiasaan',
          'color': const [
            '#8fdcff',
            '#c9b8ff',
            '#7cf0c8',
            '#ffd23f',
            '#ff7fab',
          ][i],
          'text':
              'Pertanyaan nomor ${i + 1} yang cukup panjang supaya turun ke '
              'baris kedua di layar sempit?',
          'options': const [
            'Pilihan pertama',
            'Pilihan kedua yang kalimatnya lebih panjang dari yang lain',
            'Pilihan ketiga',
            'Pilihan keempat',
          ],
          'talk': 'Apa yang membuat kalian memilih jawaban itu?',
          'my_choice': selesai ? milikku[i] : null,
          'partner_choice': terbuka ? miliknya[i] : null,
          'same': terbuka ? milikku[i] == miliknya[i] : null,
        },
    ],
  };
}

Map<String, dynamic> _jawaban(
  String path, {
  bool siklusPasangan = false,
  bool kuisSelesai = false,
  bool pasanganMenjawab = true,
}) {
  if (path.endsWith('/quiz/today') || path.endsWith('/quiz/today/answers')) {
    return {'data': _kuis(selesai: kuisSelesai, pasangan: pasanganMenjawab)};
  }

  if (path.contains('/quiz/sessions/')) {
    return {
      'data': _kuis(
        id: 3,
        selesai: true,
        tanggal: _hariIni.subtract(const Duration(days: 2)),
      ),
    };
  }

  if (path.endsWith('/quiz/history')) {
    return {
      'count': 3,
      'average': 3.5,
      'data': [
        for (final (i, sama) in const [3, null, 4].indexed)
          {
            'id': 7 - i * 2,
            'date': _tgl(_hariIni.subtract(Duration(days: i))),
            'title': 'Hal-hal kecil tentang kita dan kebiasaan sehari-hari',
            'total': 5,
            'partner_done': sama != null,
            'same': sama,
          },
      ],
    };
  }

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
      'kuis': {
        'id': 7,
        'title': 'Hal-hal kecil tentang kita',
        'total': 5,
        'done': kuisSelesai,
        'partner_done': pasanganMenjawab,
        'same': kuisSelesai && pasanganMenjawab ? 3 : null,
      },
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
      'pregnancy_chance': 'rendah',
      'fertile_window': {
        'start': _tgl(_hariIni.add(const Duration(days: 18))),
        'end': _tgl(_hariIni.add(const Duration(days: 22))),
      },
      'symptoms_today': ['lelah', 'kram'],
      'calendar': [
        for (var i = 0; i < akhir; i++)
          {
            'date': _tgl(awal.add(Duration(days: i))),
            'phase': const ['haid', 'folikular', 'subur', 'luteal'][i ~/ 8],
            'day_of_cycle': i + 1,
            'pregnancy_chance': const [
              'rendah',
              'sedang',
              'tinggi',
              'rendah',
            ][i ~/ 8],
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
  _Adaptor({
    this.siklusPasangan = false,
    this.kuisSelesai = false,
    this.pasanganMenjawab = true,
  });

  final bool siklusPasangan;
  final bool pasanganMenjawab;

  /// Menyala setelah jawaban dikirim, seperti backend sungguhan.
  bool kuisSelesai;

  /// Isi permintaan PUT terakhir ke `/quiz/today/answers`.
  Object? jawabanTerkirim;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'PUT' &&
        options.uri.path.endsWith('/quiz/today/answers')) {
      kuisSelesai = true;
      jawabanTerkirim = (options.data as Map)['answers'];
    }

    return ResponseBody.fromString(
      jsonEncode(
        _jawaban(
          options.uri.path,
          siklusPasangan: siklusPasangan,
          kuisSelesai: kuisSelesai,
          pasanganMenjawab: pasanganMenjawab,
        ),
      ),
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

  Future<_Adaptor> pasang(
    WidgetTester tester,
    Widget layar, {
    Size ukuran = const Size(411, 891),
    bool sebagaiPasangan = false,
    bool kuisSelesai = false,
    bool pasanganMenjawab = true,
  }) async {
    tester.view.physicalSize = ukuran;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final adaptor = _Adaptor(
      siklusPasangan: sebagaiPasangan,
      kuisSelesai: kuisSelesai,
      pasanganMenjawab: pasanganMenjawab,
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://uji.lokal/api'))
      ..httpClientAdapter = adaptor;

    await tester.pumpWidget(
      PenyediaBerdua(
        // Kunci baru supaya pemasangan kedua dalam satu tes tidak mewarisi
        // cubit dari pemasangan pertama.
        key: UniqueKey(),
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

    return adaptor;
  }

  /// Menggulir sampai bawah supaya kartu yang dibangun malas ikut diperiksa.
  Future<void> gulirSampaiBawah(WidgetTester tester) async {
    final daftar = find.byType(Scrollable);

    if (daftar.evaluate().isEmpty) return;

    for (var i = 0; i < 6; i++) {
      await tester.drag(daftar.first, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 300));
    }

    // Kartu di bawah lipatan bisa memulai permintaan baru saat dibangun
    // (mis. jumlah riwayat kuis); beri waktu jawabannya datang.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
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
    'kuis': () => const KuisScreen(),
    'riwayat kuis': () => const RiwayatKuisScreen(),
    'hasil kuis lama': () => const HasilKuisScreen(sessionId: 3),
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

      testWidgets('kuis: hasil dan menunggu pasangan', (tester) async {
        await pasang(
          tester,
          const KuisScreen(),
          ukuran: ukuran,
          kuisSelesai: true,
        );
        expect(find.text('3/5'), findsOneWidget);
        await gulirSampaiBawah(tester);
        expect(tester.takeException(), isNull);

        await pasang(
          tester,
          const KuisScreen(),
          ukuran: ukuran,
          kuisSelesai: true,
          pasanganMenjawab: false,
        );
        expect(find.text('Menunggu Raka'), findsOneWidget);
        await gulirSampaiBawah(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('kuis: menjawab lima pertanyaan', (tester) async {
        final adaptor = await pasang(
          tester,
          const KuisScreen(),
          ukuran: ukuran,
        );

        Future<void> ketuk(String teks) async {
          // Daftarnya malas: tombol di bawah lipatan baru ada setelah digulir.
          await tester.scrollUntilVisible(
            find.text(teks),
            120,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(find.text(teks));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text(teks));
          await tester.pump();
          await tester.pump(const Duration(seconds: 2));
        }

        await ketuk('MULAI KUIS');
        expect(find.text('1/5'), findsOneWidget);

        // Tanpa pilihan, tombol lanjut hanya mengingatkan.
        await ketuk('LANJUT');
        expect(find.text('Pilih satu jawaban dulu'), findsOneWidget);
        // Masih di soal pertama: pilihan soal itu belum berganti. (Baris
        // progres bisa di luar layar sempit, jadi tidak diperiksa di sini.)
        expect(find.text('LIHAT HASIL'), findsNothing);

        for (var i = 0; i < 5; i++) {
          await ketuk(i.isEven ? 'Pilihan ketiga' : 'Pilihan pertama');
          await ketuk(i == 4 ? 'LIHAT HASIL' : 'LANJUT');
          expect(tester.takeException(), isNull, reason: 'soal ${i + 1}');
        }

        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pump(const Duration(seconds: 2));

        expect(adaptor.jawabanTerkirim, [2, 0, 2, 0, 2]);
        expect(find.text('3/5'), findsOneWidget);
        expect(find.text('Banyak yang sama, ada yang baru'), findsOneWidget);
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

  testWidgets('beranda: kartu kuis mengikuti keadaan kuis hari ini', (
    tester,
  ) async {
    await pasang(tester, const BerandaScreen());
    await gulirSampaiBawah(tester);

    expect(find.text('Main sekarang'), findsOneWidget);
    expect(find.textContaining('Raka sudah menjawab, giliranmu'), findsOne);

    await pasang(tester, const BerandaScreen(), kuisSelesai: true);
    await gulirSampaiBawah(tester);

    expect(find.text('Lihat hasil'), findsOneWidget);
    expect(find.textContaining('selaras di 3 dari 5'), findsOne);
  });

  testWidgets('kuis: jawaban pasangan tidak tampil sebelum ia menjawab', (
    tester,
  ) async {
    await pasang(
      tester,
      const KuisScreen(),
      kuisSelesai: true,
      pasanganMenjawab: false,
    );
    await gulirSampaiBawah(tester);

    expect(find.text('Belum menjawab'), findsWidgets);
    expect(find.text('Sama'), findsNothing);
    expect(find.text('Beda'), findsNothing);
    expect(find.textContaining('Obrolkan'), findsNothing);
  });

  testWidgets('siklus: peluang kehamilan tampil untuk pencatat dan pasangan', (
    tester,
  ) async {
    for (final sebagaiPasangan in [false, true]) {
      await pasang(
        tester,
        const SiklusScreen(),
        sebagaiPasangan: sebagaiPasangan,
      );

      expect(find.text('Peluang kehamilan'), findsOneWidget);
      expect(find.text('Rendah'), findsOneWidget);
      expect(find.textContaining('tetapi tidak nol'), findsOneWidget);
      expect(find.textContaining('Masa subur berikutnya'), findsOneWidget);
      expect(find.textContaining('alat kontrasepsi'), findsWidgets);
    }
  });

  testWidgets('siklus: mengetuk tanggal menyebut peluang hari itu', (
    tester,
  ) async {
    await pasang(tester, const SiklusScreen());

    // Tanggal 17 ada di ruas "subur" pada kalender tiruan.
    await tester.ensureVisible(find.text('17'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('17'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('peluang hamil tinggi'), findsOneWidget);
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
