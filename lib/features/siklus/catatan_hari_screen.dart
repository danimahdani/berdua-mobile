import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import 'catatan_hari_cubit.dart';
import 'katalog_catatan.dart';
import 'siklus_cubit.dart';

/// Catatan harian siklus untuk satu tanggal.
///
/// Layar ini hanya ringkasan: tanda awal/akhir haid dan satu ubin untuk tiap
/// kategori. Mengisi sebuah kategori dilakukan di halamannya sendiri (pilihan
/// berikon), yang langsung menyimpan saat "Simpan" diketuk — jadi tidak ada
/// formulir panjang yang harus digulir.
///
/// Hanya untuk pencatat siklus. Isinya tidak pernah ikut dibagikan.
class CatatanHariScreen extends StatefulWidget {
  const CatatanHariScreen({super.key, required this.tanggal});

  final DateTime tanggal;

  @override
  State<CatatanHariScreen> createState() => _CatatanHariScreenState();
}

class _CatatanHariScreenState extends State<CatatanHariScreen> {
  late DateTime _tanggal = DateTime(
    widget.tanggal.year,
    widget.tanggal.month,
    widget.tanggal.day,
  );

  void _pindah(int hari) => setState(
    () =>
        _tanggal = DateTime(_tanggal.year, _tanggal.month, _tanggal.day + hari),
  );

  @override
  Widget build(BuildContext context) {
    // Cubit baru untuk tiap tanggal: pindah hari memuat ulang dari awal.
    return BlocProvider(
      key: ValueKey(_tanggal),
      create: (context) => CatatanHariCubit(
        context.read<Dio>(),
        context.read<SiklusCubit>(),
        _tanggal,
      ),
      child: Builder(
        builder: (context) {
          final muatan = context.watch<CatatanHariCubit>().state;

          return Scaffold(
            body: muatan.when(
              loading: () => const SkeletonRiwayat(),
              error: (error, _) => GalatLayar(
                pesan: error is ApiException
                    ? error.message
                    : 'Gagal memuat catatan hari ini.',
                onUlangi: () => context.read<CatatanHariCubit>().muat(),
              ),
              data: (data) => _Ringkasan(data: data, onPindah: _pindah),
            ),
          );
        },
      ),
    );
  }
}

/// "52,4" dari 52.4; kosong untuk null.
String _angka(double? nilai) => nilai == null
    ? ''
    : (nilai == nilai.roundToDouble()
              ? nilai.toStringAsFixed(0)
              : nilai.toString())
          .replaceAll('.', ',');

/// Ringkasan pilihan-banyak: namanya kalau sedikit, jumlahnya kalau banyak.
String? _ringkasBanyak(List<Butir> daftar, Set<String> nilai, String satuan) {
  if (nilai.isEmpty) return null;

  if (nilai.length <= 2) {
    return nilai.map((k) => Katalog.label(daftar, k)).join(', ');
  }

  return '${nilai.length} $satuan';
}

class _Ringkasan extends StatefulWidget {
  const _Ringkasan({required this.data, required this.onPindah});

  final CatatanHari data;
  final ValueChanged<int> onPindah;

  @override
  State<_Ringkasan> createState() => _RingkasanState();
}

class _RingkasanState extends State<_Ringkasan> {
  /// 'awal' / 'akhir' / 'pil' selama ketukan langsung sedang dikirim.
  String? _mengirim;

