import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../models/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../auth/sesi_cubit.dart';
import 'uang_cubit.dart';

/// Layar 09 (Tambah pengeluaran) dan 11 (Ubah transaksi) — satu bottom sheet,
/// karena formulirnya sama dan hanya berbeda nilai awal.
class TambahPengeluaranSheet extends StatefulWidget {
  const TambahPengeluaranSheet({super.key, this.transaksi});

  final Transaksi? transaksi;

  static Future<void> buka(BuildContext context, {Transaksi? transaksi}) {
    return bukaLembar<void>(
      context,
      (_) => TambahPengeluaranSheet(transaksi: transaksi),
    );
  }

  @override
  State<TambahPengeluaranSheet> createState() => _TambahPengeluaranSheetState();
}

class _TambahPengeluaranSheetState extends State<TambahPengeluaranSheet> {
  /// Nilai segmen "Dibayar oleh" untuk dompet bersama, yang tidak punya id.
  static const _dompet = 0;

  late final TextEditingController _judul;
  late final TextEditingController _jumlah;

  late String _kategori;
  late CaraPembagian _split;
  int? _payerId;
  int _porsiCustom = 50;
  late DateTime _tanggal;

  bool _memuat = false;
  String? _galat;

  bool get _ubah => widget.transaksi != null;

  @override
  void initState() {
    super.initState();

    final awal = widget.transaksi;

    _judul = TextEditingController(text: awal?.title ?? '');
    _jumlah = TextEditingController(
      text: awal == null ? '' : Rupiah.bare(awal.amount),
    );
    _kategori = awal?.category ?? BerduaEnums.categories.first;
    _split = awal?.split ?? CaraPembagian.equal;
    // Pengeluaran baru paling sering dibayar orang yang mencatatnya.
    _payerId = awal == null
        ? context.read<SesiCubit>().state.user?.id
        : awal.payerId;
    _porsiCustom = awal?.payerSharePct ?? 50;
    _tanggal = awal?.date ?? DateTime.now();

    // Pelunasan tidak bisa diubah lewat formulir ini.
    if (_split == CaraPembagian.settlement) _split = CaraPembagian.equal;
  }

  @override
  void dispose() {
    _judul.dispose();
    _jumlah.dispose();
    super.dispose();
  }

  void _pilihPembayar(int? nilai) => setState(() {
    if (nilai == _dompet) {
      _split = CaraPembagian.wallet;

      return;
    }

    _payerId = nilai;

    // Keluar dari dompet bersama: kembali ke pembagian bawaan.
    if (_split == CaraPembagian.wallet) _split = CaraPembagian.equal;
  });

