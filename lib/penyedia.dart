import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/api_client.dart';
import 'core/notifikasi_push.dart';
import 'features/auth/sesi_cubit.dart';
import 'features/beranda/beranda_cubit.dart';
import 'features/bersama/bersama_cubit.dart';
import 'features/kuis/kuis_cubit.dart';
import 'features/laporan/laporan_cubit.dart';
import 'features/money/uang_cubit.dart';
import 'features/notifikasi/notifikasi_cubit.dart';
import 'features/siklus/siklus_cubit.dart';

/// Menyediakan klien HTTP dan semua cubit aplikasi untuk seluruh pohon
/// widget.
///
/// Cubit dibuat malas: baru dibuat (dan mulai memuat) saat pertama kali
/// dibaca layar. Satu-satunya cubit per layar adalah [DetailTabunganCubit],
/// yang disediakan oleh layar 19 sendiri karena berbeda per target.
///
/// Tes mengganti [dio] dan [sesi] dengan versi tiruan.
class PenyediaBerdua extends StatelessWidget {
  const PenyediaBerdua({super.key, required this.child, this.dio, this.sesi});

  final Widget child;
  final Dio? dio;
  final SesiCubit Function(BuildContext context)? sesi;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TokenStore>(create: (_) => TokenStore()),
        RepositoryProvider<Dio>(
          create: (context) => dio ?? buatDio(context.read<TokenStore>()),
        ),
        // Malas: baru dibuat (dan menyentuh Firebase) saat aplikasi memakainya.
        RepositoryProvider<NotifikasiPush>(
          create: (context) => NotifikasiPush(context.read<Dio>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SesiCubit>(
            create:
                sesi ??
                (context) => SesiCubit(
                  context.read<Dio>(),
                  context.read<TokenStore>(),
                  push: context.read<NotifikasiPush>(),
                ),
          ),
          BlocProvider(create: (context) => BerandaCubit(context.read())),
          BlocProvider(create: (_) => BagianBersamaCubit()),
          BlocProvider(
            create: (context) => BelanjaCubit(context.read(), context.read()),
          ),
          BlocProvider(
            create: (context) => TodoCubit(context.read(), context.read()),
          ),
          BlocProvider(
            create: (context) => TabunganCubit(context.read(), context.read()),
          ),
          BlocProvider(
            create: (context) => JadwalCubit(context.read(), context.read()),
          ),
          BlocProvider(create: (context) => JurnalCubit(context.read())),
          BlocProvider(create: (_) => FilterUangCubit()),
          BlocProvider(
            create: (context) =>
                UangCubit(context.read(), context.read(), context.read()),
          ),
          BlocProvider(create: (_) => BulanLaporanCubit()),
          BlocProvider(
            create: (context) => LaporanCubit(context.read(), context.read()),
          ),
          BlocProvider(
            create: (context) => SiklusCubit(context.read(), context.read()),
          ),
          BlocProvider(create: (context) => RiwayatSiklusCubit(context.read())),
          BlocProvider(
            create: (context) =>
                NotifikasiCubit(context.read(), context.read()),
          ),
          BlocProvider(create: (context) => RiwayatKuisCubit(context.read())),
          BlocProvider(
            create: (context) =>
                KuisCubit(context.read(), context.read(), context.read()),
          ),
        ],
        child: child,
      ),
    );
  }
}
