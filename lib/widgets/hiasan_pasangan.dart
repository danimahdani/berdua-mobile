import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'berdua_widgets.dart';

/// Dua bingkai pasangan yang saling bersandar, dengan hati di antaranya dan
/// kilau kecil di sekitarnya. Dipakai di layar masuk dan di Beranda.
///
/// Digambar di kanvas berukuran tetap lalu dikecilkan kalau layarnya sempit,
/// supaya susunannya tidak pernah berantakan.
class HiasanPasangan extends StatelessWidget {
  /// Layar masuk: bingkai 130 dp tanpa nama, dua kilau.
  const HiasanPasangan.masuk({super.key})
    : namaKiri = null,
      namaKanan = null,
      inisialKiri = null,
      inisialKanan = null,
      warnaKiri = BerduaColors.dinda,
      warnaKanan = BerduaColors.raka,
      angka = null,
      satuan = null,
      _beranda = false;

  /// Beranda: bingkai 150 dp bernama, dengan lama hubungan di kanan.
  const HiasanPasangan.beranda({
    super.key,
    required this.namaKiri,
    required this.inisialKiri,
    required this.warnaKiri,
    this.namaKanan,
    this.inisialKanan,
    this.warnaKanan = BerduaColors.raka,
    this.angka,
    this.satuan,
  }) : _beranda = true;

  final String? namaKiri;
  final String? namaKanan;
  final String? inisialKiri;
  final String? inisialKanan;
  final Color warnaKiri;
  final Color warnaKanan;

  /// "3" dan "tahun".
  final String? angka;
  final String? satuan;

  final bool _beranda;

  static const _bayanganBiru = Color(0x2E2F8FC0);
  static const _bayanganUngu = Color(0x2E7C4FD0);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lebar = _beranda ? 380.0 : 372.0;

    // Bayangan mengikuti warna bingkainya, bukan sisinya.
    Color bayangan(Color warna) =>
        warna == BerduaColors.dinda ? _bayanganBiru : _bayanganUngu;

    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: _beranda ? Alignment.centerLeft : Alignment.center,
        child: SizedBox(
          width: lebar,
          height: 150,
          child: Stack(
            clipBehavior: Clip.none,
            children: _beranda
                ? [
                    Positioned(
                      left: 12,
                      top: 6,
                      child: BingkaiPasangan(
                        warna: warnaKiri,
                        lebar: 150,
                        tinggi: 130,
                        derajat: -5,
                        nama: namaKiri,
                        inisial: inisialKiri,
                        bayangan: bayangan(warnaKiri),
                      ),
                    ),
                    if (inisialKanan != null)
                      Positioned(
                        left: 138,
                        top: 20,
                        child: BingkaiPasangan(
                          warna: warnaKanan,
                          lebar: 150,
                          tinggi: 126,
                          derajat: 4,
                          nama: namaKanan,
                          inisial: inisialKanan,
                          kiri: false,
                          bayangan: bayangan(warnaKanan),
                        ),
                      ),
                    const Positioned(
                      left: 134,
                      top: -2,
                      child: Stiker(JenisStiker.heart, ukuran: 34),
                    ),
                    if (angka != null)
                      Positioned(
                        right: 4,
                        top: 40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              angka!,
                              style: text.headlineLarge?.copyWith(
                                fontSize: 30,
                                height: 1,
                              ),
                            ),
                            Text(
                              satuan ?? '',
                              style: text.labelSmall?.copyWith(
                                color: BerduaColors.label,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ]
                : const [
                    Positioned(
                      left: 60,
                      top: 10,
                      child: BingkaiPasangan(
                        warna: BerduaColors.dinda,
                        lebar: 130,
                        tinggi: 130,
                        derajat: -6,
                        bayangan: _bayanganBiru,
                      ),
                    ),
                    Positioned(
                      left: 176,
                      top: 24,
                      child: BingkaiPasangan(
                        warna: BerduaColors.raka,
                        lebar: 130,
                        tinggi: 126,
                        derajat: 6,
                        kiri: false,
                        bayangan: _bayanganUngu,
                      ),
                    ),
                    Positioned(
                      left: 160,
                      top: -2,
                      child: Stiker(JenisStiker.heart, ukuran: 34),
                    ),
                    Positioned(
                      left: 30,
                      top: 96,
                      child: Kilau(warna: BerduaColors.kuning),
                    ),
                    Positioned(
                      right: 42,
                      top: 6,
                      child: Kilau(warna: BerduaColors.dindaKuat, ukuran: 18),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

/// Tiga titik langkah onboarding: yang aktif memanjang dan berwarna pink.
class TitikLangkah extends StatelessWidget {
  const TitikLangkah({super.key, required this.aktif, this.jumlah = 3});

  final int aktif;
  final int jumlah;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Langkah ${aktif + 1} dari $jumlah',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < jumlah; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == aktif ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == aktif ? BerduaColors.rose : BerduaColors.netral,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}
