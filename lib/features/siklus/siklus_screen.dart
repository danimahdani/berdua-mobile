import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import '../auth/sesi_cubit.dart';
import 'catatan_hari_cubit.dart';
import 'katalog_catatan.dart';
import 'pil_kb.dart';
import 'siklus_cubit.dart';

/// Layar 13 (tampilan pencatat) dan 14 (tampilan pasangan).
///
/// Satu layar untuk keduanya: yang membedakan hanya `bisaUbah` dan kehadiran
/// tips dukungan, persis seperti aturan §5.3.
class SiklusScreen extends StatelessWidget {
  const SiklusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final siklus = context.watch<SiklusCubit>().state;

    return Scaffold(
      body: siklus.when(
        loading: () => const SkeletonSiklus(),
        error: (error, _) => GalatLayar(
          tab: 2,
          pesan: error is ApiException ? error.message : 'Gagal memuat siklus.',
          onUlangi: () => context.read<SiklusCubit>().muat(),
        ),
        data: (data) => _Isi(data: data),
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.data});

  final Siklus data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sesi = context.watch<SesiCubit>().state;
    final pencatat = sesi.user?.tracksCycle ?? false;
    final nama = data.ownerName.isEmpty ? 'Pasanganmu' : data.ownerName;

    Future<void> segarkan() => Future.wait([
      context.read<SiklusCubit>().segarkan(),
      context.read<PilCubit>().segarkan(),
    ]);

    // Belum ada catatan sama sekali.
    if (!data.tercatat) {
      return LayarBerdua(
        judul: 'Siklus',
        stiker: JenisStiker.flower,
        tab: 2,
        onSegarkan: segarkan,
        children: [
          const SizedBox(height: Gap.sm),
          _KartuPesan(
            judul: 'Belum ada catatan siklus',
            isi: data.pesan.isNotEmpty
                ? data.pesan
                : (pencatat
                      ? 'Tandai hari pertama haid untuk memulai. Prediksi '
                            'muncul setelah ada catatan.'
                      : 'Kalender muncul di sini setelah siklus mulai '
                            'dicatat.'),
            stiker: JenisStiker.flower,
          ),
          if (pencatat) ...[
            const SizedBox(height: Gap.xl),
            _TombolHaid(data: data),
            const KartuPil(),
          ],
        ],
      );
    }

    // Pasangan belum membagikan (§5.3).
    if (!data.dibagikan) {
      return LayarBerdua(
        judul: 'Siklus $nama',
        stiker: JenisStiker.flower,
        tab: 2,
        onSegarkan: segarkan,
        children: [
          const SizedBox(height: Gap.sm),
          _KartuPesan(
            judul: '$nama belum membagikan siklusnya',
            isi: data.pesan.isNotEmpty
                ? data.pesan
                : 'Kalender dan tips dukungan muncul di sini setelah $nama '
                      'mengaktifkan berbagi di Profil.',
          ),
          const KartuPil(),
        ],
      );
    }

    final namaPasangan = sesi.partner == null || sesi.partner!.name.isEmpty
        ? 'pasangan'
        : sesi.partner!.name;

