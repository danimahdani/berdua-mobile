// DIBUAT OTOMATIS oleh tool/katalog_catatan.py. Jangan diubah langsung:
// ubah daftarnya di skrip itu lalu jalankan ulang, supaya pilihan di aplikasi
// dan validasi di backend tetap sama.
// dart format off

/// Satu pilihan: kunci yang disimpan backend, label di layar, dan ikonnya.
class Butir {
  const Butir(this.kunci, this.label, this.emoji);

  final String kunci;
  final String label;
  final String emoji;
}

/// Pilihan yang dikelompokkan di bawah satu judul, mis. gejala "Perut".
class KelompokButir {
  const KelompokButir(this.judul, this.butir);

  final String judul;
  final List<Butir> butir;
}

abstract final class Katalog {
  static const aliran = <Butir>[
    Butir('sedikit', 'Sedikit', '💧'),
    Butir('sedang', 'Sedang', '🩸'),
    Butir('banyak', 'Banyak', '💦'),
    Butir('sangat banyak', 'Sangat banyak', '🌊'),
  ];

  static const pengaman = <Butir>[
    Butir('pengaman', 'Terlindung', '🛡️'),
    Butir('tanpa pengaman', 'Tak terlindung', '🚫'),
    Butir('tidak', 'Tidak melakukan', '💤'),
  ];

  static const puncak = <Butir>[
    Butir('ya', 'Ya', '😍'),
    Butir('tidak', 'Tak ada', '😕'),
  ];

  static const energi = <Butir>[
    Butir('rendah', 'Rendah', '😴'),
    Butir('sedang', 'Sedang', '🔋'),
    Butir('tinggi', 'Tinggi', '💪'),
    Butir('berenergi', 'Berenergi', '⚡'),
  ];

  static const sadari = <Butir>[
    Butir('baik', 'Semuanya baik', '✅'),
    Butir('gembung', 'Gembung', '🎈'),
    Butir('benjolan', 'Benjolan', '🔘'),
    Butir('lesung', 'Lesung', '🕳️'),
    Butir('kemerahan', 'Kulit kemerahan', '🔴'),
    Butir('puting merekah', 'Puting merekah', '🩹'),
    Butir('nyeri', 'Nyeri', '⚡'),
    Butir('cairan', 'Cairan dari puting', '💧'),
  ];

  static const ujiOvulasi = <Butir>[
    Butir('positif', 'Positif', '➕'),
    Butir('negatif', 'Negatif', '➖'),
  ];

  static const tesHamil = <Butir>[
    Butir('positif', 'Positif', '➕'),
    Butir('samar', 'Garis samar', '〰️'),
    Butir('negatif', 'Negatif', '➖'),
  ];

  static const lendir = <Butir>[
    Butir('kering', 'Kering', '🏜️'),
    Butir('lengket', 'Lengket', '🍯'),
    Butir('krim', 'Seperti krim/keruh', '🥛'),
    Butir('encer', 'Encer', '💧'),
    Butir('putih telur', 'Putih telur', '🥚'),
    Butir('kepala susu', 'Seperti kepala susu', '🧀'),
    Butir('hijau', 'Hijau', '🟢'),
    Butir('ada darah', 'Ada darah', '🩸'),
    Butir('berbau busuk', 'Berbau busuk', '👃'),
  ];

  static const suasana = <Butir>[
    Butir('senang', 'Senang', '😃'),
    Butir('tenang', 'Tenang', '🧘'),
    Butir('riang', 'Riang', '😊'),
    Butir('santai', 'Santai', '😌'),
    Butir('nyaman', 'Nyaman', '☺️'),
    Butir('puas', 'Puas', '😚'),
    Butir('damai', 'Damai', '😇'),
    Butir('ikhlas', 'Ikhlas', '🙏'),
    Butir('optimistis', 'Optimistis', '😁'),
    Butir('percaya diri', 'Percaya diri', '😄'),
    Butir('antusias', 'Antusias', '🤩'),
    Butir('dinamis', 'Dinamis', '😜'),
    Butir('lincah', 'Lincah', '😋'),
    Butir('sorak-sorai', 'Sorak-sorai', '🥳'),
    Butir('jatuh cinta', 'Jatuh cinta', '🥰'),
    Butir('berahi', 'Berahi', '😍'),
    Butir('menggoda', 'Menggoda', '😏'),
    Butir('seksi', 'Seksi', '💋'),
    Butir('normal', 'Normal', '🙂'),
    Butir('netral', 'Netral', '😶'),
    Butir('malas', 'Bermalas-malasan', '😪'),
    Butir('bosan', 'Bosan', '🥱'),
    Butir('lelah', 'Lelah', '😫'),
    Butir('sakit', 'Sakit', '🤒'),
    Butir('emosional', 'Emosional', '🎭'),
    Butir('jengkel', 'Jengkel', '😒'),
    Butir('dongkol', 'Dongkol', '😤'),
    Butir('pemarah', 'Pemarah', '😡'),
    Butir('murka', 'Murka', '🤬'),
    Butir('kasar', 'Kasar', '👿'),
    Butir('jahat', 'Jahat', '😈'),
    Butir('frustrasi', 'Frustrasi', '😩'),
    Butir('tidak sabar', 'Tidak sabar', '⏰'),
    Butir('sedih', 'Sedih', '😢'),
    Butir('berduka', 'Berduka', '😭'),
    Butir('kecewa', 'Kecewa', '😞'),
    Butir('murung', 'Murung', '☹️'),
    Butir('muram', 'Muram', '🙁'),
    Butir('depresi', 'Depresi', '😔'),
    Butir('sengsara', 'Sengsara', '😖'),
    Butir('kesepian', 'Kesepian', '🥺'),
    Butir('sepi', 'Sepi', '😐'),
    Butir('cemas', 'Cemas', '😰'),
    Butir('khawatir', 'Khawatir', '😟'),
    Butir('panik', 'Panik', '😱'),
    Butir('tegang', 'Tegang', '😬'),
    Butir('stres', 'Stres', '🤯'),
    Butir('tidak aman', 'Tidak aman', '😨'),
    Butir('cemburu', 'Cemburu', '😑'),
    Butir('curiga', 'Curigaan', '🤨'),
    Butir('malu', 'Malu', '😳'),
    Butir('pemalu', 'Pemalu', '🙈'),
    Butir('suka berahasia', 'Suka berahasia', '🤫'),
    Butir('cuek', 'Cuek', '🙄'),
    Butir('sombong', 'Sombong', '💅'),
    Butir('narsis', 'Narsis', '😎'),
    Butir('asertif', 'Asertif', '🧐'),
    Butir('tekun', 'Tekun', '🤓'),
    Butir('saleh', 'Saleh', '🤲'),
    Butir('cerewet', 'Cerewet', '🗣️'),
    Butir('konyol', 'Konyol', '🐷'),
    Butir('usil', 'Usil', '😝'),
    Butir('aneh', 'Aneh', '🤪'),
    Butir('pelupa', 'Pelupa', '🤔'),
    Butir('terheran-heran', 'Terheran-heran', '😮'),
    Butir('terkejut', 'Terkejut', '😲'),
  ];

