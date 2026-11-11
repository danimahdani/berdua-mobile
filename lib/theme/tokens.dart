import 'package:flutter/material.dart';

/// Token design system Berdua v4 — "versi fun".
///
/// Sumbernya prototipe `BerduaPhoneFun`: warna cerah (pink, kuning, ungu, biru
/// langit, mint) di atas krem, kartu bergaris tebal dengan bayangan keras ala
/// stiker, latar konfeti, dan stiker ilustrasi yang bergerak.
///
/// Jangan menulis hex, ukuran font, atau angka radius langsung di widget:
/// ambil dari sini supaya satu perubahan desain cukup diubah di satu tempat.
abstract final class BerduaColors {
  /// Latar layar: krem.
  static const background = Color(0xFFFFF8EA);

  /// Kartu putih bergaris tinta.
  static const card = Color(0xFFFFFFFF);

  /// Chip nonaktif dan wadah segmen di dalam sheet.
  static const card2 = Color(0xFFFFF1D6);

  /// Garis pemisah dan lintasan progress.
  static const line = Color(0xFFEFE6D2);

  /// Lintasan sakelar mati dan titik netral.
  static const netral = Color(0xFFE8DFCB);

  /// Tinta: teks, garis kartu, dan bayangan keras.
  static const text = Color(0xFF1B1733);
  static const ink = text;

  /// Label di atas nilai ("Dompet bersama").
  static const label = Color(0xFF5A5368);

  /// Keterangan kecil ("belum dibeli").
  static const textSecondary = Color(0xFF655E73);

  /// Tab navigasi yang tidak aktif.
  static const navMati = Color(0xFF6F6880);

  /// Teks pilihan yang tidak aktif pada segmen dan chip.
  static const pilihanMati = Color(0xFF4A4458);

  /// Satu-satunya warna aksi.
  static const rose = Color(0xFFFF4F8B);
  static const roseHover = Color(0xFFE63A76);

  /// Kartu pink untuk angka atau pesan utama — satu per layar.
  static const roseCard = Color(0xFFFFE3EE);
  static const roseChipActive = Color(0xFFFFC9DD);
  static const roseChipText = Color(0xFF8A1F4D);

  /// Tautan, galat, dan aksi teks.
  static const roseText = Color(0xFFB0124D);
  static const roseSoft = Color(0xFFFFD6E5);

  /// Bilah status dan aksen stiker.
  static const kuning = Color(0xFFFFD23F);
  static const kuningSoft = Color(0xFFFFF0B8);
  static const kuningText = Color(0xFF8A4F00);

  /// Biru langit selalu pencatat siklus, lavender selalu pasangannya.
  static const dinda = Color(0xFF8FDCFF);
  static const dindaKuat = Color(0xFF5FCFFF);
  static const dindaSoft = Color(0xFFD2F1FF);
  static const dindaText = Color(0xFF06609A);
  static const raka = Color(0xFFC9B8FF);
  static const rakaKuat = Color(0xFFA48BFF);
  static const rakaSoft = Color(0xFFE4DCFF);
  static const rakaText = Color(0xFF4A2FD0);

  /// Warna fase pada kalender siklus.
  static const period = Color(0xFFFF7FAB);
  static const periodText = Color(0xFF7A1D48);
  static const fertile = Color(0xFFC9B8FF);
  static const fertileText = Color(0xFF5B3AA6);
  static const luteal = Color(0xFFEFEAF3);
  static const lutealText = Color(0xFF5D5767);

  /// Warna fase pada cincin siklus.
  static const fol = Color(0xFF5FCFFF);
  static const subur = Color(0xFF8F73FF);
  static const lutealCincin = Color(0xFFD9CFFF);
  static const ovulasi = Color(0xFF6A4CF0);

  /// Dompet bersama dan belanja.
  static const mint = Color(0xFF2EE6A8);
  static const mintSoft = Color(0xFFC8F9E6);
  static const mintTitik = Color(0xFFC8EFE6);
  static const mintText = Color(0xFF0B6B4F);
  static const mintAngka = Color(0xFF14B884);

  /// Kotak centang yang belum dicentang dan teks yang dicoret.
  static const garisCentang = Color(0xFFCFC7D6);
  static const teksCoret = Color(0xFFB0AAB8);

  /// Empat titik konfeti pada latar.
  static const konfeti = <Color>[
    Color(0xFFFFEAA6),
    Color(0xFFC9EFFF),
    Color(0xFFFFD0E0),
    Color(0xFFDDD2FF),
  ];
}

/// Warna kategori pengeluaran: ikon pekat di atas ubin lembut.
abstract final class KategoriWarna {
  static const _peta = <String, ({Color kuat, Color lembut, IconData ikon})>{
    'Makan': (
      kuat: Color(0xFFB0124D),
      lembut: Color(0xFFFFD6E5),
      ikon: Icons.restaurant_outlined,
    ),
    'Belanja': (
      kuat: Color(0xFF5B3DF0),
      lembut: Color(0xFFE4DCFF),
      ikon: Icons.shopping_bag_outlined,
    ),
    'Transport': (
      kuat: Color(0xFF06609A),
      lembut: Color(0xFFD2F1FF),
      ikon: Icons.directions_car_outlined,
    ),
    'Tagihan': (
      kuat: Color(0xFF0A6A4E),
      lembut: Color(0xFFC8F9E6),
      ikon: Icons.bolt_outlined,
    ),
    'Hiburan': (
      kuat: Color(0xFF8A4F00),
      lembut: Color(0xFFFFF0B8),
      ikon: Icons.tv_outlined,
    ),
    'Lainnya': (
      kuat: Color(0xFF6B6475),
      lembut: Color(0xFFFFF1D6),
      ikon: Icons.sell_outlined,
    ),
  };