  Future<void> _kirim(String jenis, Future<void> Function() aksi) async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _mengirim = jenis);

    try {
      await aksi();
    } on ApiException catch (error) {
      tampilkanToastVia(messenger, error.message);
    } finally {
      if (mounted) setState(() => _mengirim = null);
    }
  }

  /// Membuka halaman satu kategori; cubit tanggal ini ikut dibawa.
  void _buka(Widget halaman) {
    final cubit = context.read<CatatanHariCubit>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(value: cubit, child: halaman),
      ),
    );
  }

  /// Halaman pilihan berikon dengan satu bagian atau lebih.
  void _bukaPilihan(String judul, List<_Bagian> bagian) =>
      _buka(_HalamanPilihan(judul: judul, bagian: bagian));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final data = widget.data;
    final isi = data.isi;
    final cubit = context.read<CatatanHariCubit>();
    final kini = DateTime.now();
    final judul =
        data.tanggal.year == kini.year &&
            data.tanggal.month == kini.month &&
            data.tanggal.day == kini.day
        ? 'Hari ini'
        : TanggalId.long(data.tanggal);

    final posisi = [
      if (data.hariKe != null) 'Hari siklus ${data.hariKe}',
      if (data.fase != null) 'fase ${data.fase}',
      if (data.peluangHamil != null)
        'peluang hamil ${data.peluangHamil!.label.toLowerCase()}',
    ].join(' · ');

    final intim = switch (isi.intim) {
      null => null,
      'tidak' => 'Tidak melakukan',
      final nilai =>
        '${Katalog.label(Katalog.pengaman, nilai)}'
            '${(isi.kaliIntim ?? 1) > 1 ? " · ${isi.kaliIntim}×" : ""}',
    };

    final tes = [
      if (isi.ujiOvulasi != null)
        'Ovulasi ${Katalog.label(Katalog.ujiOvulasi, isi.ujiOvulasi!).toLowerCase()}',
      if (isi.tesHamil != null)
        'Hamil ${Katalog.label(Katalog.tesHamil, isi.tesHamil!).toLowerCase()}',
    ].join(' · ');

    final tubuh = [
      if (isi.berat != null) '${_angka(isi.berat)} kg',
      if (isi.suhu != null) '${_angka(isi.suhu)} °C',
    ].join(' · ');

    final ubin = <_UbinKategori>[
      _UbinKategori(
        emoji: '🩸',
        judul: 'Aliran haid',
        isi: isi.aliran == null
            ? null
            : Katalog.label(Katalog.aliran, isi.aliran!),
        onTap: () => _bukaPilihan('Aliran haid', [
          _Bagian(
            butir: Katalog.aliran,
            terpilih: {?isi.aliran},
            terapkan: (lama, pilihan) =>
                lama.salin(aliran: () => pilihan.firstOrNull),
          ),
        ]),
      ),
      _UbinKategori(
        emoji: '🤒',
        judul: 'Gejala',
        isi: _ringkasBanyak(Katalog.semuaGejala, isi.gejala, 'gejala'),
        onTap: () => _bukaPilihan('Gejala', [
          for (final kelompok in Katalog.gejala)
            _Bagian(
              judul: kelompok.judul,
              butir: kelompok.butir,
              banyak: true,
              terpilih: isi.gejala,
              // Tiap kelompok hanya mengganti gejala miliknya sendiri.
              terapkan: (lama, pilihan) => lama.salin(
                gejala: {
                  ...lama.gejala.where(
                    (g) => kelompok.butir.every((b) => b.kunci != g),
                  ),
                  ...pilihan,
                },
              ),
            ),
        ]),
      ),
      _UbinKategori(
        emoji: '😊',
        judul: 'Suasana hati',
        isi: _ringkasBanyak(Katalog.suasana, isi.suasana, 'suasana'),
        onTap: () => _bukaPilihan('Suasana hati', [
          _Bagian(
            butir: Katalog.suasana,
            banyak: true,
            terpilih: isi.suasana,
            terapkan: (lama, pilihan) => lama.salin(suasana: pilihan),
          ),
        ]),
      ),
      _UbinKategori(
        emoji: '🔋',
        judul: 'Energi',
        isi: isi.energi == null
            ? null
            : Katalog.label(Katalog.energi, isi.energi!),
        onTap: () => _bukaPilihan('Energi', [
          _Bagian(
            butir: Katalog.energi,
            terpilih: {?isi.energi},
            terapkan: (lama, pilihan) =>
                lama.salin(energi: () => pilihan.firstOrNull),
          ),
        ]),
      ),
      _UbinKategori(
        emoji: '💞',
        judul: 'Intim',
        isi: intim,
        onTap: () => _buka(_HalamanIntim(isi: isi)),
      ),
      _UbinKategori(
        emoji: '💊',
        judul: 'Pil KB',
        isi: isi.pil ? 'Sudah diminum' : null,
        kosong: 'Belum diminum',
        memuat: _mengirim == 'pil',
        // Hanya ya/tidak, jadi langsung tersimpan tanpa halaman sendiri.
        onTap: _mengirim != null
            ? null
            : () => _kirim(
                'pil',
                () => cubit.simpan(cubit.state.nilai!.isi.salin(pil: !isi.pil)),
              ),
      ),
      _UbinKategori(
        emoji: '💧',
        judul: 'Lendir serviks',
        isi: isi.lendir == null
            ? null
            : Katalog.label(Katalog.lendir, isi.lendir!),
        onTap: () => _bukaPilihan('Lendir serviks', [
          _Bagian(
            butir: Katalog.lendir,
            terpilih: {?isi.lendir},
            terapkan: (lama, pilihan) =>
                lama.salin(lendir: () => pilihan.firstOrNull),
          ),
        ]),
      ),
      _UbinKategori(
        emoji: '🎗️',
        judul: 'SADARI',
        isi: _ringkasBanyak(Katalog.sadari, isi.sadari, 'temuan'),
        onTap: () => _bukaPilihan('Periksa payudara sendiri', [
          _Bagian(
            butir: Katalog.sadari,
            banyak: true,
            terpilih: isi.sadari,
            // "Semuanya baik" dan temuan lain tidak bisa bersamaan.
            sendirian: 'baik',
            catatan:
                'Benjolan atau perubahan yang menetap sebaiknya diperiksakan '
                'ke tenaga kesehatan.',
            terapkan: (lama, pilihan) => lama.salin(sadari: pilihan),
          ),
        ]),
      ),
      _UbinKategori(
        emoji: '🧪',
        judul: 'Tes',
        isi: tes.isEmpty ? null : tes,
        kosong: 'Ovulasi & hamil',
        onTap: () => _bukaPilihan('Tes', [
          _Bagian(
            judul: 'Uji ovulasi',
            butir: Katalog.ujiOvulasi,
            terpilih: {?isi.ujiOvulasi},
            terapkan: (lama, pilihan) =>
                lama.salin(ujiOvulasi: () => pilihan.firstOrNull),
          ),
          _Bagian(
            judul: 'Tes kehamilan',
            butir: Katalog.tesHamil,
            terpilih: {?isi.tesHamil},
            catatan:
                'Hasil alat tes di rumah bisa keliru. Pastikan ke tenaga '
                'kesehatan.',
            terapkan: (lama, pilihan) =>
                lama.salin(tesHamil: () => pilihan.firstOrNull),
          ),
        ]),
      ),
      _UbinKategori(
        emoji: '⚖️',
        judul: 'Berat & suhu',
        isi: tubuh.isEmpty ? null : tubuh,
        onTap: () => _buka(_HalamanTubuh(isi: isi)),
      ),
    ];

    return LayarBerdua(
      judul: judul,
      stiker: JenisStiker.note,
      kembali: true,
      children: [
        Row(
          children: [
            TombolIkon(
              ikon: Icons.chevron_left_rounded,
              keterangan: 'Hari sebelumnya',
              onTap: () => widget.onPindah(-1),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    TanggalId.full(data.tanggal),
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (posisi.isNotEmpty)
                    Text(
                      '$posisi${data.perkiraan ? " (perkiraan)" : ""}',
                      textAlign: TextAlign.center,
                      style: text.labelSmall?.copyWith(height: 1.4),
                    ),
                ],
              ),
            ),
            TombolIkon(
              ikon: Icons.chevron_right_rounded,
              keterangan: 'Hari berikutnya',
              onTap: () => widget.onPindah(1),
            ),
          ],
        ),
        const SizedBox(height: Gap.md),

        if (data.belumTiba)
          KartuBerdua(
            radius: Radii.cardBesar,
            child: Text(
              'Hari ini belum tiba. Catatan bisa diisi mulai pada tanggalnya.',
              style: text.bodyMedium?.copyWith(fontSize: 15, height: 1.45),
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _TombolTanda(
                  label: 'Awal haid',
                  ikon: Icons.play_arrow_rounded,
                  aktif: data.awalDiSini,
                  memuat: _mengirim == 'awal',
                  onTap: _mengirim != null
                      ? null
                      : () => _kirim(
                          'awal',
                          data.awalDiSini ? cubit.batalAwal : cubit.tandaiAwal,
                        ),
                ),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: _TombolTanda(
                  label: 'Akhir haid',
                  ikon: Icons.stop_rounded,
                  aktif: data.akhirDiSini,
                  memuat: _mengirim == 'akhir',
                  // Tanpa haid yang berjalan, "Akhir" tidak bisa ditandai.
                  onTap:
                      _mengirim != null ||
                          !(data.akhirDiSini || data.bisaAkhiri)
                      ? null
                      : () => _kirim(
                          'akhir',
                          data.akhirDiSini
                              ? cubit.batalAkhir
                              : cubit.tandaiAkhir,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          // Dua kolom ubin; tinggi tiap baris mengikuti ubin tertingginya.
          for (var i = 0; i < ubin.length; i += 2) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: ubin[i]),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: i + 1 < ubin.length
                        ? ubin[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.sm),
          ],
          _UbinKategori(
            emoji: '📝',
            judul: 'Catatan',
            isi: isi.catatan.trim().isEmpty ? null : isi.catatan.trim(),
            kosong: 'Tulis sesuatu',
            onTap: () => _buka(_HalamanCatatan(isi: isi)),
          ),
          const SizedBox(height: Gap.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Hanya kamu yang melihat catatan harian ini. Menyalakan '
              '"bagikan siklus" tidak ikut membagikannya.',
              style: text.labelSmall?.copyWith(fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ],
    );
  }
}

