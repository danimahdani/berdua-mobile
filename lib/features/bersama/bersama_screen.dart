import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../models/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import '../auth/auth_controller.dart';
import 'bersama_controller.dart';

/// Bagian-bagian layar "Bersama" (§5.4).
enum BagianBersama {
  belanja('Belanja'),
  todo('To-do'),
  tabungan('Tabungan'),
  jadwal('Jadwal'),
  jurnal('Jurnal');

  const BagianBersama(this.label);

  final String label;
}

final bagianBersamaProvider = NotifierProvider<_BagianController, BagianBersama>(
  _BagianController.new,
);

class _BagianController extends Notifier<BagianBersama> {
  @override
  BagianBersama build() => BagianBersama.belanja;

  void pilih(BagianBersama bagian) => state = bagian;
}

/// Layar 16-22 dalam satu tab, dipilih lewat segmen di atas.
class BersamaScreen extends ConsumerWidget {
  const BersamaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bagian = ref.watch(bagianBersamaProvider);

    return Scaffold(
      body: LayarBerdua(
        judul: 'Bersama',
        stiker: JenisStiker.bag,
        tab: 3,
        children: [
          // Lima bagian tidak muat dalam satu baris tetap di layar sempit,
          // jadi segmennya bisa digeser.
          SegmenBerdua<BagianBersama>(
            gulir: true,
            pilihan: BagianBersama.values,
            terpilih: bagian,
            label: (item) => item.label,
            onPilih: (item) =>
                ref.read(bagianBersamaProvider.notifier).pilih(item),
          ),
          const SizedBox(height: Gap.betweenCards),
          switch (bagian) {
            BagianBersama.belanja => const _Belanja(),
            BagianBersama.todo => const _Todo(),
            BagianBersama.tabungan => const _Tabungan(),
            BagianBersama.jadwal => const _Jadwal(),
            BagianBersama.jurnal => const _Jurnal(),
          },
        ],
      ),
    );
  }
}

/// Pembungkus seragam tiap bagian: area isian di atas, lalu memuat, galat,
/// kosong, atau isi. Kartunya memantul masuk tiap bagian dibuka.
class _Bagian<T> extends StatefulWidget {
  const _Bagian({
    required this.nilai,
    required this.kosong,
    required this.bangun,
    required this.skeleton,
    required this.onUlangi,
    this.atas = const [],
    this.stikerKosong = JenisStiker.bag,
  });

  final AsyncValue<List<T>> nilai;
  final String kosong;
  final JenisStiker stikerKosong;
  final List<Widget> Function(List<T>) bangun;

  /// Kerangka khusus bagian ini: tinggi barisnya mengikuti kartu aslinya,
  /// supaya isinya tidak melompat saat data datang.
  final Widget skeleton;
  final VoidCallback onUlangi;
  final List<Widget> atas;

  @override
  State<_Bagian<T>> createState() => _BagianState<T>();
}

class _BagianState<T> extends State<_Bagian<T>> {
  /// Saat bagian ini dibuka; kartu yang datang belakangan (hasil tambah)
  /// langsung tampil tanpa menunggu giliran pantulnya.
  final _mulai = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final isi = widget.nilai.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => [widget.skeleton],
      error: (error, _) => [
        KartuBerdua(
          radius: Radii.button,
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            children: [
              Text(
                error is ApiException ? error.message : 'Gagal memuat.',
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
              const SizedBox(height: Gap.md),
              TombolSekunder(label: 'Coba lagi', onPressed: widget.onUlangi),
            ],
          ),
        ),
      ],
      data: (items) => items.isEmpty
          ? [
              KartuBerdua(
                radius: Radii.button,
                padding: const EdgeInsets.all(Gap.xl),
                child: Column(
                  children: [
                    Stiker.sedang(widget.stikerKosong),
                    const SizedBox(height: Gap.sm),
                    Text(
                      widget.kosong,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: BerduaColors.label,
                      ),
                    ),
                  ],
                ),
              ),
            ]
          : widget.bangun(items),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: memantulkan([...widget.atas, ...isi], mulai: _mulai),
    );
  }
}