  Future<void> _simpan() async {
    final jumlah = Rupiah.parse(_jumlah.text);

    if (jumlah == null || jumlah < 1) {
      setState(() => _galat = 'Masukkan jumlah yang benar.');

      return;
    }

    if (_judul.text.trim().isEmpty) {
      setState(() => _galat = 'Tulis dulu untuk apa pengeluarannya.');

      return;
    }

    if (_split != CaraPembagian.wallet && _payerId == null) {
      setState(() => _galat = 'Pilih siapa yang membayar.');

      return;
    }

    // Dipegang sebelum await supaya BuildContext tidak disentuh sesudah sheet
    // ditutup.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _memuat = true;
      _galat = null;
    });

    try {
      final controller = context.read<UangCubit>();

      if (_ubah) {
        await controller.ubah(
          id: widget.transaksi!.id,
          judul: _judul.text.trim(),
          kategori: _kategori,
          jumlah: jumlah,
          payerId: _payerId,
          split: _split,
          porsiCustom: _porsiCustom,
          tanggal: _tanggal,
        );
      } else {
        await controller.tambah(
          judul: _judul.text.trim(),
          kategori: _kategori,
          jumlah: jumlah,
          payerId: _payerId,
          split: _split,
          porsiCustom: _porsiCustom,
          tanggal: _tanggal,
        );
      }

      navigator.pop();
      tampilkanToastVia(
        messenger,
        _ubah ? 'Perubahan disimpan' : 'Transaksi dicatat',
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _galat = error.message);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sesi = context.watch<SesiCubit>().state;
    final anggota = [sesi.user, sesi.partner].whereType<Pengguna>().toList();
    final dompet = _split == CaraPembagian.wallet;

    String nama(int? id) {
      for (final orang in anggota) {
        if (orang.id == id) return orang.name.isEmpty ? 'Aku' : orang.name;
      }

      return 'Pembayar';
    }

    final pembayar = nama(_payerId);
    final lainnya = anggota.where((orang) => orang.id != _payerId).toList();
    final pasangan = lainnya.isEmpty || lainnya.first.name.isEmpty
        ? 'Pasangan'
        : lainnya.first.name;

    return IsiLembar(
      judul: _ubah ? 'Ubah transaksi' : 'Tambah pengeluaran',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: BerduaColors.roseCard,
            borderRadius: BorderRadius.circular(Radii.cardBesar),
          ),
          child: Column(
            children: [
              Text(
                'Jumlah',
                style: text.bodySmall?.copyWith(color: BerduaColors.label),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BerduaColors.rose, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Rp',
                      style: text.titleMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: BerduaColors.label,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: TextField(
                          controller: _jumlah,
                          keyboardType: TextInputType.number,
                          autofocus: !_ubah,
                          style: text.headlineLarge?.copyWith(
                            fontSize: 34,
                            height: 1.3,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                            _PemisahRibuan(),
                          ],
                          // Ringkasan pembagian di bawah ikut berubah.
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: text.headlineLarge?.copyWith(
                              fontSize: 34,
                              height: 1.3,
                              color: BerduaColors.teksCoret,
                            ),
                            isDense: true,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        TextField(
          controller: _judul,
          textCapitalization: TextCapitalization.sentences,
          style: text.bodyLarge?.copyWith(fontSize: 17),
          inputFormatters: [LengthLimitingTextInputFormatter(80)],
          decoration: const InputDecoration(
            hintText: 'Untuk apa? mis. Makan siang',
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LabelIsian('Kategori'),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final kategori in BerduaEnums.categories)
                  ChipBerdua(
                    label: kategori,
                    aktif: _kategori == kategori,
                    onTap: () => setState(() => _kategori = kategori),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LabelIsian('Dibayar oleh'),
            SegmenBerdua<int?>(
              gaya: GayaSegmen.sheet,
              pilihan: [for (final orang in anggota) orang.id, _dompet],
              lebar: [for (final _ in anggota) 5, 7],
              terpilih: dompet ? _dompet : _payerId,
              label: (id) => id == _dompet ? 'Dompet bersama' : nama(id),
              onPilih: _pilihPembayar,
            ),
          ],
        ),
        // Dompet bersama tidak dibagi, jadi pilihan pembagian disembunyikan.
        if (!dompet)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LabelIsian('Pembagian transaksi ini'),
              SegmenBerdua<CaraPembagian>(
                gaya: GayaSegmen.sheet,
                pilihan: const [
                  CaraPembagian.equal,
                  CaraPembagian.custom,
                  CaraPembagian.solo,
                ],
                terpilih: _split,
                label: (split) => split.label,
                onPilih: (split) => setState(() => _split = split),
              ),
              // §5.2: porsi custom 0-100 dengan langkah 5.
              if (_split == CaraPembagian.custom) ...[
                const SizedBox(height: 6),
                Slider(
                  value: _porsiCustom.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: BerduaColors.rose,
                  inactiveColor: BerduaColors.roseCard,
                  label: '$_porsiCustom%',
                  onChanged: (value) =>
                      setState(() => _porsiCustom = value.round()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '$pembayar $_porsiCustom%',
                          style: text.labelSmall?.copyWith(
                            color: BerduaColors.label,
                          ),
                        ),
                      ),
                      const SizedBox(width: Gap.sm),
                      Flexible(
                        child: Text(
                          '$pasangan ${100 - _porsiCustom}%',
                          textAlign: TextAlign.right,
                          style: text.labelSmall?.copyWith(
                            color: BerduaColors.label,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        _ringkasanPembagian(text, pasangan),
        ?(_galat == null ? null : TeksGalat(_galat!)),
        TombolUtama(
          label: _ubah ? 'Simpan perubahan' : 'Simpan',
          memuat: _memuat,
          onPressed: _simpan,
        ),
      ],
    );
  }

  /// Pratinjau utang memakai rumus yang sama dengan backend (§5.2), supaya
  /// pengguna melihat akibatnya sebelum menyimpan.
  Widget _ringkasanPembagian(TextTheme text, String pasangan) {
    final jumlah = Rupiah.parse(_jumlah.text) ?? 0;

    final porsi = switch (_split) {
      CaraPembagian.equal => 50,
      CaraPembagian.custom => _porsiCustom,
      _ => 100,
    };

    final utang = _split == CaraPembagian.wallet
        ? 0
        : (jumlah * (100 - porsi) / 100).round();

    final pesan = switch (_split) {
      CaraPembagian.wallet => 'Mengurangi saldo dompet bersama, tanpa utang.',
      CaraPembagian.solo => 'Tercatat saja, tanpa utang.',
      _ when utang == 0 => 'Tidak menambah utang.',
      _ => '$pasangan berutang ${Rupiah.format(utang)}.',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BerduaColors.card2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        pesan,
        style: text.bodySmall?.copyWith(
          fontSize: 15,
          height: 1.45,
          color: BerduaColors.lutealText,
        ),
      ),
    );
  }
}

/// Menyisipkan titik ribuan sambil pengguna mengetik: "512000" jadi "512.000".
class _PemisahRibuan extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final angka = Rupiah.parse(newValue.text);

    if (angka == null) return newValue.copyWith(text: '');

    final teks = Rupiah.bare(angka);

    return TextEditingValue(
      text: teks,
      selection: TextSelection.collapsed(offset: teks.length),
    );
  }
}
