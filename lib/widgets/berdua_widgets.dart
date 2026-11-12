import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'potret.dart';
import 'stiker.dart';

export 'stiker.dart';

/// Komponen Berdua v4 — "versi fun".

/// Tab bawah yang sedang aktif. `LayarBerdua` mendengarkannya supaya kartu
/// memantul lagi setiap kali pengguna pindah tab, seperti di prototipe.
final tabAktifBerdua = ValueNotifier<int>(0);

/// Latar krem berkonfeti dengan bilah status kuning di atasnya.
class LatarBerdua extends StatelessWidget {
  const LatarBerdua({super.key, required this.child, this.bawah = false});

  final Widget child;

  /// true = sisakan ruang untuk bilah gestur sistem (layar tanpa navigasi).
  final bool bawah;

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: BerduaColors.background,
      child: Column(
        children: [
          Container(height: atas, color: BerduaColors.kuning),
          Expanded(
            child: CustomPaint(
              painter: const _KonfetiPainter(),
              child: SafeArea(top: false, bottom: bawah, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empat titik berwarna yang berulang tiap 96 dp.
class _KonfetiPainter extends CustomPainter {
  const _KonfetiPainter();

  static const _titik = <(double, double, double)>[
    (14, 16, 3),
    (50, 44, 2.5),
    (30, 64, 2.5),
    (62, 10, 2.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _titik.length; i++) {
      final (x, y, r) = _titik[i];
      final cat = Paint()..color = BerduaColors.konfeti[i];

      for (var dx = 0.0; dx < size.width; dx += 96) {
        for (var dy = 0.0; dy < size.height; dy += 96) {
          canvas.drawCircle(Offset(dx + x, dy + y), r, cat);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_KonfetiPainter oldDelegate) => false;
}

/// Kartu muncul memantul saat layar dibuka: naik 18 dp, membesar dari 94%,
/// 460 ms dengan easing yang sedikit melewati batas.
class MunculMemantul extends StatefulWidget {
  const MunculMemantul({
    super.key,
    required this.urutan,
    required this.child,
    this.mulai,
  });

  /// Posisi kartu di layar; tiap kartu menyusul 55 ms, paling lama 10 langkah.
  final int urutan;
  final Widget child;

  /// Saat layar dibuka. Kartu yang baru dibangun setelah gilirannya lewat
  /// (karena digulir) langsung tampil tanpa animasi.
  final DateTime? mulai;

  @override
  State<MunculMemantul> createState() => _MunculMemantulState();
}

class _MunculMemantulState extends State<MunculMemantul>
    with SingleTickerProviderStateMixin {
  static const _durasi = 460;
  static const _kurva = Cubic(.34, 1.56, .64, 1);

  late final AnimationController _kendali;

  @override
  void initState() {
    super.initState();

    _kendali = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _durasi),
    );

    final tunda = math.min(widget.urutan, 10) * 55;
    final lewat = widget.mulai == null
        ? 0
        : DateTime.now().difference(widget.mulai!).inMilliseconds;
    final sisa = tunda - lewat;

    if (sisa + _durasi <= 0) {
      _kendali.value = 1;
    } else if (sisa <= 0) {
      _kendali.forward(from: -sisa / _durasi);
    } else {
      Future.delayed(Duration(milliseconds: sisa), () {
        if (mounted) _kendali.forward();
      });
    }
  }

  @override
  void dispose() {
    _kendali.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // prefers-reduced-motion: kartu langsung di tempatnya.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _kendali,
      child: widget.child,
      builder: (context, child) {
        if (_kendali.isCompleted) return child!;

        final t = _kendali.value;
        final p = _kurva.transform(t);

        return Opacity(
          opacity: t.clamp(0, 1).toDouble(),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(0, 18 * (1 - p), 0)
              ..multiply(
                Matrix4.diagonal3Values(.94 + .06 * p, .94 + .06 * p, 1),
              ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Membungkus deretan kartu dengan [MunculMemantul]. Pemisah (`SizedBox`)
/// dilewati supaya jeda 55 ms dihitung per kartu, bukan per jarak.
List<Widget> memantulkan(List<Widget> anak, {DateTime? mulai, Object? kunci}) {
  var urutan = 0;

  return [
    for (final widget in anak)
      if (widget is SizedBox || widget is Spacer || widget is Flexible)
        widget
      else
        MunculMemantul(
          key: kunci == null ? null : ValueKey('$kunci-$urutan'),
          urutan: urutan++,
          mulai: mulai,
          child: widget,
        ),
  ];
}

/// Efek "terasa ditekan": anak turun [turun] dp selama jari menempel.
class _Tekan extends StatefulWidget {
  const _Tekan({required this.onTap, required this.builder});

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool ditekan) builder;

  @override
  State<_Tekan> createState() => _TekanState();
}

class _TekanState extends State<_Tekan> {
  bool _ditekan = false;

  void _setel(bool nilai) {
    if (widget.onTap == null || _ditekan == nilai) return;

    setState(() => _ditekan = nilai);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setel(true),
        onTapUp: (_) => _setel(false),
        onTapCancel: () => _setel(false),
        onTap: widget.onTap,
        child: widget.builder(context, _ditekan),
      ),
    );
  }
}

/// Kartu putih bergaris tinta dengan bayangan keras ala stiker — wadah dasar
/// seluruh konten. Stiker opsional menggantung di sudut kanan atas.
class KartuBerdua extends StatelessWidget {
  const KartuBerdua({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.lg),
    this.warna = BerduaColors.card,
    this.radius = Radii.card,
    this.onTap,
    this.stiker,
    this.garis = true,
    this.bayangan = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color warna;
  final double radius;
  final VoidCallback? onTap;
  final JenisStiker? stiker;

  /// false = kartu berwarna tanpa garis (kartu pink, ubin ringkasan).
  final bool garis;

  /// false = bergaris tetapi tanpa bayangan (ubin di dalam kartu lain).
  final bool bayangan;

  @override
  Widget build(BuildContext context) {
    Widget kotak(bool ditekan) => AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: double.infinity,
      padding: padding,
      transform: Matrix4.translationValues(0, ditekan ? 2 : 0, 0),
      decoration: BoxDecoration(
        color: ditekan && warna == BerduaColors.card
            ? BerduaColors.luteal
            : warna,
        borderRadius: BorderRadius.circular(radius),
        border: garis
            ? Border.all(color: BerduaColors.ink, width: Sizes.garis)
            : null,
        boxShadow: garis && bayangan
            ? (ditekan ? Shadows.tombolDitekan : Shadows.kartu)
            : null,
      ),
      child: child,
    );

    final badan = onTap == null
        ? kotak(false)
        : _Tekan(onTap: onTap, builder: (_, ditekan) => kotak(ditekan));

    if (stiker == null) return badan;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        badan,
        Positioned(
          right: 14,
          top: -16,
          child: IgnorePointer(child: Stiker(stiker!)),
        ),
      ],
    );
  }
}

/// Satu kartu pink per layar untuk angka atau pesan utama, kadang sedikit
/// miring.
class KartuRose extends StatelessWidget {
  const KartuRose({
    super.key,
    required this.child,
    this.miring = false,
    this.padding = const EdgeInsets.all(22),
    this.stiker,
    this.warna = BerduaColors.roseCard,
  });

  final Widget child;
  final bool miring;
  final EdgeInsetsGeometry padding;
  final JenisStiker? stiker;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final kartu = KartuBerdua(
      warna: warna,
      radius: Radii.cardWhite,
      padding: padding,
      garis: false,
      stiker: stiker,
      child: child,
    );

    // Kemiringan kecil saja — cukup terasa tanpa mengganggu keterbacaan.
    return miring ? Transform.rotate(angle: -0.03, child: kartu) : kartu;
  }
}

/// Angka utama dalam bingkai pink: "Rp 51.000", "BRD-4821".
class AngkaBerbingkai extends StatelessWidget {
  const AngkaBerbingkai(this.teks, {super.key, this.ukuran = 34});

  final String teks;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: BerduaColors.rose, width: Sizes.garis),
        borderRadius: BorderRadius.circular(16),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          teks,
          maxLines: 1,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontSize: ukuran, height: 1.3),
        ),
      ),
    );
  }
}

