import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Diletakkan di ujung daftar yang dimuat bertahap. Selama [ada] true,
/// menampilkan putaran kecil dan memanggil [onMuatLagi] begitu pengguna
/// menggulir mendekati ujung (atau isi belum memenuhi layar).
class MuatLagi extends StatefulWidget {
  const MuatLagi({super.key, required this.ada, required this.onMuatLagi});

  final bool ada;
  final VoidCallback onMuatLagi;

  @override
  State<MuatLagi> createState() => _MuatLagiState();
}

class _MuatLagiState extends State<MuatLagi> {
  /// Jarak dari ujung gulir yang sudah dianggap "hampir sampai".
  static const _ambang = 400.0;

  ScrollPosition? _posisi;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final baru = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;

    if (baru != _posisi) {
      _posisi?.removeListener(_cek);
      _posisi = baru?..addListener(_cek);
    }
  }

  @override
  void dispose() {
    _posisi?.removeListener(_cek);
    super.dispose();
  }

  void _cek() {
    final p = _posisi;

    if (!mounted || !widget.ada) return;
    if (p == null || !p.hasContentDimensions || p.extentAfter < _ambang) {
      widget.onMuatLagi();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.ada) return const SizedBox.shrink();

    // Diperiksa juga setelah tiap bangun: isi pendek tidak memicu gulir.
    WidgetsBinding.instance.addPostFrameCallback((_) => _cek());

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: Gap.md),
      child: Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: BerduaColors.rakaText,
          ),
        ),
      ),
    );
  }
}
