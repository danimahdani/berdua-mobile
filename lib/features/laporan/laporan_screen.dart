import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import '../auth/auth_controller.dart';
import 'laporan_controller.dart';

/// Layar 12: Laporan bulanan.
///
/// Bentuk setiap bagian dipilih dari pekerjaan datanya, bukan selera:
/// total = satu angka dengan cincin anggaran, pembagian pembayar = satu batang
/// bersegmen dengan ubin bernilai, kategori = ubin bernilai (bukan warna
/// saja), tren mingguan = garis (besaran sepanjang waktu).
class LaporanScreen extends ConsumerWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laporan = ref.watch(laporanProvider);
    final bulan = ref.watch(bulanLaporanProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: laporan.when(
        // Isi bulan sebelumnya bertahan selama bulan baru dimuat.
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const SkeletonLaporan(),
        error: (error, _) => GalatLayar(
          pesan: error is ApiException
              ? error.message
              : 'Gagal memuat laporan.',
          onUlangi: () => ref.invalidate(laporanProvider),
        ),
        data: (data) => LayarBerdua(
          judul: 'Laporan',
          kepala: _Kepala(bulan: bulan),
          kunciPantul: bulan,
          children: [
            _PemilihBulan(bulan: bulan),
            const SizedBox(height: Gap.betweenCards),
            if (data.kosong)
              KartuBerdua(
                padding: const EdgeInsets.all(Gap.xxl),
                child: Column(
                  children: [
                    const Stiker.sedang(JenisStiker.chart),
                    const SizedBox(height: Gap.sm),
                    Text(
                      'Belum ada pengeluaran di ${TanggalId.month(bulan)}.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: BerduaColors.label,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _Total(data: data),
              const SizedBox(height: Gap.betweenCards),
              _PembagianPembayar(data: data),
              const SizedBox(height: Gap.betweenCards),
              _Kategori(data: data),
              const SizedBox(height: Gap.betweenCards),
              _TrenMingguan(data: data),
              const SizedBox(height: Gap.betweenCards),
              _Sorotan(data: data),
            ],
          ],
        ),
      ),
    );
  }
}

/// Kepala laporan: kembali, judul dua baris rata kiri, dan pil bulan.
class _Kepala extends StatelessWidget {
  const _Kepala({required this.bulan});

  final DateTime bulan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        const TombolKembali(latar: BerduaColors.card),
        const SizedBox(width: Gap.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uang bersama',
                style: text.labelSmall?.copyWith(fontSize: 12),
              ),
              Text(
                'Laporan',
                style: text.titleLarge?.copyWith(
                  fontSize: 21,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: BerduaColors.card,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: BerduaColors.roseText,
              ),
              const SizedBox(width: 6),
              Text(
                TanggalId.monthYear(bulan),
                style: text.labelSmall?.copyWith(
                  color: BerduaColors.lutealText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Segmen bulan: sebelumnya, yang sedang dilihat, dan berikutnya kalau ada.
class _PemilihBulan extends ConsumerWidget {
  const _PemilihBulan({required this.bulan});

  final DateTime bulan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(bulanLaporanProvider.notifier);
    final lalu = DateTime(bulan.year, bulan.month - 1);
    final depan = DateTime(bulan.year, bulan.month + 1);

    return SegmenBerdua<DateTime>(
      gaya: GayaSegmen.polos,
      // Bulan yang belum terjadi tidak ditawarkan.
      pilihan: [lalu, bulan, if (controller.bisaMaju) depan],
      terpilih: bulan,
      label: TanggalId.month,
      onPilih: (pilihan) {
        if (pilihan == lalu) controller.mundur();
        if (pilihan == depan) controller.maju();
      },
    );
  }
}

/// Judul bagian: ubin ikon berwarna, nama, dan keterangan kanan.
class _JudulBagian extends StatelessWidget {
  const _JudulBagian({
    required this.ikon,
    required this.latar,
    required this.warna,
    required this.judul,
    this.kanan,
  });

  final IconData ikon;
  final Color latar;
  final Color warna;
  final String judul;
  final String? kanan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        UbinIkon(ikon: ikon, latar: latar, warna: warna, ukuran: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            judul,
            style: text.bodyLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (kanan != null)
          Text(
            kanan!,
            style: text.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: BerduaColors.roseText,
            ),
          ),
      ],
    );
  }
}

/// Ubin krem bergaris di dalam kartu laporan.
class _UbinKrem extends StatelessWidget {
  const _UbinKrem({required this.child, this.padding, this.radius = 16});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BerduaColors.background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
      ),
      child: child,
    );
  }
}

/// Angka utama. Satu besaran dengan pembandingnya bukan pekerjaan grafik;
/// cincin hanya muncul kalau ada anggaran untuk dibandingkan.
class _Total extends StatelessWidget {
  const _Total({required this.data});

