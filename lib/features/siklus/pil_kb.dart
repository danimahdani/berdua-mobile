import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../core/muatan.dart';
import '../../core/rupiah.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../auth/sesi_cubit.dart';

// ------------------------------------------------------------------ model

/// Status pengingat pil KB dari `GET /pill`, dilihat pencatat atau pasangan.
class StatusPil {
  const StatusPil({
    required this.terlihat,
    required this.diatur,
    required this.bisaUbah,
    required this.namaPemilik,
    this.aktif = false,
    this.jam = '21:00',
    this.pola = 'daily',
    this.mulai,
    this.pasanganBolehIngatkan = true,
    this.hariMinum = true,
    this.hariKe,
    this.sudahMinum = false,
    this.jamMinum,
    this.bisaIngatkan = false,
    this.ingatkanLagiPukul,
  });

  factory StatusPil.fromJson(Map<String, dynamic> json) {
    final hariIni = json['today'] as Map<String, dynamic>? ?? const {};
    final mulai = json['start_date'] as String?;

    return StatusPil(
      terlihat: json['visible'] as bool? ?? false,
      diatur: json['configured'] as bool? ?? false,
      bisaUbah: json['can_edit'] as bool? ?? false,
      namaPemilik: json['owner_name'] as String? ?? '',
      aktif: json['active'] as bool? ?? false,
      jam: json['time'] as String? ?? '21:00',
      pola: json['pattern'] as String? ?? 'daily',
      mulai: mulai == null ? null : DateTime.parse(mulai),
      pasanganBolehIngatkan: json['partner_can_nudge'] as bool? ?? true,
      hariMinum: hariIni['is_pill_day'] as bool? ?? true,
      hariKe: hariIni['day_in_pack'] as int?,
      sudahMinum: hariIni['taken'] as bool? ?? false,
      jamMinum: hariIni['taken_at'] as String?,
      bisaIngatkan: json['can_nudge'] as bool? ?? false,
      ingatkanLagiPukul: json['nudge_available_at'] as String?,
    );
  }

  /// false = kartu tidak ditampilkan (pasangan belum mengizinkan, dsb.).
  final bool terlihat;
  final bool diatur;

  /// true = pemilik (pencatat siklus); false = pasangannya.
  final bool bisaUbah;
  final String namaPemilik;
  final bool aktif;

  /// "HH:mm".
  final String jam;

  /// `daily` (setiap hari) atau `21_7` (21 hari minum, 7 hari jeda).
  final String pola;
  final DateTime? mulai;
  final bool pasanganBolehIngatkan;
  final bool hariMinum;
  final int? hariKe;
  final bool sudahMinum;
  final String? jamMinum;
  final bool bisaIngatkan;
  final String? ingatkanLagiPukul;

  static const namaPola = {'daily': 'Setiap hari', '21_7': '21 hari + 7 jeda'};
}

// ------------------------------------------------------------------ cubit

class PilCubit extends MuatanCubit<StatusPil> {
  PilCubit(this._dio);

  final Dio _dio;

  @override
  Future<StatusPil> ambil() async =>
      StatusPil.fromJson(await _dio.send('GET', '/pill'));

  Future<void> _kirim(String method, String path, {Object? body}) async {
    final data = await _dio.send(method, path, body: body);

    emit(Muatan.data(StatusPil.fromJson(data)));
  }

  Future<void> simpan({
    required bool aktif,
    required String jam,
    required String pola,
    required DateTime? mulai,
  }) => _kirim(
    'PUT',
    '/pill',
    body: {
      'active': aktif,
      'time': jam,
      'pattern': pola,
      'start_date': mulai == null ? null : _tanggal(mulai),
    },
  );

  Future<void> hapus() => _kirim('DELETE', '/pill');

  Future<void> sudahMinum() => _kirim('POST', '/pill/taken');

  Future<void> batalMinum() => _kirim('DELETE', '/pill/taken');

  /// Pasangan: kirim pengingat. Mengembalikan pesan dari backend.
  Future<String> ingatkan() async {
    final data = await _dio.send('POST', '/pill/nudge');

    emit(Muatan.data(StatusPil.fromJson(data)));

    return data['message'] as String? ?? 'Pengingat terkirim.';
  }

  static String _tanggal(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

// ------------------------------------------------------------------ kartu

/// Kartu pil KB di layar Siklus. Untuk pencatat: atur jadwal dan tandai
/// "Sudah minum". Untuk pasangan: lihat status dan "Ingatkan".
/// Tidak tampil sama sekali kalau tidak ada yang boleh dilihat.
class KartuPil extends StatelessWidget {
  const KartuPil({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<PilCubit>().state.nilai;

    if (status == null || !status.terlihat) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: Gap.xl),
      child: status.bisaUbah
          ? _KartuPemilik(status: status)
          : _KartuPasangan(status: status),
    );
  }
}

/// Menjalankan aksi dan menampilkan toast hasil atau galatnya.
Future<void> _jalankan(
  BuildContext context,
  Future<String?> Function() aksi,
) async {
  final messenger = ScaffoldMessenger.of(context);

  try {
    final pesan = await aksi();

    if (pesan != null) tampilkanToastVia(messenger, pesan);
  } on ApiException catch (error) {
    tampilkanToastVia(messenger, error.message);
  }
}

class _Kepala extends StatelessWidget {
  const _Kepala({required this.judul, required this.sub, this.aksi});

