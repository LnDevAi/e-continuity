import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../devices/devices_provider.dart';
import 'killswitch_provider.dart';

class KillSwitchScreen extends ConsumerWidget {
  const KillSwitchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);
    final ksState = ref.watch(killSwitchProvider);
    final isLoading = ksState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kill Switch'),
        backgroundColor: AppColors.dangerDark,
      ),
      body: Column(
        children: [
          // Bandeau d'avertissement rouge
          Container(
            width: double.infinity,
            color: AppColors.danger,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ATTENTION — Ces actions sont irréversibles. Verrouillage ou effacement définitif des données.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Corps
          Expanded(
            child: devicesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Erreur: $e',
                    style: const TextStyle(color: AppColors.danger)),
              ),
              data: (devices) {
                if (devices.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.devices_other,
                            size: 64, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'Aucun appareil enregistré',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Explication
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.danger.withOpacity(0.2)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Que font ces actions ?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.lock_outlined,
                            color: AppColors.warning,
                            text:
                                'Verrouiller — Chiffre AES-256 l\'appareil immédiatement. Seule votre clé privée permet le déchiffrement.',
                          ),
                          SizedBox(height: 6),
                          _InfoRow(
                            icon: Icons.delete_forever_outlined,
                            color: AppColors.danger,
                            text:
                                'Effacer — Réécriture sécurisée des clusters (DoD 5220.22-M, 3 passes). Données irrécupérables.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Appareils',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...devices.map((device) => _DeviceKillCard(
                          device: device,
                          isLoading: isLoading,
                          onLock: () =>
                              _confirmLock(context, ref, device),
                          onWipe: () =>
                              _confirmWipe(context, ref, device),
                        )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLock(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> device,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_outlined, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Verrouiller l\'appareil'),
          ],
        ),
        content: Text(
          'Voulez-vous verrouiller "${device['name']}" par chiffrement AES-256 ?\n\nL\'appareil sera inaccessible jusqu\'au déchiffrement avec votre clé privée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Verrouiller'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(killSwitchProvider.notifier)
          .lock(device['id'] as String);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Commande de verrouillage envoyée'
                  : 'Erreur lors du verrouillage',
            ),
            backgroundColor: success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _confirmWipe(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> device,
  ) async {
    final textController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.delete_forever,
                  color: AppColors.danger, size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Effacement sécurisé',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DANGER — Cette opération effacera définitivement toutes les données de "${device['name']}" par réécriture sécurisée (3 passes DoD). Cette action est IRRÉVERSIBLE.',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pour confirmer, tapez EFFACER ci-dessous :',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'EFFACER',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.danger, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: textController.text == 'EFFACER'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                disabledBackgroundColor: AppColors.danger.withOpacity(0.4),
              ),
              child: const Text('Effacer définitivement'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(killSwitchProvider.notifier)
          .wipe(device['id'] as String);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Commande d\'effacement envoyée'
                  : 'Erreur lors de l\'effacement',
            ),
            backgroundColor: success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }
}

class _DeviceKillCard extends StatelessWidget {
  final Map<String, dynamic> device;
  final bool isLoading;
  final VoidCallback onLock;
  final VoidCallback onWipe;

  const _DeviceKillCard({
    required this.device,
    required this.isLoading,
    required this.onLock,
    required this.onWipe,
  });

  @override
  Widget build(BuildContext context) {
    final status = device['killSwitchStatus'] as String? ?? 'active';
    final platform = device['platform'] as String? ?? 'unknown';
    final isOnline = device['isOnline'] as bool? ?? false;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (status) {
      case 'locked':
        statusColor = AppColors.warning;
        statusLabel = 'Verrouillé';
        statusIcon = Icons.lock;
        break;
      case 'wiped':
        statusColor = AppColors.danger;
        statusLabel = 'Effacé';
        statusIcon = Icons.delete_forever;
        break;
      default:
        statusColor = AppColors.success;
        statusLabel = 'Actif';
        statusIcon = Icons.check_circle_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  platform == 'android' || platform == 'ios'
                      ? Icons.smartphone
                      : Icons.computer,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
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
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? AppColors.online
                                  : AppColors.offline,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline ? 'En ligne' : 'Hors ligne',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 12),
                          Icon(statusIcon, color: statusColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (status == 'active') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : onLock,
                      icon: const Icon(Icons.lock_outlined,
                          size: 18, color: AppColors.warning),
                      label: const Text(
                        'Verrouiller',
                        style: TextStyle(color: AppColors.warning),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.warning),
                        minimumSize: const Size(0, 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : onWipe,
                      icon: const Icon(Icons.delete_forever_outlined,
                          size: 18),
                      label: const Text('Effacer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        minimumSize: const Size(0, 40),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'locked') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.warning, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Appareil verrouillé. Le déchiffrement nécessite votre clé privée.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ),
      ],
    );
  }
}
