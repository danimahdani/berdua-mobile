import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'berdua_widgets.dart';

/// Skeleton loading untuk setiap perpindahan yang menunggu proses.
///
/// Bentuk setiap skeleton sengaja meniru tata letak layar aslinya: tinggi
/// kartu, jumlah baris dan posisi judulnya sama. Dengan begitu saat data
/// datang isinya tinggal mengisi kerangka yang sudah ada, bukan melompat.
///
/// Semua warna diambil dari §13 supaya terasa satu bahasa dengan layarnya.

/// Pembungkus yang menjalankan kilau. Satu controller untuk seluruh subtree,
/// bukan satu per kotak.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  // Dibuat di initState, BUKAN lewat `late final` yang malas. Dengan gerak
  // dikurangi, build() tidak pernah menyentuh controller, sehingga inisialisasi
  // malasnya baru berjalan saat dispose() — membuat Ticker di atas elemen yang
  // sudah dinonaktifkan, dan itu melempar.
  late final AnimationController _controller;

  bool _diam = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // §7 aksesibilitas: kalau pengguna meminta gerak dikurangi, kerangkanya
    // tetap tampil tetapi diam — dan tickernya pun tidak dijalankan.
    _diam = MediaQuery.disableAnimationsOf(context);

    if (_diam) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_diam) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: const [BerduaColors.card2, Colors.white, BerduaColors.card2],
          stops: const [0.35, 0.5, 0.65],
          transform: _Geser(_controller.value * 3 - 1.5),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

/// Menggeser gradien melintasi lebar subtree.
class _Geser extends GradientTransform {
  const _Geser(this.bagian);

  final double bagian;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * bagian, 0, 0);
}

/// Satu kotak abu-abu. Warnanya dasar; kilau datang dari [SkeletonLoader].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = Radii.chip,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: BerduaColors.card2,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Satu baris teks palsu. [lebar] adalah pecahan dari lebar yang tersedia,
/// supaya barisnya tidak semua sama panjang seperti teks sungguhan.
///
/// Memakai FractionallySizedBox, jadi HARUS berada di tempat yang lebarnya
/// terbatas — langsung di dalam Row tanpa Expanded akan melempar. Untuk
/// potongan sempit di dalam Row, pakai [SkeletonBox] dengan lebar tetap.
class SkeletonTeks extends StatelessWidget {
  const SkeletonTeks({super.key, this.lebar = 1, this.tinggi = 14});

  final double lebar;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: lebar,
      child: SkeletonBox(height: tinggi, radius: tinggi / 2),
    );
  }
}

/// Kartu kosong seukuran kartu asli.
class SkeletonKartu extends StatelessWidget {
  const SkeletonKartu({super.key, required this.tinggi, this.warna});

  final double tinggi;
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: tinggi,
      decoration: BoxDecoration(
        color: warna ?? BerduaColors.card,
        borderRadius: BorderRadius.circular(Radii.card),
        // Kartu berwarna (pink) tidak bergaris, sama seperti aslinya.
        border: warna == null
            ? Border.all(color: BerduaColors.ink, width: Sizes.garis)
            : null,
      ),
    );
  }
}

/// Kerangka berjudul, meniru [LayarBerdua].
class SkeletonLayar extends StatelessWidget {
  const SkeletonLayar({
    super.key,
    required this.children,
    this.lebarJudul = 0.45,
    this.kembali = false,
    this.tanpaJudul = false,
  });

  final List<Widget> children;
  final double lebarJudul;
  final bool kembali;

  /// true = judul asli sudah tampil di luar kerangka ini.
  final bool tanpaJudul;

