"""Satu sumber untuk pilihan catatan harian siklus.

Menulis daftar yang sama ke dua tempat supaya tidak pernah berbeda:
  - Flutter : lib/features/siklus/katalog_catatan.dart (kunci, label, emoji)
  - Laravel : konstanta validasi di CyclePredictor::SYMPTOMS,
              CycleDayLog::MOODS dan CycleDayLog::CERVICAL_MUCUS

Pakai:
  python tool/katalog_catatan.py <folder-backend>

Kunci yang sudah pernah dipakai JANGAN diganti: catatan lama menyimpannya.
"""
import re
import sys

# (kunci, label, emoji)
ALIRAN = [
    ('sedikit', 'Sedikit', '💧'),
    ('sedang', 'Sedang', '🩸'),
    ('banyak', 'Banyak', '💦'),
    ('sangat banyak', 'Sangat banyak', '🌊'),
]

PENGAMAN = [
    ('pengaman', 'Terlindung', '🛡️'),
    ('tanpa pengaman', 'Tak terlindung', '🚫'),
    ('tidak', 'Tidak melakukan', '💤'),
]

PUNCAK = [
    ('ya', 'Ya', '😍'),
    ('tidak', 'Tak ada', '😕'),
]

ENERGI = [
    ('rendah', 'Rendah', '😴'),
    ('sedang', 'Sedang', '🔋'),
    ('tinggi', 'Tinggi', '💪'),
    ('berenergi', 'Berenergi', '⚡'),
]

SADARI = [
    ('baik', 'Semuanya baik', '✅'),
    ('gembung', 'Gembung', '🎈'),
    ('benjolan', 'Benjolan', '🔘'),
    ('lesung', 'Lesung', '🕳️'),
    ('kemerahan', 'Kulit kemerahan', '🔴'),
    ('puting merekah', 'Puting merekah', '🩹'),
    ('nyeri', 'Nyeri', '⚡'),
    ('cairan', 'Cairan dari puting', '💧'),
]

UJI_OVULASI = [
    ('positif', 'Positif', '➕'),
    ('negatif', 'Negatif', '➖'),
]

TES_HAMIL = [
    ('positif', 'Positif', '➕'),
    ('samar', 'Garis samar', '〰️'),
    ('negatif', 'Negatif', '➖'),
]

LENDIR = [
    ('kering', 'Kering', '🏜️'),
    ('lengket', 'Lengket', '🍯'),
    ('krim', 'Seperti krim/keruh', '🥛'),
    ('encer', 'Encer', '💧'),
    ('putih telur', 'Putih telur', '🥚'),
    ('kepala susu', 'Seperti kepala susu', '🧀'),
    ('hijau', 'Hijau', '🟢'),
    ('ada darah', 'Ada darah', '🩸'),
    ('berbau busuk', 'Berbau busuk', '👃'),
]

