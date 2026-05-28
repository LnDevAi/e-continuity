import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/explorer/explorer_screen.dart';
import '../features/clipboard/clipboard_screen.dart';
import '../features/sync/sync_screen.dart';
import '../features/killswitch/killswitch_screen.dart';
import '../features/devices/devices_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/explorer',
            name: 'explorer',
            builder: (context, state) => const ExplorerScreen(),
          ),
          GoRoute(
            path: '/clipboard',
            name: 'clipboard',
            builder: (context, state) => const ClipboardScreen(),
          ),
          GoRoute(
            path: '/sync',
            name: 'sync',
            builder: (context, state) => const SyncScreen(),
          ),
          GoRoute(
            path: '/killswitch',
            name: 'killswitch',
            builder: (context, state) => const KillSwitchScreen(),
          ),
          GoRoute(
            path: '/devices',
            name: 'devices',
            builder: (context, state) => const DevicesScreen(),
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _routes = [
    '/dashboard',
    '/explorer',
    '/clipboard',
    '/sync',
    '/killswitch',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          context.go(_routes[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Explorateur',
          ),
          NavigationDestination(
            icon: Icon(Icons.content_paste_outlined),
            selectedIcon: Icon(Icons.content_paste),
            label: 'Presse-papier',
          ),
          NavigationDestination(
            icon: Icon(Icons.sync_outlined),
            selectedIcon: Icon(Icons.sync),
            label: 'Sync',
          ),
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security),
            label: 'Kill Switch',
          ),
        ],
      ),
    );
  }
}
