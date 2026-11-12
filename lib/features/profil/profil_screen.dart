import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../models/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/potret.dart';
import '../auth/sesi_cubit.dart';

/// Layar 23: Profil — pasangan, sakelar privasi dan pengingat, lalu keluar.
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  Future<void> _ubah(BuildContext context, String kunci, bool nilai) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<SesiCubit>().ubahPengaturan(kunci, nilai);
    } on ApiException catch (error) {
      tampilkanToastVia(messenger, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesi = context.watch<SesiCubit>().state;
    final text = Theme.of(context).textTheme;
    final user = sesi.user;
    final partner = sesi.partner;
    final namaPasangan = partner == null || partner.name.isEmpty
        ? 'pasangan'
        : partner.name;

    return Scaffold(
      body: LayarBerdua(
        judul: 'Profil',
        stiker: JenisStiker.heart,
        tab: 4,
        children: [
          Column(
            children: [
              const SizedBox(height: Gap.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (user != null) _Ubin(user: user, kiri: true),
                  if (partner != null)
                    Transform.translate(
                      offset: const Offset(-10, 0),
                      child: _Ubin(user: partner, kiri: false),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                partner == null
                    ? (user?.name ?? '')
                    : '${user?.name ?? ''} & ${partner.name}',
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (partner != null && sesi.couple?.since != null)
                    'Terhubung sejak ${TanggalId.long(sesi.couple!.since!)}',
                  // Pasangan terhubung sendiri begitu masuk dengan nomornya.
                  if (partner == null) 'Pasanganmu belum masuk ke Berdua',
                ].join(' · '),
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: Gap.xs),
            ],
          ),
          const SizedBox(height: Gap.betweenCards),

          // Hanya pencatat siklus yang memutuskan apa yang dibagikan (§5.3).
          if (user?.tracksCycle ?? false) ...[
            BarisSakelar(
              keterangan: 'Privasi',
              label: 'Bagikan siklus ke $namaPasangan',
              nyala: sesi.nyala('share_cycle'),
              onUbah: (nilai) => _ubah(context, 'share_cycle', nilai),
            ),
            const SizedBox(height: Gap.betweenCards),
          ],
          BarisSakelar(
            keterangan: '2 hari sebelum prediksi',
            label: 'Pengingat haid',
            nyala: sesi.nyala('remind_period'),
            onUbah: (nilai) => _ubah(context, 'remind_period', nilai),
          ),
          const SizedBox(height: Gap.betweenCards),
          BarisSakelar(
            keterangan: 'Kos, listrik, langganan',
            label: 'Pengingat tagihan',
            nyala: sesi.nyala('remind_bills'),
            onUbah: (nilai) => _ubah(context, 'remind_bills', nilai),
          ),
          const SizedBox(height: Gap.betweenCards),
          BarisSakelar(
            keterangan: 'Pagi, siang, malam selama belum diisi',
            label: 'Ingatkan kuis',
            nyala: sesi.nyala('remind_quiz'),
            onUbah: (nilai) => _ubah(context, 'remind_quiz', nilai),
          ),
          const SizedBox(height: Gap.betweenCards),

          const _Baris(keterangan: 'Mata uang', label: 'Rupiah (Rp)'),
          const SizedBox(height: Gap.betweenCards),
          const _Versi(),
          _Baris(
            keterangan: 'Akun',
            label: 'Keluar',
            warna: BerduaColors.roseText,
            onTap: () => context.read<SesiCubit>().keluar(),
          ),
        ],
      ),
    );
  }
}

/// Versi aplikasi yang terpasang, dibaca dari `version` di pubspec.yaml.
/// Tidak tampil kalau platform tidak bisa memberitahukannya.
class _Versi extends StatefulWidget {
  const _Versi();

  @override
  State<_Versi> createState() => _VersiState();
}

class _VersiState extends State<_Versi> {
  String? _versi;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    try {
      final info = await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() => _versi = '${info.version} (${info.buildNumber})');
    } catch (_) {
      // Tanpa info paket (mis. saat uji): barisnya tidak ditampilkan.
    }
  }

  @override
  Widget build(BuildContext context) {
    final versi = _versi;

    if (versi == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.betweenCards),
      child: _Baris(keterangan: 'Versi aplikasi', label: versi),
    );
  }
}

/// Ubin potret 64 dp: bentuknya tak beraturan dan sedikit miring, bercermin
/// antara kiri dan kanan.
class _Ubin extends StatelessWidget {
  const _Ubin({required this.user, required this.kiri});

  final Pengguna user;
  final bool kiri;

  @override
  Widget build(BuildContext context) {
    final radius = kiri
        ? const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(26),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(26),
            bottomLeft: Radius.circular(20),
          );

    return Transform.rotate(
      angle: (kiri ? -6 : 6) * math.pi / 180,
      child: Container(
        width: 64,
        height: 64,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: warnaPengguna(user).fill,
          borderRadius: radius,
        ),
        child: Align(
          alignment: const Alignment(0, 1),
          child: Potret(potretPengguna(user), ukuran: 60),
        ),
      ),
    );
  }
}

/// Kartu dua baris: keterangan kecil di atas, nilai di bawah.
class _Baris extends StatelessWidget {
  const _Baris({
    required this.keterangan,
    required this.label,
    this.onTap,
    this.warna = BerduaColors.text,
  });

  final String keterangan;
  final String label;
  final VoidCallback? onTap;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuBerdua(
      radius: Radii.button,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(keterangan, style: text.labelSmall),
          Text(
            label,
            style: text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}