    return LayarBerdua(
      judul: data.bisaUbah ? 'Siklus' : 'Siklus $nama',
      stiker: JenisStiker.flower,
      tab: 2,
      onSegarkan: segarkan,
      children: [
        const SizedBox(height: Gap.sm),
        _KartuFase(data: data),
        if (data.peluangHamil != null) ...[
          const SizedBox(height: Gap.xl),
          _KartuPeluang(data: data),
        ],
        const SizedBox(height: Gap.xl),
        _Kalender(data: data),
        const SizedBox(height: Gap.xl),
        _TautanRiwayat(data: data),

        if (data.bisaUbah) ...[
          const SizedBox(height: Gap.xl),
          _KartuCatatanHariIni(
            gejala: data.gejalaHariIni,
            catatan: sesi.partner == null
                ? 'Hanya kamu yang melihat catatan harian ini.'
                : 'Selama siklus dibagikan, $namaPasangan bisa melihat '
                      'catatan harianmu, tetapi tidak bisa mengubahnya.',
          ),
          const SizedBox(height: Gap.lg),
          _TombolHaid(data: data),
          const KartuPil(),
        ],

        if (data.tips != null) ...[
          const SizedBox(height: Gap.xl),
          _KartuTips(tips: data.tips!, nama: nama),
        ],

        if (!data.bisaUbah) ...[
          const KartuPil(),
          const SizedBox(height: Gap.betweenCards),
          KartuBerdua(
            radius: Radii.button,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan $nama hari ini',
                  style: text.labelSmall?.copyWith(color: BerduaColors.label),
                ),
                const SizedBox(height: 2),
                Text(
                  data.gejalaHariIni.isEmpty
                      ? 'Belum ada catatan'
                      : data.gejalaHariIni.map(kapitalAwal).join(' · '),
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],

        if (data.disclaimer.isNotEmpty) ...[
          const SizedBox(height: Gap.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              data.disclaimer,
              style: text.labelSmall?.copyWith(height: 1.5),
            ),
          ),
        ],
      ],
    );
  }
}

/// Kartu pesan di tengah: belum dicatat atau belum dibagikan.
class _KartuPesan extends StatelessWidget {
  const _KartuPesan({required this.judul, required this.isi, this.stiker});