GEJALA = [
    ('Kepala', [
        ('sakit kepala', 'Sakit kepala', '🤕'),
        ('migrain', 'Migrain', '😖'),
        ('pusing', 'Pusing', '💫'),
        ('jerawat', 'Jerawatan', '🍓'),
        ('panas dingin', 'Panas dingin', '🥶'),
    ]),
    ('Tubuh', [
        ('sakit leher', 'Sakit leher', '🦒'),
        ('nyeri bahu', 'Nyeri bahu', '💪'),
        ('kekenyalan payudara', 'Payudara kencang', '🫧'),
        ('nyeri payudara', 'Payudara sensitif', '🌸'),
        ('nyeri punggung', 'Nyeri punggung', '🧍'),
        ('sakit pinggang', 'Sakit pinggang', '🪑'),
        ('pegal linu', 'Pegal linu', '🦴'),
        ('nyeri otot', 'Nyeri otot', '🥩'),
        ('influenza', 'Influenza', '🤧'),
        ('tidak enak badan', 'Tidak enak badan', '🤒'),
        ('kram otot', 'Kram otot', '⚡'),
        ('menggigil', 'Menggigil', '❄️'),
        ('gatal', 'Gatal', '🦟'),
        ('ruam', 'Ruam', '🔴'),
        ('keringat malam', 'Keringat malam', '💦'),
        ('muka memerah', 'Muka memerah', '😳'),
        ('berat naik', 'Berat naik', '⚖️'),
        ('pms', 'PMS', '🌀'),
    ]),
    ('Serviks', [
        ('nyeri panggul', 'Nyeri panggul', '🍐'),
        ('bercak', 'Bercak', '🩸'),
        ('iritasi', 'Iritasi', '🔥'),
        ('keputihan', 'Keputihan', '💧'),
    ]),
    ('Perut', [
        ('kram', 'Kram perut', '🌙'),
        ('kembung', 'Kembung', '🎈'),
        ('sembelit', 'Sembelit', '💩'),
        ('diare', 'Diare', '🧻'),
        ('mual', 'Mual', '🤢'),
        ('nyeri lambung', 'Nyeri lambung', '🌶️'),
        ('sering kentut', 'Kentut-kentut', '💨'),
        ('lapar', 'Lapar', '🍗'),
        ('ngidam manis', 'Mengidam', '🍰'),
        ('nyeri ovulasi', 'Nyeri ovulasi', '🥚'),
    ]),
    ('Mental', [
        ('cemas', 'Cemas', '😰'),
        ('susah tidur', 'Sulit tidur', '🐼'),
        ('stres', 'Stres', '🏋️'),
        ('mudah murung', 'Mudah murung', '😞'),
        ('tegang', 'Tegang', '⚠️'),
        ('sensitif', 'Mudah tersinggung', '😤'),
        ('sulit konsentrasi', 'Sulit konsentrasi', '🔄'),
        ('lelah', 'Kelelahan', '🥱'),
        ('linglung', 'Linglung', '❓'),
    ]),
]

SUASANA = [
    ('senang', 'Senang', '😃'),
    ('tenang', 'Tenang', '🧘'),
    ('riang', 'Riang', '😊'),
    ('santai', 'Santai', '😌'),
    ('nyaman', 'Nyaman', '☺️'),
    ('puas', 'Puas', '😚'),
    ('damai', 'Damai', '😇'),
    ('ikhlas', 'Ikhlas', '🙏'),
    ('optimistis', 'Optimistis', '😁'),
    ('percaya diri', 'Percaya diri', '😄'),
    ('antusias', 'Antusias', '🤩'),
    ('dinamis', 'Dinamis', '😜'),
    ('lincah', 'Lincah', '😋'),
    ('sorak-sorai', 'Sorak-sorai', '🥳'),
    ('jatuh cinta', 'Jatuh cinta', '🥰'),
    ('berahi', 'Berahi', '😍'),
    ('menggoda', 'Menggoda', '😏'),
    ('seksi', 'Seksi', '💋'),
    ('normal', 'Normal', '🙂'),
    ('netral', 'Netral', '😶'),
    ('malas', 'Bermalas-malasan', '😪'),
    ('bosan', 'Bosan', '🥱'),
    ('lelah', 'Lelah', '😫'),
    ('sakit', 'Sakit', '🤒'),
    ('emosional', 'Emosional', '🎭'),
    ('jengkel', 'Jengkel', '😒'),
    ('dongkol', 'Dongkol', '😤'),
    ('pemarah', 'Pemarah', '😡'),
    ('murka', 'Murka', '🤬'),
    ('kasar', 'Kasar', '👿'),
    ('jahat', 'Jahat', '😈'),
    ('frustrasi', 'Frustrasi', '😩'),
    ('tidak sabar', 'Tidak sabar', '⏰'),
    ('sedih', 'Sedih', '😢'),
    ('berduka', 'Berduka', '😭'),
    ('kecewa', 'Kecewa', '😞'),
    ('murung', 'Murung', '☹️'),
    ('muram', 'Muram', '🙁'),
    ('depresi', 'Depresi', '😔'),
    ('sengsara', 'Sengsara', '😖'),
    ('kesepian', 'Kesepian', '🥺'),
    ('sepi', 'Sepi', '😐'),
    ('cemas', 'Cemas', '😰'),
    ('khawatir', 'Khawatir', '😟'),
    ('panik', 'Panik', '😱'),
    ('tegang', 'Tegang', '😬'),
    ('stres', 'Stres', '🤯'),
    ('tidak aman', 'Tidak aman', '😨'),
    ('cemburu', 'Cemburu', '😑'),
    ('curiga', 'Curigaan', '🤨'),
    ('malu', 'Malu', '😳'),
    ('pemalu', 'Pemalu', '🙈'),
    ('suka berahasia', 'Suka berahasia', '🤫'),
    ('cuek', 'Cuek', '🙄'),
    ('sombong', 'Sombong', '💅'),
    ('narsis', 'Narsis', '😎'),
    ('asertif', 'Asertif', '🧐'),
    ('tekun', 'Tekun', '🤓'),
    ('saleh', 'Saleh', '🤲'),
    ('cerewet', 'Cerewet', '🗣️'),
    ('konyol', 'Konyol', '🐷'),
    ('usil', 'Usil', '😝'),
    ('aneh', 'Aneh', '🤪'),
    ('pelupa', 'Pelupa', '🤔'),
    ('terheran-heran', 'Terheran-heran', '😮'),
    ('terkejut', 'Terkejut', '😲'),
]


