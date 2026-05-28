import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import 'devices_provider.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes appareils'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(devicesProvider),
          ),
        ],
      ),
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erreur : $e', style: const TextStyle(color: AppColors.danger)),
        ),
        data: (devices) {
          if (devices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.devices_other, size: 64, color: AppColors.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'Aucun appareil enregistré',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final device = devices[index];
              return _DeviceCard(
                device: device,
                onDisconnect: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Déconnecter l\'appareil'),
                      content: Text(
                        'Supprimer "${device['name']}" de votre compte ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger),
                          child: const Text('Déconnecter'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final api = ref.read(apiClientProvider);
                    await api.deleteDevice(device['id'] as String);
                    ref.invalidate(devicesProvider);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Map<String, dynamic> device;
  final VoidCallback onDisconnect;

  const _DeviceCard({required this.device, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    final isOnline = device['isOnline'] as bool? ?? false;
    final platform = device['platform'] as String? ?? 'unknown';
    final status = device['killSwitchStatus'] as String? ?? 'active';

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

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'locked':
        statusColor = AppColors.warning;
        statusLabel = 'Verrouillé';
        break;
      case 'wiped':
        statusColor = AppColors.danger;
        statusLabel = 'Effacé';
        break;
      default:
        statusColor = AppColors.success;
        statusLabel = 'Actif';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 28),
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device['name'] as String? ?? 'Appareil inconnu',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        platform.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOnline ? 'En ligne' : 'Hors ligne',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline ? AppColors.online : AppColors.offline,
                    ),
                  ),
                ],
              ),
            ),
            if (status == 'active')
              TextButton(
                onPressed: onDisconnect,
                child: const Text(
                  'Déconnecter',
                  style: TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