/// Tombol hapus kecil di ujung baris. Mengetuk kartunya sendiri tidak pernah
/// menghapus apa pun.
class _TombolHapus extends StatelessWidget {
  const _TombolHapus({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hapus',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.fromLTRB(10, 8, 0, 8),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: BerduaColors.teksCoret,
          ),
        ),
      ),
    );
  }
}

/// Isian sebaris dengan tombol tambah pink di kanannya.
class _IsianTambah extends StatelessWidget {
  const _IsianTambah({
    required this.kendali,
    required this.petunjuk,
    required this.onTambah,
    required this.memuat,
  });

  final TextEditingController kendali;
  final String petunjuk;
  final VoidCallback onTambah;
  final bool memuat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: kendali,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 17,
            ),
            inputFormatters: [LengthLimitingTextInputFormatter(80)],
            onSubmitted: (_) => onTambah(),
            decoration: InputDecoration(hintText: petunjuk),
          ),
        ),
        const SizedBox(width: Gap.sm),
        TombolTambahKecil(onTap: onTambah, memuat: memuat),
      ],
    );
  }
}

/// Baris bercentang: kotak, judul (dicoret kalau selesai), dan isi kanan.
class _BarisCentang extends StatelessWidget {
  const _BarisCentang({
    super.key,
    required this.judul,
    required this.selesai,
    required this.onCentang,
    required this.onHapus,
    this.keterangan,
    this.kanan,
  });

  final String judul;
  final String? keterangan;
  final bool selesai;
  final VoidCallback onCentang;
  final VoidCallback onHapus;
  final Widget? kanan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      checked: selesai,
      child: KartuBerdua(
        radius: Radii.input,
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        onTap: onCentang,
        child: Row(
          children: [
            KotakCentang(selesai: selesai),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: text.bodyLarge?.copyWith(
                      fontSize: 17,
                      // Yang sudah selesai ditandai coret dan diredupkan.
                      decoration: selesai ? TextDecoration.lineThrough : null,
                      decorationColor: BerduaColors.teksCoret,
                      color: selesai ? BerduaColors.teksCoret : BerduaColors.ink,
                    ),
                  ),
                  if (keterangan != null) ...[
                    const SizedBox(height: 1),
                    Text(keterangan!, style: text.labelSmall),
                  ],
                ],
              ),
            ),
            if (kanan != null) ...[const SizedBox(width: Gap.sm), kanan!],
            _TombolHapus(onTap: onHapus),
          ],
        ),
      ),
    );
  }
}

/// Menjalankan aksi kecil (centang, hapus) dan menampilkan galatnya sebagai
/// toast.
Future<void> _jalankan(BuildContext context, Future<void> Function() aksi) async {
  final messenger = ScaffoldMessenger.of(context);

  try {
    await aksi();
  } on ApiException catch (error) {
    tampilkanToastVia(messenger, error.message);
  }
}

// --------------------------------------------------------------- layar 16

class _Belanja extends ConsumerStatefulWidget {
  const _Belanja();

  @override
  ConsumerState<_Belanja> createState() => _BelanjaState();
}

class _BelanjaState extends ConsumerState<_Belanja> {
  final _judul = TextEditingController();
  bool _menyimpan = false;

  @override
  void dispose() {
    _judul.dispose();
    super.dispose();
  }

  Future<void> _tambah() async {
    final judul = _judul.text.trim();

    if (judul.isEmpty || _menyimpan) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() => _menyimpan = true);

    try {
      await ref.read(belanjaProvider.notifier).tambah(judul);
      _judul.clear();
    } on ApiException catch (error) {
      tampilkanToastVia(messenger, error.message);
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final belanja = ref.read(belanjaProvider.notifier);

    return _Bagian<BarangBelanja>(
      nilai: ref.watch(belanjaProvider),
      kosong: 'Daftar belanja masih kosong.',
      skeleton: const SkeletonDaftar(sematan: true, tinggiBaris: 56),
      onUlangi: () => ref.invalidate(belanjaProvider),
      atas: [
        _IsianTambah(
          kendali: _judul,
          petunjuk: 'Tambah barang…',
          onTambah: _tambah,
          memuat: _menyimpan,
        ),
        const SizedBox(height: Gap.md),
      ],
      bangun: (items) => [
        for (final item in items) ...[
          _BarisCentang(
            key: ValueKey(item.id),
            judul: item.title,
            selesai: item.done,
            onCentang: () => _jalankan(context, () => belanja.centang(item.id)),
            onHapus: () => _jalankan(context, () => belanja.hapus(item.id)),
            kanan: Text(item.addedByName, style: text.labelSmall),
          ),
          const SizedBox(height: Gap.md),
        ],
      ],
    );
  }
}