  final String judul;
  final String sub;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BerduaColors.roseSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text('💊', style: TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: text.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(sub, style: text.labelSmall),
            ],
          ),
        ),
        ?aksi,
      ],
    );
  }
}

String _ringkasJadwal(StatusPil s) {
  final pola = StatusPil.namaPola[s.pola] ?? s.pola;
  final hari = s.hariKe == null ? '' : ' · hari ke-${s.hariKe} dari 28';

  return 'Pukul ${s.jam} · $pola$hari';
}

class _KartuPemilik extends StatelessWidget {
  const _KartuPemilik({required this.status});

  final StatusPil status;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cubit = context.read<PilCubit>();
    final sesi = context.watch<SesiCubit>().state;
    final pasangan = sesi.partner?.name.isNotEmpty ?? false
        ? sesi.partner!.name
        : 'Pasanganmu';

    void atur() => bukaLembar<void>(
      context,
      (_) => BlocProvider.value(
        value: cubit,
        child: _PengaturanPil(status: status),
      ),
    );

    if (!status.diatur) {
      return KartuBerdua(
        radius: Radii.button,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Kepala(
              judul: 'Pengingat pil KB',
              sub: 'Diingatkan setiap hari di jam yang kamu pilih.',
            ),
            const SizedBox(height: Gap.md),
            TombolSekunder(label: 'Atur pengingat', onPressed: atur),
          ],
        ),
      );
    }

    final Widget isi;

    if (!status.aktif) {
      isi = Text(
        'Pengingat sedang dimatikan.',
        style: text.bodyMedium?.copyWith(color: BerduaColors.label),
      );
    } else if (!status.hariMinum) {
      isi = Text(
        'Masa jeda: hari ini tidak perlu minum pil.',
        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      );
    } else if (status.sudahMinum) {
      isi = Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: BerduaColors.mintText),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Text(
              'Sudah diminum pukul ${status.jamMinum ?? '-'}',
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          TombolTeks(
            label: 'Batalkan',
            onTap: () => _jalankan(context, () async {
              await cubit.batalMinum();

              return 'Tanda minum dibatalkan.';
            }),
          ),
        ],
      );
    } else {
      isi = TombolUtama(
        label: 'Sudah minum',
        ukuranHuruf: 18,
        onPressed: () => _jalankan(context, () async {
          await cubit.sudahMinum();

          return 'Tercatat. Sampai besok!';
        }),
      );
    }

    return KartuBerdua(
      radius: Radii.button,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Kepala(
            judul: 'Pil KB',
            sub: _ringkasJadwal(status),
            aksi: IconButton(
              tooltip: 'Atur pengingat pil',
              icon: const Icon(Icons.tune_rounded),
              onPressed: atur,
            ),
          ),
          const SizedBox(height: Gap.md),
          isi,
          const SizedBox(height: Gap.sm),
          Text(
            '$pasangan bisa melihat sudah/belum diminum hari ini dan '
            'mengingatkanmu kalau lupa.',
            style: text.labelSmall?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _KartuPasangan extends StatelessWidget {
  const _KartuPasangan({required this.status});

  final StatusPil status;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final nama = status.namaPemilik.isEmpty ? 'Pasanganmu' : status.namaPemilik;
    final cubit = context.read<PilCubit>();

    final Widget isi;

    if (!status.hariMinum) {
      isi = Text(
        'Masa jeda: hari ini $nama tidak perlu minum pil.',
        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      );
    } else if (status.sudahMinum) {
      isi = Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: BerduaColors.mintText),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Text(
              '$nama sudah minum pukul ${status.jamMinum ?? '-'}',
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );
    } else {
      isi = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Belum ditandai diminum hari ini.',
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: Gap.md),
          TombolUtama(
            label: 'Ingatkan $nama',
            ukuranHuruf: 18,
            onPressed: status.bisaIngatkan
                ? () => _jalankan(context, cubit.ingatkan)
                : null,
          ),
          if (!status.bisaIngatkan && status.ingatkanLagiPukul != null) ...[
            const SizedBox(height: 6),
            Text(
              'Baru saja diingatkan. Bisa mengingatkan lagi pukul '
              '${status.ingatkanLagiPukul}.',
              style: text.labelSmall,
            ),
          ],
        ],
      );
    }

    return KartuBerdua(
      radius: Radii.button,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Kepala(judul: 'Pil KB $nama', sub: _ringkasJadwal(status)),
          const SizedBox(height: Gap.md),
          isi,
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- pengaturan

class _PengaturanPil extends StatefulWidget {
  const _PengaturanPil({required this.status});

  final StatusPil status;

  @override
  State<_PengaturanPil> createState() => _PengaturanPilState();
}

class _PengaturanPilState extends State<_PengaturanPil> {
  late bool _aktif = widget.status.diatur ? widget.status.aktif : true;
  late TimeOfDay _jam = _bacaJam(widget.status.jam);
  late String _pola = widget.status.pola;
  late DateTime? _mulai = widget.status.mulai;
  bool _menyimpan = false;
  String? _galat;

  static TimeOfDay _bacaJam(String jam) {
    final bagian = jam.split(':');

    return TimeOfDay(
      hour: int.tryParse(bagian.first) ?? 21,
      minute: bagian.length > 1 ? int.tryParse(bagian[1]) ?? 0 : 0,
    );
  }

  String get _jamTeks =>
      '${_jam.hour.toString().padLeft(2, '0')}:'
      '${_jam.minute.toString().padLeft(2, '0')}';

  Future<void> _simpan() async {
    if (_pola == '21_7' && _mulai == null) {
      setState(
        () => _galat = 'Pilih tanggal mulai strip untuk pola 21 + 7 jeda.',
      );

      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    try {
      await context.read<PilCubit>().simpan(
        aktif: _aktif,
        jam: _jamTeks,
        pola: _pola,
        mulai: _mulai,
      );
      navigator.pop();
      tampilkanToastVia(messenger, 'Pengingat pil KB disimpan');
    } on ApiException catch (error) {
      if (mounted) setState(() => _galat = error.message);
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  Future<void> _hapus() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<PilCubit>().hapus();
      navigator.pop();
      tampilkanToastVia(messenger, 'Pengingat pil KB dihapus');
    } on ApiException catch (error) {
      if (mounted) setState(() => _galat = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final keterangan = text.bodySmall?.copyWith(color: BerduaColors.label);

    Widget isian(String teks, IconData ikon, VoidCallback onTap) => KartuBerdua(
      radius: Radii.input,
      bayangan: false,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(teks, style: text.bodyLarge?.copyWith(fontSize: 17)),
          ),
          Icon(ikon, size: 18, color: BerduaColors.label),
        ],
      ),
    );

    return IsiLembar(
      judul: 'Pengingat pil KB',
      children: [
        BarisSakelar(
          label: 'Ingatkan setiap hari',
          nyala: _aktif,
          bayangan: false,
          onUbah: (nilai) => setState(() => _aktif = nilai),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LabelIsian('Jam minum'),
            isian('Pukul $_jamTeks', Icons.schedule_rounded, () async {
              final dipilih = await showTimePicker(
                context: context,
                initialTime: _jam,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );

              if (dipilih != null && mounted) setState(() => _jam = dipilih);
            }),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LabelIsian('Pola minum'),
            SegmenBerdua<String>(
              gaya: GayaSegmen.sheet,
              ukuranHuruf: 14,
              pilihan: StatusPil.namaPola.keys.toList(),
              terpilih: _pola,
              label: (p) => StatusPil.namaPola[p]!,
              onPilih: (p) => setState(() => _pola = p),
            ),
            const SizedBox(height: 6),
            Text(
              _pola == '21_7'
                  ? 'Minum 21 hari, lalu 7 hari jeda tanpa pengingat.'
                  : 'Minum setiap hari tanpa jeda (strip 28 pil).',
              style: keterangan,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabelIsian(
              _pola == '21_7' ? 'Mulai strip' : 'Mulai strip (opsional)',
            ),
            isian(
              _mulai == null ? 'Belum dipilih' : TanggalId.long(_mulai!),
              Icons.calendar_today_outlined,
              () async {
                final kini = DateTime.now();
                final dipilih = await showDatePicker(
                  context: context,
                  initialDate: _mulai ?? kini,
                  firstDate: DateTime(kini.year - 1),
                  lastDate: DateTime(kini.year + 1, 12, 31),
                );

                if (dipilih != null && mounted) {
                  setState(() => _mulai = dipilih);
                }
              },
            ),
          ],
        ),
        // Wajib, bukan pilihan: pasangan selalu bisa mengingatkan.
        Text(
          'Pasangan bisa melihat jam minum dan sudah/belum diminum hari ini, '
          'lalu mengirim pengingat kalau kamu lupa.',
          style: keterangan,
        ),
        ?(_galat == null ? null : TeksGalat(_galat!)),
        TombolUtama(
          label: 'Simpan pengingat',
          memuat: _menyimpan,
          onPressed: _simpan,
        ),
        if (widget.status.diatur)
          Center(
            child: TombolTeks(
              label: 'Hapus pengingat',
              warna: BerduaColors.roseText,
              onTap: _hapus,
            ),
          ),
      ],
    );
  }
}