  @override
  Widget build(BuildContext context) {
    return LatarBerdua(
      child: SkeletonLoader(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tanpaJudul)
              const SizedBox(height: Gap.sm)
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Gap.screenEdge,
                  Gap.lg,
                  Gap.screenEdge,
                  Gap.lg,
                ),
                child: Row(
                  children: [
                    if (kembali) ...[
                      const SkeletonBox(
                        width: Sizes.backButton,
                        height: Sizes.backButton,
                      ),
                      const SizedBox(width: Gap.md),
                    ],
                    Expanded(
                      child: SkeletonTeks(lebar: lebarJudul, tinggi: 24),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Gap.screenEdge,
                  0,
                  Gap.screenEdge,
                  Gap.xxl,
                ),
                // Kerangka tidak boleh bisa digulir: belum ada apa pun di sana.
                physics: const NeverScrollableScrollPhysics(),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- per layar

/// Layar 06.
class SkeletonBeranda extends StatelessWidget {
  const SkeletonBeranda({super.key});

  @override
  Widget build(BuildContext context) {
    return LatarBerdua(
      child: SkeletonLoader(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Gap.screenEdge,
            Gap.lg,
            Gap.screenEdge,
            Gap.xxl,
          ),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Row(
              children: [
                const Expanded(child: SkeletonTeks(lebar: 0.5)),
                SkeletonBox(
                  width: Sizes.icon,
                  height: Sizes.icon,
                  radius: Sizes.icon / 2,
                ),
              ],
            ),
            const SizedBox(height: Gap.xl),
            Row(
              children: [
                const SkeletonBox(width: 36, height: 36, radius: 14),
                const SizedBox(width: Gap.sm),
                const SkeletonBox(width: 36, height: 36, radius: 14),
                const SizedBox(width: Gap.md),
                // Lebar tetap: di dalam Row tidak ada lebar untuk dipecah.
                const SkeletonBox(width: 64, height: 14, radius: 7),
              ],
            ),
            const SizedBox(height: Gap.xl),
            const SkeletonTeks(lebar: 0.42, tinggi: 28),
            const SizedBox(height: Gap.lg),
            // Kartu rose saldo.
            const SkeletonKartu(tinggi: 104, warna: BerduaColors.roseCard),
            const SizedBox(height: Gap.md),
            const SkeletonTeks(lebar: 0.7),
            const SizedBox(height: Gap.xl),
            // Kartu siklus.
            const SkeletonKartu(tinggi: 148),
            const SizedBox(height: Gap.betweenCards),
            const Row(
              children: [
                Expanded(child: SkeletonKartu(tinggi: 104)),
                SizedBox(width: Gap.betweenCards),
                Expanded(child: SkeletonKartu(tinggi: 104)),
              ],
            ),
            const SizedBox(height: Gap.betweenCards),
            const SkeletonKartu(tinggi: 76),
          ],
        ),
      ),
    );
  }
}

/// Layar 08.
class SkeletonUang extends StatelessWidget {
  const SkeletonUang({super.key, this.tanpaJudul = false});

  final bool tanpaJudul;

