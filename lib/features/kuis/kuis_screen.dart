import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import 'kuis_cubit.dart';
import 'kuis_widgets.dart';

/// Nilai yang dikembalikan layar riwayat saat pengguna menekan "MULAI KUIS
/// HARI INI": layar ini langsung membuka pertanyaan pertama.
const mainKuisHariIni = 'main';

/// Layar kuis hari ini: pengantar, lima pertanyaan, lalu hasil.
class KuisScreen extends StatefulWidget {
  const KuisScreen({super.key});

  @override
  State<KuisScreen> createState() => _KuisScreenState();
}

class _KuisScreenState extends State<KuisScreen> {
  /// true selama pertanyaan sedang dijawab.
  bool _main = false;
  int _indeks = 0;
  List<int?> _jawaban = const [];
  bool _mengirim = false;

  @override
  void initState() {
    super.initState();

    // Cubit hidup selama aplikasi terbuka, jadi isinya bisa dari kemarin.
    // Tiap layar dibuka, kuis hari ini diminta lagi tanpa mengedipkan layar.
    final cubit = context.read<KuisCubit>();

    if (cubit.state.adaNilai) cubit.segarkan();
  }

  void _mulai(Kuis kuis) {
    setState(() {
      _main = true;
      _indeks = 0;
      _jawaban = List<int?>.filled(kuis.questions.length, null);
    });
  }

  void _pilih(int pilihan) {
    if (_mengirim) return;

    setState(() => _jawaban[_indeks] = pilihan);
  }