  final Laporan data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final adaPembanding = data.previousTotal > 0;
    final adaAnggaran = data.budget != null && data.budget! > 0;
    final persen = adaAnggaran
        ? (data.budgetPct ?? (data.total * 100 / data.budget!).round())
        : 0;
    // Naik = belanja lebih banyak, jadi diberi warna pink; turun mint.
    final naik = data.naik;

    return KartuBerdua(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: BerduaColors.mintSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: BerduaColors.mintAngka,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${data.jumlahTransaksi} transaksi tercatat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      fontSize: 12,
                      color: BerduaColors.mintText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Stiker.kecil(JenisStiker.chart),
                        const SizedBox(width: Gap.sm),
                        Flexible(
                          child: Text(
                            'TOTAL PENGELUARAN',
                            style: text.labelSmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.3,
                              color: BerduaColors.label,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Rupiah.format(data.total),
                        style: text.headlineLarge?.copyWith(
                          fontSize: 32,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adaAnggaran
                          ? 'dari anggaran ${Rupiah.format(data.budget!)}'
                          : 'Belum ada anggaran bulanan',
                      style: text.labelSmall?.copyWith(
                        color: BerduaColors.label,
                      ),
                    ),
                  ],
                ),
              ),
              if (adaAnggaran) ...[
                const SizedBox(width: Gap.md),
                Semantics(
                  label: '$persen persen dari anggaran',
                  excludeSemantics: true,
                  child: CincinProgres(
                    nilai: persen / 100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$persen%',
                          style: text.titleMedium?.copyWith(
                            fontSize: 19,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'ANGGARAN',
                          style: text.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: !adaPembanding
                  ? BerduaColors.card2
                  : (naik ? BerduaColors.roseSoft : BerduaColors.mintSoft),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (adaPembanding) ...[
                  Icon(
                    naik
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 15,
                    color: naik ? BerduaColors.roseText : BerduaColors.mintText,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    adaPembanding
                        ? '${naik ? "Naik" : "Turun"} '
                              '${Rupiah.format(data.delta.abs())} dari bulan '
                              'lalu'
                        : 'Belum ada pembanding bulan lalu',
                    style: text.labelSmall?.copyWith(
                      color: !adaPembanding
                          ? BerduaColors.lutealText
                          : (naik
                                ? BerduaColors.roseText
                                : BerduaColors.mintText),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Segmen {
  const _Segmen(this.label, this.nilai, this.warna, this.warnaTeks);

  final String label;
  final int nilai;
  final Color warna;
  final Color warnaTeks;
}

/// Warna mengikuti peran orangnya, bukan urutan besar-kecil.
List<_Segmen> _segmenPembayar(Laporan data, SesiState sesi) {
  _Segmen untuk(String kunci, int nilai) {
    if (kunci == 'wallet') {
      return _Segmen(
        'Dompet',
        nilai,
        ChartColors.dompet,
        ChartColors.dompetTeks,
      );
    }

    final id = int.tryParse(kunci);
    final user = id == sesi.user?.id
        ? sesi.user
        : (id == sesi.partner?.id ? sesi.partner : null);

    if (user == null) {
      return _Segmen(
        'Lainnya',
        nilai,
        ChartColors.pembanding,
        BerduaColors.lutealText,
      );
    }

    return user.tracksCycle
        ? _Segmen(
            user.name,
            nilai,
            ChartColors.pencatat,
            ChartColors.pencatatTeks,
          )
        : _Segmen(
            user.name,
            nilai,
            ChartColors.pasangan,
            ChartColors.pasanganTeks,
          );
  }

  return data.perPembayar.entries
      .where((e) => e.value > 0)
      .map((e) => untuk(e.key, e.value))
      .toList()
    ..sort((a, b) => b.nilai.compareTo(a.nilai));
}

/// Satu batang bersegmen: bagian dari satu keseluruhan, hanya 2-3 pihak.
class _PembagianPembayar extends ConsumerWidget {
  const _PembagianPembayar({required this.data});

  final Laporan data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final segmen = _segmenPembayar(data, ref.watch(sesiProvider));

    if (segmen.isEmpty) return const SizedBox.shrink();

    final total = segmen.fold<int>(0, (sum, s) => sum + s.nilai);

    return KartuBerdua(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PEMBAGIAN PEMBAYAR',
                  style: text.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: BerduaColors.pilihanMati,
                  ),
                ),
              ),
              Text(
                '${segmen.first.label} terbanyak',
                style: text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: BerduaColors.roseText,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          ExcludeSemantics(
            child: SizedBox(
              height: 10,
              child: Row(
                // stretch wajib: kotak tanpa anak tingginya nol kalau barisnya
                // meratakan di tengah, jadi batangnya tidak tergambar.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, s) in segmen.indexed) ...[
                    // Celah 3 dp memisahkan segmen, sehingga batasnya terbaca
                    // tanpa bergantung pada beda warna saja.
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      flex: (s.nilai * 1000 / total).round().clamp(1, 1000),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: s.warna,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: Gap.md),
          // Ubin WAJIB membawa nama dan nilainya: identitas tidak boleh hanya
          // lewat warna.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, s) in segmen.indexed) ...[
                  if (i > 0) const SizedBox(width: Gap.sm),
                  Expanded(
                    child: _UbinKrem(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: s.warna,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  s.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelSmall?.copyWith(
                                    fontSize: 12,
                                    color: BerduaColors.label,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            Rupiah.short(s.nilai),
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${(s.nilai / total * 100).round()}%',
                            style: text.labelSmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: s.warnaTeks,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu ubin per kategori: ikon berwarna, nama, nominal, dan persennya.
class _Kategori extends StatelessWidget {
  const _Kategori({required this.data});

  final Laporan data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final kategori = data.perKategori.entries
        .where((e) => e.value > 0)
        .toList();

    if (kategori.isEmpty) return const SizedBox.shrink();

    final total = kategori.fold<int>(0, (sum, e) => sum + e.value);

    return KartuBerdua(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _JudulBagian(
            ikon: Icons.grid_view_rounded,
            latar: BerduaColors.rakaSoft,
            warna: ChartColors.pasanganTeks,
            judul: 'Kategori',
            kanan: '${kategori.length} aktif',
          ),
          const SizedBox(height: Gap.md),
          LayoutBuilder(
            builder: (context, batas) {
              final lebar = (batas.maxWidth - 2 * Gap.sm) / 3;

              return Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  for (final entry in kategori)
                    SizedBox(
                      // Dikurangi sedikit supaya pembulatan tidak membuat ubin
                      // ketiga turun ke baris berikutnya.
                      width: lebar - .5,
                      child: _ubin(text, entry.key, entry.value, total),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _ubin(TextTheme text, String nama, int nilai, int total) {
    final warna = KategoriWarna.untuk(nama);

    return _UbinKrem(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          UbinIkon(
            ikon: warna.ikon,
            latar: warna.lembut,
            warna: warna.kuat,
            ukuran: 42,
            radius: 14,
          ),
          const SizedBox(height: 6),
          Text(
            nama,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall?.copyWith(color: BerduaColors.pilihanMati),
          ),
          const SizedBox(height: 4),
          // Nilai ditulis langsung, bukan hanya lewat warna.
          Text(
            Rupiah.short(nilai),
            style: text.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: BerduaColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: warna.lembut,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '${(nilai / total * 100).round()}%',
              style: text.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: warna.kuat,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Besaran sepanjang waktu: garis kumulatif, lalu ubin per minggu.
class _TrenMingguan extends StatelessWidget {
  const _TrenMingguan({required this.data});

  final Laporan data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final minggu = data.perMinggu.keys.map(int.parse).toList()..sort();

    if (minggu.isEmpty) return const SizedBox.shrink();

    // Kumulatif: yang dibaca orang adalah seberapa cepat belanja menumpuk.
    var berjalan = 0;
    var terbesar = 0;
    final titik = <FlSpot>[];

    for (final m in minggu) {
      final nilai = data.perMinggu['$m'] ?? 0;

      berjalan += nilai;
      if (nilai > terbesar) terbesar = nilai;

      titik.add(FlSpot(m.toDouble(), berjalan.toDouble()));
    }

    final maksimum = berjalan.toDouble();

    return KartuBerdua(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _JudulBagian(
            ikon: Icons.trending_up_rounded,
            latar: BerduaColors.dindaSoft,
            warna: BerduaColors.dindaText,
            judul: 'Tren kumulatif',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: ChartColors.batang,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Kumulatif ${TanggalId.month(DateTime(data.year, data.month))}',
                style: text.labelSmall?.copyWith(
                  fontSize: 12,
                  color: BerduaColors.label,
                ),
              ),
            ],
          ),
          // Garis butuh minimal dua titik; satu minggu cukup ubinnya saja.
          if (minggu.length >= 2 && maksimum > 0) ...[
            const SizedBox(height: Gap.md),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  minX: minggu.first.toDouble(),
                  maxX: minggu.last.toDouble(),
                  minY: 0,
                  maxY: maksimum * 1.15,
                  // Kisi dan sumbu dibuat recessive: data yang menonjol.
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maksimum / 2,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: BerduaColors.line, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: maksimum / 2,
                        getTitlesWidget: (value, _) => Text(
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
                        interval: 1,
                        getTitlesWidget: (value, _) => Padding(
                          padding: const EdgeInsets.only(top: Gap.xs),
                          child: Text(
                            'M${value.round()}',
                            style: text.labelSmall?.copyWith(
                              fontSize: 11,
                              color: BerduaColors.navMati,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => BerduaColors.ink,
                      tooltipBorderRadius: BorderRadius.circular(9),
                      getTooltipItems: (spots) => spots
                          .map(
                            (spot) => LineTooltipItem(
                              'Minggu ${spot.x.round()}\n'
                              '${Rupiah.format(spot.y.round())}',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: titik,
                      color: ChartColors.batang,
                      barWidth: 3,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      preventCurveOverShooting: true,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                          // Titik terakhir dibesarkan: di situlah total bulan
                          // ini berada.
                          radius: spot == titik.last ? 7 : 4,
                          color: ChartColors.batang,
                          strokeWidth: spot == titik.last ? 4 : 2,
                          strokeColor: spot == titik.last
                              ? BerduaColors.roseSoft
                              : BerduaColors.card,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            ChartColors.batang.withValues(alpha: .3),
                            ChartColors.batang.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: Gap.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, m) in minggu.indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _ubinMinggu(
                    text,
                    m,
                    data.perMinggu['$m'] ?? 0,
                    terbesar,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _ubinMinggu(TextTheme text, int minggu, int nilai, int terbesar) {
    return _UbinKrem(
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mgg $minggu',
            maxLines: 1,
            style: text.labelSmall?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Rupiah.short(nilai),
              style: text.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: BerduaColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              height: 4,
              color: BerduaColors.line,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: terbesar == 0 ? 0 : nilai / terbesar,
                child: ColoredBox(
                  // Minggu terboros pink, sisanya ungu.
                  color: nilai == terbesar && nilai > 0
                      ? ChartColors.batang
                      : ChartColors.batangLain,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sorotan: beberapa kesimpulan yang dihitung dari angka laporan.
class _Sorotan extends ConsumerWidget {
  const _Sorotan({required this.data});

  final Laporan data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final segmen = _segmenPembayar(data, ref.watch(sesiProvider));
    final baris =
        <
          ({
            IconData ikon,
            Color latar,
            Color warna,
            String label,
            String nilai,
            String tag,
          })
        >[];

    final kategori = data.perKategori.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (kategori.isNotEmpty && data.total > 0) {
      final warna = KategoriWarna.untuk(kategori.first.key);

      baris.add((
        ikon: warna.ikon,
        latar: warna.lembut,
        warna: warna.kuat,
        label: 'Kategori terbesar',
        nilai: '${kategori.first.key} · ${Rupiah.format(kategori.first.value)}',
        tag: '${(kategori.first.value / data.total * 100).round()}%',
      ));
    }

    final minggu = data.perMinggu.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (minggu.length > 1) {
      baris.add((
        ikon: Icons.local_fire_department_outlined,
        latar: BerduaColors.roseSoft,
        warna: BerduaColors.roseText,
        label: 'Minggu terboros',
        nilai:
            'Minggu ${minggu.first.key} · ${Rupiah.format(minggu.first.value)}',
        tag: 'Tertinggi',
      ));
    }

    if (data.jumlahTransaksi > 0) {
      baris.add((
        ikon: Icons.receipt_long_outlined,
        latar: BerduaColors.dindaSoft,
        warna: BerduaColors.dindaText,
        label: 'Rata-rata per transaksi',
        nilai: Rupiah.format((data.total / data.jumlahTransaksi).round()),
        tag: '${data.jumlahTransaksi}×',
      ));
    }

    if (segmen.length > 1) {
      final total = segmen.fold<int>(0, (sum, s) => sum + s.nilai);

      baris.add((
        ikon: Icons.person_outline_rounded,
        latar: BerduaColors.kuningSoft,
        warna: BerduaColors.kuningText,
        label: 'Paling sering membayar',
        nilai: '${segmen.first.label} · ${Rupiah.format(segmen.first.nilai)}',
        tag: '${(segmen.first.nilai / total * 100).round()}%',
      ));
    }

    if (baris.isEmpty) return const SizedBox.shrink();

    return KartuBerdua(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _JudulBagian(
            ikon: Icons.auto_awesome_outlined,
            latar: BerduaColors.kuningSoft,
            warna: BerduaColors.kuningText,
            judul: 'Sorotan',
          ),
          const SizedBox(height: 4),
          for (final (i, b) in baris.indexed) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: BerduaColors.line),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  UbinIkon(ikon: b.ikon, latar: b.latar, warna: b.warna),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.label,
                          style: text.labelSmall?.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          b.nilai,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: BerduaColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: b.latar,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      b.tag,
                      style: text.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: b.warna,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