  @override
  Widget build(BuildContext context) {
    return SkeletonLayar(
      tanpaJudul: tanpaJudul,
      children: [
        const SkeletonKartu(tinggi: 168, warna: BerduaColors.roseCard),
        const SizedBox(height: Gap.betweenCards),
        const Row(
          children: [
            Expanded(child: SkeletonKartu(tinggi: 86)),
            SizedBox(width: Gap.betweenCards),
            Expanded(child: SkeletonKartu(tinggi: 86)),
          ],
        ),
        const SizedBox(height: Gap.lg),
        const SkeletonBox(height: Sizes.segment, radius: Radii.chip),
        const SizedBox(height: Gap.lg),
        for (var i = 0; i < 5; i++) ...[
          const _BarisKartu(),
          const SizedBox(height: Gap.sm),
        ],
      ],
    );
  }
}

/// Layar 13-14.
class SkeletonSiklus extends StatelessWidget {
  const SkeletonSiklus({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLayar(
      lebarJudul: 0.28,
      children: [
        const SkeletonKartu(tinggi: 150),
        const SizedBox(height: Gap.betweenCards),
        // Kalender: enam baris sel 40 dp.
        const SkeletonKartu(tinggi: 330),
        const SizedBox(height: Gap.betweenCards),
        const SkeletonTeks(lebar: 0.85),
        const SizedBox(height: Gap.xl),
        const SkeletonTeks(lebar: 0.55, tinggi: 16),
        const SizedBox(height: Gap.md),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: const [
            SkeletonBox(width: 92, height: Sizes.minTouchTarget),
            SkeletonBox(width: 86, height: Sizes.minTouchTarget),
            SkeletonBox(width: 118, height: Sizes.minTouchTarget),
            SkeletonBox(width: 104, height: Sizes.minTouchTarget),
            SkeletonBox(width: 132, height: Sizes.minTouchTarget),
          ],
        ),
      ],
    );
  }
}

/// Layar 15.
class SkeletonRiwayat extends StatelessWidget {
  const SkeletonRiwayat({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLayar(
      kembali: true,
      lebarJudul: 0.5,
      children: [
        const SkeletonKartu(tinggi: 92),
        const SizedBox(height: Gap.xl),
        const SkeletonTeks(lebar: 0.38, tinggi: 16),
        const SizedBox(height: Gap.md),
        for (var i = 0; i < 6; i++) ...[
          const _BarisKartu(),
          const SizedBox(height: Gap.sm),
        ],
      ],
    );
  }
}

/// Layar 07.
class SkeletonNotifikasi extends StatelessWidget {
  const SkeletonNotifikasi({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLayar(
      kembali: true,
      lebarJudul: 0.4,
      children: [
        for (var i = 0; i < 6; i++) ...[
          const SkeletonKartu(tinggi: 72),
          const SizedBox(height: Gap.sm),
        ],
      ],
    );
  }
}

/// Layar kuis hari ini dan hasil kuis: kartu utama, lalu deretan kartu dan
/// dua tombol.
class SkeletonKuis extends StatelessWidget {
  const SkeletonKuis({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLayar(
      kembali: true,
      lebarJudul: 0.42,
      children: [
        const SkeletonKartu(tinggi: 190, warna: BerduaColors.kuningSoft),
        const SizedBox(height: Gap.xl),
        const SkeletonTeks(lebar: 0.3, tinggi: 16),
        for (var i = 0; i < 3; i++) ...[
          const SizedBox(height: 14),
          const SkeletonKartu(tinggi: 72),
        ],
        const SizedBox(height: 14),
        const SkeletonKartu(tinggi: 104, warna: BerduaColors.rakaSoft),
        const SizedBox(height: 14),
        const SkeletonBox(height: Sizes.primaryButton, radius: Radii.button),
        const SizedBox(height: 14),
        const SkeletonBox(height: Sizes.primaryButton, radius: Radii.button),
      ],
    );
  }
}

/// Layar riwayat kuis.
class SkeletonRiwayatKuis extends StatelessWidget {
  const SkeletonRiwayatKuis({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLayar(
      kembali: true,
      lebarJudul: 0.42,
      children: [
        const SkeletonKartu(tinggi: 200, warna: BerduaColors.rakaSoft),
        for (var i = 0; i < 4; i++) ...[
          const SizedBox(height: 14),
          const SkeletonKartu(tinggi: 84),
        ],
        const SizedBox(height: 14),
        const SkeletonBox(height: Sizes.primaryButton, radius: Radii.button),
      ],
    );
  }
}

/// Layar 12.
class SkeletonLaporan extends StatelessWidget {
  const SkeletonLaporan({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLayar(
      kembali: true,
      lebarJudul: 0.32,
      children: [
        const SkeletonKartu(tinggi: 190, warna: BerduaColors.roseCard),
        const SizedBox(height: Gap.betweenCards),
        // Pembagian pembayar: batang + tiga baris legenda.
        const SkeletonKartu(tinggi: 180),
        const SizedBox(height: Gap.betweenCards),
        // Lima kategori.
        const SkeletonKartu(tinggi: 300),
        const SizedBox(height: Gap.betweenCards),
        // Grafik garis.
        const SkeletonKartu(tinggi: 250),
      ],
    );
  }
}

/// Layar 19.
class SkeletonTabunganDetail extends StatelessWidget {
  const SkeletonTabunganDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLayar(
      kembali: true,
      lebarJudul: 0.46,
      children: [
        const SkeletonKartu(tinggi: 186, warna: BerduaColors.roseCard),
        const SizedBox(height: Gap.betweenCards),
        const Row(
          children: [
            Expanded(child: SkeletonKartu(tinggi: 86)),
            SizedBox(width: Gap.betweenCards),
            Expanded(child: SkeletonKartu(tinggi: 86)),
          ],
        ),
        const SizedBox(height: Gap.xl),
        const SkeletonTeks(lebar: 0.3, tinggi: 16),
        const SizedBox(height: Gap.md),
        const SkeletonKartu(tinggi: 86),
        const SizedBox(height: Gap.xl),
        const SkeletonBox(height: Sizes.primaryButton, radius: Radii.button),
        const SizedBox(height: Gap.xl),
        for (var i = 0; i < 3; i++) ...[
          const SkeletonKartu(tinggi: 56),
          const SizedBox(height: Gap.sm),
        ],
      ],
    );
  }
}

/// Daftar sederhana di dalam tab Bersama (layar 16-18, 20, 22).
class SkeletonDaftar extends StatelessWidget {
  const SkeletonDaftar({
    super.key,
    this.baris = 4,
    this.tinggiBaris = 76,
    this.atas,
    this.sematan = false,
  });