/// Ikon emoji di dalam lingkaran berwarna lembut.
class _LingkarEmoji extends StatelessWidget {
  const _LingkarEmoji(this.emoji, {this.ukuran = 44, this.aktif = false});

  final String emoji;
  final double ukuran;
  final bool aktif;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: aktif ? BerduaColors.roseChipActive : BerduaColors.card2,
        shape: BoxShape.circle,
        border: aktif
            ? Border.all(color: BerduaColors.ink, width: Sizes.garis)
            : null,
      ),
      child: Text(
        emoji,
        // Tinggi baris 1 supaya emoji duduk di tengah lingkaran.
        style: TextStyle(fontSize: ukuran * .5, height: 1.1),
      ),
    );
  }
}

/// Satu kategori di layar ringkasan: ikon, nama, dan isi yang sudah dicatat.
class _UbinKategori extends StatelessWidget {
  const _UbinKategori({
    required this.emoji,
    required this.judul,
    required this.isi,
    required this.onTap,
    this.kosong = 'Belum diisi',
    this.memuat = false,
  });

  final String emoji;
  final String judul;

  /// Ringkasan isi; null = belum dicatat.
  final String? isi;
  final String kosong;
  final bool memuat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final terisi = isi != null;

    return Semantics(
      button: true,
      label: '$judul, ${isi ?? kosong}',
      excludeSemantics: true,
      child: KartuBerdua(
        radius: Radii.button,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        warna: terisi ? BerduaColors.roseCard : BerduaColors.card,
        bayangan: false,
        onTap: onTap,
        child: Row(
          children: [
            if (memuat)
              const SizedBox.square(
                dimension: 44,
                child: Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: BerduaColors.ink,
                  ),
                ),
              )
            else
              _LingkarEmoji(emoji, aktif: terisi),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    judul,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isi ?? kosong,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      fontSize: 12.5,
                      height: 1.3,
                      color: terisi
                          ? BerduaColors.roseChipText
                          : BerduaColors.label,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol "Awal haid" / "Akhir haid": langsung terkirim saat diketuk.
class _TombolTanda extends StatelessWidget {
  const _TombolTanda({
    required this.label,
    required this.ikon,
    required this.aktif,
    required this.memuat,
    required this.onTap,
  });

  final String label;
  final IconData ikon;
  final bool aktif;
  final bool memuat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mati = onTap == null && !memuat;

    return Semantics(
      button: true,
      selected: aktif,
      enabled: !mati,
      label: '$label${aktif ? ", sudah ditandai" : ""}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: mati ? .45 : 1,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: aktif ? BerduaColors.rose : BerduaColors.roseSoft,
              borderRadius: BorderRadius.circular(Radii.pilihan),
              border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (memuat)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: BerduaColors.ink,
                    ),
                  )
                else
                  Icon(
                    aktif ? Icons.check_rounded : ikon,
                    size: 20,
                    color: BerduaColors.ink,
                  ),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu bagian di halaman pilihan: daftar butir berikon, pilih-satu atau
/// pilih-banyak, dan cara menuliskannya kembali ke catatan.
class _Bagian {
  const _Bagian({
    required this.butir,
    required this.terpilih,
    required this.terapkan,
    this.judul,
    this.banyak = false,
    this.sendirian,
    this.catatan,
  });

  final String? judul;
  final List<Butir> butir;
  final bool banyak;

  /// Pilihan awal; boleh memuat kunci dari bagian lain (diabaikan).
  final Set<String> terpilih;

  /// Kunci yang tidak bisa dipilih bersama yang lain, mis. "semuanya baik".
  final String? sendirian;
  final String? catatan;

  final IsiCatatan Function(IsiCatatan lama, Set<String> pilihan) terapkan;
}

/// Kerangka halaman kategori: isi yang bisa digulir dan tombol Simpan yang
/// selalu terlihat di bawah.
class _HalamanKategori extends StatelessWidget {
  const _HalamanKategori({
    required this.judul,
    required this.children,
    required this.memuat,
    required this.onSimpan,
  });

  final String judul;
  final List<Widget> children;
  final bool memuat;
  final VoidCallback? onSimpan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BerduaColors.background,
      body: LayarBerdua(judul: judul, kembali: true, children: children),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Gap.screenEdge,
            Gap.sm,
            Gap.screenEdge,
            Gap.md,
          ),
          child: TombolUtama(
            label: 'Simpan',
            ukuranHuruf: 18,
            memuat: memuat,
            onPressed: onSimpan,
          ),
        ),
      ),
    );
  }
}