/// Avatar inisial bundar berwarna peran (biru langit vs lavender).
class AvatarInisial extends StatelessWidget {
  const AvatarInisial({
    super.key,
    required this.initial,
    required this.fill,
    this.textColor = BerduaColors.ink,
    this.ukuran = 38,
  });

  final String initial;
  final Color fill;
  final Color textColor;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: BerduaColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Ubin ikon bersudut membulat: kategori, sorotan, notifikasi.
class UbinIkon extends StatelessWidget {
  const UbinIkon({
    super.key,
    required this.ikon,
    required this.latar,
    required this.warna,
    this.ukuran = 38,
    this.radius = 12,
  });

  final IconData ikon;
  final Color latar;
  final Color warna;
  final double ukuran;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(ikon, size: ukuran * .48, color: warna),
    );
  }
}

/// Tiga rupa segmen di prototipe.
enum GayaSegmen {
  /// Wadah putih bergaris dan berbayangan; pilihan aktif pink muda.
  kartu,

  /// Di dalam sheet: wadah krem tanpa garis; pilihan aktif pink penuh.
  sheet,

  /// Wadah putih bergaris tanpa bayangan (pemilih bulan di laporan).
  polos,
}

/// Segmen: "Semua | Dinda | Raka | Dompet".
class SegmenBerdua<T> extends StatelessWidget {
  const SegmenBerdua({
    super.key,
    required this.pilihan,
    required this.terpilih,
    required this.onPilih,
    required this.label,
    this.gaya = GayaSegmen.kartu,
    this.gulir = false,
    this.lebar,
    this.tinggi,
    this.ukuranHuruf = 15,
  });

  /// Tinggi tiap pilihan; kosong = mengikuti gaya.
  final double? tinggi;
  final double ukuranHuruf;

  final List<T> pilihan;
  final T terpilih;
  final ValueChanged<T> onPilih;
  final String Function(T) label;
  final GayaSegmen gaya;

  /// true = pilihan selebar isinya dan bisa digulir menyamping (tab Bersama).
  final bool gulir;

  /// Perbandingan lebar tiap pilihan; kosong = sama rata.
  final List<int>? lebar;

