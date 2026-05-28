import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import '../devices/devices_provider.dart';
import '../clipboard/clipboard_provider.dart';
import '../sync/sync_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final devicesAsync = ref.watch(devicesProvider);
    final clipboardAsync = ref.watch(latestClipboardProvider);
    final syncAsync = ref.watch(syncConfigProvider);

    final userName = auth.user?['firstName'] ?? 'Utilisateur';

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Continuity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.devices_other),
            onPressed: () => context.go('/devices'),
            tooltip: 'Mes appareils',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(devicesProvider);
          ref.invalidate(latestClipboardProvider);
          ref.invalidate(syncConfigProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Salutation
            Text(
              'Bonjour, $userName',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat("EEEE d MMMM yyyy", 'fr_FR').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Bouton Kill Switch — prominent et rouge
            GestureDetector(
              onTap: () => context.go('/killswitch'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.danger, AppColors.dangerDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.white, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kill Switch',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Verrouiller ou effacer un appareil à distance',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section appareils
            _SectionHeader(
              title: 'Appareils connectés',
              actionLabel: 'Tous',
              onAction: () => context.go('/devices'),
            ),
            devicesAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (devices) {
                if (devices.isEmpty) {
                  return _EmptyCard(
                    icon: Icons.devices_other,
                    message: 'Aucun appareil enregistré',
                  );
                }
                return Column(
                  children: devices
                      .take(3)
                      .map((d) => _DeviceTile(device: d))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // Section presse-papier
            _SectionHeader(
              title: 'Presse-papier universel',
              actionLabel: 'Gérer',
              onAction: () => context.go('/clipboard'),
            ),
            clipboardAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (item) {
                if (item == null) {
                  return _EmptyCard(
                    icon: Icons.content_paste_off,
                    message: 'Presse-papier vide',
                  );
                }
                return Card(
                  child: ListTile(
                    leading: Icon(
                      item['contentType'] == 'url'
                          ? Icons.link
                          : Icons.text_fields,
                      color: AppColors.accent,
                    ),
                    title: Text(
                      item['content'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Depuis : ${item['sourceDevice'] ?? 'inconnu'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: () {
                        // Copier dans le presse-papier local
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copié !')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Section synchronisation
            _SectionHeader(
              title: 'Synchronisation',
              actionLabel: 'Configurer',
              onAction: () => context.go('/sync'),
            ),
            syncAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (config) {
                final lastSync = config?['lastSync'] != null
                    ? DateTime.tryParse(config!['lastSync'])
                    : null;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.sync, color: AppColors.accent),
                    title: Text(lastSync != null
                        ? 'Synchronisé ${_timeAgo(lastSync)}'
                        : 'Jamais synchronisé'),
                    subtitle: Text(
                      config != null
                          ? '${(config['syncedPaths'] as List?)?.length ?? 0} dossiers configurés'
                          : 'Aucun dossier configuré',
                    ),
                    trailing: TextButton(
                      onPressed: () => ref.read(syncProvider.notifier).triggerSync(),
                      child: const Text('Sync maintenant'),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Navigation rapide
            const Text(
              'Accès rapide',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _QuickActionCard(
                  icon: Icons.folder_outlined,
                  label: 'Explorateur P2P',
                  color: AppColors.primary,
                  onTap: () => context.go('/explorer'),
                ),
                _QuickActionCard(
                  icon: Icons.content_paste_outlined,
                  label: 'Presse-papier',
                  color: AppColors.accent,
                  onTap: () => context.go('/clipboard'),
                ),
                _QuickActionCard(
                  icon: Icons.sync_outlined,
                  label: 'Synchronisation',
                  color: AppColors.primaryLight,
                  onTap: () => context.go('/sync'),
                ),
                _QuickActionCard(
                  icon: Icons.shield_outlined,
                  label: 'Kill Switch',
                  color: AppColors.danger,
                  onTap: () => context.go('/killswitch'),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.text,
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel,
                style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final Map<String, dynamic> device;

  const _DeviceTile({required this.device});

  @override
  Widget build(BuildContext context) {
    final isOnline = device['isOnline'] as bool? ?? false;
    final platform = device['platform'] as String? ?? 'unknown';

    IconData icon;
    switch (platform) {
      case 'android':
      case 'ios':
        icon = Icons.smartphone;
        break;
      case 'windows':
      case 'macos':
        icon = Icons.computer;
        break;
      default:
        icon = Icons.devices;
    }

    return Card(
      child: ListTile(
        leading: Stack(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.online : AppColors.offline,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          device['name'] as String? ?? 'Appareil inconnu',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          isOnline ? 'En ligne' : 'Hors ligne',
          style: TextStyle(
            color: isOnline ? AppColors.online : AppColors.offline,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          device['killSwitchStatus'] as String? ?? 'active',
          style: TextStyle(
            fontSize: 11,
            color: device['killSwitchStatus'] == 'active'
                ? AppColors.success
                : AppColors.danger,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Erreur: $message', style: const TextStyle(color: AppColors.danger)),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 32),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
