import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../models/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/hiasan_pasangan.dart';
import '../../widgets/potret.dart';
import '../../widgets/skeleton.dart';
import '../bersama/bersama_cubit.dart';
import '../money/tambah_pengeluaran_sheet.dart';
import 'beranda_cubit.dart';

/// Layar 06: Beranda.
class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final beranda = context.watch<BerandaCubit>().state;

    return Scaffold(
      floatingActionButton: beranda.adaNilai
          ? FabBerdua(
              keterangan: 'Tambah pengeluaran',
              onTap: () => TambahPengeluaranSheet.buka(context),
            )
          : null,
      body: beranda.when(
        loading: () => const SkeletonBeranda(),
        error: (error, _) => GalatLayar(
          tab: 0,
          pesan: error is ApiException
              ? error.message
              : 'Gagal memuat beranda.',
          onUlangi: () => context.read<BerandaCubit>().muat(),
        ),
        data: (data) => _Isi(data: data),
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.data});

  final Beranda data;

  void _keBersama(BuildContext context, BagianBersama bagian) {
    context.read<BagianBersamaCubit>().pilih(bagian);
    context.go('/bersama');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final user = data.user;
    final partner = data.partner;
    final durasi = data.couple.durasi.split(' ');

    return LayarBerdua(
      judul: 'Beranda',
      tab: 0,
      ruangFab: true,
      onSegarkan: () => context.read<BerandaCubit>().segarkan(),
      kepala: _BarisAtas(belumDibaca: data.notifikasiBelumDibaca),
      children: [
        const SizedBox(height: Gap.xs),
        HiasanPasangan.beranda(
          namaKiri: user.name.isEmpty ? 'Kamu' : user.name,
          potretKiri: potretPengguna(user),
          warnaKiri: warnaPengguna(user).fill,
          namaKanan: partner == null
              ? null
              : (partner.name.isEmpty ? 'Pasangan' : partner.name),
          potretKanan: partner == null ? null : potretPengguna(partner),
          warnaKanan: partner == null
              ? BerduaColors.raka
              : warnaPengguna(partner).fill,
          angka: partner != null && durasi.length == 2 ? durasi[0] : null,
          satuan: durasi.length == 2 ? durasi[1] : null,
        ),
        const SizedBox(height: Gap.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Hai, ${user.name.isEmpty ? "kamu" : user.name}',
            style: text.headlineMedium?.copyWith(fontSize: 28, height: 1.15),
          ),
        ),
        const SizedBox(height: Gap.xl),

        _KartuUang(data: data),
        const SizedBox(height: Gap.xl),

        if (data.siklus != null) ...[
          _KartuSiklus(siklus: data.siklus!),
          const SizedBox(height: Gap.xl),
        ],

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _KartuHitung(
                  label: 'Belanja',
                  nilai: data.belanjaBelumDibeli,
                  keterangan: 'belum dibeli',
                  warna: BerduaColors.mintAngka,
                  stiker: JenisStiker.bag,
                  onTap: () => _keBersama(context, BagianBersama.belanja),
                ),
              ),
              const SizedBox(width: Gap.betweenCards),
              Expanded(
                child: _KartuHitung(
                  label: 'To-do',
                  nilai: data.todoTerbuka,
                  keterangan: 'tugas terbuka',
                  warna: BerduaColors.dindaText,
                  stiker: JenisStiker.check,
                  onTap: () => _keBersama(context, BagianBersama.todo),
                ),
              ),
            ],
          ),
        ),

        if (data.jadwalTerdekat != null) ...[
          const SizedBox(height: Gap.xl),
          _KartuJadwal(
            jadwal: data.jadwalTerdekat!,
            onTap: () => _keBersama(context, BagianBersama.jadwal),
          ),
        ],

        if (data.kuis != null) ...[
          const SizedBox(height: Gap.xl),
          _KartuKuis(
            kuis: data.kuis!,
            pasangan: partner == null || partner.name.isEmpty
                ? 'pasangan'
                : partner.name,
          ),
        ],

        if (data.tabungan != null) ...[
          const SizedBox(height: Gap.xl),
          _KartuTabungan(tabungan: data.tabungan!),
        ],
      ],
    );
  }
}

