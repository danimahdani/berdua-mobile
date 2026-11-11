import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import 'siklus_cubit.dart';

/// Layar 15: riwayat siklus dan gejala.
class RiwayatSiklusScreen extends StatelessWidget {
  const RiwayatSiklusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final riwayat = context.watch<RiwayatSiklusCubit>().state;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: riwayat.when(
        loading: () => const SkeletonRiwayat(),
        error: (error, _) => GalatLayar(
          pesan: error is ApiException
              ? error.message
              : 'Gagal memuat riwayat.',
          onUlangi: () => context.read<RiwayatSiklusCubit>().muat(),
        ),
        data: (data) => LayarBerdua(
          judul: 'Riwayat siklus',
          stiker: JenisStiker.flower,
          kembali: true,
          children: [
            if (data.siklus.isEmpty)
              KartuBerdua(
                radius: Radii.cardBesar,
                padding: const EdgeInsets.all(Gap.xxl),
                child: Column(
                  children: [
                    const Stiker.sedang(JenisStiker.flower),
                    const SizedBox(height: Gap.sm),
                    Text(
                      'Belum ada siklus tercatat',
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _Ubin(
                        nilai: Rupiah.decimal(data.rataRataPanjang),
                        label: 'hari rata-rata siklus',
                        warna: BerduaColors.rakaSoft,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Ubin(
                        nilai: Rupiah.decimal(data.rataRataLamaHaid),
                        label: 'hari rata-rata haid',
                        warna: BerduaColors.roseSoft,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Ubin(
                        nilai: data.teratur == null
                            ? '—'
                            : (data.teratur! ? 'Teratur' : 'Tidak'),
                        label: 'selisih ≤ 2 hari',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.xl),
              _KartuSiklus(data: data),
              if (data.gejalaSering.isNotEmpty) ...[
                const SizedBox(height: Gap.betweenCards),
                _KartuGejala(gejala: data.gejalaSering),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Ubin angka: berwarna tanpa garis, atau putih bergaris kalau tanpa warna.
class _Ubin extends StatelessWidget {
  const _Ubin({required this.nilai, required this.label, this.warna});

  final String nilai;
  final String label;
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuBerdua(
      radius: Radii.button,
      padding: const EdgeInsets.all(14),
      warna: warna ?? BerduaColors.card,
      garis: warna == null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              nilai,
              style: text.headlineMedium?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.labelSmall?.copyWith(
              fontSize: 12,
              height: 1.3,
              color: BerduaColors.label,
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuSiklus extends StatelessWidget {
  const _KartuSiklus({required this.data});

  final RiwayatSiklus data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    Widget legenda(Color warna, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: text.labelSmall?.copyWith(
            fontSize: 12,
            color: BerduaColors.label,
          ),
        ),
      ],
    );

    return KartuBerdua(
      radius: Radii.cardBesar,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      stiker: JenisStiker.chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${data.siklus.length} siklus terakhir',
            style: text.bodyLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              legenda(BerduaColors.period, 'haid'),
              const SizedBox(width: 10),
              legenda(BerduaColors.rakaKuat, 'subur'),
            ],
          ),
          for (final siklus in data.siklus) ...[
            const SizedBox(height: Gap.md),
            _BarisSiklus(
              siklus: siklus,
              lamaHaidRata: data.rataRataLamaHaid.round(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Satu siklus: tanggal mulai, panjangnya, lalu satu titik per hari.
class _BarisSiklus extends StatelessWidget {
  const _BarisSiklus({required this.siklus, required this.lamaHaidRata});

  final SiklusLalu siklus;
  final int lamaHaidRata;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final berjalan = siklus.panjangSiklus == null;
    // Siklus terbaru belum punya panjang: baru diketahui setelah haid
    // berikutnya dimulai. Titiknya digambar sampai hari ini saja.
    final panjang = berjalan
        ? (DateTime.now().difference(siklus.mulai).inDays + 1).clamp(1, 45)
        : siklus.panjangSiklus!.clamp(1, 60);
    final lamaHaid = siklus.lamaHaid ?? (lamaHaidRata > 0 ? lamaHaidRata : 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Wrap, bukan Row: di layar sempit keterangannya turun ke bawah.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: Gap.sm,
          children: [
            Text(
              TanggalId.long(siklus.mulai),
              style: text.bodySmall?.copyWith(color: BerduaColors.ink),
            ),
            Text(
              [
                berjalan ? 'berjalan' : '${siklus.panjangSiklus} hari',
                if (siklus.lamaHaid != null) 'haid ${siklus.lamaHaid} hari',
              ].join(' · '),
              style: text.bodySmall?.copyWith(color: BerduaColors.label),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, batas) {
              // Titik mengecil kalau siklusnya panjang, supaya tetap sebaris.
              final sisi = math.min(
                9.0,
                (batas.maxWidth - 2 * (panjang - 1)) / panjang,
              );

              return Row(
                children: [
                  for (var hari = 1; hari <= panjang; hari++) ...[
                    if (hari > 1) const SizedBox(width: 2),
                    Container(
                      width: sisi,
                      height: sisi,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: switch (faseHariSiklus(
                          hari,
                          // Masa subur siklus berjalan dihitung dari panjang
                          // rata-rata, bukan dari hari yang sudah lewat.
                          berjalan ? math.max(panjang, 28) : panjang,
                          lamaHaid,
                        )) {
                          'haid' => BerduaColors.period,
                          'subur' => BerduaColors.rakaKuat,
                          _ => BerduaColors.netral,
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Gelembung gejala: makin sering, makin besar.
class _KartuGejala extends StatelessWidget {
  const _KartuGejala({required this.gejala});

  final Map<String, int> gejala;

  static const _warna = [
    BerduaColors.roseSoft,
    BerduaColors.rakaSoft,
    BerduaColors.dindaSoft,
    BerduaColors.kuningSoft,
    BerduaColors.mintSoft,
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final urut = gejala.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final terbanyak = math.max(urut.first.value, 1);

    return KartuBerdua(
      radius: Radii.cardBesar,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Stiker.kecil(JenisStiker.heart),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(
                  'Gejala paling sering',
                  style: text.bodyLarge?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final (i, entry) in urut.indexed)
                _Gelembung(
                  nama: entry.key,
                  jumlah: entry.value,
                  diameter: 72 + 40 * entry.value / terbanyak,
                  warna: _warna[i % _warna.length],
                  derajat: i.isEven ? -4 : 4,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Gelembung extends StatelessWidget {
  const _Gelembung({
    required this.nama,
    required this.jumlah,
    required this.diameter,
    required this.warna,
    required this.derajat,
  });

  final String nama;
  final int jumlah;
  final double diameter;
  final Color warna;
  final double derajat;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      label: '$nama, $jumlah kali',
      excludeSemantics: true,
      child: Transform.rotate(
        angle: derajat * math.pi / 180,
        child: Container(
          width: diameter,
          height: diameter,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$jumlah×',
                style: text.titleMedium?.copyWith(
                  fontSize: diameter * .22,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                nama,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(
                  fontSize: 12,
                  height: 1.2,
                  color: BerduaColors.pilihanMati,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
