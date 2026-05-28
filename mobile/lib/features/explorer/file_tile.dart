import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import 'explorer_provider.dart';

class FileTile extends StatelessWidget {
  final FileEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  const FileTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: entry.isDirectory
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getIcon(),
          color: entry.isDirectory ? AppColors.primary : AppColors.accent,
          size: 22,
        ),
      ),
      title: Text(
        entry.name,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (!entry.isDirectory)
            Text(
              _formatSize(entry.size),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          if (!entry.isDirectory) const SizedBox(width: 8),
          if (entry.modifiedAt != null)
            Text(
              DateFormat('dd/MM/yy HH:mm').format(entry.modifiedAt!),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
        ],
      ),
      trailing: entry.isDirectory
          ? const Icon(Icons.chevron_right, color: AppColors.textMuted)
          : (onDownload != null
              ? IconButton(
                  icon: const Icon(Icons.download_outlined,
                      color: AppColors.accent, size: 20),
                  onPressed: onDownload,
                  tooltip: 'Télécharger',
                )
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  IconData _getIcon() {
    if (entry.isDirectory) return Icons.folder;
    final ext = entry.name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_outlined;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.videocam_outlined;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.music_note_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_outlined;
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
        return Icons.data_object_outlined;
      case 'dart':
      case 'py':
      case 'js':
      case 'ts':
      case 'java':
      case 'cs':
        return Icons.code;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }
}
