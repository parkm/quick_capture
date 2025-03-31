import 'package:flutter/material.dart';
import 'dart:io';
import '../models/file_attachment.dart';
import 'package:path/path.dart' as path;

class AttachmentList extends StatelessWidget {
  final List<FileAttachment> attachments;
  final Function(int) onRemove;

  const AttachmentList({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 120, // Fixed height for attachment squares
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          final fileSize = _getFileSize(attachment.file);

          // Calculate width to make it a square
          return Container(
            width: 120, // Square width matching height
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Stack(
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // File type icon
                      Icon(
                        _getIconForAttachment(attachment),
                        size: 36,
                        color: _getColorForAttachment(attachment, colorScheme),
                      ),
                      const SizedBox(height: 4),
                      // Filename with ellipsis
                      Flexible(
                        child: Text(
                          path.basename(attachment.filename),
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // File type and size
                      Text(
                        '${_getAttachmentTypeText(attachment)} · $fileSize',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Remove button
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onRemove(index),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForAttachment(FileAttachment attachment) {
    switch (attachment.type) {
      case 'image':
        return Icons.image;
      case 'audio':
        return Icons.audio_file;
      case 'video':
        return Icons.video_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.attachment;
    }
  }

  Color _getColorForAttachment(FileAttachment attachment, ColorScheme colorScheme) {
    switch (attachment.type) {
      case 'image':
        return Colors.blue;
      case 'audio':
        return Colors.orange;
      case 'video':
        return Colors.red;
      case 'pdf':
        return Colors.green;
      default:
        return colorScheme.primary;
    }
  }

  String _getAttachmentTypeText(FileAttachment attachment) {
    switch (attachment.type) {
      case 'image':
        return 'Image';
      case 'audio':
        return 'Audio';
      case 'video':
        return 'Video';
      case 'pdf':
        return 'PDF';
      default:
        return 'File';
    }
  }

  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return '? KB';
    }
  }
}