  @override
  Widget build(BuildContext context) {
    final sheet = gaya == GayaSegmen.sheet;
    final tinggi =
        this.tinggi ??
        (sheet ? 40.0 : (gaya == GayaSegmen.polos ? 36.0 : 38.0));

    Widget tombol(T item) {
      final aktif = item == terpilih;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onPilih(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: tinggi,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: gulir ? 14 : 4),
          decoration: BoxDecoration(
            color: aktif
                ? (sheet ? BerduaColors.rose : BerduaColors.roseChipActive)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.pilihan),
          ),
          child: Text(
            label(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: ukuranHuruf,
              fontWeight: FontWeight.w500,
              color: aktif
                  ? (sheet ? BerduaColors.ink : BerduaColors.roseChipText)
                  : BerduaColors.pilihanMati,
            ),
          ),
        ),
      );
    }

    final anak = <Widget>[];

    for (var i = 0; i < pilihan.length; i++) {
      if (i > 0) anak.add(const SizedBox(width: 6));

      anak.add(
        gulir
            ? tombol(pilihan[i])
            : Expanded(flex: lebar?[i] ?? 1, child: tombol(pilihan[i])),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: sheet ? BerduaColors.card2 : BerduaColors.card,
        borderRadius: BorderRadius.circular(
          gaya == GayaSegmen.polos ? 16 : Radii.input,
        ),
        border: sheet
            ? null
            : Border.all(color: BerduaColors.ink, width: Sizes.garis),
        boxShadow: gaya == GayaSegmen.kartu ? Shadows.kartu : null,
      ),
      child: gulir
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: anak),
            )
          : Row(children: anak),
    );
  }
}

/// Chip: gejala, kategori, jenis jadwal.
class ChipBerdua extends StatelessWidget {
  const ChipBerdua({
    super.key,
    required this.label,
    required this.aktif,
    required this.onTap,
    this.tinggi = 38,
  });

  final String label;
  final bool aktif;
  final VoidCallback onTap;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        // Tanpa `alignment`: Container dengan alignment akan memuai memenuhi
        // lebar yang tersedia, sehingga di dalam Wrap setiap chip memakan satu
        // baris penuh. Perataan tengah diserahkan ke Text.
        constraints: BoxConstraints(minHeight: tinggi),
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: (tinggi - 22) / 2,
        ),
        decoration: BoxDecoration(
          color: aktif ? BerduaColors.roseChipActive : BerduaColors.card2,
          borderRadius: BorderRadius.circular(Radii.pilihan),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: tinggi < 36 ? 14 : 15,
            height: 22 / (tinggi < 36 ? 14 : 15),
            fontWeight: FontWeight.w500,
            color: aktif ? BerduaColors.roseChipText : BerduaColors.pilihanMati,
          ),
        ),
      ),
    );
  }
}

/// Label kecil berwarna: "Fase luteal", "Berdua", "Tagihan".
class LabelKecil extends StatelessWidget {
  const LabelKecil(
    this.teks, {
    super.key,
    this.latar = BerduaColors.rakaSoft,
    this.warna = BerduaColors.rakaText,
    this.ukuran = 13,
    this.tebal = FontWeight.w400,
  });

  final String teks;
  final Color latar;
  final Color warna;
  final double ukuran;
  final FontWeight tebal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        teks,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: ukuran,
          fontWeight: tebal,
          color: warna,
        ),
      ),
    );
  }
}

/// Batang progres 10 dp: pink di atas lintasan krem.
class BatangProgres extends StatelessWidget {
  const BatangProgres(this.nilai, {super.key, this.tinggi = Sizes.progressBar});

