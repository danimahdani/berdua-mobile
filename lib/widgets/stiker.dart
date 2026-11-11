import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Dua belas stiker ilustrasi Berdua v4. Bentuknya disalin dari prototipe
/// (kanvas 48x48, garis tinta 2,5 dengan ujung membulat).
enum JenisStiker {
  coin,
  heart,
  flower,
  bag,
  check,
  cal,
  piggy,
  wallet,
  mail,
  bell,
  note,
  chart,
}

enum _Gerak { flip, pulse, wiggle, bounce, ring, float }

/// Stiker yang bergerak pelan di sudut kartu atau di samping judul.
///
/// Geraknya berhenti kalau pengguna menyalakan "hilangkan animasi" di sistem;
/// stikernya tetap tampil, hanya diam.
class Stiker extends StatefulWidget {
  const Stiker(this.jenis, {super.key, this.ukuran = 42});

  /// 28 dp — di samping judul layar atau di dalam tombol.
  const Stiker.kecil(this.jenis, {super.key}) : ukuran = 28;

  /// 40 dp — deretan stiker di layar masuk.
  const Stiker.sedang(this.jenis, {super.key}) : ukuran = 40;

  /// 64 dp — ilustrasi tunggal di layar kode.
  const Stiker.besar(this.jenis, {super.key}) : ukuran = 64;

  final JenisStiker jenis;
  final double ukuran;

  @override
  State<Stiker> createState() => _StikerState();
}

class _StikerState extends State<Stiker> with SingleTickerProviderStateMixin {
  late final AnimationController _kendali;

  static const _durasi = <JenisStiker, int>{
    JenisStiker.coin: 3200,
    JenisStiker.heart: 1500,
    JenisStiker.flower: 2600,
    JenisStiker.bag: 2000,
    JenisStiker.check: 2200,
    JenisStiker.cal: 3000,
    JenisStiker.piggy: 2400,
    JenisStiker.wallet: 3000,
    JenisStiker.mail: 2600,
    JenisStiker.chart: 2600,
    JenisStiker.bell: 2400,
    JenisStiker.note: 2800,
  };

  static const _gerak = <JenisStiker, _Gerak>{
    JenisStiker.coin: _Gerak.flip,
    JenisStiker.heart: _Gerak.pulse,
    JenisStiker.flower: _Gerak.wiggle,
    JenisStiker.bag: _Gerak.bounce,
    JenisStiker.check: _Gerak.pulse,
    JenisStiker.cal: _Gerak.ring,
    JenisStiker.piggy: _Gerak.bounce,
    JenisStiker.wallet: _Gerak.float,
    JenisStiker.mail: _Gerak.float,
    JenisStiker.chart: _Gerak.bounce,
    JenisStiker.bell: _Gerak.ring,
    JenisStiker.note: _Gerak.wiggle,
  };

  @override
  void initState() {
    super.initState();

    final durasi = _durasi[widget.jenis]!;

    _kendali = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durasi),
    );

    // Tiap jenis mulai di fase berbeda supaya stiker di satu layar tidak
    // bergerak serempak.
    _kendali.value = (widget.jenis.index * 0.37 * 1000 / durasi) % 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final diam = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (diam) {
      _kendali.stop();
    } else if (!_kendali.isAnimating) {
      _kendali.repeat();
    }
  }

  @override
  void dispose() {
    _kendali.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diam = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final gambar = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.ukuran),
        painter: _StikerPainter(widget.jenis),
      ),
    );

    if (diam) return ExcludeSemantics(child: gambar);

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _kendali,
        child: gambar,
        builder: (context, child) => Transform(
          // transform-origin: 50% 60%.
          alignment: const Alignment(0, 0.2),
          transform: _matriks(_gerak[widget.jenis]!, _kendali.value),
          child: child,
        ),
      ),
    );
  }

  /// Nilai di antara keyframe, dengan easing ease-in-out per ruas seperti CSS.
  static double _antara(List<(double, double)> kunci, double t) {
    for (var i = 1; i < kunci.length; i++) {
      final (t1, v1) = kunci[i];

      if (t <= t1) {
        final (t0, v0) = kunci[i - 1];
        final p = t1 == t0 ? 1.0 : (t - t0) / (t1 - t0);

        return v0 + (v1 - v0) * Curves.easeInOut.transform(p);
      }
    }

    return kunci.last.$2;
  }

  static const _derajat = math.pi / 180;

  static Matrix4 _matriks(_Gerak gerak, double t) {
    switch (gerak) {
      case _Gerak.float:
        final y = _antara(const [(0, 0), (.5, -5), (1, 0)], t);
        final r = _antara(const [(0, -4), (.5, 4), (1, -4)], t);

        return Matrix4.translationValues(0, y, 0)..rotateZ(r * _derajat);
      case _Gerak.wiggle:
        final r = _antara(const [(0, -9), (.5, 9), (1, -9)], t);

        return Matrix4.rotationZ(r * _derajat);
      case _Gerak.pulse:
        final s = _antara(const [(0, 1), (.5, 1.14), (1, 1)], t);

        return Matrix4.diagonal3Values(s, s, 1);
      case _Gerak.bounce:
        final y = _antara(
          const [(0, 0), (.4, -7), (.55, 0), (.7, -2), (1, 0)],
          t,
        );
        final sx = _antara(
          const [(0, 1), (.4, .96), (.55, 1.06), (.7, 1), (1, 1)],
          t,
        );
        final sy = _antara(
          const [(0, 1), (.4, 1.05), (.55, .94), (.7, 1), (1, 1)],
          t,
        );

        return Matrix4.translationValues(0, y, 0)
          ..multiply(Matrix4.diagonal3Values(sx, sy, 1));
      case _Gerak.flip:
        final r = _antara(const [(0, 0), (.6, 0), (.8, 360), (1, 360)], t);

        return Matrix4.rotationY(r * _derajat);
      case _Gerak.ring:
        final r = _antara(
          const [
            (0, 0),
            (.7, 0),
            (.75, -14),
            (.8, 12),
            (.85, -9),
            (.9, 6),
            (1, 0),
          ],
          t,
        );

        return Matrix4.rotationZ(r * _derajat);
    }
  }
}