  Future<void> _lanjut() async {
    if (_jawaban[_indeks] == null) {
      tampilkanToast(context, 'Pilih satu jawaban dulu');

      return;
    }

    if (_indeks < _jawaban.length - 1) {
      setState(() => _indeks++);

      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    setState(() => _mengirim = true);

    try {
      await context.read<KuisCubit>().kirim(_jawaban.cast<int>());

      if (mounted) setState(() => _main = false);
    } on ApiException catch (error) {
      tampilkanToastVia(messenger, error.message);
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  Future<void> _bukaRiwayat(Kuis kuis) async {
    final hasil = await context.push<String>('/kuis/riwayat');

    if (hasil == mainKuisHariIni && mounted) _mulai(kuis);
  }

  @override
  Widget build(BuildContext context) {
    final muatan = context.watch<KuisCubit>().state;

    return PopScope(
      // Di tengah pertanyaan, kembali berarti ke pengantar, bukan keluar.
      canPop: !_main,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_mengirim) setState(() => _main = false);
      },
      child: Scaffold(
        body: muatan.when(
          loading: () => const SkeletonKuis(),
          error: (error, _) => GalatLayar(
            pesan: error is ApiException ? error.message : 'Gagal memuat kuis.',
            onUlangi: () => context.read<KuisCubit>().muat(),
          ),
          data: (kuis) {
            final soal = _main && kuis.questions.length == _jawaban.length;
            final langkah = soal
                ? 'soal-$_indeks'
                : (kuis.done ? 'hasil' : 'pengantar');

            return LayarBerdua(
              // Kunci per langkah: tiap pertanyaan mulai dari atas layar dan
              // kartunya memantul lagi, seperti di prototipe.
              key: ValueKey(langkah),
              judul: 'Kuis berdua',
              stiker: JenisStiker.quiz,
              kembali: true,
              onSegarkan: soal
                  ? null
                  : () => context.read<KuisCubit>().segarkan(),
              children: soal
                  ? _pertanyaan(context, kuis)
                  : (kuis.done
                        ? _hasil(context, kuis)
                        : _pengantar(context, kuis)),
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------ pengantar

  List<Widget> _pengantar(BuildContext context, Kuis kuis) {
    final text = Theme.of(context).textTheme;

    const langkah = [
      (
        warna: BerduaColors.dinda,
        teks: 'Jawab pertanyaan yang mudah dan menyenangkan bersama.',
      ),
      (
        warna: BerduaColors.kuning,
        teks: 'Lihat di mana jawaban kalian selaras atau sama.',
      ),
      (
        warna: BerduaColors.period,
        teks: 'Mengobrol dan menikmati koneksi yang kalian bangun.',
      ),
    ];

    return [
      KartuBerdua(
        warna: BerduaColors.kuning,
        radius: Radii.cardWhite,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Stiker.sedang(JenisStiker.quiz),
                SizedBox(width: 10),
                Stiker.sedang(JenisStiker.heart),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Kenali pasanganmu lebih dekat',
              style: text.headlineMedium?.copyWith(
                fontSize: 26,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Fitur ini untuk saling memahami lebih baik dan memicu '
              'percakapan melalui pertanyaan yang menyenangkan.',
              style: text.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.5,
                color: BerduaColors.teksDiWarna,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          'Cara kerja',
          style: text.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      for (final (i, l) in langkah.indexed) ...[
        const SizedBox(height: 14),
        KartuBerdua(
          radius: Radii.cardBesar,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: l.warna,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: BerduaColors.ink,
                    width: Sizes.garis,
                  ),
                ),
                child: Text(
                  '${i + 1}',
                  style: text.titleMedium?.copyWith(
                    fontSize: 18,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l.teks,
                  style: text.bodyMedium?.copyWith(fontSize: 15, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 14),
      KartuBerdua(
        warna: BerduaColors.rakaSoft,
        radius: Radii.cardBesar,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KUIS HARI INI',
              style: text.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: BerduaColors.rakaText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              kuis.title,
              style: text.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                PilKuis('${kuis.total} pertanyaan'),
                const PilKuis('±2 menit'),
                if (kuis.partnerDone)
                  PilKuis(
                    '${kuis.namaPasangan} sudah menjawab',
                    latar: BerduaColors.mintSoft,
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      TombolUtama(
        label: 'Mulai kuis',
        ukuranHuruf: 18,
        onPressed: () => _mulai(kuis),
      ),
      const SizedBox(height: 9),
      TombolUtama(
        label: labelRiwayatKuis(context),
        ukuranHuruf: 18,
        putih: true,
        onPressed: () => _bukaRiwayat(kuis),
      ),
    ];
  }

  // ----------------------------------------------------------- pertanyaan

  List<Widget> _pertanyaan(BuildContext context, Kuis kuis) {
    final text = Theme.of(context).textTheme;
    final soal = kuis.questions[_indeks];
    final pilihan = _jawaban[_indeks];
    final terakhir = _indeks == kuis.questions.length - 1;

    return [
      Semantics(
        label: 'Pertanyaan ${_indeks + 1} dari ${kuis.questions.length}',
        excludeSemantics: true,
        child: Row(
          children: [
            for (var i = 0; i < kuis.questions.length; i++) ...[
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: i < _indeks
                        ? BerduaColors.mint
                        : (i == _indeks
                              ? BerduaColors.rose
                              : BerduaColors.card),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: BerduaColors.ink,
                      width: Sizes.garis,
                    ),
                  ),
                ),
              ),
              SizedBox(width: i == kuis.questions.length - 1 ? 10 : 6),
            ],
            Text(
              '${_indeks + 1}/${kuis.questions.length}',
              style: text.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      KartuBerdua(
        warna: soal.warna,
        radius: Radii.cardWhite,
        stiker: JenisStiker.quiz,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 102),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (soal.category.isNotEmpty) ...[
                Padding(
                  // Stiker menggantung di kanan atas kartu.
                  padding: const EdgeInsets.only(right: 48),
                  child: PilKuis(
                    soal.category.toUpperCase(),
                    tebal: FontWeight.w600,
                    ukuran: 12,
                    jarakHuruf: 1,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                soal.text,
                style: text.headlineSmall?.copyWith(
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      for (final (i, label) in soal.options.indexed) ...[
        const SizedBox(height: 14),
        _TombolPilihan(
          huruf: 'ABCD'[i % 4],
          label: label,
          dipilih: pilihan == i,
          onTap: () => _pilih(i),
        ),
      ],
      const SizedBox(height: 14),
      Text(
        'Jawaban ${kuis.namaPasangan} tersembunyi sampai kamu selesai.',
        textAlign: TextAlign.center,
        style: text.labelSmall?.copyWith(
          fontSize: 13,
          color: BerduaColors.label,
        ),
      ),
      const SizedBox(height: 14),
      TombolUtama(
        label: terakhir ? 'Lihat hasil' : 'Lanjut',
        ukuranHuruf: 18,
        memuat: _mengirim,
        onPressed: _lanjut,
      ),
    ];
  }

  // ---------------------------------------------------------------- hasil

  List<Widget> _hasil(BuildContext context, Kuis kuis) {
    return [
      ...hasilKuis(context, kuis),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: TombolUtama(
              label: 'Main lagi',
              ukuranHuruf: 18,
              putih: true,
              onPressed: () => _mulai(kuis),
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
      const SizedBox(height: 9),
      TombolUtama(
        label: labelRiwayatKuis(context),
        ukuranHuruf: 18,
        putih: true,
        onPressed: () => _bukaRiwayat(kuis),
      ),
    ];
  }
}

/// Satu pilihan jawaban: lencana huruf dan teksnya. Yang dipilih berlatar
/// pink muda dan tampak tertekan.
class _TombolPilihan extends StatelessWidget {
  const _TombolPilihan({
    required this.huruf,
    required this.label,
    required this.dipilih,
    required this.onTap,
  });

  final String huruf;
  final String label;
  final bool dipilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: dipilih,
      label: 'Pilihan $huruf: $label',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          transform: Matrix4.translationValues(0, dipilih ? 3 : 0, 0),
          decoration: BoxDecoration(
            color: dipilih ? BerduaColors.roseCard : BerduaColors.card,
            borderRadius: BorderRadius.circular(Radii.button),
            border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
            boxShadow: [
              BoxShadow(
                color: BerduaColors.ink,
                offset: Offset(0, dipilih ? 1 : 4),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dipilih ? BerduaColors.rose : BerduaColors.card2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BerduaColors.ink,
                    width: Sizes.garis,
                  ),
                ),
                child: Text(
                  huruf,
                  style: text.titleMedium?.copyWith(
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: text.bodyLarge?.copyWith(
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
