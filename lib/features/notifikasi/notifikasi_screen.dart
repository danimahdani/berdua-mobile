import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import '../bersama/bersama_cubit.dart';
import 'notifikasi_cubit.dart';

/// Warna ubin ikon per jenis notifikasi.
({Color latar, Color warna}) _warnaJenis(String type) => switch (type) {
  'transaction_new' || 'transaction_changed' || 'saving_milestone' => (
    latar: BerduaColors.roseSoft,
    warna: BerduaColors.roseText,
  ),
  'settlement' || 'shopping_new' => (
    latar: BerduaColors.mintSoft,
    warna: BerduaColors.mintText,
  ),
  'period_forecast' => (
    latar: BerduaColors.rakaSoft,
    warna: BerduaColors.rakaText,
  ),
  'todo_due' => (latar: BerduaColors.dindaSoft, warna: BerduaColors.dindaText),
  'event_reminder' => (
    latar: BerduaColors.kuningSoft,
    warna: BerduaColors.kuningText,
  ),
  _ => (latar: BerduaColors.card2, warna: BerduaColors.lutealText),
};

/// Layar 07: Notifikasi.
class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({super.key});

  /// Mengetuk notifikasi membawa ke tempat kejadiannya.
  void _buka(BuildContext context, Notifikasi row) {
    void keBersama(BagianBersama bagian) {
      context.read<BagianBersamaCubit>().pilih(bagian);
      context.go('/bersama');
    }

    switch (row.type) {
      case 'transaction_new' || 'transaction_changed' || 'settlement':
        context.go('/uang');
      case 'period_forecast':
        context.go('/siklus');
      case 'todo_due':
        keBersama(BagianBersama.todo);
      case 'event_reminder':
        keBersama(BagianBersama.jadwal);
      case 'shopping_new':
        keBersama(BagianBersama.belanja);
      case 'saving_milestone':
        keBersama(BagianBersama.tabungan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daftar = context.watch<NotifikasiCubit>().state;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: daftar.when(
        loading: () => const SkeletonNotifikasi(),
        error: (error, _) => GalatLayar(
          pesan: error is ApiException
              ? error.message
              : 'Gagal memuat notifikasi.',
          onUlangi: () => context.read<NotifikasiCubit>().muat(),
        ),
        data: (rows) {
          final belumDibaca = rows.where((row) => !row.read).length;

          return LayarBerdua(
            judul: 'Notifikasi',
            stiker: JenisStiker.bell,
            kembali: true,
            onSegarkan: () => context.read<NotifikasiCubit>().segarkan(),
            children: [
              if (belumDibaca > 0) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TombolTeks(
                    label: 'Tandai semua dibaca',
                    stiker: JenisStiker.check,
                    ukuran: 15,
                    tebal: FontWeight.w500,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        await context
                            .read<NotifikasiCubit>()
                            .tandaiSemuaDibaca();
                      } on ApiException catch (error) {
                        tampilkanToastVia(messenger, error.message);
                      }
                    },
                  ),
                ),
                const SizedBox(height: Gap.sm),
              ],
              if (rows.isEmpty)
                KartuBerdua(
                  padding: const EdgeInsets.all(Gap.xxl),
                  child: Column(
                    children: [
                      const Stiker.sedang(JenisStiker.bell),
                      const SizedBox(height: Gap.sm),
                      Text(
                        'Belum ada notifikasi.',
                        style: text.bodyMedium?.copyWith(
                          color: BerduaColors.label,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final row in rows) ...[
                  Semantics(
                    label: row.read ? null : 'Belum dibaca',
                    child: KartuBerdua(
                      // Yang belum dibaca diberi latar pink muda dan titik
                      // pink supaya menonjol.
                      warna: row.read
                          ? BerduaColors.card
                          : BerduaColors.roseCard,
                      garis: false,
                      radius: Radii.button,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      onTap: () => _buka(context, row),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UbinIkon(
                            ikon: row.ikon,
                            latar: _warnaJenis(row.type).latar,
                            warna: _warnaJenis(row.type).warna,
                            ukuran: 36,
                          ),
                          const SizedBox(width: Gap.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.text,
                                  style: text.bodyMedium?.copyWith(
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  kapitalAwal(
                                    TanggalId.relative(row.createdAt),
                                  ),
                                  style: text.labelSmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: Gap.sm),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: row.read
                                    ? Colors.transparent
                                    : BerduaColors.rose,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}