/// Menyimpan ubahan satu kategori lalu kembali ke ringkasan.
mixin _Penyimpan<T extends StatefulWidget> on State<T> {
  bool menyimpan = false;

  Future<void> simpan(IsiCatatan Function(IsiCatatan lama) ubah) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final cubit = context.read<CatatanHariCubit>();
    final lama = cubit.state.nilai?.isi;

    if (lama == null) return;

    setState(() => menyimpan = true);

    try {
      await cubit.simpan(ubah(lama));
      navigator.pop();
    } on ApiException catch (error) {
      tampilkanToastVia(messenger, error.message);
    } finally {
      if (mounted) setState(() => menyimpan = false);
    }
  }
}

/// Halaman pilihan berikon: satu bagian atau lebih, empat ikon per baris.
class _HalamanPilihan extends StatefulWidget {
  const _HalamanPilihan({required this.judul, required this.bagian});

  final String judul;
  final List<_Bagian> bagian;

  @override
  State<_HalamanPilihan> createState() => _HalamanPilihanState();
}

class _HalamanPilihanState extends State<_HalamanPilihan>
    with _Penyimpan<_HalamanPilihan> {
  late final List<Set<String>> _pilihan = [
    for (final bagian in widget.bagian)
      bagian.terpilih
          .where((kunci) => bagian.butir.any((b) => b.kunci == kunci))
          .toSet(),
  ];

  void _ketuk(int i, String kunci) => setState(() {
    final bagian = widget.bagian[i];
    final pilihan = _pilihan[i];

    if (pilihan.remove(kunci)) return;

    if (!bagian.banyak || kunci == bagian.sendirian) pilihan.clear();

    pilihan
      ..remove(bagian.sendirian)
      ..add(kunci);
  });

  @override
  Widget build(BuildContext context) {
    return _HalamanKategori(
      judul: widget.judul,
      memuat: menyimpan,
      onSimpan: () => simpan((lama) {
        var isi = lama;

        for (final (i, bagian) in widget.bagian.indexed) {
          isi = bagian.terapkan(isi, _pilihan[i]);
        }

        return isi;
      }),
      children: [
        for (final (i, bagian) in widget.bagian.indexed) ...[
          _KartuPilihan(
            judul: bagian.judul,
            butir: bagian.butir,
            terpilih: _pilihan[i],
            catatan: bagian.catatan,
            onKetuk: (kunci) => _ketuk(i, kunci),
          ),
          const SizedBox(height: Gap.betweenCards),
        ],
      ],
    );
  }
}