  final String judul;
  final String isi;
  final JenisStiker? stiker;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuBerdua(
      radius: Radii.cardBesar,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      stiker: stiker,
      child: Column(
        children: [
          if (stiker == null) ...[
            const Icon(
              Icons.lock_outline_rounded,
              color: BerduaColors.label,
              size: 26,
            ),
            const SizedBox(height: Gap.sm),
          ],
          Text(
            judul,
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Gap.sm),
          Text(
            isi,
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(
              fontSize: 15,
              height: 1.5,
              color: BerduaColors.label,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu lavender: cincin siklus, fase, dan perkiraan haid berikutnya.
class _KartuFase extends StatelessWidget {
  const _KartuFase({required this.data});

  final Siklus data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final panjang = data.rataRataPanjang.round();
    final lamaHaid = data.rataRataLamaHaid.round();
    final hari = data.hariSampaiHaid;
    final berikutnya = DateTime.now().add(Duration(days: hari));

    return KartuRose(
      warna: BerduaColors.rakaSoft,
      padding: const EdgeInsets.all(20),
      stiker: JenisStiker.flower,
      child: Row(
        children: [
          CincinSiklus(
            hariKe: data.hariKe,
            panjang: panjang > 0 ? panjang : 28,
            lamaHaid: lamaHaid > 0 ? lamaHaid : 5,
            ukuran: 110,
            lubang: 74,
            warnaLubang: BerduaColors.rakaSoft,
          ),
          const SizedBox(width: Gap.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.faseLabel.isEmpty ? 'Siklus' : data.faseLabel,
                  style: text.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hari <= 0
                      ? 'Haid diperkirakan sekitar hari ini'
                      : 'Haid berikutnya ±${TanggalId.short(berikutnya)}, '
                            '$hari hari lagi',
                  style: text.bodySmall?.copyWith(
                    fontSize: 15,
                    height: 1.4,
                    color: BerduaColors.lutealText,
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

/// Warna tiap tingkat peluang. Tingkatnya selalu ikut ditulis sebagai teks,
/// jadi warna hanya penguat.
({Color latar, Color teks}) _warnaPeluang(PeluangHamil peluang) =>
    switch (peluang) {
      PeluangHamil.rendah => (
        latar: BerduaColors.mintSoft,
        teks: BerduaColors.mintText,
      ),
      PeluangHamil.sedang => (
        latar: BerduaColors.kuningSoft,
        teks: BerduaColors.kuningText,
      ),
      PeluangHamil.tinggi => (
        latar: BerduaColors.roseSoft,
        teks: BerduaColors.roseText,
      ),
    };

/// "12–16 Nov" atau "28 Nov – 2 Des".
String _rentang(DateTime mulai, DateTime selesai) =>
    mulai.month == selesai.month && mulai.year == selesai.year
    ? '${mulai.day}–${TanggalId.short(selesai)}'
    : '${TanggalId.short(mulai)} – ${TanggalId.short(selesai)}';

/// Kartu perkiraan peluang kehamilan hari ini, dengan masa subur terdekat.
class _KartuPeluang extends StatelessWidget {
  const _KartuPeluang({required this.data});

  final Siklus data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final peluang = data.peluangHamil!;
    final warna = _warnaPeluang(peluang);
    final mulai = data.masaSuburMulai;
    final selesai = data.masaSuburSelesai;

    final penjelasan = switch (peluang) {
      PeluangHamil.tinggi =>
        'Hari ini di dalam perkiraan masa subur. Peluang hamil paling besar '
            'di hari-hari ini.',
      PeluangHamil.sedang =>
        'Hari ini dekat dengan perkiraan masa subur. Kehamilan masih mungkin '
            'terjadi.',
      PeluangHamil.rendah =>
        'Hari ini di luar perkiraan masa subur. Peluangnya kecil, tetapi '
            'tidak nol.',
    };

    // Seberapa bisa dipercaya perkiraannya, menurut riwayat yang ada.
    final ketepatan = switch (data.teratur) {
      false =>
        'Siklus belum teratur, jadi perkiraan ini bisa meleset beberapa hari.',
      null =>
        'Riwayat siklus masih sedikit, jadi perkiraan ini belum begitu tepat.',
      true => null,
    };

    String? masaSubur;

    if (mulai != null && selesai != null) {
      final kini = DateTime.now();
      final hariIni = DateTime(kini.year, kini.month, kini.day);

      masaSubur = mulai.isAfter(hariIni)
          ? 'Masa subur berikutnya ±${_rentang(mulai, selesai)}'
          : 'Masa subur ±${_rentang(mulai, selesai)}, sedang berlangsung';
    }

    return Semantics(
      label: 'Peluang kehamilan hari ini ${peluang.label}. $penjelasan',
      child: KartuBerdua(
        radius: Radii.cardBesar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Peluang kehamilan',
                    style: text.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: warna.latar,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: BerduaColors.ink,
                      width: Sizes.garis,
                    ),
                  ),
                  child: Text(
                    peluang.label,
                    style: text.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: warna.teks,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            // Tiga ruas: terisi sampai tingkat hari ini.
            ExcludeSemantics(
              child: Row(
                children: [
                  for (final tingkat in PeluangHamil.values) ...[
                    if (tingkat.index > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: tingkat.index <= peluang.index
                              ? warna.latar
                              : BerduaColors.card,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: BerduaColors.ink,
                            width: Sizes.garis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Gap.md),
            Text(
              penjelasan,
              style: text.bodyMedium?.copyWith(fontSize: 15, height: 1.45),
            ),
            if (masaSubur != null) ...[
              const SizedBox(height: 6),
              Text(
                masaSubur,
                style: text.bodyMedium?.copyWith(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: Gap.md),
            Text(
              [
                'Perkiraan dari kalender saja. Jangan dipakai sebagai alat '
                    'kontrasepsi maupun kepastian untuk program hamil.',
                ?ketepatan,
              ].join(' '),
              style: text.labelSmall?.copyWith(fontSize: 13, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

/// §16: kalender sel 40 dp dengan warna fase. Mengetuk tanggal memilihnya:
/// rinciannya tampil di bawah kalender, dan pencatat bisa membuka catatan
/// harian tanggal itu.
class _Kalender extends StatefulWidget {
  const _Kalender({required this.data});

  final Siklus data;

  @override
  State<_Kalender> createState() => _KalenderState();
}

class _KalenderState extends State<_Kalender> {
  static const _namaHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  /// Tanggal yang diketuk; null = hari ini (kalau ada di bulan ini).
  DateTime? _dipilih;

  /// true selama bulan lain sedang dimuat.
  bool _memuat = false;

  @override
  void didUpdateWidget(_Kalender lama) {
    super.didUpdateWidget(lama);

    // Bulan berganti: pilihan lama tidak lagi ada di kalender.
    if (lama.data.bulan != widget.data.bulan) _dipilih = null;
  }

  Future<void> _geser(DateTime acuan, int bulan) async {
    setState(() => _memuat = true);

    await context.read<SiklusCubit>().gantiBulan(
      DateTime(acuan.year, acuan.month + bulan),
    );

    if (mounted) setState(() => _memuat = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final data = widget.data;
    final hari = data.kalender;

    if (hari.isEmpty) return const SizedBox.shrink();

    final acuan = data.bulan ?? hari.first.tanggal;

    HariSiklus? terpilih;

    for (final h in hari) {
      if (_dipilih == null ? h.hariIni : h.tanggal == _dipilih) terpilih = h;
    }

    // Senin = 1 pada DateTime.weekday, jadi sel kosong di awal bulan dihitung
    // langsung dari hari pertama.
    final kosong = hari.first.tanggal.weekday - 1;
    final sel = <Widget?>[
      for (var i = 0; i < kosong; i++) null,
      for (final h in hari)
        _SelHari(
          key: ValueKey('sel-${h.tanggal.day}'),
          hari: h,
          dipilih: identical(h, terpilih),
          onTap: () => setState(() => _dipilih = h.tanggal),
        ),
    ];

    return KartuBerdua(
      radius: Radii.cardBesar,
      stiker: JenisStiker.cal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 48),
            child: Row(
              children: [
                TombolIkon(
                  ikon: Icons.chevron_left_rounded,
                  keterangan: 'Bulan sebelumnya',
                  ukuran: 36,
                  onTap: _memuat ? () {} : () => _geser(acuan, -1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        TanggalId.monthYear(acuan),
                        textAlign: TextAlign.center,
                        style: text.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (data.rataRataPanjang > 0)
                        Text(
                          'siklus ${Rupiah.decimal(data.rataRataPanjang)} hari',
                          style: text.labelSmall,
                        ),
                    ],
                  ),
                ),
                TombolIkon(
                  ikon: Icons.chevron_right_rounded,
                  keterangan: 'Bulan berikutnya',
                  ukuran: 36,
                  onTap: _memuat ? () {} : () => _geser(acuan, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final nama in _namaHari)
                Expanded(
                  child: Text(
                    nama,
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Baris demi baris, bukan GridView, supaya tinggi sel tetap 40 dp
          // berapa pun lebar layarnya.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: _memuat ? .45 : 1,
            child: Column(
              children: [
                for (var awal = 0; awal < sel.length; awal += 7) ...[
                  if (awal > 0) const SizedBox(height: 4),
                  Row(
                    children: [
                      for (var i = awal; i < awal + 7; i++) ...[
                        if (i > awal) const SizedBox(width: 4),
                        Expanded(
                          child:
                              (i < sel.length ? sel[i] : null) ??
                              const SizedBox(height: _tinggiSel),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Gap.md),
          // Keterangan warna ada di balik tombol (i), seperti kalender
          // aplikasi siklus pada umumnya; rinciannya membawa tombol itu.
          if (terpilih != null)
            _RincianHari(hari: terpilih, bisaUbah: data.bisaUbah)
          else
            const Align(
              alignment: Alignment.centerRight,
              child: _TombolKeterangan(),
            ),
        ],
      ),
    );
  }
}

/// Nama tiap penanda catatan harian, untuk ringkasan di bawah kalender.
const _namaPenanda = {
  'flow': 'aliran haid',
  'note': 'catatan',
  'intimacy': 'hubungan intim',
  'pill': 'pil KB',
  'symptoms': 'gejala',
  'mood': 'suasana hati',
  'test': 'hasil tes',
  'body': 'catatan tubuh',
};

/// Rincian tanggal yang dipilih: posisi di siklus, peluang hamil, apa saja
/// yang sudah dicatat, dan tombol menuju catatan hariannya.
class _RincianHari extends StatelessWidget {
  const _RincianHari({required this.hari, required this.bisaUbah});

  final HariSiklus hari;
  final bool bisaUbah;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final kini = DateTime.now();
    final belumTiba = hari.tanggal.isAfter(
      DateTime(kini.year, kini.month, kini.day),
    );
    final peluang = hari.peluangHamil;

    final tercatat = [
      for (final MapEntry(key: kunci, value: nama) in _namaPenanda.entries)
        if (hari.penanda.contains(kunci)) nama,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BerduaColors.card2,
        borderRadius: BorderRadius.circular(Radii.pilihan),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${TanggalId.short(hari.tanggal)}'
                  '${hari.hariKe > 0 ? " · Hari siklus ${hari.hariKe}" : ""}',
                  style: text.bodyLarge?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const _TombolKeterangan(),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Fase ${hari.fase}'
            '${hari.ovulasi ? " · perkiraan hari ovulasi" : ""}'
            '${peluang == null ? "" : " · peluang hamil ${peluang.label.toLowerCase()}"}'
            '${hari.perkiraan ? " (perkiraan)" : ""}',
            style: text.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
          ),
          if (!bisaUbah && !belumTiba) ...[
            const SizedBox(height: 4),
            Text(
              tercatat.isEmpty
                  ? 'Belum ada catatan di tanggal ini.'
                  : 'Tercatat: ${tercatat.join(", ")}',
              style: text.labelSmall?.copyWith(fontSize: 13, height: 1.45),
            ),
            if (tercatat.isNotEmpty) ...[
              const SizedBox(height: Gap.md),
              TombolPink(
                label: 'Lihat catatan',
                tinggi: 46,
                ukuranHuruf: 16,
                tebal: FontWeight.w600,
                onPressed: () =>
                    context.push('/siklus/hari/${tanggalKawat(hari.tanggal)}'),
              ),
            ],
          ],
          if (bisaUbah) ...[
            const SizedBox(height: 4),
            Text(
              tercatat.isEmpty
                  ? (belumTiba
                        ? 'Bisa dicatat mulai pada tanggalnya.'
                        : 'Belum ada catatan di tanggal ini.')
                  : 'Tercatat: ${tercatat.join(", ")}',
              style: text.labelSmall?.copyWith(fontSize: 13, height: 1.45),
            ),
            if (!belumTiba) ...[
              const SizedBox(height: Gap.md),
              TombolPink(
                label: tercatat.isEmpty ? 'Catat' : 'Ubah catatan',
                tinggi: 46,
                ukuranHuruf: 16,
                tebal: FontWeight.w600,
                onPressed: () =>
                    context.push('/siklus/hari/${tanggalKawat(hari.tanggal)}'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Tinggi sel kalender: muat tanggal besar dan nomor hari siklus kecil.
const _tinggiSel = 54.0;

/// Warna sel per fase, memakai warna fase tema Berdua.
({Color latar, Color teks, Color kecil}) _warnaSel(HariSiklus hari) =>
    switch (hari.fase) {
      'haid' when hari.perkiraan => (
        latar: BerduaColors.roseSoft,
        teks: BerduaColors.roseText,
        kecil: BerduaColors.roseText,
      ),
      'haid' => (
        latar: BerduaColors.period,
        teks: BerduaColors.ink,
        kecil: BerduaColors.periodText,
      ),
      'subur' => (
        latar: BerduaColors.rakaSoft,
        teks: BerduaColors.ink,
        kecil: BerduaColors.fertileText,
      ),
      _ => (
        latar: BerduaColors.card,
        teks: BerduaColors.ink,
        kecil: BerduaColors.label,
      ),
    };

/// Penanda kecil di pojok kiri atas sel.
class _IkonSel extends StatelessWidget {
  const _IkonSel.subur() : ovulasi = false;
  const _IkonSel.ovulasi() : ovulasi = true;

  final bool ovulasi;

  @override
  Widget build(BuildContext context) {
    if (!ovulasi) {
      return const Icon(
        Icons.eco_rounded,
        size: 12,
        color: BerduaColors.fertileText,
      );
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: BerduaColors.ovulasi,
        shape: BoxShape.circle,
        border: Border.all(color: BerduaColors.card, width: 1.5),
      ),
    );
  }
}

/// Penanda "ada catatan harian".
class _BintangCatatan extends StatelessWidget {
  const _BintangCatatan();

  @override
  Widget build(BuildContext context) => const Icon(
    Icons.auto_awesome_rounded,
    size: 11,
    color: BerduaColors.roseText,
  );
}

class _SelHari extends StatelessWidget {
  const _SelHari({
    super.key,
    required this.hari,
    required this.dipilih,
    required this.onTap,
  });

  final HariSiklus hari;
  final bool dipilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final warna = _warnaSel(hari);
    final peluang = hari.peluangHamil;
    final adaCatatan = hari.penanda.isNotEmpty;
    final polos = warna.latar == BerduaColors.card;

    return Semantics(
      label:
          '${TanggalId.short(hari.tanggal)}, ${hari.fase}'
          '${hari.hariKe > 0 ? ", hari siklus ${hari.hariKe}" : ""}'
          '${hari.ovulasi ? ", perkiraan ovulasi" : ""}'
          '${peluang == null ? "" : ", peluang hamil ${peluang.label.toLowerCase()}"}'
          '${hari.perkiraan ? ", perkiraan" : ""}'
          '${adaCatatan ? ", ada catatan" : ""}'
          '${hari.hariIni ? ", hari ini" : ""}',
      button: true,
      selected: dipilih,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: _tinggiSel,
          padding: const EdgeInsets.fromLTRB(5, 4, 5, 3),
          decoration: BoxDecoration(
            color: warna.latar,
            borderRadius: BorderRadius.circular(10),
            // Dipilih = garis ungu tebal; hari ini = garis tinta; hari biasa
            // bergaris tipis supaya tetap terbaca sebagai kotak tanggal.
            border: dipilih
                ? Border.all(color: BerduaColors.rakaText, width: 2.5)
                : hari.hariIni
                ? Border.all(color: BerduaColors.ink, width: 2)
                : (polos ? Border.all(color: BerduaColors.line) : null),
          ),
          child: Stack(
            children: [
              if (hari.ovulasi)
                const Positioned(left: 0, top: 0, child: _IkonSel.ovulasi())
              else if (hari.fase == 'subur')
                const Positioned(left: 0, top: 0, child: _IkonSel.subur()),
              // Nomor hari siklus di pojok kanan atas.
              if (hari.hariKe > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Text(
                    '${hari.hariKe}',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                      color: warna.kecil,
                    ),
                  ),
                ),
              // Tanggal besar di kiri bawah.
              Positioned(
                left: 0,
                bottom: 0,
                child: Text(
                  '${hari.tanggal.day}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 17,
                    height: 1.1,
                    fontWeight: hari.hariIni
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: warna.teks,
                  ),
                ),
              ),
              if (adaCatatan)
                const Positioned(right: 0, bottom: 1, child: _BintangCatatan()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol (i) yang membuka keterangan warna dan penanda kalender.
class _TombolKeterangan extends StatelessWidget {
  const _TombolKeterangan();

  @override
  Widget build(BuildContext context) => TombolIkon(
    ikon: Icons.info_outline_rounded,
    keterangan: 'Keterangan kalender',
    ukuran: 36,
    onTap: () => bukaLembar<void>(context, (_) => const _LembarKeterangan()),
  );
}

class _LembarKeterangan extends StatelessWidget {
  const _LembarKeterangan();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    Widget contoh({
      Color latar = BerduaColors.card,
      Border? garis,
      Widget? ikon,
      Color teks = BerduaColors.ink,
    }) => Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.fromLTRB(4, 3, 4, 2),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(9),
        border: garis ?? Border.all(color: BerduaColors.line),
      ),
      child: Stack(
        children: [
          if (ikon != null) Positioned(left: 0, top: 0, child: ikon),
          Positioned(
            left: 0,
            bottom: 0,
            child: Text(
              '9',
              style: text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: teks,
              ),
            ),
          ),
        ],
      ),
    );

    Widget baris(Widget contohSel, String judul, String isi) => Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Row(
        children: [
          contohSel,
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: text.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(isi, style: text.labelSmall?.copyWith(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );

    return IsiLembar(
      judul: 'Keterangan kalender',
      children: [
        Column(
          children: [
            baris(
              contoh(
                latar: BerduaColors.period,
                garis: Border.all(color: BerduaColors.period),
              ),
              'Haid',
              'Hari haid yang sudah dicatat.',
            ),
            baris(
              contoh(
                latar: BerduaColors.roseSoft,
                garis: Border.all(color: BerduaColors.roseSoft),
                teks: BerduaColors.roseText,
              ),
              'Perkiraan haid',
              'Perkiraan haid berikutnya dari rata-rata siklus.',
            ),
            baris(
              contoh(
                latar: BerduaColors.rakaSoft,
                garis: Border.all(color: BerduaColors.rakaSoft),
                ikon: const _IkonSel.subur(),
              ),
              'Masa subur',
              'Peluang hamil tinggi.',
            ),
            baris(
              contoh(
                latar: BerduaColors.rakaSoft,
                garis: Border.all(color: BerduaColors.rakaSoft),
                ikon: const _IkonSel.ovulasi(),
              ),
              'Hari ovulasi',
              'Perkiraan, di tengah masa subur.',
            ),
            baris(
              contoh(
                ikon: const Padding(
                  padding: EdgeInsets.only(left: 18),
                  child: _BintangCatatan(),
                ),
              ),
              'Ada catatan',
              'Ada catatan harian di tanggal ini.',
            ),
            baris(
              contoh(garis: Border.all(color: BerduaColors.ink, width: 2)),
              'Hari ini',
              'Ketuk tanggal mana saja untuk melihat rinciannya.',
            ),
            baris(
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: BerduaColors.card,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: BerduaColors.line),
                ),
                child: const Text(
                  '20',
                  style: TextStyle(fontSize: 10, color: BerduaColors.label),
                ),
              ),
              'Angka kecil',
              'Hari ke berapa dalam siklus.',
            ),
          ],
        ),
        Text(
          'Semua perkiraan dihitung dari kalender saja, bukan alat '
          'kontrasepsi.',
          style: text.labelSmall?.copyWith(height: 1.4),
        ),
      ],
    );
  }
}

class _TautanRiwayat extends StatelessWidget {
  const _TautanRiwayat({required this.data});

  final Siklus data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuBerdua(
      radius: Radii.button,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      stiker: JenisStiker.chart,
      onTap: () => context.push('/siklus/riwayat'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat siklus & gejala',
                  style: text.bodyLarge?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  [
                    if (data.rataRataPanjang > 0)
                      'Rata-rata ${Rupiah.decimal(data.rataRataPanjang)} hari',
                    '${data.siklusTercatat} siklus tercatat',
                  ].join(' · '),
                  style: text.labelSmall,
                ),
              ],
            ),
          ),
          const Padding(
            // Panah bergeser ke bawah stiker supaya tidak bertumpuk.
            padding: EdgeInsets.only(top: 18),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: BerduaColors.label,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pintu ke catatan harian hari ini: aliran, gejala, suasana hati, dan
/// kategori lain diisi di layarnya sendiri.
class _KartuCatatanHariIni extends StatelessWidget {
  const _KartuCatatanHariIni({required this.gejala, required this.catatan});

  /// Gejala yang sudah dicatat hari ini.
  final List<String> gejala;
  final String catatan;

  static const _ikon = ['🩸', '🤒', '😊', '🔋', '💞', '💊'];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuBerdua(
      radius: Radii.cardBesar,
      stiker: JenisStiker.heart,
      onTap: () => context.push('/siklus/hari/${tanggalKawat(DateTime.now())}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 48),
            child: Text(
              'Bagaimana rasanya hari ini?',
              style: text.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: Gap.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final emoji in _ikon)
                SizedBox(
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: BerduaColors.card2,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 19, height: 1.1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Text(
            gejala.isEmpty
                ? 'Catat aliran, gejala, suasana hati, dan lainnya.'
                : 'Gejala hari ini: '
                      '${gejala.map((g) => Katalog.label(Katalog.semuaGejala, g)).join(', ')}',
            style: text.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            catatan,
            style: text.labelSmall?.copyWith(fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Flexible(
                child: Text(
                  'Isi catatan hari ini',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: BerduaColors.roseChipText,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: BerduaColors.roseChipText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tombol haid untuk pencatat, mengikuti keadaan haid terakhir:
/// - belum ada haid berjalan: "Haid mulai hari ini";
/// - haid sedang berjalan: "Haid selesai hari ini" ("mulai" disembunyikan);
/// - baru ditandai selesai hari ini: keterangan dan "Batalkan".
class _TombolHaid extends StatefulWidget {
  const _TombolHaid({required this.data});

  final Siklus data;

  @override
  State<_TombolHaid> createState() => _TombolHaidState();
}

class _TombolHaidState extends State<_TombolHaid> {
  bool _memuat = false;

  Future<void> _kirim(Future<void> Function() aksi, String berhasil) async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _memuat = true);

    try {
      await aksi();
      tampilkanToastVia(messenger, berhasil);
    } on ApiException catch (error) {
      tampilkanToastVia(messenger, error.message);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SiklusCubit>();
    final data = widget.data;

    if (data.haidSelesaiHariIni) {
      return KartuBerdua(
        radius: Radii.button,
        bayangan: false,
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: BerduaColors.ink),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: Text(
                'Haid ditandai selesai hari ini.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TombolTeks(
              label: 'Batalkan',
              onTap: _memuat
                  ? null
                  : () => _kirim(
                      cubit.batalHaidSelesai,
                      'Tanda selesai dibatalkan.',
                    ),
            ),
          ],
        ),
      );
    }

    if (data.haidBerjalan) {
      return TombolUtama(
        label: 'Haid selesai hari ini',
        ukuranHuruf: 18,
        memuat: _memuat,
        onPressed: () => _kirim(
          cubit.tandaiHaidSelesai,
          'Haid ditandai selesai. Prediksi diperbarui.',
        ),
      );
    }

    return TombolUtama(
      label: 'Haid mulai hari ini',
      ukuranHuruf: 18,
      memuat: _memuat,
      onPressed: () =>
          _kirim(cubit.tandaiHaidMulai, 'Tercatat. Prediksi diperbarui.'),
    );
  }
}

/// Kartu pink untuk pasangan: ringkasan fase dan tips bernomor.
class _KartuTips extends StatelessWidget {
  const _KartuTips({required this.tips, required this.nama});

  final TipsDukungan tips;
  final String nama;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuRose(
      stiker: JenisStiker.heart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              'Cara mendukung $nama minggu ini',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (tips.ringkasan.isNotEmpty) ...[
            const SizedBox(height: Gap.md),
            Text(
              tips.ringkasan,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                height: 1.5,
                color: BerduaColors.label,
              ),
            ),
          ],
          const SizedBox(height: Gap.md),
          for (final (i, tip) in tips.tips.indexed) ...[
            if (i > 0) const SizedBox(height: Gap.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: BerduaColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}',
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: BerduaColors.rose,
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Text(
                      tip,
                      style: text.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (tips.perluDitinjau) ...[
            const SizedBox(height: Gap.md),
            Text(
              'Tips ini belum ditinjau tenaga kesehatan.',
              textAlign: TextAlign.center,
              style: text.labelSmall?.copyWith(color: BerduaColors.label),
            ),
          ],
        ],
      ),
    );
  }
}
