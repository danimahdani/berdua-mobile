import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/masuk_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/beranda/beranda_screen.dart';
import 'features/bersama/bersama_screen.dart';
import 'features/bersama/tabungan_detail_screen.dart';
import 'features/laporan/laporan_screen.dart';
import 'features/money/uang_screen.dart';
import 'features/notifikasi/notifikasi_screen.dart';
import 'features/profil/profil_screen.dart';
import 'features/siklus/riwayat_screen.dart';
import 'features/siklus/siklus_screen.dart';
import 'theme/berdua_theme.dart';
import 'theme/tokens.dart';
import 'widgets/berdua_widgets.dart';
import 'widgets/skeleton.dart';

/// §9: go_router dengan 5 tab bawah dan rute anak.
final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Router ikut berubah begitu sesi berubah, sehingga pengalihan di bawah
  // dijalankan ulang tanpa perlu navigasi manual dari layar.
  final notifier = ValueNotifier(ref.read(sesiProvider));

  ref.listen(sesiProvider, (_, next) => notifier.value = next);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/beranda',
    refreshListenable: notifier,
    redirect: (context, state) {
      final sesi = ref.read(sesiProvider);

      // Selama token lama diperiksa, jangan pindah ke mana pun.
      if (sesi.memuat) return '/memuat';

      final path = state.matchedLocation;

      if (!sesi.masuk) return path == '/masuk' ? null : '/masuk';

      if (sesi.perluOnboarding) {
        return path == '/onboarding' ? null : '/onboarding';
      }

      // Sudah masuk: jangan biarkan kembali ke layar masuk atau onboarding.
      if (path == '/masuk' || path == '/onboarding' || path == '/memuat') {
        return '/beranda';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/memuat', builder: (_, _) => const _LayarMemuat()),
      GoRoute(path: '/masuk', builder: (_, _) => const MasukScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      // Layar 07 ditampilkan penuh di atas shell, sehingga navigasi bawah
      // tersembunyi dan tombol kembali jadi satu-satunya jalan keluar.
      GoRoute(
        path: '/notifikasi',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const NotifikasiScreen(),
      ),
      GoRoute(
        path: '/siklus/riwayat',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const RiwayatSiklusScreen(),
      ),
      GoRoute(
        path: '/laporan',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const LaporanScreen(),
      ),
      GoRoute(
        path: '/bersama/tabungan/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => TabunganDetailScreen(
          goalId: int.parse(state.pathParameters['id']!),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/beranda', builder: (_, _) => const BerandaScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/uang', builder: (_, _) => const UangScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/siklus', builder: (_, _) => const SiklusScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/bersama', builder: (_, _) => const BersamaScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profil', builder: (_, _) => const ProfilScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});

class BerduaApp extends ConsumerWidget {
  const BerduaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Berdua',
      debugShowCheckedModeBanner: false,
      theme: BerduaTheme.light(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

/// Navigasi bawah 5 tab: kartu putih bergaris tinta dengan bayangan keras,
/// tab aktif berwarna pink.
class _Shell extends StatelessWidget {
  const _Shell({required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (icon: Icons.home_outlined, label: 'Beranda'),
    (icon: Icons.account_balance_wallet_outlined, label: 'Uang'),
    (icon: Icons.water_drop_outlined, label: 'Siklus'),
    (icon: Icons.favorite_border_rounded, label: 'Bersama'),
    (icon: Icons.account_circle_outlined, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    // Layar mendengarkan tab aktif supaya kartunya memantul lagi tiap dibuka.
    // Nilainya disetel sesudah frame ini, karena pendengarnya memanggil
    // setState.
    if (tabAktifBerdua.value != shell.currentIndex) {
      final tab = shell.currentIndex;

      WidgetsBinding.instance.addPostFrameCallback(
        (_) => tabAktifBerdua.value = tab,
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: ColoredBox(
        color: BerduaColors.card,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, 10),
            child: Container(
              height: Sizes.bottomNav,
              decoration: BoxDecoration(
                color: BerduaColors.card,
                borderRadius: BorderRadius.circular(Radii.card),
                border: Border.all(color: BerduaColors.ink, width: Sizes.garis),
                boxShadow: Shadows.kartu,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: _TabNavigasi(
                        ikon: _tabs[i].icon,
                        label: _tabs[i].label,
                        aktif: i == shell.currentIndex,
                        onTap: () => shell.goBranch(
                          i,
                          initialLocation: i == shell.currentIndex,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabNavigasi extends StatelessWidget {
  const _TabNavigasi({
    required this.ikon,
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  final IconData ikon;
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final warna = aktif ? BerduaColors.rose : BerduaColors.navMati;

    return Semantics(
      button: true,
      selected: aktif,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon tab aktif membesar sedikit dengan pantulan.
            AnimatedScale(
              scale: aktif ? 1.12 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Icon(ikon, size: Sizes.icon, color: warna),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: warna,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayarMemuat extends StatelessWidget {
  const _LayarMemuat();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SkeletonPembuka());
  }
}