def periksa(nama, daftar):
    kunci = [k for k, _, _ in daftar]
    ganda = {k for k in kunci if kunci.count(k) > 1}
    assert not ganda, (nama, ganda)


def dart_butir(daftar, indent):
    return ''.join(f"{indent}Butir('{k}', '{l}', '{e}'),\n" for k, l, e in daftar)


def tulis_dart(path):
    semua_gejala = [b for _, daftar in GEJALA for b in daftar]
    periksa('gejala', semua_gejala)

    s = """// DIBUAT OTOMATIS oleh tool/katalog_catatan.py. Jangan diubah langsung:
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
"""
    for nama, daftar in [
        ('aliran', ALIRAN), ('pengaman', PENGAMAN), ('puncak', PUNCAK), ('energi', ENERGI),
        ('sadari', SADARI), ('ujiOvulasi', UJI_OVULASI), ('tesHamil', TES_HAMIL),
        ('lendir', LENDIR), ('suasana', SUASANA),
    ]:
        periksa(nama, daftar)
        s += f"  static const {nama} = <Butir>[\n{dart_butir(daftar, '    ')}  ];\n\n"

    s += "  static const gejala = <KelompokButir>[\n"
    for judul, daftar in GEJALA:
        s += f"    KelompokButir('{judul}', [\n{dart_butir(daftar, '      ')}    ]),\n"
    s += """  ];

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
"""
    open(path, 'w', encoding='utf-8', newline='\n').write(s)


def php_daftar(kunci, indent='        '):
    baris, kini = [], indent
    for k in kunci:
        potong = f"'{k}', "
        if len(kini) + len(potong) > 100:
            baris.append(kini.rstrip())
            kini = indent
        kini += potong
    baris.append(kini.rstrip())
    return '\n'.join(baris)


def ganti_konstanta(path, nama, kunci):
    s = open(path, encoding='utf-8', newline='').read()
    pola = re.compile(r'(public const ' + nama + r' = \[)(.*?)(\n?\s*\];)', re.S)
    assert len(pola.findall(s)) == 1, (path, nama)
    s = pola.sub(lambda m: m.group(1) + '\n' + php_daftar(kunci) + '\n    ];', s)
    open(path, 'w', encoding='utf-8', newline='').write(s)


if __name__ == '__main__':
    tulis_dart('lib/features/siklus/katalog_catatan.dart')

    if len(sys.argv) > 1:
        backend = sys.argv[1].rstrip('/\\')
        ganti_konstanta(backend + '/app/Support/CyclePredictor.php', 'SYMPTOMS',
                        [k for _, daftar in GEJALA for k, _, _ in daftar])
        ganti_konstanta(backend + '/app/Models/CycleDayLog.php', 'MOODS', [k for k, _, _ in SUASANA])
        ganti_konstanta(backend + '/app/Models/CycleDayLog.php', 'CERVICAL_MUCUS', [k for k, _, _ in LENDIR])

    print('ok')
