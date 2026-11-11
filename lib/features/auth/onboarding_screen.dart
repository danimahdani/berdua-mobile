import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/hiasan_pasangan.dart';
import 'sesi_cubit.dart';

/// Layar 03 (perkenalan), 04 (profil) dan 05 (undang pasangan).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nama = TextEditingController();

  int _langkah = 0;
  bool? _catatSiklus;
  bool _memuat = false;
  bool _disalin = false;
  String? _galat;
  DateTime _mulai = DateTime.now();

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  void _ke(int langkah) => setState(() {
    _langkah = langkah;
    _galat = null;
    _mulai = DateTime.now();
  });

  Future<void> _simpanProfil() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });

    try {
      await context.read<SesiCubit>().simpanProfil(
        nama: _nama.text.trim(),
        catatSiklus: _catatSiklus ?? false,
      );

      if (mounted) _ke(2);
    } on ApiException catch (error) {
      if (mounted) setState(() => _galat = error.message);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesi = context.watch<SesiCubit>().state;
    final text = Theme.of(context).textTheme;

    final isi = switch (_langkah) {
      0 => _perkenalan(text),
      1 => _profil(text),
      _ => _undang(text, sesi),
    };

    return Scaffold(
      body: LatarBerdua(
        bawah: true,
        // Isi setinggi layar supaya tombol utama menempel di bawah, tetapi
        // tetap bisa digulir saat papan ketik muncul atau layarnya pendek.
        child: LayoutBuilder(
          builder: (context, batas) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.md, Gap.xl, Gap.xxl),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(0, batas.maxHeight - Gap.md - Gap.xxl),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: memantulkan(
                    isi,
                    mulai: _mulai,
                    kunci: 'langkah$_langkah',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kepala(String judul, VoidCallback kembali) {
    return Row(
      children: [
        TombolKembali(onTap: kembali),
        Expanded(
          child: Text(
            judul,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 20),
          ),
        ),
        const SizedBox(width: Sizes.backButton),
      ],
    );
  }

  /// Layar 03.
  List<Widget> _perkenalan(TextTheme text) {
    return [
      const _DuaKartu(),
      const SizedBox(height: 18),
      const TitikLangkah(aktif: 0),
      const SizedBox(height: 18),
      Text(
        'Satu catatan untuk berdua',
        textAlign: TextAlign.center,
        style: text.displaySmall,
      ),
      const SizedBox(height: 18),
      Text(
        'Uang, siklus, belanja, dan rencana kalian di satu tempat yang sama.',
        textAlign: TextAlign.center,
        style: text.bodyLarge?.copyWith(color: BerduaColors.label, height: 1.5),
      ),
      const Spacer(),
      const SizedBox(height: 18),
      TombolUtama(label: 'Mulai', onPressed: () => _ke(1)),
    ];
  }

  /// Layar 04.
  List<Widget> _profil(TextTheme text) {
    final siap = _nama.text.trim().isNotEmpty && _catatSiklus != null;

    return [
      _kepala('Kenalan dulu', () => _ke(0)),
      const SizedBox(height: Gap.xl),
      const TitikLangkah(aktif: 1),
      const SizedBox(height: Gap.xl),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LabelIsian('Nama panggilan'),
          TextField(
            controller: _nama,
            textCapitalization: TextCapitalization.words,
            style: text.bodyLarge?.copyWith(fontSize: 18),
            inputFormatters: [LengthLimitingTextInputFormatter(40)],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'mis. Dinda'),
          ),
        ],
      ),
      const SizedBox(height: Gap.xl),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LabelIsian('Kamu ingin mencatat siklus haid?'),
          SegmenBerdua<bool?>(
            pilihan: const [true, false],
            terpilih: _catatSiklus,
            tinggi: 48,
            ukuranHuruf: 18,
            label: (nilai) => nilai == true ? 'Ya' : 'Tidak',
            onPilih: (nilai) => setState(() => _catatSiklus = nilai),
          ),
          const SizedBox(height: Gap.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Kamu yang memutuskan apa yang bisa dilihat pasangan. '
              'Bisa diubah kapan saja di Profil.',
              style: text.labelSmall?.copyWith(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
      if (_galat != null) ...[
        const SizedBox(height: Gap.md),
        TeksGalat(_galat!),
      ],
      const Spacer(),
      const SizedBox(height: Gap.xl),
      TombolUtama(
        label: 'Lanjut',
        memuat: _memuat,
        onPressed: siap ? _simpanProfil : null,
      ),
    ];
  }

  /// Layar 05.
  List<Widget> _undang(TextTheme text, SesiState sesi) {
    final kode = sesi.couple?.inviteCode ?? '—';
    final nama = sesi.user?.name ?? '';
    final pasangan = sesi.partner;

    return [
      _kepala('Undang pasangan', () => _ke(1)),
      const SizedBox(height: Gap.lg),
      const TitikLangkah(aktif: 2),
      const SizedBox(height: Gap.lg),
      // Ilustrasi undangan masih tempat kosong; stiker surat mengisinya dulu.
      Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BerduaColors.dinda,
          borderRadius: BorderRadius.circular(Radii.cardWhite),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stiker.sedang(JenisStiker.heart),
            SizedBox(width: Gap.lg),
            Stiker(JenisStiker.mail, ukuran: 84),
            SizedBox(width: Gap.lg),
            Stiker.sedang(JenisStiker.flower),
          ],
        ),
      ),
      const SizedBox(height: Gap.xxl),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: KartuRose(
          miring: true,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Column(
            children: [
              AngkaBerbingkai(kode, ukuran: 30),
              const SizedBox(height: 10),
              Text(
                pasangan != null
                    ? 'Kalian sudah terhubung. Kode ini jadi tanda pasangan '
                          'kalian.'
                    : 'Kirim kode ini ke pasanganmu'
                          '${nama.isEmpty ? "" : ", $nama"}. Berlaku 48 jam.',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: Gap.xxl),
      TombolSekunder(
        label: _disalin ? 'Kode disalin' : 'Bagikan kode',
        ikon: _disalin ? Icons.check_rounded : Icons.copy_rounded,
        onPressed: () {
          Clipboard.setData(ClipboardData(text: kode));
          setState(() => _disalin = true);
          tampilkanToast(context, 'Kode disalin');
        },
      ),
      if (pasangan != null) ...[
        const SizedBox(height: Gap.lg),
        KartuBerdua(
          radius: Radii.button,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              const Stiker.kecil(JenisStiker.check),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Text(
                  'Terhubung dengan '
                  '${pasangan.name.isEmpty ? "pasanganmu" : pasangan.name}',
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
      const Spacer(),
      const SizedBox(height: Gap.xl),
      TombolUtama(
        label: pasangan != null ? 'Selesai' : 'Masuk ke Berdua',
        // Router berpindah sendiri setelah onboarding selesai; memuat ulang
        // profil cukup untuk memicunya.
        onPressed: () => context.read<SesiCubit>().muatProfil(),
      ),
      if (pasangan == null) ...[
        const SizedBox(height: Gap.md),
        Text(
          'Belum sempat mengundang? Kodenya tetap ada di Profil.',
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
      ],
    ];
  }
}

/// Ilustrasi layar 03: dua kartu miring biru langit dan lavender dengan hati
/// di tengah. Tempat ilustrasi karakternya masih kosong (§17); sementara itu
/// diisi stiker.
class _DuaKartu extends StatelessWidget {
  const _DuaKartu();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 372,
          height: 350,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 30,
                child: _kartu(
                  context,
                  label: 'Kamu',
                  warna: BerduaColors.dinda,
                  tinggi: 220,
                  derajat: -4,
                  kiri: true,
                  stiker: JenisStiker.flower,
                ),
              ),
              Positioned(
                right: 0,
                top: 110,
                child: _kartu(
                  context,
                  label: 'Pasanganmu',
                  warna: BerduaColors.raka,
                  tinggi: 230,
                  derajat: 5,
                  kiri: false,
                  stiker: JenisStiker.wallet,
                ),
              ),
              const Positioned(
                left: 172,
                top: 66,
                child: Stiker(JenisStiker.heart, ukuran: 50),
              ),
              const Positioned(
                left: 24,
                top: 280,
                child: Kilau(warna: BerduaColors.kuning, ukuran: 26),
              ),
              const Positioned(
                right: 20,
                top: 40,
                child: Kilau(warna: BerduaColors.mint, ukuran: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kartu(
    BuildContext context, {
    required String label,
    required Color warna,
    required double tinggi,
    required double derajat,
    required bool kiri,
    required JenisStiker stiker,
  }) {
    return Transform.rotate(
      angle: derajat * math.pi / 180,
      child: Container(
        width: 200,
        height: tinggi,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: warna,
          borderRadius: kiri
              ? const BorderRadius.only(
                  topLeft: Radius.circular(48),
                  topRight: Radius.circular(70),
                  bottomRight: Radius.circular(40),
                  bottomLeft: Radius.circular(60),
                )
              : const BorderRadius.only(
                  topLeft: Radius.circular(70),
                  topRight: Radius.circular(48),
                  bottomRight: Radius.circular(60),
                  bottomLeft: Radius.circular(40),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: Gap.sm),
            Expanded(
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stiker(stiker, ukuran: 72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
