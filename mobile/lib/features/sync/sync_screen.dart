import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import 'sync_provider.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  static const _defaultPaths = [
    '~/Documents',
    '~/Desktop',
    '~/Pictures',
    '~/Downloads',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncConfigAsync = ref.watch(syncConfigProvider);
    final syncState = ref.watch(syncProvider);
    final isSyncing = syncState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synchronisation'),
      ),
      body: syncConfigAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erreur: $e', style: const TextStyle(color: AppColors.danger)),
        ),
        data: (config) {
          final syncedPaths = config != null
              ? List<String>.from(config['syncedPaths'] as List? ?? [])
              : <String>[];
          final lastSync = config?['lastSync'] != null
              ? DateTime.tryParse(config!['lastSync'] as String)
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Statut de synchronisation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync, color: Colors.white, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statut de synchronisation',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            lastSync != null
                                ? 'Synchronisé le ${DateFormat('dd/MM/yyyy à HH:mm').format(lastSync)}'
                                : 'Jamais synchronisé',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bouton synchroniser maintenant
              ElevatedButton.icon(
                onPressed: isSyncing
                    ? null
                    : () => ref.read(syncProvider.notifier).triggerSync(),
                icon: isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync),
                label: Text(isSyncing ? 'Synchronisation...' : 'Synchroniser maintenant'),
              ),
              const SizedBox(height: 24),

              // Dossiers synchronisés
              const Text(
                'Dossiers synchronisés',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Activez les dossiers à synchroniser entre vos appareils',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),

              ..._defaultPaths.map((path) {
                final isEnabled = syncedPaths.contains(path);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: SwitchListTile(
                    value: isEnabled,
                    onChanged: (enabled) {
                      final newPaths = List<String>.from(syncedPaths);
                      if (enabled) {
                        newPaths.add(path);
                      } else {
                        newPaths.remove(path);
                      }
                      ref.read(syncProvider.notifier).updatePaths(newPaths);
                    },
                    title: Text(
                      path,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                    ),
                    subtitle: Text(
                      isEnabled ? 'Synchronisé' : 'Non synchronisé',
                      style: TextStyle(
                        color: isEnabled ? AppColors.success : AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    secondary: Icon(
                      _pathIcon(path),
                      color: isEnabled ? AppColors.accent : AppColors.textMuted,
                    ),
                    activeColor: AppColors.accent,
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Note sécurité
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined,
                        color: AppColors.accent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tous les fichiers sont chiffrés AES-256 côté client avant la synchronisation. Le serveur ne voit jamais vos données en clair.',
                        style: TextStyle(
                          color: AppColors.accentDark,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _pathIcon(String path) {
    if (path.contains('Document')) return Icons.description_outlined;
    if (path.contains('Desktop')) return Icons.desktop_windows_outlined;
    if (path.contains('Picture')) return Icons.photo_outlined;
    if (path.contains('Download')) return Icons.download_outlined;
    return Icons.folder_outlined;
  }
}
