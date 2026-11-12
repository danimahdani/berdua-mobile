import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/rupiah.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../auth/sesi_cubit.dart';
import 'kuis_cubit.dart';

/// "Hari ini, 9 Nov" untuk kuis hari ini, selain itu "8 Nov" (dengan tahun
/// kalau tahunnya berbeda).
String tanggalKuis(DateTime tanggal) {
  final kini = DateTime.now();
  final hariIni = DateTime(kini.year, kini.month, kini.day);
  final hari = DateTime(tanggal.year, tanggal.month, tanggal.day);

  if (hari == hariIni) return 'Hari ini, ${TanggalId.short(tanggal)}';

  return hari.year == hariIni.year
      ? TanggalId.short(tanggal)
      : TanggalId.long(tanggal);
}

/// Label "RIWAYAT KUIS (4)"; jumlahnya menyusul setelah riwayat termuat.
String labelRiwayatKuis(BuildContext context) {
  final jumlah = context.watch<RiwayatKuisCubit>().state.nilai?.count;

  return jumlah == null ? 'Riwayat kuis' : 'Riwayat kuis ($jumlah)';
}

/// Pil kecil bergaris tinta: kategori soal, tanggal, "5 pertanyaan", "Sama".
class PilKuis extends StatelessWidget {
  const PilKuis(
    this.teks, {
    super.key,
    this.latar = BerduaColors.card,
    this.tebal = FontWeight.w400,
    this.ukuran = 13,
    this.jarakHuruf = 0,
  });

  final String teks;
  final Color latar;
  final FontWeight tebal;
  final double ukuran;
  final double jarakHuruf;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
      ),
      child: Text(
        teks,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: ukuran,
          height: 1.3,
          fontWeight: tebal,
          letterSpacing: jarakHuruf,
          color: BerduaColors.ink,
        ),
      ),
    );
  }
}

/// Cincin skor bergaris tinta: busur pink sebesar [sama]/[total], dengan
/// lubang putih berisi [child].
class CincinSkor extends StatelessWidget {
  const CincinSkor({
    super.key,
    required this.sama,
    required this.total,
    required this.child,
    this.ukuran = 112,
    this.lubang = 78,
    this.sisa = BerduaColors.card,
  });

  /// null = belum bisa dibandingkan; cincinnya kosong.
  final int? sama;
  final int total;
  final Widget child;
  final double ukuran;
  final double lubang;

  /// Warna bagian cincin yang tidak terisi.
  final Color sisa;

  @override
  Widget build(BuildContext context) {
    final nilai = sama == null || total == 0 ? 0.0 : sama! / total;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: nilai.clamp(0, 1).toDouble()),
      duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? Duration.zero
          : const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, anak) =>
          CustomPaint(painter: _CincinSkorPainter(v, sisa), child: anak),
      child: SizedBox(
        width: ukuran,
        height: ukuran,
        child: Center(
          child: Container(
            width: lubang,
            height: lubang,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: BerduaColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
            ),
            // Huruf yang diperbesar di pengaturan sistem tetap muat di lubang.
            child: FittedBox(fit: BoxFit.scaleDown, child: child),
          ),
        ),
      ),
    );
  }
}

class _CincinSkorPainter extends CustomPainter {
  const _CincinSkorPainter(this.nilai, this.sisa);

  final double nilai;
  final Color sisa;

  @override
  void paint(Canvas canvas, Size size) {
    final pusat = size.center(Offset.zero);
    final r = size.width / 2;
    final kotak = Rect.fromCircle(center: pusat, radius: r);

    canvas.drawCircle(pusat, r, Paint()..color = sisa);

    if (nilai > 0) {
      canvas.drawArc(
        kotak,
        -math.pi / 2,
        2 * math.pi * nilai,
        true,
        Paint()..color = BerduaColors.rose,
      );
    }

    canvas.drawCircle(
      pusat,
      r - Sizes.garis / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = Sizes.garis
        ..color = BerduaColors.ink,
    );
  }

  @override
  bool shouldRepaint(_CincinSkorPainter oldDelegate) =>
      oldDelegate.nilai != nilai || oldDelegate.sisa != sisa;
}

/// Nama dan warna kedua orang pada layar hasil. Biru langit selalu pencatat
/// siklus, lavender selalu pasangannya (§12).
({String nama, Color latar, Color teks}) _orang(String nama, bool pencatat) =>
    pencatat
    ? (nama: nama, latar: BerduaColors.dindaSoft, teks: BerduaColors.dindaText)
    : (nama: nama, latar: BerduaColors.rakaSoft, teks: BerduaColors.rakaText);

