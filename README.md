# Berdua

Aplikasi Android untuk mencatat keuangan, siklus haid, dan rencana bersama pasangan.

Spesifikasi lengkap ada di dokumen proyek "Berdua" (Bagian A produk, B design
system, C inventaris 23 layar). Nomor `§` di komentar kode mengacu ke bagian
dokumen itu.

## Susunan

Kode terbagi dua filesystem, dan itu disengaja:

| Bagian | Lokasi | Alasan |
| --- | --- | --- |
| Flutter | `Documents\personal project\berdua` (Windows) | Android SDK, emulator dan toolchain-nya hidup di sisi Windows |
| Laravel | `~/berdua-backend` (WSL Ubuntu-22.04) | ext4; PHP, Composer dan database ada di sini |

Jangan menaruh salah satunya di `/mnt/c` lalu menjalankannya dari sisi
seberang: I/O lintas filesystem lewat 9p lambat dan file watcher-nya tidak
reliable, sehingga hot reload dan `artisan serve` sering tidak mendeteksi
perubahan.

## Database

PostgreSQL 14 di dalam WSL. Database dan role-nya terpisah dari proyek lain:

```sql
CREATE ROLE berdua WITH LOGIN PASSWORD '...' CREATEDB;
CREATE DATABASE berdua OWNER berdua ENCODING UTF8;
```

Kredensialnya ada di `.env` (`DB_CONNECTION=pgsql`, port 5432). Kata sandi di
sana hanya untuk pengembangan lokal — ganti sebelum dipakai di tempat lain.

```bash
php artisan migrate          # 11 migrasi
php artisan migrate:fresh    # mulai dari nol
```

Test tetap memakai SQLite in-memory (lihat `phpunit.xml`), jadi `php artisan
test` cepat dan tidak menyentuh data PostgreSQL.

Catatan yang mudah menjebak: kolom bertipe `date` disimpan Eloquent sebagai
`Y-m-d 00:00:00`, sehingga `where('period_start', '2026-10-20')` tidak pernah
cocok di SQLite. Pakai `whereDate()` — portabel di kedua basis data.

## Menjalankan

Backend, dari dalam WSL:

```bash
cd ~/berdua-backend
php artisan serve --host=0.0.0.0 --port=8000
```

`--host=0.0.0.0` wajib. Kalau server bind ke `127.0.0.1`, dia hanya bisa
diakses dari dalam WSL dan aplikasi gagal menyambung.

Aplikasi, dari Windows:

```bash
flutter run -d chrome      # paling cepat untuk iterasi
flutter run -d <emulator>  # target sebenarnya
```

## Alamat backend per target

`lib/core/env.dart` memilih alamat ini sendiri:

| Target | Alamat |
| --- | --- |
| Chrome / Windows | `localhost:8000` |
| Emulator Android | `10.0.2.2:8000` |
| HP fisik via USB | `localhost:8000` + `adb reverse tcp:8000 tcp:8000` |
| HP fisik via Wi-Fi | IP LAN Windows |

