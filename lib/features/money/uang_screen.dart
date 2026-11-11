import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../models/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import '../auth/sesi_cubit.dart';
import 'uang_cubit.dart';
import 'tambah_pengeluaran_sheet.dart';

/// Layar 08: Uang bersama.
class UangScreen extends StatelessWidget {
  const UangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ringkasan = context.watch<UangCubit>().state;
    final sesi = context.watch<SesiCubit>().state;

    return Scaffold(
      floatingActionButton: ringkasan.adaNilai
          ? FabBerdua(
              keterangan: 'Tambah pengeluaran',
              onTap: () => TambahPengeluaranSheet.buka(context),
            )
          : null,
      body: ringkasan.when(
        // Isi lama bertahan saat filter berganti; hanya pemuatan pertama yang
        // memakai kerangka.
        loading: () => const SkeletonUang(),
        error: (error, _) => GalatLayar(
          tab: 1,
          pesan: error is ApiException
              ? error.message
              : 'Gagal memuat transaksi.',
          onUlangi: () => context.read<UangCubit>().muat(),
        ),
        data: (data) => _Isi(data: data, sesi: sesi),
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.data, required this.sesi});

  final RingkasanUang data;
  final SesiState sesi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final filter = context.watch<FilterUangCubit>().state;

    // Segmen §16: Semua / nama masing-masing.
    final pilihan = <Pengguna?>[null, ?sesi.user, ?sesi.partner];

    final pasangan = sesi.partner == null || sesi.partner!.name.isEmpty
        ? 'pasangan'
        : sesi.partner!.name;
    final kalimat = data.lunas
        ? 'Tidak ada utang'
        : (data.balance > 0
              ? 'Kamu berutang ke $pasangan'
              : '${kapitalAwal(pasangan)} berutang ke kamu');