/// Empat titik menu, tanggal hari ini, dan lonceng notifikasi.
class _BarisAtas extends StatelessWidget {
  const _BarisAtas({required this.belumDibaca});

  final int belumDibaca;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    Widget titik() => Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: BerduaColors.label, width: 1.5),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          ExcludeSemantics(
            child: SizedBox(
              width: 40,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [titik(), const SizedBox(width: 5), titik()],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [titik(), const SizedBox(width: 5), titik()],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              TanggalId.full(DateTime.now()),
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: BerduaColors.label),
            ),
          ),
          // Lonceng dengan jumlah belum dibaca (§5.5).
          Stack(
            clipBehavior: Clip.none,
            children: [
              TombolIkon(
                ikon: Icons.notifications_none_rounded,
                warna: BerduaColors.lutealText,
                keterangan: belumDibaca > 0
                    ? 'Notifikasi, $belumDibaca belum dibaca'
                    : 'Notifikasi',
                onTap: () => context.push('/notifikasi'),
              ),
              if (belumDibaca > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 18,
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: BerduaColors.rose,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        belumDibaca > 99 ? '99+' : '$belumDibaca',
                        style: text.labelSmall?.copyWith(
                          fontSize: 11,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: BerduaColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Baris kecil di atas kartu: bulatan ikon berwarna dan labelnya.
class _LabelKartu extends StatelessWidget {
  const _LabelKartu({
    required this.ikon,
    required this.latar,
    required this.warnaIkon,
    required this.teks,
  });

  final IconData ikon;
  final Color latar;
  final Color warnaIkon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: latar, shape: BoxShape.circle),
          child: Icon(ikon, size: 14, color: warnaIkon),
        ),
        const SizedBox(width: Gap.sm),
        Expanded(
          child: Padding(
            // Stiker menggantung di kanan atas; teks jangan sampai ke bawahnya.
            padding: const EdgeInsets.only(right: 44),
            child: Text(
              teks,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: BerduaColors.label),
            ),
          ),
        ),
      ],
    );
  }
}

class _KartuUang extends StatelessWidget {
  const _KartuUang({required this.data});

  final Beranda data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pasangan = data.partner == null || data.partner!.name.isEmpty
        ? 'pasangan'
        : data.partner!.name;
    final kalimat = data.lunas
        ? 'Tidak ada utang'
        : (data.balance > 0
              ? 'Kamu berutang ke $pasangan'
              : '${kapitalAwal(pasangan)} berutang ke kamu');