  static ({Color kuat, Color lembut, IconData ikon}) untuk(String nama) =>
      _peta[nama] ?? _peta['Lainnya']!;
}

/// Warna untuk mark grafik (layar 12), disalin dari prototipe v4.
///
/// Warna mengikuti orangnya, bukan peringkatnya: pencatat siklus selalu biru,
/// pasangannya selalu ungu, dompet selalu mint. Batangnya cerah dan kontrasnya
/// rendah terhadap putih, jadi setiap segmen WAJIB membawa nama dan nilainya
/// sebagai teks (varian `...Teks`), bukan warna saja.
abstract final class ChartColors {
  static const pencatat = Color(0xFF3CC8FF);
  static const pencatatTeks = Color(0xFF06609A);
  static const pasangan = Color(0xFF8F73FF);
  static const pasanganTeks = Color(0xFF5B3DF0);
  static const dompet = Color(0xFF2EE6A8);
  static const dompetTeks = Color(0xFF0A6A4E);

  /// Garis bulan ini dan batang minggu terbesar.
  static const batang = BerduaColors.rose;

  /// Batang minggu lainnya.
  static const batangLain = Color(0xFFA48BFF);

  /// Pembanding bulan lalu dibuat recessive: ia latar, bukan subjek.
  static const pembanding = Color(0xFFB0AAB8);
}

/// Spasi: 4 · 8 · 12 · 16 · 20 · 24.
abstract final class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;

  /// Tepi layar 16, jarak antarkartu 12.
  static const screenEdge = 16.0;
  static const betweenCards = 12.0;
}

/// Radius. Semua sudut membulat; tidak ada sudut tajam.
abstract final class Radii {
  /// Tombol kembali dan label kecil.
  static const chip = 12.0;

  /// Chip dan isi segmen.
  static const pilihan = 13.0;

  /// Input, wadah segmen, dan tombol sekunder.
  static const input = 18.0;

  /// Tombol utama, FAB, dan kartu daftar.
  static const button = 20.0;

  static const card = 22.0;
  static const cardBesar = 24.0;

  /// Kartu pink.
  static const cardWhite = 28.0;

  /// Bottom sheet — hanya sudut atas.
  static const sheet = 32.0;
}

/// Tinggi kontrol.
abstract final class Sizes {
  static const primaryButton = 60.0;
  static const input = 54.0;
  static const segment = 38.0;
  static const bottomNav = 64.0;
  static const fab = 60.0;
  static const backButton = 40.0;
  static const progressBar = 10.0;
  static const calendarCell = 40.0;

  /// Tebal garis tinta pada kartu, input, dan tombol.
  static const garis = 2.0;

  static const icon = 22.0;
  static const iconSmall = 20.0;

  /// Aksesibilitas: area sentuh minimal 44x44 dp.
  static const minTouchTarget = 44.0;
}

/// Elevasi. Versi fun memakai bayangan keras tanpa blur, seperti stiker.
abstract final class Shadows {
  /// Kartu: 0 4 0 tinta.
  static const kartu = <BoxShadow>[
    BoxShadow(color: BerduaColors.ink, offset: Offset(0, 4)),
  ];

  /// Tombol utama: 0 5 0 tinta; saat ditekan turun jadi 0 2 0.
  static const tombol = <BoxShadow>[
    BoxShadow(color: BerduaColors.ink, offset: Offset(0, 5)),
  ];
  static const tombolDitekan = <BoxShadow>[
    BoxShadow(color: BerduaColors.ink, offset: Offset(0, 2)),
  ];

  /// Tombol sekunder putih: 0 3 0 tinta.
  static const sekunder = <BoxShadow>[
    BoxShadow(color: BerduaColors.ink, offset: Offset(0, 3)),
  ];

  /// FAB: 0 10 24 pink 30%.
  static const action = <BoxShadow>[
    BoxShadow(
      color: Color(0x4DE2558F),
      offset: Offset(0, 10),
      blurRadius: 24,
    ),
  ];

  /// Toast: 0 12 30 ungu 18%.
  static const frame = <BoxShadow>[
    BoxShadow(
      color: Color(0x2E5A3C78),
      offset: Offset(0, 12),
      blurRadius: 30,
    ),
  ];
}

/// Kategori pengeluaran bawaan (§5.2) dan gejala siklus (§5.3), supaya daftar
/// di aplikasi tidak pernah menyimpang dari spesifikasi.
abstract final class BerduaEnums {
  static const categories = <String>[
    'Makan',
    'Belanja',
    'Transport',
    'Tagihan',
    'Hiburan',
    'Lainnya',
  ];

  static const symptoms = <String>[
    'kram',
    'lelah',
    'kembung',
    'sensitif',
    'sakit kepala',
    'jerawat',
    'ngidam manis',
  ];

  static const eventTypes = <String>[
    'Ulang tahun',
    'Anniversary',
    'Tagihan',
    'Kencan',
    'Lainnya',
  ];
}