  /// true = ditanam di dalam daftar lain: tanpa tepi dan setinggi isinya.
  final bool sematan;

  final int baris;
  final double tinggiBaris;

  /// Tinggi area input di atas daftar, kalau bagian itu punya.
  final double? atas;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView(
        shrinkWrap: sematan,
        padding: sematan
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(
                Gap.screenEdge,
                Gap.sm,
                Gap.screenEdge,
                Gap.xxl,
              ),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          if (atas != null) ...[
            SkeletonBox(height: atas!, radius: Radii.input),
            const SizedBox(height: Gap.md),
          ],
          for (var i = 0; i < baris; i++) ...[
            SkeletonKartu(tinggi: tinggiBaris),
            const SizedBox(height: Gap.sm),
          ],
        ],
      ),
    );
  }
}

/// Kartu daftar dengan avatar dan dua baris teks.
class _BarisKartu extends StatelessWidget {
  const _BarisKartu();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: BerduaColors.card,
        borderRadius: BorderRadius.circular(Radii.button),
        border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 44, height: 44, radius: 16),
          const SizedBox(width: Gap.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonTeks(lebar: 0.6, tinggi: 15),
                SizedBox(height: Gap.sm),
                SkeletonTeks(lebar: 0.35, tinggi: 12),
              ],
            ),
          ),
          const SizedBox(width: Gap.md),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonBox(width: 86, height: 15, radius: 8),
              SizedBox(height: Gap.sm),
              SkeletonBox(width: 48, height: 12, radius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dipakai saat token lama diperiksa waktu aplikasi dibuka. Bentuknya netral
/// karena belum diketahui apakah pengguna akan mendarat di beranda atau di
/// layar masuk.
class SkeletonPembuka extends StatelessWidget {
  const SkeletonPembuka({super.key});

  @override
  Widget build(BuildContext context) {
    return LatarBerdua(
      child: SkeletonLoader(
        child: Padding(
          padding: const EdgeInsets.all(Gap.screenEdge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SkeletonTeks(lebar: 0.8, tinggi: 32),
              SizedBox(height: Gap.md),
              SkeletonTeks(lebar: 0.6, tinggi: 32),
              SizedBox(height: Gap.xxl),
              SkeletonTeks(lebar: 0.9),
              SizedBox(height: Gap.sm),
              SkeletonTeks(lebar: 0.5),
            ],
          ),
        ),
      ),
    );
  }
}
