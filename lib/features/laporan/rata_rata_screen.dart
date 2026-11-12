import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import 'rata_rata_cubit.dart';

/// Rata-rata pengeluaran bersama per minggu, bulan, atau tahun.
///
/// Bentuknya: satu angka utama (pekerjaannya satu besaran), lalu batang per
/// periode dengan garis rata-rata (besaran sepanjang waktu, satu seri), lalu
/// rata-rata tiap kategori sebagai baris bernilai.
class RataRataScreen extends StatelessWidget {
  const RataRataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final muatan = context.watch<RataRataCubit>().state;
    final periode = context.watch<PeriodeRataRataCubit>().state;

    return Scaffold(
      body: muatan.when(
        // Isi rentang sebelumnya bertahan selama rentang baru dimuat.
        loading: () => const SkeletonLaporan(),
        error: (error, _) => GalatLayar(
          pesan: error is ApiException
              ? error.message
              : 'Gagal memuat rata-rata pengeluaran.',
          onUlangi: () => context.read<RataRataCubit>().muat(),
        ),
        data: (data) => LayarBerdua(
          judul: 'Rata-rata',
          stiker: JenisStiker.chart,
          kembali: true,
          kunciPantul: periode,
          onSegarkan: () => context.read<RataRataCubit>().segarkan(),
          children: [
            SegmenBerdua<PeriodeRataRata>(
              pilihan: PeriodeRataRata.values,
              terpilih: periode,
              label: (p) => p.label,
              onPilih: context.read<PeriodeRataRataCubit>().pilih,
            ),
            const SizedBox(height: Gap.betweenCards),
            if (data.kosong)
              KartuBerdua(
                padding: const EdgeInsets.all(Gap.xxl),
                child: Column(
                  children: [
                    const Stiker.sedang(JenisStiker.chart),
                    const SizedBox(height: Gap.sm),
                    Text(
                      'Belum ada pengeluaran untuk dirata-rata.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BerduaColors.label,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _Utama(data: data),
              const SizedBox(height: Gap.betweenCards),
              _Grafik(data: data),
              const SizedBox(height: Gap.betweenCards),
              _TertinggiTerendah(data: data),
              if (data.perKategori.isNotEmpty) ...[
                const SizedBox(height: Gap.betweenCards),
                _Kategori(data: data),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Angka utama dan apa yang dirata-rata.
class _Utama extends StatelessWidget {
  const _Utama({required this.data});

  final RataRata data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final satuan = data.periode.satuan;
    final berjalan = data.berjalan;

    final keterangan = data.tanpaBerjalan
        ? 'Dari ${data.jumlahPeriode} $satuan terakhir. '
              '${data.periode.yangBerjalan} belum dihitung karena masih '
              'berjalan.'
        : 'Baru ada satu $satuan tercatat, jadi $satuan ini itulah '
              'patokannya.';

    return KartuRose(
      stiker: JenisStiker.coin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RATA-RATA PER ${satuan.toUpperCase()}',
            style: text.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: BerduaColors.label,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Rupiah.format(data.rataRata),
              style: text.headlineLarge?.copyWith(fontSize: 34, height: 1.1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            keterangan,
            style: text.labelSmall?.copyWith(fontSize: 13, height: 1.45),
          ),
          if (berjalan != null && data.tanpaBerjalan) ...[
            const SizedBox(height: Gap.md),
            _ChipBanding(
              berjalan: berjalan,
              rataRata: data.rataRata,
              periode: data.periode,
            ),
          ],
        ],
      ),
    );
  }
}

/// "Minggu ini sejauh ini Rp 70.000 · 30% dari rata-rata".
class _ChipBanding extends StatelessWidget {
  const _ChipBanding({
    required this.berjalan,
    required this.rataRata,
    required this.periode,
  });

  final PeriodeUang berjalan;
  final int rataRata;
  final PeriodeRataRata periode;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lewat = rataRata > 0 && berjalan.total > rataRata;
    final persen = rataRata == 0
        ? null
        : (berjalan.total * 100 / rataRata).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: lewat ? BerduaColors.roseSoft : BerduaColors.mintSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            lewat ? Icons.trending_up_rounded : Icons.hourglass_bottom_rounded,
            size: 15,
            color: lewat ? BerduaColors.roseText : BerduaColors.mintText,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${periode.yangBerjalan} sejauh ini '
              '${Rupiah.format(berjalan.total)}'
              '${persen == null ? "" : " · $persen% dari rata-rata"}',
              style: text.labelSmall?.copyWith(
                fontSize: 13,
                color: lewat ? BerduaColors.roseText : BerduaColors.mintText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Batang per periode dengan garis putus-putus di nilai rata-rata.
class _Grafik extends StatelessWidget {
  const _Grafik({required this.data});

  final RataRata data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final daftar = data.daftar;
    final terbesar = daftar.fold<int>(
      data.rataRata,
      (m, p) => p.total > m ? p.total : m,
    );
    final maksimum = terbesar == 0 ? 1.0 : terbesar * 1.2;

    // Label sumbu dijarangkan supaya tidak bertabrakan; yang terakhir (periode
    // berjalan) selalu diberi label.
    final langkah = switch (data.periode) {
      PeriodeRataRata.minggu => daftar.length > 6 ? 3 : 1,
      PeriodeRataRata.bulan => daftar.length > 8 ? 2 : 1,
      PeriodeRataRata.tahun => 1,
    };

    return KartuBerdua(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const UbinIkon(
                ikon: Icons.bar_chart_rounded,
                latar: BerduaColors.roseSoft,
                warna: BerduaColors.roseText,
                ukuran: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pengeluaran per ${data.periode.satuan}',
                  style: text.bodyLarge?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maksimum,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maksimum / 2,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: BerduaColors.line, strokeWidth: 1),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (data.rataRata > 0)
                      HorizontalLine(
                        y: data.rataRata.toDouble(),
                        color: BerduaColors.ink,
                        strokeWidth: 1.5,
                        dashArray: [5, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(bottom: 2, right: 2),
                          style: text.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: BerduaColors.ink,
                          ),
                          labelResolver: (_) => 'rata-rata',
                        ),
                      ),
                  ],
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: maksimum / 2,
                      getTitlesWidget: (value, meta) => value == meta.max
                          ? const SizedBox.shrink()
                          : Text(
                              Rupiah.short(value.round()),
                              style: text.labelSmall?.copyWith(
                                fontSize: 11,
                                color: BerduaColors.navMati,
                              ),
                            ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) {
                        final i = value.round();

                        if (i < 0 ||
                            i >= daftar.length ||
                            (daftar.length - 1 - i) % langkah != 0) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: Gap.xs),
                          child: Text(
                            daftar[i].labelSumbu(data.periode),
                            style: text.labelSmall?.copyWith(
                              fontSize: 11,
                              color: BerduaColors.navMati,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => BerduaColors.ink,
                    tooltipBorderRadius: BorderRadius.circular(9),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, _, _, _) {
                      final p = daftar[group.x];

                      return BarTooltipItem(
                        '${p.labelPanjang(data.periode)}'
                        '${p.berjalan ? " (berjalan)" : ""}\n'
                        '${Rupiah.format(p.total)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (final (i, p) in daftar.indexed)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: p.total.toDouble(),
                          width: daftar.length > 8 ? 12 : 20,
                          // Periode berjalan belum utuh: warnanya dibedakan,
                          // dan keterangannya ditulis di bawah grafik.
                          color: p.berjalan && data.tanpaBerjalan
                              ? ChartColors.batangLain
                              : ChartColors.batang,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (data.tanpaBerjalan) ...[
            const SizedBox(height: Gap.sm),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: ChartColors.batangLain,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${data.periode.yangBerjalan}, masih berjalan',
                    style: text.labelSmall?.copyWith(
                      fontSize: 12,
                      color: BerduaColors.label,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Periode termahal dan terhemat di antara yang dirata-rata.
class _TertinggiTerendah extends StatelessWidget {
  const _TertinggiTerendah({required this.data});

  final RataRata data;

  @override
  Widget build(BuildContext context) {
    final tinggi = data.tertinggi;
    final rendah = data.terendah;

    if (tinggi == null || rendah == null || data.jumlahPeriode < 2) {
      return const SizedBox.shrink();
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Ubin(
              ikon: Icons.local_fire_department_outlined,
              latar: BerduaColors.roseSoft,
              warna: BerduaColors.roseText,
              label: 'Paling boros',
              nilai: Rupiah.format(tinggi.total),
              periode: tinggi.labelPanjang(data.periode),
            ),
          ),
          const SizedBox(width: Gap.betweenCards),
          Expanded(
            child: _Ubin(
              ikon: Icons.savings_outlined,
              latar: BerduaColors.mintSoft,
              warna: BerduaColors.mintText,
              label: 'Paling hemat',
              nilai: Rupiah.format(rendah.total),
              periode: rendah.labelPanjang(data.periode),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ubin extends StatelessWidget {
  const _Ubin({
    required this.ikon,
    required this.latar,
    required this.warna,
    required this.label,
    required this.nilai,
    required this.periode,
  });

  final IconData ikon;
  final Color latar;
  final Color warna;
  final String label;
  final String nilai;
  final String periode;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuBerdua(
      radius: Radii.button,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UbinIkon(ikon: ikon, latar: latar, warna: warna, ukuran: 30),
          const SizedBox(height: Gap.sm),
          Text(label, style: text.labelSmall?.copyWith(fontSize: 12)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              nilai,
              style: text.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            periode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall?.copyWith(
              fontSize: 12,
              color: BerduaColors.label,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rata-rata tiap kategori per periode: ikon, nama, nominal, dan batang tipis.
class _Kategori extends StatelessWidget {
  const _Kategori({required this.data});

  final RataRata data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final baris = data.perKategori.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (baris.isEmpty) return const SizedBox.shrink();

    final terbesar = baris.first.value;

    return KartuBerdua(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const UbinIkon(
                ikon: Icons.grid_view_rounded,
                latar: BerduaColors.rakaSoft,
                warna: ChartColors.pasanganTeks,
                ukuran: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Per kategori',
                  style: text.bodyLarge?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'per ${data.periode.satuan}',
                style: text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: BerduaColors.roseText,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          for (final e in baris) ...[
            const SizedBox(height: Gap.sm),
            _BarisKategori(
              nama: e.key,
              nilai: e.value,
              porsi: terbesar == 0 ? 0 : e.value / terbesar,
            ),
          ],
        ],
      ),
    );
  }
}

class _BarisKategori extends StatelessWidget {
  const _BarisKategori({
    required this.nama,
    required this.nilai,
    required this.porsi,
  });

  final String nama;
  final int nilai;
  final double porsi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final warna = KategoriWarna.untuk(nama);

    return Row(
      children: [
        UbinIkon(
          ikon: warna.ikon,
          latar: warna.lembut,
          warna: warna.kuat,
          ukuran: 36,
        ),
        const SizedBox(width: Gap.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(fontSize: 15),
                    ),
                  ),
                  Text(
                    Rupiah.format(nilai),
                    style: text.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 6,
                  color: BerduaColors.line,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: porsi.clamp(0, 1),
                    child: ColoredBox(
                      color: warna.kuat,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