    return LayarBerdua(
      judul: 'Uang bersama',
      tab: 1,
      ruangFab: true,
      kiri: const Stiker.kecil(JenisStiker.wallet),
      aksi: TombolIkon(
        ikon: Icons.bar_chart_rounded,
        keterangan: 'Laporan',
        onTap: () => context.push('/laporan'),
      ),
      children: [
        const SizedBox(height: Gap.sm),
        // §12: satu kartu rose per layar — di sini untuk saldo utang.
        KartuRose(
          stiker: JenisStiker.coin,
          child: Column(
            children: [
              Text(
                kalimat,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: BerduaColors.label),
              ),
              const SizedBox(height: Gap.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AngkaBerbingkai(Rupiah.format(data.balance.abs())),
              ),
              if (!data.lunas) ...[
                const SizedBox(height: 14),
                const _TombolLunas(),
              ],
            ],
          ),
        ),
        const SizedBox(height: Gap.xl),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Ringkas(
                  label: 'Dompet bersama',
                  nilai: Rupiah.format(data.walletBalance),
                  stiker: JenisStiker.wallet,
                ),
              ),
              const SizedBox(width: Gap.betweenCards),
              Expanded(
                child: _Ringkas(
                  label: 'Total ${TanggalId.month(DateTime.now())}',
                  nilai: Rupiah.format(data.monthTotal),
                  stiker: JenisStiker.chart,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.betweenCards),
        SegmenBerdua<Pengguna?>(
          pilihan: pilihan,
          terpilih: pilihan.firstWhere(
            (user) => user?.id == filter.payerId,
            orElse: () => null,
          ),
          label: (user) =>
              user == null ? 'Semua' : (user.name.isEmpty ? 'Aku' : user.name),
          onPilih: (user) => context.read<FilterUangCubit>().pilih(user?.id),
        ),
        const SizedBox(height: Gap.betweenCards),
        if (data.transaksi.isEmpty)
          KartuBerdua(
            radius: Radii.button,
            padding: const EdgeInsets.all(Gap.xl),
            child: Column(
              children: [
                const Stiker.sedang(JenisStiker.coin),
                const SizedBox(height: Gap.sm),
                Text(
                  'Belum ada transaksi',
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  'Ketuk tombol + untuk mencatat pengeluaran pertama.',
                  style: text.labelSmall?.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          for (final transaksi in data.transaksi) ...[
            _BarisTransaksi(transaksi: transaksi, sesi: sesi),
            const SizedBox(height: Gap.sm),
          ],
      ],
    );
  }
}

/// Kartu kecil dua baris dengan stiker: "Dompet bersama" di atas nominalnya.
class _Ringkas extends StatelessWidget {
  const _Ringkas({
    required this.label,
    required this.nilai,
    required this.stiker,
  });

  final String label;
  final String nilai;
  final JenisStiker stiker;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuBerdua(
      radius: Radii.button,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      stiker: stiker,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall?.copyWith(color: BerduaColors.label),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              nilai,
              style: text.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Warna bulatan mengikuti peran pembayar (§12); dompet bersama mint.
Color _warnaPembayar(Transaksi transaksi, SesiState sesi) {
  final pembayar = transaksi.payerId == sesi.user?.id
      ? sesi.user
      : (transaksi.payerId == sesi.partner?.id ? sesi.partner : null);

  return pembayar == null ? BerduaColors.mint : warnaPengguna(pembayar).fill;
}

class _BarisTransaksi extends StatelessWidget {
  const _BarisTransaksi({required this.transaksi, required this.sesi});

  final Transaksi transaksi;
  final SesiState sesi;

  @override
  Widget build(BuildContext context) {
    return KartuDaftar(
      leading: AvatarInisial(
        initial: transaksi.initial,
        fill: _warnaPembayar(transaksi, sesi),
      ),
      judul: transaksi.title,
      keterangan: '${transaksi.category} · ${transaksi.keterangan}',
      trailing: Rupiah.format(transaksi.amount),
      trailingBawah: TanggalId.short(transaksi.date),
      onTap: () => bukaLembar<void>(
        context,
        (_) => _LembarDetail(transaksi: transaksi, sesi: sesi, induk: context),
      ),
    );
  }
}

/// Layar 10: detail transaksi, dengan jalur ubah dan hapus (§5.2).
class _LembarDetail extends StatefulWidget {
  const _LembarDetail({
    required this.transaksi,
    required this.sesi,
    required this.induk,
  });

  final Transaksi transaksi;
  final SesiState sesi;

  /// Konteks layar Uang, dipakai membuka sheet ubah setelah sheet ini tutup.
  final BuildContext induk;

  @override
  State<_LembarDetail> createState() => _LembarDetailState();
}

class _LembarDetailState extends State<_LembarDetail> {
  bool _menghapus = false;

  Future<void> _hapus() async {
    // Messenger dan navigator dipegang sebelum await supaya BuildContext tidak
    // disentuh sesudah sheet ditutup.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _menghapus = true);

    try {
      await context.read<UangCubit>().hapus(widget.transaksi.id);

      navigator.pop();
      tampilkanToastVia(messenger, 'Transaksi dihapus');
    } on ApiException catch (error) {
      if (mounted) setState(() => _menghapus = false);

      tampilkanToastVia(messenger, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final transaksi = widget.transaksi;
    final sesi = widget.sesi;
    final user = sesi.user;
    final partner = sesi.partner;

    // Bagian tiap orang: payerShare milik pembayar, partnerShare milik yang
    // satunya.
    final akuPembayar = transaksi.payerId == user?.id;
    final bagianAku = akuPembayar
        ? transaksi.payerShare
        : transaksi.partnerShare;
    final bagianPasangan = akuPembayar
        ? transaksi.partnerShare
        : transaksi.payerShare;
    final adaBagian =
        !transaksi.dariDompet &&
        !transaksi.pelunasan &&
        user != null &&
        partner != null;

    final baris = transaksi.dariDompet
        ? 'Dari dompet bersama'
        : (transaksi.pelunasan
              ? 'Pelunasan oleh ${transaksi.payerName ?? "-"}'
              : 'Dibayar ${transaksi.payerName ?? "-"} · '
                    '${transaksi.split == CaraPembagian.custom ? "${transaksi.payerSharePct}/${100 - transaksi.payerSharePct}" : transaksi.split.label}');

    Widget ubin(Pengguna orang, int nominal) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: warnaPengguna(orang).fill,
          borderRadius: BorderRadius.circular(Radii.button),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bagian ${orang.name.isEmpty ? "-" : orang.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(color: BerduaColors.ink),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Rupiah.format(nominal),
                style: text.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return IsiLembar(
      judul: '${transaksi.category} · ${TanggalId.full(transaksi.date)}',
      judulKecil: true,
      jarak: 14,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: KartuRose(
            miring: true,
            child: Column(
              children: [
                Text(
                  transaksi.title,
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(fontSize: 20),
                ),
                const SizedBox(height: Gap.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AngkaBerbingkai(
                    Rupiah.format(transaksi.amount),
                    ukuran: 32,
                  ),
                ),
                const SizedBox(height: Gap.sm),
                Text(
                  baris,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    fontSize: 15,
                    color: BerduaColors.label,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (adaBagian)
          Row(
            children: [
              ubin(user, bagianAku),
              const SizedBox(width: 10),
              ubin(partner, bagianPasangan),
            ],
          ),
        Row(
          children: [
            // Pelunasan dibuat backend dan tidak bisa diubah lewat formulir.
            if (!transaksi.pelunasan) ...[
              Expanded(
                child: TombolPink(
                  label: 'Ubah',
                  tebal: FontWeight.w600,
                  onPressed: _menghapus
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          TambahPengeluaranSheet.buka(
                            widget.induk,
                            transaksi: transaksi,
                          );
                        },
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: TombolSekunder(
                label: _menghapus ? 'Menghapus…' : 'Hapus',
                warna: BerduaColors.roseText,
                onPressed: _menghapus ? null : _hapus,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TombolLunas extends StatefulWidget {
  const _TombolLunas();

  @override
  State<_TombolLunas> createState() => _TombolLunasState();
}

class _TombolLunasState extends State<_TombolLunas> {
  bool _memuat = false;

  @override
  Widget build(BuildContext context) {
    return TombolPink(
      label: 'TANDAI LUNAS',
      tinggi: 42,
      radius: 14,
      ukuranHuruf: 15,
      lebarPenuh: false,
      memuat: _memuat,
      onPressed: () async {
        // Messenger dipegang sebelum await; `context` dari build tidak lagi
        // disentuh sesudahnya.
        final messenger = ScaffoldMessenger.of(context);

        setState(() => _memuat = true);

        try {
          await context.read<UangCubit>().tandaiLunas();

          tampilkanToastVia(messenger, 'Saldo kembali Rp 0');
        } on ApiException catch (error) {
          tampilkanToastVia(messenger, error.message);
        } finally {
          if (mounted) setState(() => _memuat = false);
        }
      },
    );
  }
}