    return KartuBerdua(
      radius: Radii.cardBesar,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      stiker: JenisStiker.coin,
      onTap: () => context.go('/uang'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelKartu(
            ikon: Icons.account_balance_wallet_outlined,
            latar: BerduaColors.rose,
            warnaIkon: BerduaColors.ink,
            teks: kalimat,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Rupiah.format(data.balance.abs()),
              style: text.headlineLarge?.copyWith(fontSize: 34, height: 1.1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dompet ${Rupiah.format(data.walletBalance)} · '
            '${TanggalId.month(DateTime.now())} '
            '${Rupiah.format(data.monthTotal)}',
            style: text.labelSmall?.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _KartuSiklus extends StatelessWidget {
  const _KartuSiklus({required this.siklus});

  final RingkasanSiklus siklus;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label = _LabelKartu(
      ikon: Icons.water_drop_outlined,
      latar: BerduaColors.rakaKuat,
      warnaIkon: Colors.white,
      teks: siklus.ownerName.isEmpty ? 'Siklus' : 'Siklus ${siklus.ownerName}',
    );

    // Pasangan belum membagikan siklusnya (§5.3).
    if (!siklus.dibagikan) {
      return KartuBerdua(
        radius: Radii.cardBesar,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        stiker: JenisStiker.flower,
        onTap: () => context.go('/siklus'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: 10),
            Text(
              '${siklus.ownerName.isEmpty ? "Pasanganmu" : siklus.ownerName} '
              'belum membagikan siklusnya.',
              style: text.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      );
    }

    final panjang = siklus.rataRataPanjang.round();
    final hari = siklus.hariSampaiHaid;
    final catatan = siklus.gejalaHariIni.isNotEmpty
        ? siklus.gejalaHariIni.map(kapitalAwal).join(' · ')
        : (siklus.rataRataPanjang > 0
              ? 'Rata-rata ${Rupiah.decimal(siklus.rataRataPanjang)} hari'
              : 'Ketuk untuk melihat kalender');

    return KartuBerdua(
      radius: Radii.cardBesar,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      stiker: JenisStiker.flower,
      onTap: () => context.go('/siklus'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 10),
          Row(
            children: [
              CincinSiklus(
                hariKe: siklus.hariKe,
                panjang: panjang > 0 ? panjang : 28,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (siklus.faseLabel.isNotEmpty) ...[
                      LabelKecil(siklus.faseLabel, ukuran: 15),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      siklus.fase == 'haid'
                          ? 'Sedang haid'
                          : (hari <= 0
                                ? 'Haid sekitar hari ini'
                                : 'Haid ±$hari hari lagi'),
                      style: text.titleMedium?.copyWith(
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      catatan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KartuHitung extends StatelessWidget {
  const _KartuHitung({
    required this.label,
    required this.nilai,
    required this.keterangan,
    required this.warna,
    required this.stiker,
    required this.onTap,
  });

  final String label;
  final int nilai;
  final String keterangan;
  final Color warna;
  final JenisStiker stiker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      label: '$label: $nilai $keterangan',
      button: true,
      excludeSemantics: true,
      child: KartuBerdua(
        radius: Radii.cardBesar,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        stiker: stiker,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: text.bodySmall?.copyWith(color: BerduaColors.label),
            ),
            const SizedBox(height: 4),
            Text(
              '$nilai',
              style: text.headlineLarge?.copyWith(
                fontSize: 32,
                height: 1.1,
                color: warna,
              ),
            ),
            const SizedBox(height: 4),
            Text(keterangan, style: text.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _KartuJadwal extends StatelessWidget {
  const _KartuJadwal({required this.jadwal, required this.onTap});

  final Jadwal jadwal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuBerdua(
      radius: Radii.cardBesar,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      stiker: JenisStiker.cal,
      onTap: onTap,
      child: Row(
        children: [
          BlokTanggal(
            bulan: TanggalId.monthBadge(jadwal.date),
            hari: jadwal.date.day,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jadwal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${jadwal.type} · ${TanggalId.relative(jadwal.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu kuning "Kuis berdua": ajakan bermain, atau hasil kalau sudah.
class _KartuKuis extends StatelessWidget {
  const _KartuKuis({required this.kuis, required this.pasangan});

  final RingkasanKuis kuis;
  final String pasangan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ajakan = kuis.done ? 'Lihat hasil' : 'Main sekarang';

    return Semantics(
      button: true,
      label: 'Kuis berdua. ${kuis.catatan(pasangan)} $ajakan',
      excludeSemantics: true,
      child: KartuBerdua(
        warna: BerduaColors.kuning,
        radius: Radii.cardBesar,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        stiker: JenisStiker.quiz,
        onTap: () => context.push('/kuis'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 44),
              child: Text(
                'Kuis berdua',
                style: text.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              kuis.catatan(pasangan),
              style: text.bodySmall?.copyWith(
                fontSize: 14,
                height: 1.45,
                color: BerduaColors.teksDiWarna,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: BerduaColors.ink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                ajakan,
                style: text.titleMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuTabungan extends StatelessWidget {
  const _KartuTabungan({required this.tabungan});

  final Tabungan tabungan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      label:
          'Tabungan ${tabungan.title}, ${(tabungan.progres * 100).round()} '
          'persen terkumpul',
      button: true,
      child: KartuBerdua(
        radius: Radii.cardBesar,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        stiker: JenisStiker.piggy,
        onTap: () => context.push('/bersama/tabungan/${tabungan.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 44),
              child: Text(
                tabungan.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${Rupiah.format(tabungan.collected)} dari '
              '${Rupiah.format(tabungan.target)}',
              style: text.labelSmall?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 10),
            BatangProgres(tabungan.progres),
          ],
        ),
      ),
    );
  }
}