// --------------------------------------------------------------- layar 17

class _Todo extends ConsumerStatefulWidget {
  const _Todo();

  @override
  ConsumerState<_Todo> createState() => _TodoState();
}

class _TodoState extends ConsumerState<_Todo> {
  final _judul = TextEditingController();
  int? _assignee;
  DateTime? _tenggat;
  bool _menyimpan = false;

  @override
  void dispose() {
    _judul.dispose();
    super.dispose();
  }

  Future<void> _tambah() async {
    final judul = _judul.text.trim();

    if (judul.isEmpty || _menyimpan) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() => _menyimpan = true);

    try {
      await ref.read(todoProvider.notifier).tambah(
        judul: judul,
        assigneeId: _assignee,
        tenggat: _tenggat,
      );

      _judul.clear();

      if (mounted) setState(() => _tenggat = null);
    } on ApiException catch (error) {
      tampilkanToastVia(messenger, error.message);
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  Future<void> _pilihTenggat() async {
    // Sudah ada tenggat: ketukan berikutnya menghapusnya.
    if (_tenggat != null) {
      setState(() => _tenggat = null);

      return;
    }

    final sekarang = DateTime.now();
    final dipilih = await showDatePicker(
      context: context,
      initialDate: sekarang,
      firstDate: sekarang,
      lastDate: sekarang.add(const Duration(days: 730)),
    );

    if (dipilih != null && mounted) setState(() => _tenggat = dipilih);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sesi = ref.watch(sesiProvider);
    final anggota = [sesi.user, sesi.partner].whereType<Pengguna>().toList();
    final todo = ref.read(todoProvider.notifier);

    return _Bagian<Tugas>(
      nilai: ref.watch(todoProvider),
      kosong: 'Belum ada tugas.',
      stikerKosong: JenisStiker.check,
      skeleton: const SkeletonDaftar(sematan: true, baris: 3, tinggiBaris: 64),
      onUlangi: () => ref.invalidate(todoProvider),
      atas: [
        _IsianTambah(
          kendali: _judul,
          petunjuk: 'Tugas baru…',
          onTambah: _tambah,
          memuat: _menyimpan,
        ),
        const SizedBox(height: Gap.sm),
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  'Untuk',
                  style: text.bodySmall?.copyWith(color: BerduaColors.label),
                ),
              ),
              ChipBerdua(
                label: 'Berdua',
                tinggi: 32,
                aktif: _assignee == null,
                onTap: () => setState(() => _assignee = null),
              ),
              for (final user in anggota)
                ChipBerdua(
                  label: user.name.isEmpty ? 'Aku' : user.name,
                  tinggi: 32,
                  aktif: _assignee == user.id,
                  onTap: () => setState(() => _assignee = user.id),
                ),
              ChipBerdua(
                label: _tenggat == null
                    ? '+ Tenggat'
                    : '${TanggalId.short(_tenggat!)} ×',
                tinggi: 32,
                aktif: _tenggat != null,
                onTap: _pilihTenggat,
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
      ],
      bangun: (items) => [
        for (final tugas in items) ...[
          _BarisCentang(
            key: ValueKey(tugas.id),
            judul: tugas.title,
            keterangan: tugas.dueDate == null
                ? null
                : kapitalAwal(TanggalId.relative(tugas.dueDate!)),
            selesai: tugas.done,
            onCentang: () => _jalankan(context, () => todo.centang(tugas.id)),
            onHapus: () => _jalankan(context, () => todo.hapus(tugas.id)),
            kanan: LabelKecil(tugas.penanggungJawab),
          ),
          const SizedBox(height: Gap.md),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------ layar 18-19

class _Tabungan extends ConsumerWidget {
  const _Tabungan();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return _Bagian<TargetTabungan>(
      nilai: ref.watch(tabunganProvider),
      kosong: 'Belum ada target tabungan.',
      stikerKosong: JenisStiker.piggy,
      skeleton: const SkeletonDaftar(sematan: true, baris: 2, tinggiBaris: 112),
      onUlangi: () => ref.invalidate(tabunganProvider),
      atas: [
        TombolPutus(
          label: 'Tambah target tabungan',
          stiker: JenisStiker.piggy,
          onTap: () => bukaLembar<void>(context, (_) => const _TabunganSheet()),
        ),
        // Stiker kartu pertama menggantung 16 dp ke atas.
        const SizedBox(height: Gap.xl),
      ],
      bangun: (items) => [
        for (final goal in items) ...[
          KartuBerdua(
            key: ValueKey(goal.id),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            stiker: JenisStiker.piggy,
            onTap: () => context.push('/bersama/tabungan/${goal.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 48),
                  child: Text(
                    goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                BatangProgres(goal.progres),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: Rupiah.format(goal.collected),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: BerduaColors.ink,
                              ),
                            ),
                            TextSpan(
                              text: ' dari ${Rupiah.format(goal.target)}',
                            ),
                          ],
                        ),
                        style: text.labelSmall?.copyWith(fontSize: 14),
                      ),
                    ),
                    if (goal.dueDate != null)
                      Text(
                        TanggalId.monthYearShort(goal.dueDate!),
                        style: text.labelSmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.xl),
        ],
      ],
    );
  }
}

/// Kotak bergaris yang membuka pemilih tanggal — pengganti input tanggal.
class _IsianTanggal extends StatelessWidget {
  const _IsianTanggal({required this.teks, required this.onTap, this.terisi = true});

