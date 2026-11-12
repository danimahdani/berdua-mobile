import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import 'kuis_cubit.dart';
import 'kuis_screen.dart';
import 'kuis_widgets.dart';

/// Layar riwayat kuis: jumlah kuis selesai, rata-rata selaras, dan daftar
/// kuis yang bisa dibuka lagi.
class RiwayatKuisScreen extends StatefulWidget {
  const RiwayatKuisScreen({super.key});

  @override
  State<RiwayatKuisScreen> createState() => _RiwayatKuisScreenState();
}

class _RiwayatKuisScreenState extends State<RiwayatKuisScreen> {
  @override
  void initState() {
    super.initState();

    // Pasangan bisa saja baru menjawab; minta ulang tanpa mengedipkan layar.
    final cubit = context.read<RiwayatKuisCubit>();

    if (cubit.state.adaNilai) cubit.segarkan();
  }

  Future<void> _buka(KuisSelesai baris, int? idHariIni) async {
    // Kuis hari ini sudah tampil di layar di bawah layar ini.
    if (baris.id == idHariIni) {
      context.pop();

      return;
    }

    final hasil = await context.push<String>('/kuis/sesi/${baris.id}');

    // "KUIS BARU" pada layar hasil: teruskan ke layar kuis hari ini.
    if (hasil == mainKuisHariIni && mounted) context.pop(mainKuisHariIni);
  }

  @override
  Widget build(BuildContext context) {
    final muatan = context.watch<RiwayatKuisCubit>().state;
    final hariIni = context.watch<KuisCubit>().state.nilai;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: muatan.when(
        loading: () => const SkeletonRiwayatKuis(),
        error: (error, _) => GalatLayar(
          pesan: error is ApiException
              ? error.message
              : 'Gagal memuat riwayat kuis.',
          onUlangi: () => context.read<RiwayatKuisCubit>().muat(),
        ),
        data: (riwayat) {
          Widget ubin(String nilai, String keterangan) => Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: BerduaColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nilai,
                    style: text.headlineSmall?.copyWith(
                      fontSize: 22,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    keterangan,
                    style: text.labelSmall?.copyWith(
                      fontSize: 12,
                      color: BerduaColors.label,
                    ),
                  ),
                ],
              ),
            ),
          );

          return LayarBerdua(
            judul: 'Kuis berdua',
            stiker: JenisStiker.quiz,
            kembali: true,
            onSegarkan: () => context.read<RiwayatKuisCubit>().segarkan(),
            children: [
              const SizedBox(height: Gap.sm),
              KartuBerdua(
                warna: BerduaColors.raka,
                radius: Radii.cardWhite,
                stiker: JenisStiker.note,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat kuis',
                      style: text.headlineSmall?.copyWith(
                        fontSize: 24,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Semua kuis yang sudah selesai tersimpan di sini. Ketuk '
                      'salah satu untuk melihat lagi jawaban kalian.',
                      style: text.bodySmall?.copyWith(
                        fontSize: 14,
                        height: 1.45,
                        color: BerduaColors.teksDiWarna,
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ubin('${riwayat.count}', 'kuis selesai'),
                          const SizedBox(width: 8),
                          ubin(
                            riwayat.average == null
                                ? '–'
                                : '${Rupiah.decimal(riwayat.average!)}/5',
                            'rata-rata selaras',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (riwayat.data.isEmpty) ...[
                const SizedBox(height: 14),
                KartuBerdua(
                  radius: Radii.cardBesar,
                  padding: const EdgeInsets.all(Gap.xl),
                  child: Text(
                    'Belum ada kuis yang selesai. Kuis pertama kalian akan '
                    'muncul di sini.',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      height: 1.45,
                      color: BerduaColors.label,
                    ),
                  ),
                ),
              ],
              for (final baris in riwayat.data) ...[
                const SizedBox(height: 14),
                Semantics(
                  button: true,
                  label:
                      '${baris.title}, ${tanggalKuis(baris.date)}, '
                      '${baris.same == null ? 'menunggu pasangan' : '${baris.same} dari ${baris.total} selaras'}',
                  excludeSemantics: true,
                  child: KartuBerdua(
                    radius: Radii.cardBesar,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    onTap: () => _buka(baris, hariIni?.id),
                    child: Row(
                      children: [
                        CincinSkor(
                          sama: baris.same,
                          total: baris.total,
                          ukuran: 56,
                          lubang: 38,
                          sisa: BerduaColors.card2,
                          child: Text(
                            '${baris.same ?? '?'}/${baris.total}',
                            style: text.titleMedium?.copyWith(
                              fontSize: 13,
                              height: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                baris.title,
                                style: text.titleMedium?.copyWith(
                                  fontSize: 16,
                                  height: 1.3,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${tanggalKuis(baris.date)} · '
                                '${baris.same == null ? 'menunggu pasangan' : '${baris.total} pertanyaan'}',
                                style: text.labelSmall?.copyWith(
                                  fontSize: 13,
                                  color: BerduaColors.label,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Gap.sm),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: BerduaColors.ink,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TombolUtama(
                label: hariIni?.done ?? false
                    ? 'Main lagi kuis hari ini'
                    : 'Mulai kuis hari ini',
                ukuranHuruf: 18,
                onPressed: () => context.pop(mainKuisHariIni),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Hasil satu kuis dari riwayat.
class HasilKuisScreen extends StatelessWidget {
  const HasilKuisScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context) {
    // Tiap sesi punya cubitnya sendiri, hidup selama layar ini terbuka.
    return BlocProvider(
      create: (context) => HasilKuisCubit(context.read(), sessionId),
      child: const _LayarHasil(),
    );
  }
}

class _LayarHasil extends StatelessWidget {
  const _LayarHasil();

  @override
  Widget build(BuildContext context) {
    final muatan = context.watch<HasilKuisCubit>().state;

    return Scaffold(
      body: muatan.when(
        loading: () => const SkeletonKuis(),
        error: (error, _) => GalatLayar(
          pesan: error is ApiException
              ? error.message
              : 'Gagal memuat hasil kuis.',
          onUlangi: () => context.read<HasilKuisCubit>().muat(),
        ),
        data: (kuis) => LayarBerdua(
          judul: 'Kuis berdua',
          stiker: JenisStiker.quiz,
          kembali: true,
          onSegarkan: () => context.read<HasilKuisCubit>().segarkan(),
          children: [
            ...hasilKuis(context, kuis),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TombolUtama(
                    label: 'Kuis baru',
                    ukuranHuruf: 18,
                    putih: true,
                    onPressed: () => context.pop(mainKuisHariIni),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TombolUtama(
                    label: 'Bagikan',
                    ukuranHuruf: 18,
                    onPressed: () => bagikanKuis(context, kuis),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
