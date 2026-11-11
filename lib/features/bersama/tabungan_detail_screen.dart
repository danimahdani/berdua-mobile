import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/rupiah.dart';
import '../../theme/tokens.dart';
import '../../widgets/berdua_widgets.dart';
import '../../widgets/skeleton.dart';
import '../auth/auth_controller.dart';
import 'bersama_controller.dart';

/// Layar 19: Detail tabungan — progres, sisa, kebutuhan per bulan, kontribusi
/// masing-masing, dan riwayat setoran (§5.4).
class TabunganDetailScreen extends ConsumerWidget {
  const TabunganDetailScreen({super.key, required this.goalId});

  final int goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(detailTabunganProvider(goalId));
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: detail.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const SkeletonTabunganDetail(),
        error: (error, _) => GalatLayar(
          pesan: error is ApiException
              ? error.message
              : 'Gagal memuat tabungan.',
          onUlangi: () => ref.invalidate(detailTabunganProvider(goalId)),
        ),
        data: (goal) => LayarBerdua(
          judul: goal.title,
          stiker: JenisStiker.piggy,
          kembali: true,
          children: [
            KartuRose(
              child: Column(
                children: [
                  Semantics(
                    label: '${goal.percent} persen terkumpul',
                    excludeSemantics: true,
                    child: CincinProgres(
                      nilai: goal.progres,
                      ukuran: 150,
                      lubang: 118,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${goal.percent}%',
                            style: text.headlineLarge?.copyWith(
                              fontSize: 32,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'terkumpul',
                            style: text.labelSmall?.copyWith(
                              fontSize: 12,
                              color: BerduaColors.label,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    Rupiah.format(goal.collected),
                    style: text.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'dari ${Rupiah.format(goal.target)}'
                    '${goal.dueDate == null ? "" : " · target ${TanggalId.monthYearShort(goal.dueDate!)}"}',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      fontSize: 15,
                      color: BerduaColors.label,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.betweenCards),

            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Ubin(
                      label: 'Kurang',
                      nilai: Rupiah.format(goal.remaining),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Ubin(
                      label: 'Perlu per bulan',
                      // null kalau target tidak punya tenggat.
                      nilai: goal.perMonth == null
                          ? '—'
                          : Rupiah.format(goal.perMonth!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.xl),

            _KartuSetor(goalId: goal.id),

            if (goal.kontribusi.isNotEmpty || goal.riwayat.isNotEmpty) ...[
              const SizedBox(height: Gap.betweenCards),
              _Kontribusi(goal: goal),
            ],
          ],
        ),
      ),
    );
  }
}

class _Ubin extends StatelessWidget {
  const _Ubin({required this.label, required this.nilai});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return KartuBerdua(
      radius: Radii.button,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.labelSmall?.copyWith(color: BerduaColors.label),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              nilai,
              style: text.bodyLarge?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu setor: tiga nominal cepat, isian nominal lain, lalu tombolnya.
class _KartuSetor extends ConsumerStatefulWidget {
  const _KartuSetor({required this.goalId});

  final int goalId;

  @override
  ConsumerState<_KartuSetor> createState() => _KartuSetorState();
}

class _KartuSetorState extends ConsumerState<_KartuSetor> {
  static const _cepat = [100000, 250000, 500000];

  final _lain = TextEditingController();
  int _jumlah = _cepat.first;
  bool _menyimpan = false;

  @override
  void dispose() {
    _lain.dispose();
    super.dispose();
  }

  /// Nominal yang diketik menang atas pilihan cepat.
  int get _nominal => Rupiah.parse(_lain.text) ?? _jumlah;

  Future<void> _setor() async {
    final jumlah = _nominal;

    if (jumlah < 1) return;

    final messenger = ScaffoldMessenger.of(context);
    final fokus = FocusScope.of(context);

    setState(() => _menyimpan = true);

    try {
      await ref
          .read(tabunganProvider.notifier)
          .setor(goalId: widget.goalId, jumlah: jumlah);

      _lain.clear();
      fokus.unfocus();
      tampilkanToastVia(messenger, 'Setoran ${Rupiah.format(jumlah)} tercatat');
    } on ApiException catch (error) {
      tampilkanToastVia(messenger, error.message);
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final diketik = _lain.text.isNotEmpty;

    return KartuBerdua(
      radius: Radii.cardBesar,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      stiker: JenisStiker.coin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Setor',
            style: text.bodyLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              for (final (i, nominal) in _cepat.indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: ChipBerdua(
                    label: Rupiah.short(nominal),
                    tinggi: 40,
                    aktif: !diketik && _jumlah == nominal,
                    onTap: () => setState(() {
                      _jumlah = nominal;
                      _lain.clear();
                    }),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Gap.sm),
          TextField(
            controller: _lain,
            keyboardType: TextInputType.number,
            style: text.bodyLarge?.copyWith(fontSize: 17),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixText: 'Rp ',
              hintText: 'Nominal lain',
            ),
          ),
          const SizedBox(height: Gap.md),
          TombolPink(
            label: 'SETOR ${Rupiah.format(_nominal).toUpperCase()}',
            memuat: _menyimpan,
            onPressed: _nominal < 1 ? null : _setor,
          ),
        ],
      ),
    );
  }
}

class _Kontribusi extends ConsumerWidget {
  const _Kontribusi({required this.goal});

  final TargetTabungan goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final sesi = ref.watch(sesiProvider);

    // Warna peran §12, bukan urutan besar-kecil.
    bool pencatat(int userId) => userId == sesi.user?.id
        ? (sesi.user?.tracksCycle ?? false)
        : (sesi.partner?.tracksCycle ?? false);

    Color warna(int userId) =>
        pencatat(userId) ? BerduaColors.dinda : BerduaColors.raka;
    Color warnaTeks(int userId) =>
        pencatat(userId) ? BerduaColors.dindaText : BerduaColors.rakaText;

    // Riwayat hanya membawa nama, jadi warnanya dicari lewat kontribusi.
    final idMenurutNama = {for (final k in goal.kontribusi) k.name: k.userId};
    final total = goal.kontribusi.fold<int>(0, (jumlah, k) => jumlah + k.amount);

    return KartuBerdua(
      radius: Radii.cardBesar,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kontribusi',
            style: text.bodyLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (goal.kontribusi.isNotEmpty) ...[
            const SizedBox(height: 10),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: SizedBox(
                  height: 14,
                  child: total == 0
                      ? const ColoredBox(color: BerduaColors.line)
                      : Row(
                          children: [
                            for (final k in goal.kontribusi)
                              if (k.amount > 0)
                                Expanded(
                                  flex: k.amount,
                                  child: ColoredBox(color: warna(k.userId)),
                                ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final k in goal.kontribusi)
                  Flexible(
                    child: Text(
                      '${k.name} ${Rupiah.format(k.amount)}',
                      style: text.bodySmall?.copyWith(
                        color: warnaTeks(k.userId),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          for (final setoran in goal.riwayat) ...[
            const SizedBox(height: Gap.sm),
            const Divider(height: 1, thickness: 1, color: BerduaColors.line),
            const SizedBox(height: Gap.sm),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: idMenurutNama[setoran.name] == null
                        ? BerduaColors.netral
                        : warna(idMenurutNama[setoran.name]!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${setoran.name} · ${TanggalId.short(setoran.date)}',
                    style: text.bodySmall?.copyWith(color: BerduaColors.ink),
                  ),
                ),
                Text(
                  '+${Rupiah.format(setoran.amount)}',
                  style: text.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: BerduaColors.ink,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