/// Kartu berisi kisi pilihan berikon.
class _KartuPilihan extends StatelessWidget {
  const _KartuPilihan({
    required this.butir,
    required this.terpilih,
    required this.onKetuk,
    this.judul,
    this.catatan,
  });

  final String? judul;
  final List<Butir> butir;
  final Set<String> terpilih;
  final ValueChanged<String> onKetuk;
  final String? catatan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuBerdua(
      radius: Radii.cardBesar,
      padding: const EdgeInsets.fromLTRB(10, Gap.lg, 10, Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (judul != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                judul!,
                style: text.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: Gap.md),
          ],
          LayoutBuilder(
            builder: (context, batas) {
              // Empat per baris; tiga di layar yang sangat sempit.
              final kolom = batas.maxWidth < 300 ? 3 : 4;
              final lebar = batas.maxWidth / kolom;

              return Wrap(
                runSpacing: Gap.md,
                children: [
                  for (final b in butir)
                    SizedBox(
                      width: lebar,
                      child: _PilihanIkon(
                        butir: b,
                        aktif: terpilih.contains(b.kunci),
                        onTap: () => onKetuk(b.kunci),
                      ),
                    ),
                ],
              );
            },
          ),
          if (catatan != null) ...[
            const SizedBox(height: Gap.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                catatan!,
                style: text.labelSmall?.copyWith(fontSize: 13, height: 1.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Satu pilihan: ikon bundar dengan label di bawahnya.
class _PilihanIkon extends StatelessWidget {
  const _PilihanIkon({
    required this.butir,
    required this.aktif,
    required this.onTap,
  });

  final Butir butir;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: aktif,
      label: butir.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 140),
                  scale: aktif ? 1.06 : 1,
                  child: _LingkarEmoji(butir.emoji, ukuran: 56, aktif: aktif),
                ),
                if (aktif)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: BerduaColors.rose,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: BerduaColors.ink,
                          width: Sizes.garis,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: BerduaColors.ink,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                butir.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 12.5,
                  height: 1.25,
                  fontWeight: aktif ? FontWeight.w600 : FontWeight.w500,
                  color: aktif ? BerduaColors.ink : BerduaColors.label,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hubungan intim: terlindung atau tidak, ada puncak atau tidak, berapa kali.
class _HalamanIntim extends StatefulWidget {
  const _HalamanIntim({required this.isi});

  final IsiCatatan isi;

  @override
  State<_HalamanIntim> createState() => _HalamanIntimState();
}

class _HalamanIntimState extends State<_HalamanIntim>
    with _Penyimpan<_HalamanIntim> {
  late String? _intim = widget.isi.intim;
  late bool? _puncak = widget.isi.puncak;
  late int _kali = widget.isi.kaliIntim ?? 1;

  bool get _melakukan => _intim != null && _intim != 'tidak';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return _HalamanKategori(
      judul: 'Hubungan intim',
      memuat: menyimpan,
      onSimpan: () => simpan(
        (lama) => lama.salin(
          intim: () => _intim,
          kaliIntim: () => _melakukan ? _kali : null,
          puncak: () => _melakukan ? _puncak : null,
        ),
      ),
      children: [
        _KartuPilihan(
          judul: 'Pengaman',
          butir: Katalog.pengaman,
          terpilih: {?_intim},
          onKetuk: (kunci) =>
              setState(() => _intim = _intim == kunci ? null : kunci),
        ),
        if (_melakukan) ...[
          const SizedBox(height: Gap.betweenCards),
          _KartuPilihan(
            judul: 'Puncak',
            butir: Katalog.puncak,
            terpilih: {if (_puncak != null) _puncak! ? 'ya' : 'tidak'},
            onKetuk: (kunci) => setState(() {
              final nilai = kunci == 'ya';

              _puncak = _puncak == nilai ? null : nilai;
            }),
          ),
          const SizedBox(height: Gap.betweenCards),
          KartuBerdua(
            radius: Radii.cardBesar,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Berapa kali',
                    style: text.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TombolIkon(
                  ikon: Icons.remove_rounded,
                  keterangan: 'Kurangi',
                  latar: BerduaColors.roseSoft,
                  onTap: () =>
                      setState(() => _kali = _kali > 1 ? _kali - 1 : 1),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    '$_kali',
                    textAlign: TextAlign.center,
                    style: text.headlineLarge?.copyWith(fontSize: 26),
                  ),
                ),
                TombolIkon(
                  ikon: Icons.add_rounded,
                  keterangan: 'Tambah',
                  latar: BerduaColors.roseSoft,
                  onTap: () =>
                      setState(() => _kali = _kali < 9 ? _kali + 1 : 9),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Berat badan dan suhu tubuh.
class _HalamanTubuh extends StatefulWidget {
  const _HalamanTubuh({required this.isi});

  final IsiCatatan isi;

  @override
  State<_HalamanTubuh> createState() => _HalamanTubuhState();
}

class _HalamanTubuhState extends State<_HalamanTubuh>
    with _Penyimpan<_HalamanTubuh> {
  late final _berat = TextEditingController(text: _angka(widget.isi.berat));
  late final _suhu = TextEditingController(text: _angka(widget.isi.suhu));

  static double? _baca(String teks) =>
      double.tryParse(teks.trim().replaceAll(',', '.'));

  /// Pesan galat, atau null kalau kosong atau di dalam rentang.
  static String? _galat(String teks, double min, double max, String satuan) {
    if (teks.trim().isEmpty) return null;

    final nilai = _baca(teks);

    return nilai == null || nilai < min || nilai > max
        ? 'Isi antara ${min.toInt()} dan ${max.toInt()} $satuan.'
        : null;
  }

  @override
  void dispose() {
    _berat.dispose();
    _suhu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final galatBerat = _galat(_berat.text, 20, 300, 'kg');
    final galatSuhu = _galat(_suhu.text, 34, 43, '°C');

    return _HalamanKategori(
      judul: 'Berat & suhu',
      memuat: menyimpan,
      onSimpan: galatBerat != null || galatSuhu != null
          ? null
          : () => simpan(
              (lama) => lama.salin(
                berat: () => _baca(_berat.text),
                suhu: () => _baca(_suhu.text),
              ),
            ),
      children: [
        _KartuAngka(
          emoji: '⚖️',
          judul: 'Berat badan',
          kendali: _berat,
          satuan: 'kg',
          petunjuk: 'mis. 52,4',
          galat: galatBerat,
          onUbah: () => setState(() {}),
        ),
        const SizedBox(height: Gap.betweenCards),
        _KartuAngka(
          emoji: '🌡️',
          judul: 'Suhu tubuh',
          kendali: _suhu,
          satuan: '°C',
          petunjuk: 'mis. 36,6',
          galat: galatSuhu,
          onUbah: () => setState(() {}),
        ),
      ],
    );
  }
}

/// Kartu isian angka desimal dengan satuan di belakangnya.
class _KartuAngka extends StatelessWidget {
  const _KartuAngka({
    required this.emoji,
    required this.judul,
    required this.kendali,
    required this.satuan,
    required this.petunjuk,
    required this.galat,
    required this.onUbah,
  });

  final String emoji;
  final String judul;
  final TextEditingController kendali;
  final String satuan;
  final String petunjuk;
  final String? galat;
  final VoidCallback onUbah;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuBerdua(
      radius: Radii.cardBesar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LingkarEmoji(emoji, ukuran: 40),
              const SizedBox(width: 10),
              Text(
                judul,
                style: text.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          TextField(
            controller: kendali,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: text.bodyLarge?.copyWith(fontSize: 17),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) => onUbah(),
            decoration: InputDecoration(hintText: petunjuk, suffixText: satuan),
          ),
          if (galat != null) ...[const SizedBox(height: 6), TeksGalat(galat!)],
        ],
      ),
    );
  }
}

/// Catatan bebas.
class _HalamanCatatan extends StatefulWidget {
  const _HalamanCatatan({required this.isi});

  final IsiCatatan isi;

  @override
  State<_HalamanCatatan> createState() => _HalamanCatatanState();
}

class _HalamanCatatanState extends State<_HalamanCatatan>
    with _Penyimpan<_HalamanCatatan> {
  late final _catatan = TextEditingController(text: widget.isi.catatan);

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _HalamanKategori(
      judul: 'Catatan',
      memuat: menyimpan,
      onSimpan: () => simpan((lama) => lama.salin(catatan: _catatan.text)),
      children: [
        TextField(
          controller: _catatan,
          autofocus: true,
          minLines: 5,
          maxLines: 10,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
          decoration: const InputDecoration(hintText: 'Tulis sesuatu'),
        ),
      ],
    );
  }
}
