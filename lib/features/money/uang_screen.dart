import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/fitur.dart';
import '../../core/rupiah.dart';
import '../../models/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import '../auth/sesi_cubit.dart';
import '../laporan/rata_rata_cubit.dart';
import '../pribadi/pribadi_cubit.dart';
import '../pribadi/pribadi_screen.dart';
import 'uang_cubit.dart';
import 'tambah_pengeluaran_sheet.dart';

/// Tab Uang: uang bersama dan uang pribadi berdampingan, bisa digeser ke
/// kiri/kanan atau dipilih lewat segmen di atasnya.
class UangScreen extends StatefulWidget {
  const UangScreen({super.key});

  @override
  State<UangScreen> createState() => _UangScreenState();
}

class _UangScreenState extends State<UangScreen> {
  late final PageController _halaman = PageController(
    initialPage: context.read<ModeUangCubit>().state ? 1 : 0,
  );

  @override
  void dispose() {
    _halaman.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pribadi = context.watch<ModeUangCubit>().state;
    final siap = pribadi
        ? context.watch<PribadiCubit>().state.adaNilai
        : context.watch<UangCubit>().state.adaNilai;

    return BlocListener<ModeUangCubit, bool>(
      // Segmen diketuk → geser ke halamannya.
      listener: (context, pribadi) {
        final tujuan = pribadi ? 1 : 0;

        if (!_halaman.hasClients || _halaman.page?.round() == tujuan) return;

        _halaman.animateToPage(
          tujuan,
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeInOutCubic,
        );
      },
      child: Scaffold(
        floatingActionButton: !siap
            ? null
            : pribadi
            ? FabBerdua(
                keterangan: 'Tambah pengeluaran pribadi',
                onTap: () => LembarPribadi.buka(context),
              )
            : FabBerdua(
                keterangan: 'Tambah pengeluaran',
                onTap: () => TambahPengeluaranSheet.buka(context),
              ),
        body: LatarBerdua(
          child: Column(
            children: [
              // Kepala dan segmen diam di tempat; hanya isi di bawahnya yang
              // bergeser.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Gap.screenEdge,
                  Gap.sm,
                  Gap.screenEdge,
                  0,
                ),
                child: Column(
                  children: [
                    // Judul berganti dengan memudar, bukan melompat.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KepalaLayar(
                        key: ValueKey(pribadi),
                        judul: pribadi ? 'Uang pribadi' : 'Uang bersama',
                        kiri: Stiker.kecil(
                          pribadi ? JenisStiker.piggy : JenisStiker.wallet,
                        ),
                        aksi: TombolIkon(
                          ikon: Icons.bar_chart_rounded,
                          keterangan: pribadi ? 'Laporan pribadi' : 'Laporan',
                          onTap: () => context.push(
                            pribadi ? '/laporan-pribadi' : '/laporan',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                    PemilihModeUang(halaman: _halaman),
                    // Ruang untuk bayangan segmen agar tidak tertutup isi.
                    const SizedBox(height: Gap.sm),
                  ],
                ),
              ),
              Expanded(
                // Bilah status sudah digambar oleh latar di atas.
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: PageView(
                    controller: _halaman,
                    // Halaman digeser → segmen ikut berpindah.
                    onPageChanged: (i) =>
                        context.read<ModeUangCubit>().pilih(pribadi: i == 1),
                    children: const [
                      _TetapHidup(child: UangBersamaScreen()),
                      _TetapHidup(child: PribadiScreen()),
                    ],
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

/// Menjaga posisi gulir halaman yang sedang tidak tampil.
class _TetapHidup extends StatefulWidget {
  const _TetapHidup({required this.child});

  final Widget child;

  @override
  State<_TetapHidup> createState() => _TetapHidupState();
}

class _TetapHidupState extends State<_TetapHidup>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return widget.child;
  }
}

/// Layar 08: isi uang bersama (kepala & FAB dipasang oleh [UangScreen]).
class UangBersamaScreen extends StatelessWidget {
  const UangBersamaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ringkasan = context.watch<UangCubit>().state;
    final sesi = context.watch<SesiCubit>().state;

    return ringkasan.when(
      // Isi lama bertahan saat filter berganti; hanya pemuatan pertama yang
      // memakai kerangka.
      loading: () => const SkeletonUang(tanpaJudul: true),
      error: (error, _) => GalatLayar(
        tab: 1,
        pesan: error is ApiException
            ? error.message
            : 'Gagal memuat transaksi.',
        onUlangi: () => context.read<UangCubit>().muat(),
      ),
      data: (data) => _Isi(data: data, sesi: sesi),
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
      tanpaKepala: true,
      tab: 1,
      ruangFab: true,
      children: [
        const SizedBox(height: Gap.xs),
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
                  label: 'Total ${TanggalId.month(DateTime.now())}',
                  nilai: Rupiah.format(data.monthTotal),
                  stiker: JenisStiker.chart,
                ),
              ),
              const SizedBox(width: Gap.betweenCards),
              if (Fitur.dompetBersama)
                Expanded(
                  child: _Ringkas(
                    label: 'Dompet bersama',
                    nilai: Rupiah.format(data.walletBalance),
                    stiker: JenisStiker.wallet,
                  ),
                )
              else
                const Expanded(child: _RingkasRataRata()),
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

/// Rata-rata pengeluaran untuk rentang yang terakhir dipilih; mengetuknya
/// membuka layar rata-rata.
class _RingkasRataRata extends StatelessWidget {
  const _RingkasRataRata();

  @override
  Widget build(BuildContext context) {
    final periode = context.watch<PeriodeRataRataCubit>().state;
    final rataRata = context.watch<RataRataCubit>().state.nilai;

    return _Ringkas(
      label: 'Rata-rata / ${periode.satuan}',
      nilai: rataRata == null ? '–' : Rupiah.format(rataRata.rataRata),
      stiker: JenisStiker.coin,
      onTap: () => context.push('/rata-rata'),
    );
  }
}

/// Kartu kecil dua baris dengan stiker: label di atas nominalnya.
class _Ringkas extends StatelessWidget {
  const _Ringkas({
    required this.label,
    required this.nilai,
    required this.stiker,
    this.onTap,
  });

  final String label;
  final String nilai;
  final JenisStiker stiker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuBerdua(
      radius: Radii.button,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      stiker: stiker,
      onTap: onTap,
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