/// Kartu-kartu hasil satu kuis: judul, skor, lalu jawaban tiap pertanyaan.
/// Dipakai untuk kuis hari ini maupun kuis dari riwayat.
List<Widget> hasilKuis(BuildContext context, Kuis kuis) {
  final text = Theme.of(context).textTheme;
  final sesi = context.watch<SesiCubit>().state;
  final sayaPencatat = sesi.user?.tracksCycle ?? true;
  final namaSaya = sesi.user == null || sesi.user!.name.isEmpty
      ? 'Kamu'
      : sesi.user!.name;
  final saya = _orang(namaSaya, sayaPencatat);
  final pasangan = _orang(kuis.namaPasangan, !sayaPencatat);
  final sama = kuis.same;

  return [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              kuis.title,
              style: text.titleMedium?.copyWith(
                fontSize: 16,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          PilKuis(tanggalKuis(kuis.date), tebal: FontWeight.w600, ukuran: 12),
        ],
      ),
    ),
    const SizedBox(height: 14),
    Semantics(
      label: sama == null
          ? 'Menunggu ${kuis.namaPasangan} menjawab'
          : '$sama dari ${kuis.total} jawaban selaras',
      child: KartuBerdua(
        warna: BerduaColors.roseSoft,
        radius: Radii.cardWhite,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            ExcludeSemantics(
              child: CincinSkor(
                sama: sama,
                total: kuis.total,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${sama ?? '?'}/${kuis.total}',
                      style: text.headlineMedium?.copyWith(
                        fontSize: 26,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'selaras',
                      style: text.labelSmall?.copyWith(
                        fontSize: 11,
                        color: BerduaColors.label,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sama == null
                        ? 'Menunggu ${kuis.namaPasangan}'
                        : judulHasilKuis(sama),
                    style: text.titleLarge?.copyWith(
                      fontSize: 21,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sama == null
                        ? 'Jawabanmu sudah tersimpan. Hasilnya muncul setelah '
                              '${kuis.namaPasangan} ikut menjawab.'
                        : '$sama jawaban sama, ${kuis.total - sama} berbeda. '
                              'Yang berbeda justru bahan obrolan.',
                    style: text.bodySmall?.copyWith(
                      fontSize: 14,
                      height: 1.45,
                      color: BerduaColors.teksDiWarna,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 18),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Jawaban kalian',
        style: text.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    for (final soal in kuis.questions) ...[
      const SizedBox(height: 14),
      _KartuJawaban(soal: soal, saya: saya, pasangan: pasangan),
    ],
  ];
}

class _KartuJawaban extends StatelessWidget {
  const _KartuJawaban({
    required this.soal,
    required this.saya,
    required this.pasangan,
  });

  final SoalKuis soal;
  final ({String nama, Color latar, Color teks}) saya;
  final ({String nama, Color latar, Color teks}) pasangan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    Widget ubin(
      ({String nama, Color latar, Color teks}) orang,
      String? jawaban,
      String kosong,
    ) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: orang.latar,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            orang.nama,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: orang.teks,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            jawaban ?? kosong,
            style: text.bodySmall?.copyWith(
              fontSize: 14,
              height: 1.35,
              color: jawaban == null ? BerduaColors.label : BerduaColors.ink,
            ),
          ),
        ],
      ),
    );

    return KartuBerdua(
      radius: Radii.cardBesar,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  soal.text,
                  style: text.titleMedium?.copyWith(
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (soal.same != null) ...[
                const SizedBox(width: 10),
                PilKuis(
                  soal.same! ? 'Sama' : 'Beda',
                  latar: soal.same!
                      ? BerduaColors.mintCerah
                      : BerduaColors.kuning,
                  tebal: FontWeight.w700,
                  ukuran: 12,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: ubin(saya, soal.jawabanSaya, 'Belum dijawab')),
                const SizedBox(width: 8),
                Expanded(
                  child: ubin(pasangan, soal.jawabanPasangan, 'Belum menjawab'),
                ),
              ],
            ),
          ),
          // Bahan obrolan baru berguna setelah kedua jawaban terlihat.
          if (soal.same != null && soal.talk.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _GarisPutus(),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Obrolkan  ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: BerduaColors.roseText,
                    ),
                  ),
                  TextSpan(text: soal.talk),
                ],
              ),
              style: text.bodySmall?.copyWith(
                fontSize: 14,
                height: 1.45,
                color: BerduaColors.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pemisah putus-putus di atas "Obrolkan".
class _GarisPutus extends StatelessWidget {
  const _GarisPutus();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      width: double.infinity,
      child: CustomPaint(painter: _GarisPutusKuisPainter()),
    );
  }
}

class _GarisPutusKuisPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final kuas = Paint()
      ..color = BerduaColors.netral
      ..strokeWidth = 2;

    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(
        Offset(x, 1),
        Offset(math.min(x + 6, size.width), 1),
        kuas,
      );
    }
  }

  @override
  bool shouldRepaint(_GarisPutusKuisPainter oldDelegate) => false;
}

/// Ringkasan hasil sebagai teks, untuk ditempel di aplikasi obrolan.
///
/// Selama pasangan belum menjawab, isinya hanya ajakan: jawaban pengguna ini
/// tidak ikut disalin supaya pasangan tetap menjawab tanpa melihatnya.
String ringkasanKuis(Kuis kuis, String namaSaya) {
  final sama = kuis.same;

  if (sama == null) {
    return 'Aku sudah menjawab Kuis berdua hari ini: "${kuis.title}". '
        'Giliranmu, lalu kita bandingkan jawabannya.';
  }

  final baris = <String>[
    'Kuis berdua: ${kuis.title} (${tanggalKuis(kuis.date)})',
    'Selaras $sama dari ${kuis.total}.',
    '',
  ];

  for (final (i, soal) in kuis.questions.indexed) {
    baris
      ..add('${i + 1}. ${soal.text}')
      ..add(
        '   $namaSaya: ${soal.jawabanSaya ?? '-'} | '
        '${kuis.namaPasangan}: ${soal.jawabanPasangan ?? '-'}',
      );
  }

  return baris.join('\n');
}

/// Tombol "BAGIKAN": menyalin ringkasan ke papan klip.
Future<void> bagikanKuis(BuildContext context, Kuis kuis) async {
  final messenger = ScaffoldMessenger.of(context);
  final sesi = context.read<SesiCubit>().state;
  final namaSaya = sesi.user == null || sesi.user!.name.isEmpty
      ? 'Aku'
      : sesi.user!.name;

  await Clipboard.setData(ClipboardData(text: ringkasanKuis(kuis, namaSaya)));

  tampilkanToastVia(
    messenger,
    kuis.same == null
        ? 'Ajakan disalin. Tempel di chat untuk ${kuis.namaPasangan}.'
        : 'Ringkasan hasil disalin. Tempel di chat untuk ${kuis.namaPasangan}.',
  );
}
