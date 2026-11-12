import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import 'pribadi_cubit.dart';

/// Pemilih di atas tab Uang: uang bersama atau uang pribadi.
///
/// Pil pink-nya mengikuti posisi [halaman] setiap frame, jadi ikut bergeser
/// mulus bersama jari saat halaman diswipe (bukan melompat di tengah jalan).
/// Bentuknya sama dengan [SegmenBerdua] gaya kartu.
class PemilihModeUang extends StatelessWidget {
  const PemilihModeUang({super.key, required this.halaman});

  final PageController halaman;

  static const _tinggi = 38.0;
  static const _celah = 6.0;
  static const _labels = ['Bersama', 'Pribadi'];

  @override
  Widget build(BuildContext context) {
    final gayaTeks = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontSize: 15, fontWeight: FontWeight.w500);

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: BerduaColors.card,
        borderRadius: BorderRadius.circular(Radii.input),
        border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
        boxShadow: Shadows.kartu,
      ),
      child: LayoutBuilder(
        builder: (context, batas) {
          final lebar = (batas.maxWidth - _celah) / 2;

          return AnimatedBuilder(
            animation: halaman,
            builder: (context, _) {
              // 0 = Bersama, 1 = Pribadi, di antaranya saat sedang digeser.
              final posisi =
                  (halaman.hasClients && halaman.position.haveDimensions
                          ? halaman.page ?? 0
                          : (context.read<ModeUangCubit>().state ? 1.0 : 0.0))
                      .clamp(0.0, 1.0);

              return SizedBox(
                height: _tinggi,
                child: Stack(
                  children: [
                    Positioned(
                      left: posisi * (lebar + _celah),
                      top: 0,
                      bottom: 0,
                      width: lebar,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: BerduaColors.roseChipActive,
                          borderRadius: BorderRadius.circular(Radii.pilihan),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < 2; i++) ...[
                          if (i > 0) const SizedBox(width: _celah),
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: posisi.round() == i,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => context
                                    .read<ModeUangCubit>()
                                    .pilih(pribadi: i == 1),
                                child: Center(
                                  child: Text(
                                    _labels[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: gayaTeks?.copyWith(
                                      // Warna teks ikut berpindah perlahan.
                                      color: Color.lerp(
                                        BerduaColors.roseChipText,
                                        BerduaColors.pilihanMati,
                                        (posisi - i).abs().clamp(0.0, 1.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Uang pribadi: catatan pengeluaran milik akun ini saja. Kepala dan FAB
/// dipasang oleh layar tab Uang.
///
/// Sengaja dibuat berbeda dari uang bersama (warna ungu, ikon gembok) supaya
/// tidak tertukar saat mencatat.
class PribadiScreen extends StatelessWidget {
  const PribadiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final muatan = context.watch<PribadiCubit>().state;

    return muatan.when(
      loading: () => const SkeletonUang(tanpaJudul: true),
      error: (error, _) => GalatLayar(
        tab: 1,
        pesan: error is ApiException
            ? error.message
            : 'Gagal memuat pengeluaran pribadi.',
        onUlangi: () => context.read<PribadiCubit>().muat(),
      ),
      data: (data) => _Isi(data: data),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.data});

  final RingkasanPribadi data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return LayarBerdua(
      judul: 'Uang pribadi',
      tanpaKepala: true,
      tab: 1,
      ruangFab: true,
      kunciPantul: data.bulan,
      onSegarkan: () => context.read<PribadiCubit>().segarkan(),
      children: [
        const SizedBox(height: Gap.xs),
        const _CatatanPrivasi(),
        const SizedBox(height: Gap.md),
        _PemilihBulan(bulan: data.bulan),
        const SizedBox(height: Gap.md),
        _Ringkasan(data: data),
        if (data.perKategori.isNotEmpty) ...[
          const SizedBox(height: Gap.betweenCards),
          _Kategori(data: data),
        ],
        const SizedBox(height: Gap.xl),
        if (data.daftar.isEmpty)
          KartuBerdua(
            radius: Radii.button,
            padding: const EdgeInsets.all(Gap.xl),
            child: Column(
              children: [
                const Stiker.sedang(JenisStiker.piggy),
                const SizedBox(height: Gap.sm),
                Text(
                  'Belum ada pengeluaran pribadi di '
                  '${TanggalId.month(data.bulan)}',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  'Ketuk tombol + untuk mencatat.',
                  style: text.labelSmall?.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          for (final p in data.daftar) ...[
            _Baris(pengeluaran: p),
            const SizedBox(height: Gap.sm),
          ],
      ],
    );
  }
}

class _CatatanPrivasi extends StatelessWidget {
  const _CatatanPrivasi();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BerduaColors.rakaSoft,
        borderRadius: BorderRadius.circular(Radii.pilihan),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: ChartColors.pasanganTeks,
          ),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Text(
              'Hanya kamu yang bisa melihat ini. Tidak ikut ke uang bersama, '
              'laporan, atau utang.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 13,
                height: 1.4,
                color: ChartColors.pasanganTeks,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PemilihBulan extends StatelessWidget {
  const _PemilihBulan({required this.bulan});

  final DateTime bulan;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BulanPribadiCubit>();
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        TombolIkon(
          ikon: Icons.chevron_left_rounded,
          keterangan: 'Bulan sebelumnya',
          onTap: cubit.mundur,
        ),
        Expanded(
          child: Text(
            TanggalId.monthYear(bulan),
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Opacity(
          opacity: cubit.bisaMaju ? 1 : .3,
          child: TombolIkon(
            ikon: Icons.chevron_right_rounded,
            keterangan: 'Bulan berikutnya',
            onTap: cubit.bisaMaju ? cubit.maju : () {},
          ),
        ),
      ],
    );
  }
}

/// Total bulan ini, rata-rata per bulan, dan perbandingan dengan bulan lalu.
class _Ringkasan extends StatelessWidget {
  const _Ringkasan({required this.data});

  final RingkasanPribadi data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rataRata = data.rataRataBulanan;
    final selisih = data.total - data.totalBulanLalu;

    return KartuRose(
      warna: BerduaColors.rakaSoft,
      stiker: JenisStiker.piggy,
      child: Column(
        children: [
          Text(
            'Total ${TanggalId.month(data.bulan)}',
            style: text.bodyMedium?.copyWith(color: BerduaColors.label),
          ),
          const SizedBox(height: Gap.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AngkaBerbingkai(Rupiah.format(data.total)),
          ),
          const SizedBox(height: Gap.md),
          Text(
            rataRata == null
                ? 'Rata-rata per bulan muncul setelah satu bulan penuh '
                      'tercatat.'
                : 'Rata-rata per bulan ${Rupiah.format(rataRata)} '
                      '(${data.jumlahBulanRataRata} bulan terakhir)',
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(fontSize: 14, height: 1.4),
          ),
          if (data.totalBulanLalu > 0) ...[
            const SizedBox(height: 4),
            Text(
              selisih == 0
                  ? 'Sama dengan bulan lalu'
                  : '${selisih > 0 ? "Naik" : "Turun"} '
                        '${Rupiah.format(selisih.abs())} dari bulan lalu',
              textAlign: TextAlign.center,
              style: text.labelSmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selisih > 0
                    ? BerduaColors.roseText
                    : BerduaColors.mintText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Kategori extends StatelessWidget {
  const _Kategori({required this.data});

  final RingkasanPribadi data;

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
          Text(
            'Per kategori',
            style: text.bodyLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final e in baris) ...[
            const SizedBox(height: Gap.md),
            Row(
              children: [
                UbinIkon(
                  ikon: KategoriWarna.untuk(e.key).ikon,
                  latar: KategoriWarna.untuk(e.key).lembut,
                  warna: KategoriWarna.untuk(e.key).kuat,
                  ukuran: 34,
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
                              e.key,
                              style: text.bodyMedium?.copyWith(fontSize: 15),
                            ),
                          ),
                          Text(
                            Rupiah.format(e.value),
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
                            widthFactor: (e.value / terbesar).clamp(0, 1),
                            child: ColoredBox(
                              color: KategoriWarna.untuk(e.key).kuat,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _Baris extends StatelessWidget {
  const _Baris({required this.pengeluaran});

  final PengeluaranPribadi pengeluaran;

  @override
  Widget build(BuildContext context) {
    final warna = KategoriWarna.untuk(pengeluaran.kategori);

    return KartuDaftar(
      leading: UbinIkon(
        ikon: warna.ikon,
        latar: warna.lembut,
        warna: warna.kuat,
        ukuran: 44,
        radius: 14,
      ),
      judul: pengeluaran.judul,
      keterangan: pengeluaran.kategori,
      trailing: Rupiah.format(pengeluaran.jumlah),
      trailingBawah: TanggalId.short(pengeluaran.tanggal),
      onTap: () => LembarPribadi.buka(context, pengeluaran: pengeluaran),
    );
  }
}

/// Lembar tambah / ubah pengeluaran pribadi, dengan tombol hapus saat ubah.
class LembarPribadi extends StatefulWidget {
  const LembarPribadi({super.key, this.pengeluaran});

  final PengeluaranPribadi? pengeluaran;

  static Future<void> buka(
    BuildContext context, {
    PengeluaranPribadi? pengeluaran,
  }) =>
      bukaLembar<void>(context, (_) => LembarPribadi(pengeluaran: pengeluaran));

  @override
  State<LembarPribadi> createState() => _LembarPribadiState();
}

class _LembarPribadiState extends State<LembarPribadi> {
  late final _judul = TextEditingController(
    text: widget.pengeluaran?.judul ?? '',
  );
  late final _jumlah = TextEditingController(
    text: widget.pengeluaran == null
        ? ''
        : Rupiah.bare(widget.pengeluaran!.jumlah),
  );
  late String _kategori =
      widget.pengeluaran?.kategori ?? BerduaEnums.categories.first;
  late DateTime _tanggal = widget.pengeluaran?.tanggal ?? _hariIni();

  bool _memuat = false;
  bool _menghapus = false;
  String? _galat;

  bool get _ubah => widget.pengeluaran != null;

  static DateTime _hariIni() {
    final n = DateTime.now();

    return DateTime(n.year, n.month, n.day);
  }

  @override
  void dispose() {
    _judul.dispose();
    _jumlah.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: _hariIni(),
    );

    if (hasil != null) setState(() => _tanggal = hasil);
  }

  Future<void> _simpan() async {
    final jumlah = Rupiah.parse(_jumlah.text);

    if (jumlah == null || jumlah < 1) {
      setState(() => _galat = 'Masukkan jumlah yang benar.');

      return;
    }

    if (_judul.text.trim().isEmpty) {
      setState(() => _galat = 'Tulis dulu untuk apa pengeluarannya.');

      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final cubit = context.read<PribadiCubit>();

    setState(() {
      _memuat = true;
      _galat = null;
    });

    try {
      if (_ubah) {
        await cubit.ubah(
          id: widget.pengeluaran!.id,
          judul: _judul.text.trim(),
          kategori: _kategori,
          jumlah: jumlah,
          tanggal: _tanggal,
        );
      } else {
        await cubit.tambah(
          judul: _judul.text.trim(),
          kategori: _kategori,
          jumlah: jumlah,
          tanggal: _tanggal,
        );
      }

      navigator.pop();
      tampilkanToastVia(
        messenger,
        _ubah ? 'Perubahan disimpan' : 'Pengeluaran pribadi dicatat',
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _galat = error.message);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  Future<void> _hapus() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final cubit = context.read<PribadiCubit>();

    setState(() => _menghapus = true);

    try {
      await cubit.hapus(widget.pengeluaran!.id);
      navigator.pop();
      tampilkanToastVia(messenger, 'Pengeluaran pribadi dihapus');
    } on ApiException catch (error) {
      if (mounted) setState(() => _menghapus = false);
      tampilkanToastVia(messenger, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hariIni = _hariIni();
    final kemarin = hariIni.subtract(const Duration(days: 1));
    final lain = _tanggal != hariIni && _tanggal != kemarin;

    return IsiLembar(
      judul: _ubah ? 'Ubah pengeluaran pribadi' : 'Pengeluaran pribadi',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: BerduaColors.rakaSoft,
            borderRadius: BorderRadius.circular(Radii.cardBesar),
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: ChartColors.pasanganTeks,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Jumlah · hanya kamu yang melihat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: ChartColors.pasanganTeks,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ChartColors.pasangan, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Rp',
                      style: text.titleMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: BerduaColors.label,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: TextField(
                          controller: _jumlah,
                          keyboardType: TextInputType.number,
                          autofocus: !_ubah,
                          style: text.headlineLarge?.copyWith(
                            fontSize: 34,
                            height: 1.3,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                            _PemisahRibuan(),
                          ],
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: text.headlineLarge?.copyWith(
                              fontSize: 34,
                              height: 1.3,
                              color: BerduaColors.teksCoret,
                            ),
                            isDense: true,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        TextField(
          controller: _judul,
          textCapitalization: TextCapitalization.sentences,
          style: text.bodyLarge?.copyWith(fontSize: 17),
          inputFormatters: [LengthLimitingTextInputFormatter(80)],
          decoration: const InputDecoration(
            hintText: 'Untuk apa? mis. Kopi, skincare',
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LabelIsian('Kategori'),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final kategori in BerduaEnums.categories)
                  ChipBerdua(
                    label: kategori,
                    aktif: _kategori == kategori,
                    onTap: () => setState(() => _kategori = kategori),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LabelIsian('Tanggal'),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                ChipBerdua(
                  label: 'Hari ini',
                  aktif: _tanggal == hariIni,
                  onTap: () => setState(() => _tanggal = hariIni),
                ),
                ChipBerdua(
                  label: 'Kemarin',
                  aktif: _tanggal == kemarin,
                  onTap: () => setState(() => _tanggal = kemarin),
                ),
                ChipBerdua(
                  label: lain ? TanggalId.short(_tanggal) : 'Pilih tanggal',
                  aktif: lain,
                  onTap: _pilihTanggal,
                ),
              ],
            ),
          ],
        ),
        ?(_galat == null ? null : TeksGalat(_galat!)),
        TombolUtama(
          label: _ubah ? 'Simpan perubahan' : 'Simpan',
          memuat: _memuat,
          onPressed: _menghapus ? null : _simpan,
        ),
        if (_ubah)
          Center(
            child: _menghapus
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : TombolTeks(
                    label: 'Hapus pengeluaran ini',
                    ukuran: 15,
                    onTap: _memuat ? () {} : _hapus,
                  ),
          ),
      ],
    );
  }
}

/// "512000" jadi "512.000" sambil diketik.
class _PemisahRibuan extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final angka = Rupiah.parse(newValue.text);

    if (angka == null) return newValue.copyWith(text: '');

    final teks = Rupiah.bare(angka);

    return TextEditingValue(
      text: teks,
      selection: TextSelection.collapsed(offset: teks.length),
    );
  }
}
