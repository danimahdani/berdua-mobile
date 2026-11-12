import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/tokens.dart';

/// Ilustrasi potret pengganti foto profil.
enum JenisPotret {
  /// Perempuan berhijab.
  wanita,

  /// Laki-laki berkacamata, rambut pendek.
  pria,
}

/// Potret mengikuti peran, sama seperti warna (§12): pencatat siklus
/// digambar sebagai perempuan berhijab, pasangannya laki-laki berkacamata.
JenisPotret potretPengguna(Pengguna user) =>
    user.tracksCycle ? JenisPotret.wanita : JenisPotret.pria;

/// Potret setengah badan bergaya stiker (garis tinta, warna rata). Bagian
/// bawahnya sengaja melewati kanvas: pasang di dalam bingkai yang memotong.
class Potret extends StatelessWidget {
  const Potret(this.jenis, {super.key, required this.ukuran});

  final JenisPotret jenis;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(ukuran),
          painter: _PotretPainter(jenis),
        ),
      ),
    );
  }
}

class _PotretPainter extends CustomPainter {
  const _PotretPainter(this.jenis);

  final JenisPotret jenis;

  static const _tinta = BerduaColors.ink;
  static const _kulitWanita = Color(0xFFFFDDC4);
  static const _kulitPria = Color(0xFFF6CBA3);
  static const _hijab = BerduaColors.rose;
  static const _hijabGelap = Color(0xFFD62E6C);
  static const _rambut = Color(0xFF43304F);
  static const _baju = BerduaColors.kuning;
  static const _pipi = Color(0x66FF6F9F);

  @override
  void paint(Canvas canvas, Size size) {
    // Digambar di kanvas 100x100.
    canvas.save();
    canvas.scale(size.width / 100);

    final isi = Paint()..style = PaintingStyle.fill;

    Paint garis(double tebal, [Color warna = _tinta]) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tebal
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = warna;

    void bentuk(Path path, Color warna, [double tebal = 2.4]) {
      canvas.drawPath(path, isi..color = warna);
      canvas.drawPath(path, garis(tebal));
    }

    void titik(double x, double y, double r, Color warna) =>
        canvas.drawCircle(Offset(x, y), r, isi..color = warna);

    void mata(double x, double y) {
      titik(x, y, 2.5, _tinta);
      titik(x - .8, y - .9, .9, Colors.white);
    }

    switch (jenis) {
      case JenisPotret.wanita:
        _wanita(canvas, bentuk, garis, titik, mata, isi);
      case JenisPotret.pria:
        _pria(canvas, bentuk, garis, titik, mata, isi);
    }

    canvas.restore();
  }

  void _wanita(
    Canvas canvas,
    void Function(Path, Color, [double]) bentuk,
    Paint Function(double, [Color]) garis,
    void Function(double, double, double, Color) titik,
    void Function(double, double) mata,
    Paint isi,
  ) {
    // Hijab: tudung kepala menyatu dengan juntaian yang menutup bahu.
    final tudung = Path()
      ..addOval(
        Rect.fromCenter(center: const Offset(50, 43), width: 60, height: 64),
      );
    final juntai = Path()
      ..moveTo(6, 108)
      ..cubicTo(8, 82, 22, 70, 34, 62)
      ..lineTo(66, 62)
      ..cubicTo(78, 70, 92, 82, 94, 108)
      ..close();

    bentuk(Path.combine(PathOperation.union, tudung, juntai), _hijab);

    // Lipatan kain di bawah dagu dan yang jatuh ke dada.
    canvas
      ..drawPath(
        Path()
          ..moveTo(31, 62)
          ..quadraticBezierTo(48, 77, 70, 68),
        garis(2, _hijabGelap),
      )
      ..drawPath(
        Path()
          ..moveTo(70, 68)
          ..quadraticBezierTo(77, 86, 72, 104),
        garis(2, _hijabGelap),
      )
      ..drawPath(
        Path()
          ..moveTo(30, 74)
          ..quadraticBezierTo(26, 90, 28, 104),
        garis(2, _hijabGelap),
      )
      // Kilau di puncak tudung.
      ..drawPath(
        Path()
          ..moveTo(28, 32)
          ..quadraticBezierTo(31, 21, 42, 16),
        garis(2.6, Colors.white.withValues(alpha: .7)),
      );

    // Wajah, dengan ciput (dalaman hijab) di dahi.
    final wajah = Path()
      ..addOval(
        Rect.fromCenter(center: const Offset(50, 46), width: 37, height: 40),
      );

    canvas.drawPath(wajah, isi..color = _kulitWanita);

    final ciput = Path.combine(
      PathOperation.intersect,
      wajah,
      Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0)
        ..lineTo(100, 36)
        ..quadraticBezierTo(50, 28, 0, 36)
        ..close(),
    );

    canvas
      ..drawPath(ciput, isi..color = _hijabGelap)
      ..drawPath(ciput, garis(1.8))
      ..drawPath(wajah, garis(2.4));

    titik(38.5, 53.5, 4, _pipi);
    titik(61.5, 53.5, 4, _pipi);

    mata(43, 46.5);
    mata(57, 46.5);