Timpa kapan saja:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000
```

HP fisik lewat Wi-Fi perlu `netsh interface portproxy` karena WSL di mesin ini
masih mode NAT. Alternatif yang lebih bersih: buat `%USERPROFILE%\.wslconfig`
berisi `[wsl2]` dan `networkingMode=mirrored`, lalu `wsl --shutdown`. Mode itu
kadang bentrok dengan Docker Desktop dan beberapa client VPN; hapus filenya
untuk kembali ke NAT.

## Masuk ke aplikasi

Hanya dua nomor yang terdaftar yang bisa masuk (§5.1). Daftarnya ada di
`.env` backend:

```
BERDUA_PHONE_A / BERDUA_EMAIL_A
BERDUA_PHONE_B / BERDUA_EMAIL_B
BERDUA_FIXED_CODE=123456
```

Selama `BERDUA_FIXED_CODE` terisi, kode itulah yang diterima dan tidak ada
email yang dikirim. **Kosongkan di produksi.**

## Yang sudah jalan

- Layar 01-05: masuk dengan nomor + kode email, pemasangan otomatis dua akun,
  onboarding, kode undangan
- Layar 06: beranda — satu endpoint yang menggabungkan saldo, siklus, belanja,
  to-do, jadwal terdekat dan tabungan
- Layar 07: notifikasi dan "Tandai semua dibaca"
- Layar 08-11: uang bersama — catat, ubah, hapus, pelunasan, dompet bersama
- Layar 12: laporan bulanan — total, anggaran, pembagian pembayar, per kategori,
  tren kumulatif mingguan
- Layar 13-15: siklus — kalender berwarna fase, gejala harian, riwayat, tips
  dukungan untuk pasangan, dan seluruh aturan privasi §5.3
- Layar 16-22: bersama — belanja, to-do, tabungan + detail, jadwal, jurnal
- Design system §13-§17 sebagai token Dart (`lib/theme/`)

Seluruh 23 layar Bagian C sudah punya endpoint dan tampilannya.

## Yang belum

- **Push notification (FCM).** Notifikasi sudah tercatat di `app_notifications`
  dan tampil di layar 07; yang belum ada hanya pengirimannya ke perangkat.
- **Pengingat terjadwal.** To-do dan jadwal menyimpan `due_date` dan
  `remind_before`, tetapi belum ada pekerjaan yang membacanya dan mengirim
  pengingat pada waktunya.
- **Sinkronisasi realtime <3 detik dan mode offline (§7).** Firestore dulu
  memberi ini gratis; dengan Laravel butuh Reverb atau polling, dan cache lokal
  dengan antrean sinkronisasi.
- **Ekspor PDF** di layar 12 (ada di prototipe, tidak ada di spesifikasi).

**Tips dukungan per fase belum ditinjau tenaga kesehatan.** Teksnya ada di
`app/Support/CycleTips.php` dan dikirim dengan penanda `perlu_ditinjau: true`,
mengikuti pertanyaan terbuka §11 dokumen proyek.

## Keadaan memuat

Setiap perpindahan yang menunggu proses menampilkan **skeleton**, bukan spinner
bundar. Kerangkanya ada di `lib/widgets/skeleton.dart` dan bentuknya meniru
tata letak layar aslinya — tinggi kartu, jumlah baris dan posisi judul sama —
supaya isinya tinggal mengisi kerangka, bukan melompat.

Tiga aturan yang dipegang:

1. **Kerangka hanya untuk pemuatan pertama.** Saat menyegarkan setelah aksi
   (menambah barang, mencentang tugas), isi lama dibiarkan di layar.
   `MuatanCubit.segarkan()` (`lib/core/muatan.dart`) sengaja tidak memancarkan
   `Muatan.memuat()`; hanya `muat()` — pemuatan pertama dan "Coba lagi" — yang
   melakukannya. Kalau tidak, penambahan sekecil apa pun membuat seluruh
   daftar berkedip.
2. **Aksi pada elemen yang sudah terlihat memakai indikator di elemen itu**,
   bukan kerangka. `TombolUtama(memuat: true)` menampilkan spinner di tempat
   labelnya — itu satu-satunya `CircularProgressIndicator` yang tersisa.
3. **Kerangka tidak bisa digulir** (`NeverScrollableScrollPhysics`), karena
   belum ada apa pun di sana.

Kilau berhenti sendiri kalau pengguna menyalakan "hilangkan animasi" di
sistem (§7 aksesibilitas); kerangkanya tetap tampil, hanya diam.

## Warna grafik

§13 menyediakan dua varian per peran: isian pastel dan varian teks yang lebih
pekat. Untuk avatar dan chip, isian pastel benar. **Sebagai mark grafik di atas
latar putih, isian pastel tidak layak** — divalidasi, bukan dikira-kira:

| Palet | Hasil |
| --- | --- |
| Isian pastel (`#BFE6F7`, `#E3D1FB`, `#9FE0D2`) | GAGAL. Dinda vs Raka hanya ΔE 1,7 (deutan) dan 7,0 (penglihatan normal, ambang 15). Kontras 1,3:1 |
| Varian teks (`#2F8FC0`, `#6B46B8`, `#2AA595`) | LOLOS semua. Pasangan terdekat ΔE 14,0 (deutan), 19,1 (normal) |

Karena itu grafik memakai varian teks lewat `ChartColors` di `lib/theme/tokens.dart`.
Mint tetap 2,96:1 terhadap latar, jadi setiap segmen wajib membawa label nilai
yang terlihat — bukan warna saja.

## Data contoh

Supaya layar 06 ada isinya tanpa mengetik manual:

```bash
cd ~/berdua-backend
php artisan db:seed --class=DemoSeeder
```

Seeder ini idempoten dan butuh kedua akun sudah pernah masuk. Dia membuat
6 siklus ke belakang (rata-rata 28,8 hari, hari ini jatuh di fase luteal),
beberapa transaksi, belanja, to-do, tabungan dan jadwal.

## Postman

Koleksi ada di repo backend:

```
\\wsl.localhost\Ubuntu-22.04\home\danimahdani\berdua-backend\docs\Berdua.postman_collection.json
```

Import lewat Postman → Import → File. Isinya 24 request dalam 5 folder,
mencakup seluruh 19 rute API.

Jalankan **Auth > Minta kode** lalu **Auth > Verifikasi kode** — token Sanctum
otomatis tersimpan ke variabel koleksi dan dipakai request lain. Ganti
`base_url` jadi `http://10.0.2.2:8000` kalau menguji dari emulator.

Ingat: minta kode dibatasi 5 kali per nomor per 10 menit. Kalau kena 429,
jalankan `php artisan cache:clear`.

## Catatan: tiga pertentangan di dokumen

1. §9 menulis `ColorScheme.dark`, tetapi seluruh palet §13 adalah tema terang.
   Yang dipakai di sini **terang**, karena itulah yang digambar di prototipe.
2. §5.1 menyebut pemasangan **otomatis** oleh backend, tetapi juga
   mendefinisikan kode undangan `BRD-0000` 48 jam. Yang dipakai: auto-pair
   sebagai jalur utama, kode undangan tetap diterbitkan dan ditampilkan.
3. Prototipe layar 12 punya "anggaran", "Atur anggaran" dan "Ekspor PDF", yang
   tidak ada di §5.2 maupun model data §8. `monthly_budget` sudah ditambahkan
   di tabel `couples`; ekspor PDF belum.

## Test

```bash
cd ~/berdua-backend && php artisan test   # 40 test
flutter test                              # 11 test
```

Logika saldo (`SplitCalculator`) dan prediksi siklus (`CyclePredictor`) ditulis
sebagai fungsi murni dengan unit test, sesuai §9.