class _StikerPainter extends CustomPainter {
  const _StikerPainter(this.jenis);

  final JenisStiker jenis;

  static const _tinta = BerduaColors.ink;
  static const _pink = Color(0xFFFF4F8B);
  static const _pinkMuda = Color(0xFFFF7FAB);
  static const _kuning = Color(0xFFFFD23F);
  static const _biru = Color(0xFF5FCFFF);
  static const _ungu = Color(0xFFA48BFF);
  static const _mint = Color(0xFF2EE6A8);

  @override
  void paint(Canvas canvas, Size size) {
    final skala = size.width / 48;

    // drop-shadow(0 2px 0 tinta 90%): siluet tinta digeser 2 dp ke bawah.
    canvas.save();
    canvas.translate(0, 2);
    canvas.scale(skala);
    _gambar(canvas, siluet: _tinta.withValues(alpha: .9));
    canvas.restore();

    canvas.save();
    canvas.scale(skala);
    _gambar(canvas);
    canvas.restore();
  }

  void _gambar(Canvas canvas, {Color? siluet}) {
    Paint isi(Color warna) => Paint()
      ..style = PaintingStyle.fill
      ..color = siluet ?? warna;

    Paint garis([double tebal = 2.5, Color warna = _tinta]) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tebal
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = siluet ?? warna;

    void lingkaran(double x, double y, double r, Color warna) {
      canvas.drawCircle(Offset(x, y), r, isi(warna));
      canvas.drawCircle(Offset(x, y), r, garis());
    }

    void kotak(
      double x,
      double y,
      double w,
      double h,
      double r,
      Color warna,
    ) {
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(r),
      );

      canvas.drawRRect(rr, isi(warna));
      canvas.drawRRect(rr, garis());
    }

    void bentuk(Path path, Color warna) {
      canvas.drawPath(path, isi(warna));
      canvas.drawPath(path, garis());
    }

    Path busur(
      double x0,
      double y0,
      double x1,
      double y1,
      double r, {
      bool searah = true,
    }) => Path()
      ..moveTo(x0, y0)
      ..arcToPoint(
        Offset(x1, y1),
        radius: Radius.circular(r),
        clockwise: searah,
      );