  /// 0..1.
  final double nilai;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(tinggi / 2),
      child: Container(
        height: tinggi,
        color: BerduaColors.line,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: nilai.clamp(0, 1).toDouble(),
          child: Container(
            decoration: BoxDecoration(
              color: BerduaColors.rose,
              borderRadius: BorderRadius.circular(tinggi / 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sakelar 46x26 dengan tombol putih 20 dp.
class SakelarBerdua extends StatelessWidget {
  const SakelarBerdua({super.key, required this.nyala});

  final bool nyala;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 46,
      height: 26,
      padding: const EdgeInsets.all(3),
      alignment: nyala ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: nyala ? BerduaColors.rose : BerduaColors.netral,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Tombol utama: pink bergaris tinta dengan bayangan keras. Saat ditekan ia
/// turun 3 dp dan bayangannya memendek — terasa seperti tombol sungguhan.
class TombolUtama extends StatelessWidget {
  const TombolUtama({
    super.key,
    required this.label,
    required this.onPressed,
    this.memuat = false,
    this.tinggi = Sizes.primaryButton,
    this.ukuranHuruf = 20,
    this.ikon,
    this.kapital = true,
    this.putih = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool memuat;
  final double tinggi;
  final double ukuranHuruf;
  final IconData? ikon;
  final bool kapital;

  /// true = varian putih untuk aksi kedua di samping tombol pink
  /// ("RIWAYAT KUIS", "MAIN LAGI").
  final bool putih;

  @override
  Widget build(BuildContext context) {
    final aktif = onPressed != null && !memuat;
    final gaya = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontSize: ukuranHuruf,
      fontWeight: kapital ? FontWeight.w700 : FontWeight.w600,
      letterSpacing: kapital ? ukuranHuruf * .04 : 0,
      color: aktif || memuat ? BerduaColors.ink : BerduaColors.textSecondary,
    );
    final radius = tinggi >= 56 ? Radii.button : 16.0;

    return _Tekan(
      onTap: aktif ? onPressed : null,
      builder: (context, ditekan) => SizedBox(
        // Ruang 5 dp di bawah untuk bayangan, supaya tombol tidak bergeser.
        height: tinggi + 5,
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            height: tinggi,
            width: double.infinity,
            alignment: Alignment.center,
            transform: Matrix4.translationValues(0, ditekan ? 3 : 0, 0),
            decoration: BoxDecoration(
              color: aktif || memuat
                  ? (putih
                        ? (ditekan ? BerduaColors.card2 : BerduaColors.card)
                        : (ditekan
                              ? BerduaColors.roseHover
                              : BerduaColors.rose))
                  : BerduaColors.netral,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
              boxShadow: ditekan ? Shadows.tombolDitekan : Shadows.tombol,
            ),
            child: memuat
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: BerduaColors.ink,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ikon != null) ...[
                        Icon(ikon, size: 17, color: gaya?.color),
                        const SizedBox(width: Gap.sm),
                      ],
                      Flexible(
                        child: Text(
                          kapital ? label.toUpperCase() : label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: gaya,
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

/// Tombol pink datar tanpa garis: "TANDAI LUNAS", "SETOR", "Ubah".
class TombolPink extends StatelessWidget {
  const TombolPink({
    super.key,
    required this.label,
    required this.onPressed,
    this.tinggi = 52,
    this.radius = Radii.input,
    this.ukuranHuruf = 17,
    this.tebal = FontWeight.w700,
    this.stiker,
    this.memuat = false,
    this.lebarPenuh = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final double tinggi;
  final double radius;
  final double ukuranHuruf;
  final FontWeight tebal;
  final JenisStiker? stiker;
  final bool memuat;
  final bool lebarPenuh;

  @override
  Widget build(BuildContext context) {
    final aktif = onPressed != null && !memuat;

    return _Tekan(
      onTap: aktif ? onPressed : null,
      builder: (context, ditekan) => AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        height: tinggi,
        width: lebarPenuh ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
        alignment: lebarPenuh ? Alignment.center : null,
        decoration: BoxDecoration(
          color: onPressed == null
              ? BerduaColors.netral
              : (ditekan ? BerduaColors.roseHover : BerduaColors.rose),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: memuat
            ? const Center(
                widthFactor: 1,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: BerduaColors.ink,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (stiker != null) ...[
                    Stiker.kecil(stiker!),
                    const SizedBox(width: Gap.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: ukuranHuruf,
                        fontWeight: tebal,
                        letterSpacing: tebal == FontWeight.w700
                            ? ukuranHuruf * .035
                            : 0,
                        color: onPressed == null
                            ? BerduaColors.textSecondary
                            : BerduaColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Tombol sekunder putih bergaris dengan bayangan 3 dp: "Bagikan kode",
/// "Hapus".
class TombolSekunder extends StatelessWidget {
  const TombolSekunder({
    super.key,
    required this.label,
    required this.onPressed,
    this.warna = BerduaColors.ink,
    this.ikon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color warna;
  final IconData? ikon;

  @override
  Widget build(BuildContext context) {
    return _Tekan(
      onTap: onPressed,
      builder: (context, ditekan) => SizedBox(
        height: 55,
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            height: 52,
            width: double.infinity,
            alignment: Alignment.center,
            transform: Matrix4.translationValues(0, ditekan ? 2 : 0, 0),
            decoration: BoxDecoration(
              color: ditekan ? BerduaColors.netral : BerduaColors.card,
              borderRadius: BorderRadius.circular(Radii.input),
              border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
              boxShadow: ditekan
                  ? const [
                      BoxShadow(color: BerduaColors.ink, offset: Offset(0, 1)),
                    ]
                  : Shadows.sekunder,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ikon != null) ...[
                  Icon(ikon, size: Sizes.iconSmall, color: warna),
                  const SizedBox(width: Gap.sm),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: warna,
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

/// Tombol ikon 40x40 bergaris tinta: kembali, buka laporan, tutup sheet.
class TombolIkon extends StatelessWidget {
  const TombolIkon({
    super.key,
    required this.ikon,
    required this.onTap,
    this.ukuran = Sizes.backButton,
    this.latar = Colors.transparent,
    this.warna = BerduaColors.ink,
    this.keterangan,
  });

  final IconData ikon;
  final VoidCallback? onTap;
  final double ukuran;
  final Color latar;
  final Color warna;
  final String? keterangan;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: keterangan,
      child: _Tekan(
        onTap: onTap,
        builder: (context, ditekan) => Container(
          width: ukuran,
          height: ukuran,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ditekan ? BerduaColors.card : latar,
            border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
            borderRadius: BorderRadius.circular(ukuran >= 40 ? 12 : 11),
          ),
          child: Icon(ikon, size: ukuran / 2, color: warna),
        ),
      ),
    );
  }
}

/// Tombol kembali 40x40 bergaris.
class TombolKembali extends StatelessWidget {
  const TombolKembali({super.key, this.onTap, this.latar = Colors.transparent});

  final VoidCallback? onTap;
  final Color latar;

  @override
  Widget build(BuildContext context) {
    return TombolIkon(
      ikon: Icons.arrow_back,
      latar: latar,
      keterangan: 'Kembali',
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
    );
  }
}

/// Kartu daftar: avatar, judul, keterangan, nominal.
class KartuDaftar extends StatelessWidget {
  const KartuDaftar({
    super.key,
    required this.leading,
    required this.judul,
    required this.keterangan,
    this.trailing,
    this.trailingBawah,
    this.onTap,
  });

  final Widget leading;
  final String judul;
  final String keterangan;
  final String? trailing;
  final String? trailingBawah;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuBerdua(
      onTap: onTap,
      radius: Radii.button,
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
      child: Row(
        children: [
          leading,
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  keterangan,
                  style: text.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Gap.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trailing!,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (trailingBawah != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    trailingBawah!,
                    style: text.labelSmall?.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Kepala bottom sheet: tombol tutup 36x36 di kiri, judul di tengah.
class KepalaSheet extends StatelessWidget {
  const KepalaSheet({super.key, required this.judul, this.kecil = false});

  final String judul;

  /// true = judul berupa keterangan kecil ("Tagihan · 8 Nov").
  final bool kecil;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        TombolIkon(
          ikon: Icons.close,
          ukuran: 36,
          warna: BerduaColors.label,
          keterangan: 'Tutup',
          onTap: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Text(
            judul,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: kecil
                ? text.bodySmall
                : text.titleLarge?.copyWith(fontSize: 21),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}

/// Bingkai foto pasangan: persegi membulat tak beraturan yang sedikit miring,
/// berisi ilustrasi potret.
class BingkaiPasangan extends StatelessWidget {
  const BingkaiPasangan({
    super.key,
    required this.warna,
    required this.lebar,
    required this.tinggi,
    required this.derajat,
    this.nama,
    this.potret,
    this.kiri = true,
    this.bayangan,
  });

  /// Warna bayangan lembut di bawah bingkai (0 10 22).
  final Color? bayangan;

  final Color warna;
  final double lebar;
  final double tinggi;
  final double derajat;
  final String? nama;
  final JenisPotret? potret;

  /// Bentuk sudutnya bercermin antara bingkai kiri dan kanan.
  final bool kiri;

  @override
  Widget build(BuildContext context) {
    final s = lebar / 150;
    final radius = kiri
        ? BorderRadius.only(
            topLeft: Radius.circular(36 * s),
            topRight: Radius.circular(52 * s),
            bottomRight: Radius.circular(30 * s),
            bottomLeft: Radius.circular(44 * s),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(52 * s),
            topRight: Radius.circular(36 * s),
            bottomRight: Radius.circular(44 * s),
            bottomLeft: Radius.circular(30 * s),
          );

    return Transform.rotate(
      angle: derajat * math.pi / 180,
      child: Container(
        width: lebar,
        height: tinggi,
        // Potret dipotong mengikuti bentuk bingkai.
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: warna,
          borderRadius: radius,
          boxShadow: bayangan == null
              ? null
              : [
                  BoxShadow(
                    color: bayangan!,
                    offset: const Offset(0, 10),
                    blurRadius: 22,
                  ),
                ],
        ),
        child: Stack(
          children: [
            if (potret != null)
              // Sedikit ke kanan-bawah supaya kepala tidak tertutup label nama.
              Positioned(
                left: (lebar - tinggi * .94) / 2 + (nama == null ? 0 : 10 * s),
                top: tinggi * .1,
                child: Potret(potret!, ukuran: tinggi * .94),
              ),
            if (nama != null && nama!.isNotEmpty)
              Positioned(
                left: 12,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    nama!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: BerduaColors.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Toast pink muda di atas navigasi.
void tampilkanToast(BuildContext context, String pesan) {
  final messenger = ScaffoldMessenger.of(context);

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(_snackBar(pesan));
}

SnackBar _snackBar(String pesan) {
  return SnackBar(
    content: Text(
      pesan,
      style: const TextStyle(
        color: BerduaColors.ink,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
    ),
    backgroundColor: BerduaColors.roseCard,
    behavior: SnackBarBehavior.floating,
    elevation: 6,
    duration: const Duration(milliseconds: 2200),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.input),
    ),
    margin: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.md),
  );
}

/// Varian toast untuk dipakai sesudah await: messenger diambil sebelum
/// operasi async, sehingga BuildContext tidak disentuh setelahnya.
void tampilkanToastVia(ScaffoldMessengerState messenger, String pesan) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(_snackBar(pesan));
}

/// Kepala layar: tombol kembali atau stiker di kiri, judul di tengah, aksi di
/// kanan.
class KepalaLayar extends StatelessWidget {
  const KepalaLayar({
    super.key,
    required this.judul,
    this.stiker,
    this.kembali = false,
    this.kiri,
    this.aksi,
  });

  final String judul;

  /// Stiker kecil di samping judul.
  final JenisStiker? stiker;
  final bool kembali;

  /// Pengganti tombol kembali di sisi kiri (mis. stiker dompet di layar Uang).
  final Widget? kiri;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    final adaSisi = kembali || kiri != null || aksi != null;
    final kosong = adaSisi ? const SizedBox(width: 40) : const SizedBox();

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          if (kembali)
            const TombolKembali()
          else if (kiri != null)
            SizedBox(width: 40, child: Center(child: kiri))
          else
            kosong,
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (stiker != null) ...[
                  Stiker.kecil(stiker!),
                  const SizedBox(width: Gap.sm),
                ],
                Flexible(
                  child: Text(
                    judul,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: kembali ? 21 : 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          aksi ?? kosong,
        ],
      ),
    );
  }
}

/// Kerangka layar: latar konfeti, kepala, dan daftar kartu yang muncul
/// memantul satu per satu.
class LayarBerdua extends StatefulWidget {
  const LayarBerdua({
    super.key,
    required this.judul,
    required this.children,
    this.aksi,
    this.kiri,
    this.stiker,
    this.kembali = false,
    this.kepala,
    this.tab,
    this.ruangFab = false,
    this.kunciPantul,
    this.onSegarkan,
    this.tanpaKepala = false,
  });

  /// true = kepala tidak ikut digulir karena sudah dipasang di luar layar ini
  /// (mis. halaman yang bisa digeser di tab Uang).
  final bool tanpaKepala;

  /// Kalau diisi, daftar bisa ditarik ke bawah untuk memuat ulang.
  final Future<void> Function()? onSegarkan;

  final String judul;
  final List<Widget> children;
  final Widget? aksi;
  final Widget? kiri;
  final JenisStiker? stiker;
  final bool kembali;

  /// Pengganti kepala bawaan (Beranda dan Laporan punya kepala sendiri).
  final Widget? kepala;

  /// Indeks tab bawah layar ini; kartu memantul lagi tiap tab ini dibuka.
  final int? tab;

  /// true = sisakan ruang di bawah supaya FAB tidak menutupi kartu terakhir.
  final bool ruangFab;

  /// Nilai yang kalau berubah memicu pantulan ulang (mis. sub-tab Bersama).
  final Object? kunciPantul;

  @override
  State<LayarBerdua> createState() => _LayarBerduaState();
}

class _LayarBerduaState extends State<LayarBerdua> {
  DateTime _mulai = DateTime.now();
  int _putaran = 0;

  @override
  void initState() {
    super.initState();
    tabAktifBerdua.addListener(_saatTabBerubah);
  }

  @override
  void didUpdateWidget(LayarBerdua oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.kunciPantul != widget.kunciPantul) _ulang();
  }

  @override
  void dispose() {
    tabAktifBerdua.removeListener(_saatTabBerubah);
    super.dispose();
  }

  void _saatTabBerubah() {
    if (widget.tab != null && tabAktifBerdua.value == widget.tab && mounted) {
      setState(_ulang);
    }
  }

  void _ulang() {
    _mulai = DateTime.now();
    _putaran++;
  }

  @override
  Widget build(BuildContext context) {
    final kepala =
        widget.kepala ??
        KepalaLayar(
          judul: widget.judul,
          stiker: widget.stiker,
          kembali: widget.kembali,
          kiri: widget.kiri,
          aksi: widget.aksi,
        );

    final daftar = ListView(
      physics: widget.onSegarkan == null
          ? null
          : const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        Gap.screenEdge,
        Gap.sm,
        Gap.screenEdge,
        widget.ruangFab ? 96 : Gap.xxl,
      ),
      children: memantulkan(
        [
          if (!widget.tanpaKepala) ...[kepala, const SizedBox(height: Gap.md)],
          ...widget.children,
        ],
        mulai: _mulai,
        kunci: _putaran,
      ),
    );

    return LatarBerdua(
      // Layar tanpa navigasi bawah menyisakan ruang untuk bilah gestur.
      bawah: widget.tab == null,
      child: widget.onSegarkan == null
          ? daftar
          : RefreshIndicator(
              color: BerduaColors.rose,
              backgroundColor: BerduaColors.card,
              onRefresh: widget.onSegarkan!,
              child: daftar,
            ),
    );
  }
}

// ---------------------------------------------------------------- tambahan

/// FAB pink 60x60 radius 20 dengan bayangan pink lembut. Hanya di Beranda dan
/// Uang.
class FabBerdua extends StatelessWidget {
  const FabBerdua({super.key, required this.onTap, this.keterangan = 'Tambah'});

  final VoidCallback onTap;
  final String keterangan;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: keterangan,
      child: _Tekan(
        onTap: onTap,
        builder: (context, ditekan) => AnimatedScale(
          scale: ditekan ? .92 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            width: Sizes.fab,
            height: Sizes.fab,
            decoration: BoxDecoration(
              color: ditekan ? BerduaColors.roseHover : BerduaColors.rose,
              borderRadius: BorderRadius.circular(Radii.button),
              boxShadow: Shadows.action,
            ),
            child: const Icon(Icons.add, size: 28, color: BerduaColors.ink),
          ),
        ),
      ),
    );
  }
}

/// Tombol pink persegi 52x52 di samping input: "tambah barang".
class TombolTambahKecil extends StatelessWidget {
  const TombolTambahKecil({
    super.key,
    required this.onTap,
    this.memuat = false,
  });

  final VoidCallback? onTap;
  final bool memuat;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tambah',
      child: _Tekan(
        onTap: memuat ? null : onTap,
        builder: (context, ditekan) => AnimatedScale(
          scale: ditekan ? .92 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ditekan ? BerduaColors.roseHover : BerduaColors.rose,
              borderRadius: BorderRadius.circular(Radii.input),
            ),
            child: memuat
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: BerduaColors.ink,
                    ),
                  )
                : const Icon(Icons.add, size: 24, color: BerduaColors.ink),
          ),
        ),
      ),
    );
  }
}

/// Kotak centang 26x26 radius 9: pink berisi centang putih saat selesai.
class KotakCentang extends StatelessWidget {
  const KotakCentang({super.key, required this.selesai});

  final bool selesai;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selesai ? BerduaColors.rose : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: selesai ? BerduaColors.rose : BerduaColors.garisCentang,
          width: 2,
        ),
      ),
      child: AnimatedScale(
        scale: selesai ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: const Icon(Icons.check_rounded, size: 17, color: Colors.white),
      ),
    );
  }
}

/// Blok tanggal 54x58 pink muda: "NOV" di atas "22".
class BlokTanggal extends StatelessWidget {
  const BlokTanggal({super.key, required this.bulan, required this.hari});

  final String bulan;
  final int hari;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      width: 54,
      height: 58,
      decoration: BoxDecoration(
        color: BerduaColors.roseCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            bulan,
            style: text.labelSmall?.copyWith(
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: BerduaColors.rose,
            ),
          ),
          Text(
            '$hari',
            style: text.titleMedium?.copyWith(fontSize: 22, height: 1.1),
          ),
        ],
      ),
    );
  }
}

/// Label di atas isian: "Nomor telepon", "Kategori".
class LabelIsian extends StatelessWidget {
  const LabelIsian(this.teks, {super.key});

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: Gap.sm),
      child: Text(teks, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

/// Teks galat di bawah isian.
class TeksGalat extends StatelessWidget {
  const TeksGalat(this.pesan, {super.key});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        pesan,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: BerduaColors.roseText),
      ),
    );
  }
}

/// Bintang empat sudut — hiasan di sekitar bingkai pasangan.
class Kilau extends StatelessWidget {
  const Kilau({super.key, required this.warna, this.ukuran = 22});

  final Color warna;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(ukuran),
      painter: _KilauPainter(warna),
    );
  }
}

class _KilauPainter extends CustomPainter {
  const _KilauPainter(this.warna);

  final Color warna;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = Path()
      ..moveTo(12 * s, 2 * s)
      ..lineTo(14.4 * s, 9.6 * s)
      ..lineTo(22 * s, 12 * s)
      ..lineTo(14.4 * s, 14.4 * s)
      ..lineTo(12 * s, 22 * s)
      ..lineTo(9.6 * s, 14.4 * s)
      ..lineTo(2 * s, 12 * s)
      ..lineTo(9.6 * s, 9.6 * s)
      ..close();

    canvas.drawPath(path, Paint()..color = warna);
  }

  @override
  bool shouldRepaint(_KilauPainter oldDelegate) => oldDelegate.warna != warna;
}

/// Fase satu hari dalam siklus sepanjang [panjang] hari. Masa subur dihitung
/// mundur dari akhir siklus (ovulasi ±14 hari sebelum haid berikutnya), sama
/// seperti prototipe.
String faseHariSiklus(int hari, int panjang, int lamaHaid) {
  if (hari <= lamaHaid) return 'haid';
  if (hari >= panjang - 16 && hari <= panjang - 12) return 'subur';

  return hari < panjang - 16 ? 'folikular' : 'luteal';
}

/// Cincin siklus: satu ruas per hari, berwarna menurut fase. Hari yang belum
/// lewat diredupkan, dan titik tinta menandai hari ini.
class CincinSiklus extends StatelessWidget {
  const CincinSiklus({
    super.key,
    required this.hariKe,
    this.panjang = 28,
    this.lamaHaid = 5,
    this.ukuran = 104,
    this.lubang = 70,
    this.warnaLubang = BerduaColors.card,
  });

  final int hariKe;
  final int panjang;
  final int lamaHaid;
  final double ukuran;
  final double lubang;
  final Color warnaLubang;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      label: 'Hari ke-$hariKe dari $panjang',
      child: SizedBox(
        width: ukuran,
        height: ukuran,
        child: CustomPaint(
          painter: _CincinSiklusPainter(
            hariKe: hariKe,
            panjang: math.max(panjang, 1),
            lamaHaid: lamaHaid,
            tebal: (ukuran - lubang) / 2,
          ),
          child: Center(
            child: Container(
              width: lubang,
              height: lubang,
              decoration: BoxDecoration(
                color: warnaLubang,
                shape: BoxShape.circle,
              ),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$hariKe',
                      style: text.headlineLarge?.copyWith(
                        fontSize: lubang * .41,
                        height: 1,
                      ),
                    ),
                    Text(
                      'hari ke',
                      style: text.bodySmall?.copyWith(
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CincinSiklusPainter extends CustomPainter {
  const _CincinSiklusPainter({
    required this.hariKe,
    required this.panjang,
    required this.lamaHaid,
    required this.tebal,
  });

  final int hariKe;
  final int panjang;
  final int lamaHaid;
  final double tebal;

  static const _warna = <String, Color>{
    'haid': BerduaColors.period,
    'folikular': BerduaColors.fol,
    'subur': BerduaColors.subur,
    'luteal': BerduaColors.lutealCincin,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final pusat = size.center(Offset.zero);
    final radius = size.width / 2;
    final ruas = 2 * math.pi / panjang;
    // Celah 2,2 derajat antar-ruas, dikecilkan kalau siklusnya panjang.
    final celah = math.min(2.2 * math.pi / 180, ruas * .25);
    final kotak = Rect.fromCircle(center: pusat, radius: radius - tebal / 2);

    for (var i = 0; i < panjang; i++) {
      final dasar = _warna[faseHariSiklus(i + 1, panjang, lamaHaid)]!;
      final cat = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tebal
        ..color = i < hariKe ? dasar : dasar.withValues(alpha: .53);

      canvas.drawArc(kotak, -math.pi / 2 + i * ruas, ruas - celah, false, cat);
    }

    // Titik hari ini: tinta 16 dp dengan cincin putih 3 dp, sedikit keluar.
    final sudut = -math.pi / 2 + (hariKe.clamp(1, panjang) - .5) * ruas;
    final titik =
        pusat + Offset(math.cos(sudut), math.sin(sudut)) * (radius - 3);

    canvas.drawCircle(titik, 11, Paint()..color = Colors.white);
    canvas.drawCircle(titik, 8, Paint()..color = BerduaColors.ink);
  }

  @override
  bool shouldRepaint(_CincinSiklusPainter old) =>
      old.hariKe != hariKe ||
      old.panjang != panjang ||
      old.lamaHaid != lamaHaid ||
      old.tebal != tebal;
}

/// Cincin progres: pink sebesar [nilai], sisanya pink muda. Isinya bebas
/// ("70%" + "terkumpul").
class CincinProgres extends StatelessWidget {
  const CincinProgres({
    super.key,
    required this.nilai,
    required this.child,
    this.ukuran = 92,
    this.lubang = 72,
  });

  /// 0..1.
  final double nilai;
  final Widget child;
  final double ukuran;
  final double lubang;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: nilai.clamp(0, 1).toDouble()),
      duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? Duration.zero
          : const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, anak) => SizedBox(
        width: ukuran,
        height: ukuran,
        child: CustomPaint(
          painter: _CincinProgresPainter(v, (ukuran - lubang) / 2),
          child: anak,
        ),
      ),
      child: Center(
        child: Container(
          width: lubang,
          height: lubang,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CincinProgresPainter extends CustomPainter {
  const _CincinProgresPainter(this.nilai, this.tebal);

  final double nilai;
  final double tebal;

  @override
  void paint(Canvas canvas, Size size) {
    final kotak = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - tebal / 2,
    );

    canvas.drawArc(
      kotak,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tebal
        ..color = BerduaColors.roseCard,
    );
    canvas.drawArc(
      kotak,
      -math.pi / 2,
      2 * math.pi * nilai,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tebal
        ..color = BerduaColors.rose,
    );
  }

  @override
  bool shouldRepaint(_CincinProgresPainter old) =>
      old.nilai != nilai || old.tebal != tebal;
}

/// Tombol bergaris putus-putus: "Tambah jadwal atau pengingat".
class TombolPutus extends StatelessWidget {
  const TombolPutus({
    super.key,
    required this.label,
    required this.onTap,
    this.stiker,
  });

  final String label;
  final VoidCallback onTap;
  final JenisStiker? stiker;

  @override
  Widget build(BuildContext context) {
    return _Tekan(
      onTap: onTap,
      builder: (context, ditekan) => CustomPaint(
        painter: const _GarisPutusPainter(),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ditekan ? BerduaColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.input),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (stiker != null) ...[
                Stiker.kecil(stiker!),
                const SizedBox(width: Gap.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GarisPutusPainter extends CustomPainter {
  const _GarisPutusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bentuk = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(Radii.input),
        ).deflate(.75),
      );
    final cat = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = BerduaColors.garisCentang;

    for (final metrik in bentuk.computeMetrics()) {
      for (var d = 0.0; d < metrik.length; d += 10) {
        canvas.drawPath(
          metrik.extractPath(d, math.min(d + 6, metrik.length)),
          cat,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GarisPutusPainter oldDelegate) => false;
}

/// Tombol teks polos: "Ganti nomor", "Kirim ulang kode".
class TombolTeks extends StatelessWidget {
  const TombolTeks({
    super.key,
    required this.label,
    required this.onTap,
    this.warna = BerduaColors.roseText,
    this.tebal = FontWeight.w600,
    this.ukuran = 14,
    this.stiker,
  });

  final String label;
  final VoidCallback? onTap;
  final Color warna;
  final FontWeight tebal;
  final double ukuran;
  final JenisStiker? stiker;

  @override
  Widget build(BuildContext context) {
    return _Tekan(
      onTap: onTap,
      builder: (context, ditekan) => Opacity(
        opacity: onTap == null ? .5 : (ditekan ? .6 : 1),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (stiker != null) ...[
                Stiker.kecil(stiker!),
                const SizedBox(width: Gap.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: ukuran,
                    fontWeight: tebal,
                    color: warna,
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

/// Baris sakelar dalam kartu bergaris: keterangan kecil di atas, label di
/// bawah, sakelar di kanan.
class BarisSakelar extends StatelessWidget {
  const BarisSakelar({
    super.key,
    required this.label,
    required this.nyala,
    required this.onUbah,
    this.keterangan,
    this.bayangan = true,
  });

  final String label;
  final String? keterangan;
  final bool nyala;
  final ValueChanged<bool> onUbah;
  final bool bayangan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      toggled: nyala,
      child: KartuBerdua(
        radius: bayangan ? Radii.button : Radii.input,
        bayangan: bayangan,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        onTap: () => onUbah(!nyala),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (keterangan != null)
                    Text(keterangan!, style: text.labelSmall),
                  Text(
                    label,
                    style: text.bodyLarge?.copyWith(
                      fontSize: keterangan == null ? 16 : 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gap.md),
            SakelarBerdua(nyala: nyala),
          ],
        ),
      ),
    );
  }
}

/// Pesan galat satu layar penuh dengan tombol coba lagi, di atas latar
/// konfeti.
class GalatLayar extends StatelessWidget {
  const GalatLayar({super.key, required this.pesan, this.onUlangi, this.tab});

  final String pesan;
  final VoidCallback? onUlangi;
  final int? tab;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return LatarBerdua(
      bawah: tab == null,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Gap.xxl),
          child: KartuBerdua(
            stiker: JenisStiker.bell,
            padding: const EdgeInsets.all(Gap.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ada yang tersendat',
                  style: text.titleMedium?.copyWith(fontSize: 19),
                ),
                const SizedBox(height: Gap.sm),
                Text(
                  pesan,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(fontSize: 15, height: 1.5),
                ),
                if (onUlangi != null) ...[
                  const SizedBox(height: Gap.lg),
                  TombolSekunder(label: 'Coba lagi', onPressed: onUlangi),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Membuka bottom sheet bergaya Berdua: sudut atas 32, paling tinggi 88%
/// layar, dan naik bersama papan ketik.
Future<T?> bukaLembar<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .88,
        ),
        child: builder(sheetContext),
      ),
    ),
  );
}

/// Isi bottom sheet: kepala bertombol tutup, lalu anak-anaknya berjarak 16.
class IsiLembar extends StatelessWidget {
  const IsiLembar({
    super.key,
    required this.judul,
    required this.children,
    this.judulKecil = false,
    this.jarak = Gap.lg,
  });

  final String judul;
  final bool judulKecil;
  final List<Widget> children;
  final double jarak;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Gap.xl, 18, Gap.xl, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KepalaSheet(judul: judul, kecil: judulKecil),
            for (final anak in children) ...[SizedBox(height: jarak), anak],
          ],
        ),
      ),
    );
  }
}

/// Menulis huruf pertama sebagai kapital: "sakit kepala" jadi "Sakit kepala".
String kapitalAwal(String teks) =>
    teks.isEmpty ? teks : '${teks[0].toUpperCase()}${teks.substring(1)}';
