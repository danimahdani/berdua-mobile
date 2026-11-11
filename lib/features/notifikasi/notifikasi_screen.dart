import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import '../beranda/beranda_controller.dart';
import '../bersama/bersama_screen.dart';

/// Satu baris notifikasi (§5.5).
class Notifikasi {
  const Notifikasi({
    required this.id,
    required this.type,
    required this.text,
    required this.read,
    required this.createdAt,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) => Notifikasi(
    id: json['id'] as int,
    type: json['type'] as String,
    text: json['text'] as String,
    read: json['read'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final int id;
  final String type;
  final String text;
  final bool read;
  final DateTime createdAt;

  /// Ikon per pemicu di §5.5.
  IconData get ikon => switch (type) {
    'transaction_new' => Icons.receipt_long_outlined,
    'transaction_changed' => Icons.edit_outlined,
    'settlement' => Icons.check_circle_outline,
    'period_forecast' => Icons.favorite_outline,
    'todo_due' => Icons.task_alt_outlined,
    'event_reminder' => Icons.event_outlined,
    'shopping_new' => Icons.shopping_basket_outlined,
    'saving_milestone' => Icons.savings_outlined,
    _ => Icons.notifications_none,
  };
}

class NotifikasiController extends AsyncNotifier<List<Notifikasi>> {
  @override
  Future<List<Notifikasi>> build() async {
    final data = await ref.read(dioProvider).send('GET', '/notifications');

    return (data['data'] as List<dynamic>)
        .map((e) => Notifikasi.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tandaiSemuaDibaca() async {
    await ref.read(dioProvider).send('POST', '/notifications/read-all');

    // Sengaja TIDAK menyetel AsyncValue.loading() di sini: isi lama
    // bertahan di layar selama permintaan berjalan, sehingga penambahan
    // kecil tidak membuat seluruh daftar berkedip jadi kerangka.
    // Kerangka hanya untuk pemuatan pertama; tombol yang menekan aksi
    // sudah menampilkan indikatornya sendiri.
    state = await AsyncValue.guard(build);

    // Lonceng di layar 06 ikut diperbarui.
    await ref.read(berandaProvider.notifier).segarkan();
  }
}

final notifikasiProvider =
    AsyncNotifierProvider<NotifikasiController, List<Notifikasi>>(
  NotifikasiController.new,
);


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
class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key});

  /// Mengetuk notifikasi membawa ke tempat kejadiannya.
  void _buka(BuildContext context, WidgetRef ref, Notifikasi row) {
    void keBersama(BagianBersama bagian) {
      ref.read(bagianBersamaProvider.notifier).pilih(bagian);
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
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(notifikasiProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: daftar.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const SkeletonNotifikasi(),
        error: (error, _) => GalatLayar(
          pesan: error is ApiException
              ? error.message
              : 'Gagal memuat notifikasi.',
          onUlangi: () => ref.invalidate(notifikasiProvider),
        ),
        data: (rows) {
          final belumDibaca = rows.where((row) => !row.read).length;

          return LayarBerdua(
            judul: 'Notifikasi',
            stiker: JenisStiker.bell,
            kembali: true,
            onSegarkan: () => ref.refresh(notifikasiProvider.future),
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
                        await ref
                            .read(notifikasiProvider.notifier)
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
                      onTap: () => _buka(context, ref, row),
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