    switch (jenis) {
      case JenisStiker.coin:
        lingkaran(24, 24, 18, _kuning);

        if (siluet == null) {
          // Lingkaran putus-putus 2 4 di dalam koin.
          final p = garis(1.5);
          const r = 12.5;
          const keliling = 2 * math.pi * r;
          const langkah = 6 / keliling * 2 * math.pi;
          const panjang = 2 / keliling * 2 * math.pi;

          for (var a = 0.0; a < 2 * math.pi; a += langkah) {
            canvas.drawArc(
              Rect.fromCircle(center: const Offset(24, 24), radius: r),
              a,
              panjang,
              false,
              p,
            );
          }

          final teks = TextPainter(
            text: const TextSpan(
              text: 'Rp',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _tinta,
                height: 1,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          teks.paint(
            canvas,
            Offset(24 - teks.width / 2, 24.5 - teks.height / 2),
          );
        }
      case JenisStiker.heart:
        bentuk(
          Path()
            ..moveTo(24, 40)
            ..cubicTo(24, 40, 7, 30, 7, 18)
            ..arcToPoint(const Offset(24, 14), radius: const Radius.circular(9))
            ..arcToPoint(const Offset(41, 18), radius: const Radius.circular(9))
            ..relativeCubicTo(0, 12, -17, 22, -17, 22)
            ..close(),
          _pink,
        );

        if (siluet == null) {
          canvas.drawPath(busur(13, 17, 17, 13, 4), garis(2.5, Colors.white));
        }
      case JenisStiker.flower:
        for (final (x, y) in const [
          (24.0, 11.0),
          (36.0, 20.0),
          (32.0, 35.0),
          (16.0, 35.0),
          (12.0, 20.0),
        ]) {
          lingkaran(x, y, 8, _pinkMuda);
        }

        lingkaran(24, 24, 7, _kuning);
      case JenisStiker.bag:
        bentuk(
          Path()
            ..moveTo(10, 18)
            ..lineTo(38, 18)
            ..lineTo(35, 42)
            ..lineTo(13, 42)
            ..close(),
          _biru,
        );
        canvas.drawPath(
          Path()
            ..moveTo(17, 18)
            ..lineTo(17, 14)
            ..arcToPoint(const Offset(31, 14), radius: const Radius.circular(7))
            ..lineTo(31, 18),
          garis(),
        );
        canvas.drawPath(busur(19, 28, 29, 28, 5, searah: false), garis());
      case JenisStiker.check:
        lingkaran(24, 24, 18, _mint);
        canvas.drawPath(
          Path()
            ..moveTo(15, 24)
            ..lineTo(21, 31)
            ..lineTo(33, 17),
          garis(3.5),
        );
      case JenisStiker.cal:
        kotak(7, 10, 34, 31, 6, Colors.white);
        bentuk(
          Path()
            ..moveTo(7, 20)
            ..lineTo(7, 16)
            ..arcToPoint(const Offset(13, 10), radius: const Radius.circular(6))
            ..lineTo(35, 10)
            ..arcToPoint(const Offset(41, 16), radius: const Radius.circular(6))
            ..lineTo(41, 20)
            ..close(),
          _pink,
        );
        canvas.drawLine(const Offset(16, 6), const Offset(16, 14), garis());
        canvas.drawLine(const Offset(32, 6), const Offset(32, 14), garis());
        lingkaran(24, 31, 4.5, _kuning);
      case JenisStiker.piggy:
        lingkaran(23, 8, 5, _kuning);
        bentuk(
          Path()
            ..moveTo(14, 18)
            ..lineTo(12, 10)
            ..lineTo(21, 14)
            ..close(),
          _pinkMuda,
        );

        final badan = Rect.fromCenter(
          center: const Offset(23, 28),
          width: 32,
          height: 24,
        );
        canvas.drawOval(badan, isi(_pinkMuda));
        canvas.drawOval(badan, garis());

        final moncong = Rect.fromCenter(
          center: const Offset(38, 28),
          width: 10,
          height: 12,
        );
        canvas.drawOval(moncong, isi(const Color(0xFFFFC9DD)));
        canvas.drawOval(moncong, garis());

        lingkaran(30, 23, 1.6, _tinta);
        canvas.drawLine(const Offset(15, 38), const Offset(15, 43), garis());
        canvas.drawLine(const Offset(29, 38), const Offset(29, 43), garis());
        canvas.drawLine(const Offset(19, 18), const Offset(27, 18), garis());
      case JenisStiker.wallet:
        kotak(6, 13, 36, 26, 6, _ungu);
        kotak(28, 21, 14, 10, 4, _kuning);
        lingkaran(34, 26, 1.6, _tinta);
      case JenisStiker.mail:
        kotak(6, 12, 36, 26, 5, Colors.white);
        canvas.drawPath(
          Path()
            ..moveTo(7, 15)
            ..lineTo(24, 28)
            ..lineTo(41, 15),
          garis(),
        );
        lingkaran(37, 35, 6.5, _pink);
      case JenisStiker.bell:
        bentuk(
          Path()
            ..moveTo(11, 34)
            ..relativeCubicTo(3, -3, 5, -7, 5, -13)
            ..arcToPoint(const Offset(32, 21), radius: const Radius.circular(8))
            ..relativeCubicTo(0, 6, 2, 10, 5, 13)
            ..close(),
          _kuning,
        );
        canvas.drawPath(busur(20, 38, 28, 38, 4, searah: false), garis());
        lingkaran(24, 9, 2.5, _tinta);
      case JenisStiker.note:
        kotak(10, 6, 28, 36, 5, Colors.white);
        canvas.drawLine(const Offset(16, 16), const Offset(32, 16), garis());
        canvas.drawLine(const Offset(16, 23), const Offset(32, 23), garis());
        canvas.drawLine(const Offset(16, 30), const Offset(24, 30), garis());
        lingkaran(33, 35, 6, _ungu);
      case JenisStiker.chart:
        kotak(8, 24, 8, 16, 2, _biru);
        kotak(20, 12, 8, 28, 2, _pink);
        kotak(32, 18, 8, 22, 2, _kuning);
    }
  }

  @override
  bool shouldRepaint(_StikerPainter oldDelegate) => oldDelegate.jenis != jenis;
}
