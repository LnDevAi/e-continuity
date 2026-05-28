import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../devices/devices_provider.dart';
import 'explorer_provider.dart';
import 'file_tile.dart';

class ExplorerScreen extends ConsumerWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorerState = ref.watch(explorerProvider);
    final devicesAsync = ref.watch(devicesProvider);

    if (!explorerState.isConnected) {
      return Scaffold(
        appBar: AppBar(title: const Text('Explorateur P2P')),
        body: devicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Erreur: $e',
                style: const TextStyle(color: AppColors.danger)),
          ),
          data: (devices) {
            final desktopDevices = devices
                .where((d) =>
                    d['type'] == 'desktop_windows' ||
                    d['type'] == 'desktop_macos')
                .toList();

            if (desktopDevices.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.computer_outlined,
                        size: 72, color: AppColors.textMuted),
                    SizedBox(height: 16),
                    Text(
                      'Aucun PC disponible',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Installez E-Continuity sur votre PC Windows ou macOS et connectez-vous avec le même compte.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête informatif
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.accent.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_tethering,
                            color: AppColors.accent, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Connexion directe P2P via WebRTC — vos fichiers ne transitent pas par le serveur',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.accentDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sélectionner un PC',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...desktopDevices.map((device) => _PcCard(
                        device: device,
                        onConnect: () => ref
                            .read(explorerProvider.notifier)
                            .connectToDevice(device['id'] as String),
                      )),
                ],
              ),
            );
          },
        ),
      );
    }

    // Explorateur de fichiers connecté
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Explorateur P2P', style: TextStyle(fontSize: 16)),
            Text(
              explorerState.currentPath,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        leading: explorerState.pathHistory.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    ref.read(explorerProvider.notifier).navigateBack(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>
                ref.read(explorerProvider.notifier).disconnect(),
            tooltip: 'Déconnecter',
          ),
        ],
      ),
      body: explorerState.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement du répertoire...',
                      style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            )
          : explorerState.entries.isEmpty
              ? const Center(
                  child: Text('Dossier vide',
                      style: TextStyle(color: AppColors.textMuted)),
                )
              : ListView.separated(
                  itemCount: explorerState.entries.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    final entry = explorerState.entries[index];
                    return FileTile(
                      entry: entry,
                      onTap: () {
                        if (entry.isDirectory) {
                          ref
                              .read(explorerProvider.notifier)
                              .navigateTo(entry.path);
                        }
                      },
                      onDownload: entry.isDirectory
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Téléchargement de ${entry.name}...'),
                                  backgroundColor: AppColors.accent,
                                ),
                              );
                            },
                    );
                  },
                ),
    );
  }
}

class _PcCard extends StatelessWidget {
  final Map<String, dynamic> device;
  final VoidCallback onConnect;

  const _PcCard({required this.device, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final isOnline = device['isOnline'] as bool? ?? false;
    final platform = device['platform'] as String? ?? 'windows';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                platform == 'macos' ? Icons.laptop_mac : Icons.computer,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.online : AppColors.offline,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          device['name'] as String? ?? 'PC inconnu',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isOnline ? 'Disponible pour connexion' : 'Hors ligne',
          style: TextStyle(
            color: isOnline ? AppColors.success : AppColors.offline,
            fontSize: 12,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: isOnline ? onConnect : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(100, 36),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Connecter'),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
