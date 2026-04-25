import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/landing/presentation/landing_page.dart';
import '../theme/app_colors.dart';
import 'dashboard_shell.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: RouteNames.landing,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Auth (sin bottom nav) ─────────────────────────────────────────────
      GoRoute(
        path: RouteNames.landing,
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),

      // ── Full-screen (sobre el bottom nav) — implementados en fases 4–6 ───
      GoRoute(
        path: RouteNames.routeDetail,
        builder: (context, state) => _Placeholder(
          label: 'Ruta ${state.pathParameters['id']}',
          icon: Icons.route,
        ),
      ),
      GoRoute(
        path: RouteNames.publishRoute,
        builder: (context, state) => const _Placeholder(
          label: 'Publicar ruta',
          icon: Icons.add_road,
        ),
      ),
      GoRoute(
        path: RouteNames.myRoutes,
        builder: (context, state) => const _Placeholder(
          label: 'Mis rutas',
          icon: Icons.list_alt_outlined,
        ),
      ),
      GoRoute(
        path: RouteNames.chatDetail,
        builder: (context, state) => _Placeholder(
          label: 'Chat ${state.pathParameters['conversationId']}',
          icon: Icons.chat_outlined,
        ),
      ),

      // ── Dashboard shell con BottomNavigationBar ───────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            DashboardShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.search,
                builder: (context, state) => const _Placeholder(
                  label: 'Buscar rutas',
                  icon: Icons.search,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.bookings,
                builder: (context, state) => const _Placeholder(
                  label: 'Reservas',
                  icon: Icons.bookmark_outline,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.chat,
                builder: (context, state) => const _Placeholder(
                  label: 'Conversaciones',
                  icon: Icons.chat_bubble_outline,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profile,
                builder: (context, state) => const _Placeholder(
                  label: 'Perfil',
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// Escucha cambios en authControllerProvider y notifica al router para
// que re-evalúe el redirect.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<Object?>>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authControllerProvider);

    // No redirigir mientras carga la sesión inicial
    if (authState.isLoading) return null;

    final isAuthenticated = authState.valueOrNull != null;
    final location = state.matchedLocation;

    final isAuthRoute = location == RouteNames.landing ||
        location.startsWith(RouteNames.login) ||
        location.startsWith(RouteNames.register);

    if (!isAuthenticated && !isAuthRoute) return RouteNames.login;
    if (isAuthenticated && isAuthRoute) return RouteNames.dashboard;

    return null;
  }
}

// Widget provisional para rutas aún no implementadas (Fases 3–7)
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Próximamente',
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