  final String teks;
  final bool terisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: KartuBerdua(
        radius: Radii.input,
        bayangan: false,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                teks,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  color: terisi ? BerduaColors.ink : BerduaColors.teksCoret,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: BerduaColors.label,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabunganSheet extends ConsumerStatefulWidget {
  const _TabunganSheet();

  @override
  ConsumerState<_TabunganSheet> createState() => _TabunganSheetState();
}

class _TabunganSheetState extends ConsumerState<_TabunganSheet> {
  final _judul = TextEditingController();
  final _target = TextEditingController();
  DateTime? _tenggat;
  bool _menyimpan = false;
  String? _galat;

  @override
  void dispose() {
    _judul.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final target = Rupiah.parse(_target.text);

    if (_judul.text.trim().isEmpty || target == null || target < 1) {
      setState(() => _galat = 'Isi judul dan target yang benar.');

      return;
    }

    // Navigator dipegang sebelum await supaya BuildContext tidak disentuh
    // setelah sheet selesai menyimpan.
    final navigator = Navigator.of(context);

    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    try {
      await ref.read(tabunganProvider.notifier).tambah(
        judul: _judul.text.trim(),
        target: target,
        tenggat: _tenggat,
      );

      navigator.pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _galat = error.message);
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return IsiLembar(
      judul: 'Target baru',
      children: [
        TextField(
          controller: _judul,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: text.bodyLarge?.copyWith(fontSize: 17),
          inputFormatters: [LengthLimitingTextInputFormatter(80)],
          decoration: const InputDecoration(
            hintText: 'Nama target, mis. Liburan ke Bali',
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LabelIsian('Target'),
            TextField(
              controller: _target,
              keyboardType: TextInputType.number,
              style: text.bodyLarge?.copyWith(fontSize: 17),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '12000000',
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LabelIsian('Tenggat'),
            _IsianTanggal(
              teks: _tenggat == null
                  ? 'Tanpa tenggat'
                  : TanggalId.long(_tenggat!),
              terisi: _tenggat != null,
              onTap: () async {
                final sekarang = DateTime.now();
                final dipilih = await showDatePicker(
                  context: context,
                  initialDate:
                      _tenggat ?? sekarang.add(const Duration(days: 30)),
                  firstDate: sekarang.add(const Duration(days: 1)),
                  lastDate: sekarang.add(const Duration(days: 3650)),
                );

                if (dipilih != null && mounted) {
                  setState(() => _tenggat = dipilih);
                }
              },
            ),
          ],
        ),
        ?(_galat == null ? null : TeksGalat(_galat!)),
        TombolUtama(label: 'Simpan', memuat: _menyimpan, onPressed: _simpan),
      ],
    );
  }
}

// ------------------------------------------------------------ layar 20-21

class _Jadwal extends ConsumerWidget {
  const _Jadwal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final jadwal = ref.read(jadwalProvider.notifier);

    return _Bagian<Acara>(
      nilai: ref.watch(jadwalProvider),
      kosong: 'Belum ada jadwal.',
      stikerKosong: JenisStiker.cal,
      skeleton: const SkeletonDaftar(sematan: true, baris: 3, tinggiBaris: 82),
      onUlangi: () => ref.invalidate(jadwalProvider),
      atas: [
        TombolPutus(
          label: 'Tambah jadwal atau pengingat',
          stiker: JenisStiker.cal,
          onTap: () => bukaLembar<void>(context, (_) => const _JadwalSheet()),
        ),
        const SizedBox(height: Gap.md),
      ],
      bangun: (items) => [
        for (final acara in items) ...[
          KartuBerdua(
            key: ValueKey(acara.id),
            radius: Radii.button,
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                BlokTanggal(
                  bulan: TanggalId.monthBadge(acara.nextOccurrence),
                  hari: acara.nextOccurrence.day,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acara.title,
                        style: text.bodyLarge?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          kapitalAwal(TanggalId.relative(acara.nextOccurrence)),
                          'ingatkan ${acara.labelPengingat}',
                          if (acara.yearly) 'tahunan',
                        ].join(' · '),
                        style: text.labelSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Gap.sm),
                LabelKecil(
                  acara.type,
                  latar: BerduaColors.card2,
                  warna: BerduaColors.lutealText,
                  ukuran: 12,
                ),
                _TombolHapus(
                  onTap: () => _jalankan(context, () => jadwal.hapus(acara.id)),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.md),
        ],
      ],
    );
  }
}

/// Layar 21: Tambah jadwal.
class _JadwalSheet extends ConsumerStatefulWidget {
  const _JadwalSheet();

  @override
  ConsumerState<_JadwalSheet> createState() => _JadwalSheetState();
}

class _JadwalSheetState extends ConsumerState<_JadwalSheet> {
  final _judul = TextEditingController();
  DateTime _tanggal = DateTime.now().add(const Duration(days: 1));
  String _jenis = BerduaEnums.eventTypes.first;
  int _ingatkan = 1;
  bool _tahunan = false;
  bool _menyimpan = false;
  String? _galat;

  static const _pilihanIngatkan = {
    0: 'Hari H',
    1: '1 hari',
    3: '3 hari',
    7: '1 minggu',
  };

  @override
  void dispose() {
    _judul.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_judul.text.trim().isEmpty) {
      setState(() => _galat = 'Judul tidak boleh kosong.');

      return;
    }

    // Navigator dipegang sebelum await supaya BuildContext tidak disentuh
    // setelah sheet selesai menyimpan.
    final navigator = Navigator.of(context);

    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    try {
      await ref.read(jadwalProvider.notifier).tambah(
        judul: _judul.text.trim(),
        tanggal: _tanggal,
        jenis: _jenis,
        ingatkan: _ingatkan,
        tahunan: _tahunan,
      );

      navigator.pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _galat = error.message);
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return IsiLembar(
      judul: 'Jadwal baru',
      children: [
        TextField(
          controller: _judul,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: text.bodyLarge?.copyWith(fontSize: 17),
          inputFormatters: [LengthLimitingTextInputFormatter(80)],
          decoration: const InputDecoration(
            hintText: 'Judul, mis. Makan malam anniversary',
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LabelIsian('Tanggal'),
            _IsianTanggal(
              teks: TanggalId.long(_tanggal),
              onTap: () async {
                final tahun = DateTime.now().year;
                final dipilih = await showDatePicker(
                  context: context,
                  initialDate: _tanggal,
                  firstDate: DateTime(tahun - 5),
                  lastDate: DateTime(tahun + 5, 12, 31),
                );

                if (dipilih != null && mounted) {
                  setState(() => _tanggal = dipilih);
                }
              },
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LabelIsian('Jenis'),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final jenis in BerduaEnums.eventTypes)
                  ChipBerdua(
                    label: jenis,
                    aktif: _jenis == jenis,
                    onTap: () => setState(() => _jenis = jenis),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LabelIsian('Ingatkan'),
            SegmenBerdua<int>(
              gaya: GayaSegmen.sheet,
              ukuranHuruf: 14,
              pilihan: _pilihanIngatkan.keys.toList(),
              terpilih: _ingatkan,
              label: (hari) => _pilihanIngatkan[hari]!,
              onPilih: (hari) => setState(() => _ingatkan = hari),
            ),
          ],
        ),
        BarisSakelar(
          label: 'Ulangi setiap tahun',
          nyala: _tahunan,
          onUbah: (nilai) => setState(() => _tahunan = nilai),
        ),
        ?(_galat == null ? null : TeksGalat(_galat!)),
        TombolUtama(
          label: 'Simpan jadwal',
          memuat: _menyimpan,
          onPressed: _simpan,
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- layar 22

class _Jurnal extends ConsumerStatefulWidget {
  const _Jurnal();

  @override
  ConsumerState<_Jurnal> createState() => _JurnalState();
}

class _JurnalState extends ConsumerState<_Jurnal> {
  final _teks = TextEditingController();
  bool _menyimpan = false;

  @override
  void dispose() {
    _teks.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final teks = _teks.text.trim();

    if (teks.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final fokus = FocusScope.of(context);

    setState(() => _menyimpan = true);

    try {
      await ref.read(jurnalProvider.notifier).tulis(teks);
      _teks.clear();
      fokus.unfocus();
      tampilkanToastVia(messenger, 'Catatan disimpan');
    } on ApiException catch (error) {
      tampilkanToastVia(messenger, error.message);
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sesi = ref.watch(sesiProvider);
    final jurnal = ref.read(jurnalProvider.notifier);

    return _Bagian<CatatanJurnal>(
      nilai: ref.watch(jurnalProvider),
      kosong: 'Belum ada catatan.',
      stikerKosong: JenisStiker.note,
      skeleton: const SkeletonDaftar(sematan: true, baris: 2, tinggiBaris: 104),
      onUlangi: () => ref.invalidate(jurnalProvider),
      atas: [
        TextField(
          controller: _teks,
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          style: text.bodyLarge?.copyWith(fontSize: 17, height: 1.45),
          inputFormatters: [LengthLimitingTextInputFormatter(2000)],
          decoration: const InputDecoration(
            hintText: 'Tulis sesuatu tentang hari ini…',
          ),
        ),
        const SizedBox(height: 10),
        TombolPink(
          label: 'SIMPAN CATATAN',
          tinggi: 50,
          ukuranHuruf: 16,
          stiker: JenisStiker.note,
          memuat: _menyimpan,
          onPressed: _simpan,
        ),
        const SizedBox(height: Gap.lg),
      ],
      bangun: (items) => [
        for (final catatan in items) ...[
          KartuBerdua(
            key: ValueKey(catatan.id),
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${catatan.authorName} · '
                        '${TanggalId.short(catatan.date)}',
                        style: text.labelSmall?.copyWith(
                          color: BerduaColors.label,
                        ),
                      ),
                    ),
                    // §5.4 tidak mengatur penghapusan; backend membatasi ke
                    // penulisnya, jadi tombolnya pun hanya muncul untuk dia.
                    if (catatan.authorId == sesi.user?.id)
                      _TombolHapus(
                        onTap: () =>
                            _jalankan(context, () => jurnal.hapus(catatan.id)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    catatan.text,
                    style: text.bodyLarge?.copyWith(fontSize: 17, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.md),
        ],
      ],
    );
  }
}
