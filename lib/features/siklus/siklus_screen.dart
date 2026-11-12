import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import '../auth/sesi_cubit.dart';
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

    Future<void> segarkan() => context.read<SiklusCubit>().segarkan();

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
            const _TombolHaidMulai(),
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
          _KartuGejala(
            terpilih: data.gejalaHariIni,
            catatan: sesi.partner == null
                ? 'Hanya kamu yang melihat catatan ini.'
                : (sesi.nyala('share_cycle')
                      ? 'Dibagikan ke $namaPasangan. Bisa dimatikan di Profil.'
                      : 'Hanya kamu yang melihat. $namaPasangan tidak melihat '
                            'siklusmu.'),
          ),
          const SizedBox(height: Gap.lg),
          const _TombolHaidMulai(),
        ],

        if (data.tips != null) ...[
          const SizedBox(height: Gap.xl),
          _KartuTips(tips: data.tips!, nama: nama),
        ],

        if (!data.bisaUbah) ...[
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

/// §16: kalender sel 40 dp dengan warna fase.
class _Kalender extends StatelessWidget {
  const _Kalender({required this.data});

  final Siklus data;

  static const _namaHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hari = data.kalender;

    if (hari.isEmpty) return const SizedBox.shrink();

    // Senin = 1 pada DateTime.weekday, jadi sel kosong di awal bulan dihitung
    // langsung dari hari pertama.
    final kosong = hari.first.tanggal.weekday - 1;
    final sel = <Widget?>[
      for (var i = 0; i < kosong; i++) null,
      for (final h in hari) _SelHari(hari: h),
    ];
    // Hari ini menentukan bulan pada judul; kalau tidak ada, hari pertama.
    final acuan = hari
        .firstWhere((h) => h.hariIni, orElse: () => hari.first)
        .tanggal;

    return KartuBerdua(
      radius: Radii.cardBesar,
      stiker: JenisStiker.cal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 48),
            // Wrap, bukan Row: di layar sempit keterangannya turun ke bawah.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: Gap.sm,
              children: [
                Text(
                  TanggalId.monthYear(acuan),
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
          for (var awal = 0; awal < sel.length; awal += 7) ...[
            if (awal > 0) const SizedBox(height: 4),
            Row(
              children: [
                for (var i = awal; i < awal + 7; i++) ...[
                  if (i > awal) const SizedBox(width: 4),
                  Expanded(
                    child:
                        (i < sel.length ? sel[i] : null) ??
                        const SizedBox(height: Sizes.calendarCell),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 10),
          const _Legenda(),
        ],
      ),
    );
  }
}

class _SelHari extends StatelessWidget {
  const _SelHari({required this.hari});

  final HariSiklus hari;

  @override
  Widget build(BuildContext context) {
    // Hari perkiraan memakai warna yang lebih lembut daripada yang tercatat.
    final (latar, warna) = switch (hari.fase) {
      'haid' when hari.perkiraan => (
        BerduaColors.roseSoft,
        BerduaColors.periodText,
      ),
      'haid' => (BerduaColors.rose, BerduaColors.ink),
      'subur' when hari.perkiraan => (
        BerduaColors.rakaSoft,
        BerduaColors.fertileText,
      ),
      'subur' => (BerduaColors.rakaKuat, BerduaColors.ink),
      'luteal' => (BerduaColors.netral, BerduaColors.ink),
      _ => (Colors.transparent, BerduaColors.ink),
    };

    final peluang = hari.peluangHamil;

    return Semantics(
      label:
          '${TanggalId.short(hari.tanggal)}, ${hari.fase}'
          '${peluang == null ? "" : ", peluang hamil ${peluang.label.toLowerCase()}"}'
          '${hari.perkiraan ? ", perkiraan" : ""}'
          '${hari.hariIni ? ", hari ini" : ""}',
      button: peluang != null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Mengetuk tanggal menyebut fase dan peluang hamil hari itu.
        onTap: peluang == null
            ? null
            : () => tampilkanToast(
                context,
                '${TanggalId.short(hari.tanggal)}: fase ${hari.fase}, '
                'peluang hamil ${peluang.label.toLowerCase()}'
                '${hari.perkiraan ? " (perkiraan)" : ""}',
              ),
        child: Container(
          height: Sizes.calendarCell,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: latar,
            borderRadius: BorderRadius.circular(Radii.chip),
            border: hari.hariIni
                ? Border.all(color: BerduaColors.ink, width: 2)
                : null,
          ),
          child: Text(
            '${hari.tanggal.day}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 15,
              fontWeight: hari.hariIni ? FontWeight.w700 : FontWeight.w500,
              color: warna,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    Widget item(String label, {Color? warna}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: warna,
            borderRadius: BorderRadius.circular(5),
            // Tanpa warna = penanda "hari ini": hanya garis tinta.
            border: warna == null
                ? Border.all(color: BerduaColors.ink, width: 2)
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: text.labelSmall?.copyWith(
            fontSize: 12,
            color: BerduaColors.label,
          ),
        ),
      ],
    );

    return Wrap(
      spacing: Gap.md,
      runSpacing: 6,
      children: [
        item('Haid', warna: BerduaColors.rose),
        item('Masa subur', warna: BerduaColors.rakaKuat),
        item('Luteal', warna: BerduaColors.netral),
        item('Hari ini'),
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

class _KartuGejala extends StatefulWidget {
  const _KartuGejala({required this.terpilih, required this.catatan});

  final List<String> terpilih;
  final String catatan;

  @override
  State<_KartuGejala> createState() => _KartuGejalaState();
}

class _KartuGejalaState extends State<_KartuGejala> {
  late Set<String> _dipilih = widget.terpilih.toSet();
  bool _menyimpan = false;

  @override
  void didUpdateWidget(_KartuGejala oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_samaIsi(oldWidget.terpilih.toSet(), widget.terpilih.toSet())) {
      _dipilih = widget.terpilih.toSet();
    }
  }

  Future<void> _simpan() async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _menyimpan = true);

    try {
      await context.read<SiklusCubit>().simpanGejala(_dipilih.toList());
      tampilkanToastVia(messenger, 'Gejala disimpan');
    } on ApiException catch (error) {
      tampilkanToastVia(messenger, error.message);
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final berubah = !_samaIsi(_dipilih, widget.terpilih.toSet());

    return KartuBerdua(
      radius: Radii.cardBesar,
      stiker: JenisStiker.heart,
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
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final gejala in BerduaEnums.symptoms)
                ChipBerdua(
                  label: kapitalAwal(gejala),
                  aktif: _dipilih.contains(gejala),
                  onTap: () => setState(() {
                    if (!_dipilih.remove(gejala)) _dipilih.add(gejala);
                  }),
                ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Text(
            widget.catatan,
            style: text.labelSmall?.copyWith(fontSize: 14, height: 1.45),
          ),
          if (berubah) ...[
            const SizedBox(height: Gap.md),
            TombolPink(
              label: 'Simpan gejala',
              tinggi: 46,
              ukuranHuruf: 16,
              tebal: FontWeight.w600,
              memuat: _menyimpan,
              onPressed: _simpan,
            ),
          ],
        ],
      ),
    );
  }
}

bool _samaIsi(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

class _TombolHaidMulai extends StatefulWidget {
  const _TombolHaidMulai();

  @override
  State<_TombolHaidMulai> createState() => _TombolHaidMulaiState();
}

class _TombolHaidMulaiState extends State<_TombolHaidMulai> {
  bool _memuat = false;

  @override
  Widget build(BuildContext context) {
    return TombolUtama(
      label: 'Haid mulai hari ini',
      ukuranHuruf: 18,
      memuat: _memuat,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);

        setState(() => _memuat = true);

        try {
          await context.read<SiklusCubit>().tandaiHaidMulai();
          tampilkanToastVia(messenger, 'Tercatat. Prediksi diperbarui.');
        } on ApiException catch (error) {
          tampilkanToastVia(messenger, error.message);
        } finally {
          if (mounted) setState(() => _memuat = false);
        }
      },
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
