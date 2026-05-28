import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import 'clipboard_provider.dart';

class ClipboardScreen extends ConsumerStatefulWidget {
  const ClipboardScreen({super.key});

  @override
  ConsumerState<ClipboardScreen> createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends ConsumerState<ClipboardScreen> {
  final _contentController = TextEditingController();
  String _selectedType = 'text';

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(clipboardHistoryProvider);
    final clipboardState = ref.watch(clipboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presse-papier universel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(clipboardHistoryProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone d'envoi
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Collez un texte ou une URL à partager sur tous vos appareils...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Type de contenu
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'text', label: Text('Texte')),
                        ButtonSegment(value: 'url', label: Text('URL')),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (s) =>
                          setState(() => _selectedType = s.first),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: clipboardState is AsyncLoading
                          ? null
                          : () async {
                              final content = _contentController.text.trim();
                              if (content.isEmpty) return;
                              await ref.read(clipboardProvider.notifier).push(
                                    content: content,
                                    contentType: _selectedType,
                                    sourceDevice: 'mobile',
                                  );
                              _contentController.clear();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Envoyé sur tous vos appareils'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Envoyer'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Historique
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Erreur: $e',
                    style: const TextStyle(color: AppColors.danger)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.content_paste_off,
                            size: 64, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'Aucun contenu partagé',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Collez un texte ci-dessus pour le partager',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ClipboardItemCard(
                      item: item,
                      onDelete: () =>
                          ref.read(clipboardProvider.notifier).delete(
                                item['id'] as String,
                              ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClipboardItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const _ClipboardItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final contentType = item['contentType'] as String? ?? 'text';
    final content = item['content'] as String? ?? '';
    final sourceDevice = item['sourceDevice'] as String?;
    final createdAt = item['createdAt'] != null
        ? DateTime.tryParse(item['createdAt'] as String)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  contentType == 'url' ? Icons.link : Icons.text_fields,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    contentType.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                if (createdAt != null)
                  Text(
                    DateFormat('HH:mm').format(createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copié dans le presse-papier local'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Copier',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.danger),
                  onPressed: onDelete,
                  tooltip: 'Supprimer',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
            ),
            if (sourceDevice != null) ...[
              const SizedBox(height: 6),
              Text(
                'Depuis : $sourceDevice',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