    canvas
      // Alis melengkung lembut dan bulu mata yang menjentik ke luar.
      ..drawPath(
        Path()
          ..moveTo(40, 41.6)
          ..quadraticBezierTo(43, 39.6, 46, 41.4),
        garis(1.5),
      )
      ..drawPath(
        Path()
          ..moveTo(54, 41.4)
          ..quadraticBezierTo(57, 39.6, 60, 41.6),
        garis(1.5),
      )
      ..drawLine(const Offset(40.7, 47.2), const Offset(38.6, 47.6), garis(1.4))
      ..drawLine(const Offset(59.3, 47.2), const Offset(61.4, 47.6), garis(1.4))
      // Senyum.
      ..drawPath(
        Path()
          ..moveTo(45, 54.5)
          ..quadraticBezierTo(50, 60, 55, 54.5),
        garis(2),
      );

    // Bros bunga di samping.
    for (final (dx, dy) in const [
      (0.0, -3.4),
      (3.3, 0.0),
      (0.0, 3.4),
      (-3.3, 0.0),
    ]) {
      titik(71 + dx, 68 + dy, 2.6, Colors.white);
    }

    canvas.drawCircle(const Offset(71, 68), 2.4, isi..color = _baju);
    canvas.drawCircle(const Offset(71, 68), 2.4, garis(1.4));
  }

  void _pria(
    Canvas canvas,
    void Function(Path, Color, [double]) bentuk,
    Paint Function(double, [Color]) garis,
    void Function(double, double, double, Color) titik,
    void Function(double, double) mata,
    Paint isi,
  ) {
    // Leher, lalu kaus berkerah V di atasnya.
    bentuk(
      Path()
        ..addRRect(RRect.fromLTRBR(42, 58, 58, 84, const Radius.circular(6))),
      _kulitPria,
    );
    bentuk(
      Path()
        ..moveTo(8, 108)
        ..cubicTo(10, 86, 26, 78, 41, 74)
        ..lineTo(50, 85)
        ..lineTo(59, 74)
        ..cubicTo(74, 78, 90, 86, 92, 108)
        ..close(),
      _baju,
    );
    // Garis kerah.
    canvas.drawPath(
      Path()
        ..moveTo(37, 76.5)
        ..lineTo(50, 91)
        ..lineTo(63, 76.5),
      garis(1.8, BerduaColors.kuningText.withValues(alpha: .55)),
    );

    // Telinga.
    for (final x in const [29.5, 70.5]) {
      bentuk(
        Path()..addOval(
          Rect.fromCenter(center: Offset(x, 47), width: 9, height: 11),
        ),
        _kulitPria,
      );
    }

    // Kepala.
    bentuk(
      Path()
        ..addRRect(RRect.fromLTRBR(30, 20, 70, 66, const Radius.circular(20))),
      _kulitPria,
    );

    // Rambut pendek dengan jambul kecil ke samping.
    bentuk(
      Path()
        ..moveTo(29, 40)
        ..cubicTo(24, 22, 38, 12, 52, 14)
        ..cubicTo(57, 10, 66, 11, 67, 17)
        ..cubicTo(74, 22, 74, 32, 71, 40)
        ..cubicTo(70, 34, 67, 30, 63, 28)
        ..cubicTo(55, 33, 43, 32, 36, 27)
        ..cubicTo(32, 30, 30, 34, 29, 40)
        ..close(),
      _rambut,
    );
    canvas.drawPath(
      Path()
        ..moveTo(37, 20)
        ..quadraticBezierTo(44, 16, 52, 17),
      garis(2, Colors.white.withValues(alpha: .35)),
    );

    titik(37.5, 55.5, 3.6, _pipi);
    titik(62.5, 55.5, 3.6, _pipi);

    // Alis.
    canvas
      ..drawLine(const Offset(37.5, 37.2), const Offset(44, 36.4), garis(2))
      ..drawLine(const Offset(56, 36.4), const Offset(62.5, 37.2), garis(2));

    // Kacamata bulat: lensa, jembatan, gagang ke telinga.
    for (final x in const [41.0, 59.0]) {
      final lensa = Offset(x, 46);

      canvas
        ..drawCircle(
          lensa,
          7.6,
          isi..color = Colors.white.withValues(alpha: .5),
        )
        ..drawCircle(lensa, 7.6, garis(2.4));
    }

    canvas
      ..drawPath(
        Path()
          ..moveTo(48.2, 45)
          ..quadraticBezierTo(50, 43.4, 51.8, 45),
        garis(2.2),
      )
      ..drawLine(const Offset(33.4, 45), const Offset(30, 44), garis(2.2))
      ..drawLine(const Offset(66.6, 45), const Offset(70, 44), garis(2.2));

    mata(41, 46.5);
    mata(59, 46.5);

    // Kilau lensa.
    canvas
      ..drawLine(
        const Offset(36.4, 43),
        const Offset(38.2, 41.2),
        garis(1.4, Colors.white),
      )
      ..drawLine(
        const Offset(54.4, 43),
        const Offset(56.2, 41.2),
        garis(1.4, Colors.white),
      );

    // Senyum lebar.
    bentuk(
      Path()
        ..moveTo(44, 57)
        ..quadraticBezierTo(50, 58.5, 56, 57)
        ..quadraticBezierTo(50, 65, 44, 57)
        ..close(),
      Colors.white,
      1.8,
    );
  }

  @override
  bool shouldRepaint(_PotretPainter lama) => lama.jenis != jenis;
}