  static const gejala = <KelompokButir>[
    KelompokButir('Kepala', [
      Butir('sakit kepala', 'Sakit kepala', '🤕'),
      Butir('migrain', 'Migrain', '😖'),
      Butir('pusing', 'Pusing', '💫'),
      Butir('jerawat', 'Jerawatan', '🍓'),
      Butir('panas dingin', 'Panas dingin', '🥶'),
    ]),
    KelompokButir('Tubuh', [
      Butir('sakit leher', 'Sakit leher', '🦒'),
      Butir('nyeri bahu', 'Nyeri bahu', '💪'),
      Butir('kekenyalan payudara', 'Payudara kencang', '🫧'),
      Butir('nyeri payudara', 'Payudara sensitif', '🌸'),
      Butir('nyeri punggung', 'Nyeri punggung', '🧍'),
      Butir('sakit pinggang', 'Sakit pinggang', '🪑'),
      Butir('pegal linu', 'Pegal linu', '🦴'),
      Butir('nyeri otot', 'Nyeri otot', '🥩'),
      Butir('influenza', 'Influenza', '🤧'),
      Butir('tidak enak badan', 'Tidak enak badan', '🤒'),
      Butir('kram otot', 'Kram otot', '⚡'),
      Butir('menggigil', 'Menggigil', '❄️'),
      Butir('gatal', 'Gatal', '🦟'),
      Butir('ruam', 'Ruam', '🔴'),
      Butir('keringat malam', 'Keringat malam', '💦'),
      Butir('muka memerah', 'Muka memerah', '😳'),
      Butir('berat naik', 'Berat naik', '⚖️'),
      Butir('pms', 'PMS', '🌀'),
    ]),
    KelompokButir('Serviks', [
      Butir('nyeri panggul', 'Nyeri panggul', '🍐'),
      Butir('bercak', 'Bercak', '🩸'),
      Butir('iritasi', 'Iritasi', '🔥'),
      Butir('keputihan', 'Keputihan', '💧'),
    ]),
    KelompokButir('Perut', [
      Butir('kram', 'Kram perut', '🌙'),
      Butir('kembung', 'Kembung', '🎈'),
      Butir('sembelit', 'Sembelit', '💩'),
      Butir('diare', 'Diare', '🧻'),
      Butir('mual', 'Mual', '🤢'),
      Butir('nyeri lambung', 'Nyeri lambung', '🌶️'),
      Butir('sering kentut', 'Kentut-kentut', '💨'),
      Butir('lapar', 'Lapar', '🍗'),
      Butir('ngidam manis', 'Mengidam', '🍰'),
      Butir('nyeri ovulasi', 'Nyeri ovulasi', '🥚'),
    ]),
    KelompokButir('Mental', [
      Butir('cemas', 'Cemas', '😰'),
      Butir('susah tidur', 'Sulit tidur', '🐼'),
      Butir('stres', 'Stres', '🏋️'),
      Butir('mudah murung', 'Mudah murung', '😞'),
      Butir('tegang', 'Tegang', '⚠️'),
      Butir('sensitif', 'Mudah tersinggung', '😤'),
      Butir('sulit konsentrasi', 'Sulit konsentrasi', '🔄'),
      Butir('lelah', 'Kelelahan', '🥱'),
      Butir('linglung', 'Linglung', '❓'),
    ]),
  ];

  /// Semua gejala tanpa kelompoknya.
  static final semuaGejala = <Butir>[
    for (final kelompok in gejala) ...kelompok.butir,
  ];

  /// Butir dengan kunci itu, atau null kalau tidak ada di daftar (mis. kunci
  /// lama yang sudah dihapus).
  static Butir? cari(List<Butir> daftar, String? kunci) {
    for (final butir in daftar) {
      if (butir.kunci == kunci) return butir;
    }

    return null;
  }

  /// Label untuk kunci itu; kuncinya sendiri kalau tidak dikenal.
  static String label(List<Butir> daftar, String kunci) =>
      cari(daftar, kunci)?.label ?? kunci;
}
