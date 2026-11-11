import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/hiasan_pasangan.dart';
import 'sesi_cubit.dart';

/// Layar 01 (Masuk) dan 02 (Kode verifikasi email).
///
/// §5.1: masuk dengan nomor telepon, lalu kode 6 digit yang dikirim ke email
/// yang terhubung dengan nomor itu. Hanya 2 nomor terdaftar yang bisa masuk.
class MasukScreen extends StatefulWidget {
  const MasukScreen({super.key});

  @override
  State<MasukScreen> createState() => _MasukScreenState();
}

class _MasukScreenState extends State<MasukScreen> {
  final _nomor = TextEditingController();
  final _kode = TextEditingController();

  bool _tahapKode = false;
  bool _memuat = false;
  String? _galat;
  String _emailHint = '';
  String? _devCode;

  /// Saat tahap terakhir dibuka; isi layar memantul lagi tiap tahap berganti.
  DateTime _mulai = DateTime.now();

  @override
  void dispose() {
    _nomor.dispose();
    _kode.dispose();
    super.dispose();
  }

  Future<void> _mintaKode({bool ulang = false}) async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _memuat = true;
      _galat = null;
    });

    try {
      final hasil = await context.read<SesiCubit>().mintaKode(
        '+62${_nomor.text.trim()}',
      );

      if (!mounted) return;

      setState(() {
        if (!_tahapKode) _mulai = DateTime.now();

        _tahapKode = true;
        _emailHint = hasil.emailHint;
        _devCode = hasil.devCode;
      });

      tampilkanToastVia(
        messenger,
        ulang ? 'Kode baru dikirim ke email' : 'Kode dikirim ke email',
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _galat = error.message);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  Future<void> _verifikasi() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });

    try {
      await context.read<SesiCubit>().verifikasi(
        '+62${_nomor.text.trim()}',
        _kode.text.trim(),
      );
      // Router otomatis berpindah begitu sesi terisi.
    } on ApiException catch (error) {
      if (mounted) setState(() => _galat = error.message);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  void _gantiNomor() => setState(() {
    _tahapKode = false;
    _kode.clear();
    _galat = null;
    _mulai = DateTime.now();
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: LatarBerdua(
        bawah: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Gap.xl, 22, Gap.xl, Gap.xxl),
          children: memantulkan(
            [
              const HiasanPasangan.masuk(),
              const SizedBox(height: Gap.lg),
              Text(
                _tahapKode ? 'Masukkan kode' : 'Masuk ke Berdua',
                textAlign: TextAlign.center,
                style: text.displaySmall?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: Gap.lg),
              Text(
                _tahapKode
                    ? 'Kode 6 digit sudah dikirim ke email $_emailHint. '
                          'Cek juga folder spam.'
                    : 'Masukkan nomor teleponmu. Akun pasangan akan terhubung '
                          'otomatis.',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: Gap.lg),
              if (_tahapKode) ..._tahapKodeIsi(text) else ..._tahapNomor(text),
              if (_galat != null) ...[
                const SizedBox(height: Gap.md),
                TeksGalat(_galat!),
              ],
              const SizedBox(height: Gap.lg),
              TombolUtama(
                label: _tahapKode ? 'Verifikasi' : 'Kirim kode',
                ukuranHuruf: 18,
                memuat: _memuat,
                onPressed: _tahapKode
                    ? (_kode.text.length == 6 ? _verifikasi : null)
                    : (_nomor.text.length >= 8 ? _mintaKode : null),
              ),
            ],
            mulai: _mulai,
            kunci: _tahapKode ? 'kode' : 'nomor',
          ),
        ),
      ),
    );
  }

  List<Widget> _tahapNomor(TextTheme text) {
    return [
      // Lima stiker: semua yang dicatat berdua di aplikasi ini.
      const FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stiker.sedang(JenisStiker.coin),
            SizedBox(width: 14),
            Stiker.sedang(JenisStiker.flower),
            SizedBox(width: 14),
            Stiker.sedang(JenisStiker.bag),
            SizedBox(width: 14),
            Stiker.sedang(JenisStiker.cal),
            SizedBox(width: 14),
            Stiker.sedang(JenisStiker.piggy),
          ],
        ),
      ),
      const SizedBox(height: Gap.lg),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LabelIsian('Nomor telepon'),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                  decoration: BoxDecoration(
                    color: BerduaColors.card2,
                    borderRadius: BorderRadius.circular(Radii.input),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 18,
                        color: BerduaColors.label,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+62',
                        style: text.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: TextField(
                    controller: _nomor,
                    keyboardType: TextInputType.phone,
                    style: text.bodyLarge?.copyWith(
                      fontSize: 18,
                      letterSpacing: .4,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(13),
                    ],
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (_nomor.text.length >= 8 && !_memuat) _mintaKode();
                    },
                    decoration: const InputDecoration(hintText: '81234567801'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: Gap.lg),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 15,
                color: BerduaColors.textSecondary,
              ),
            ),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: Text(
                'Hanya 2 nomor yang terdaftar yang bisa masuk. Kode '
                'verifikasi dikirim ke email yang terhubung dengan nomormu.',
                style: text.labelSmall?.copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _tahapKodeIsi(TextTheme text) {
    return [
      const Center(child: Stiker.besar(JenisStiker.mail)),
      const SizedBox(height: Gap.lg),
      TextField(
        controller: _kode,
        keyboardType: TextInputType.number,
        autofocus: true,
        textAlign: TextAlign.center,
        style: text.headlineLarge?.copyWith(
          fontSize: 28,
          letterSpacing: 14,
          height: 1.25,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        onChanged: (value) {
          setState(() {});

          if (value.length == 6 && !_memuat) _verifikasi();
        },
        decoration: InputDecoration(
          hintText: '••••••',
          hintStyle: text.headlineLarge?.copyWith(
            fontSize: 28,
            letterSpacing: 14,
            height: 1.25,
            color: BerduaColors.garisCentang,
          ),
        ),
      ),
      const SizedBox(height: Gap.sm),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TombolTeks(
              label: 'Ganti nomor',
              warna: BerduaColors.label,
              tebal: FontWeight.w500,
              onTap: _memuat ? null : _gantiNomor,
            ),
            TombolTeks(
              label: 'Kirim ulang kode',
              onTap: _memuat ? null : () => _mintaKode(ulang: true),
            ),
          ],
        ),
      ),
      if (_devCode != null) ...[
        const SizedBox(height: Gap.xs),
        // Muncul hanya selama BERDUA_FIXED_CODE aktif di backend.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            'Mode pengembangan: kodenya $_devCode.',
            style: text.labelSmall,
          ),
        ),
      ],
    ];
  }
}
