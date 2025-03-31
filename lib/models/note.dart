import 'dart:io';
import 'file_attachment.dart';

class Note {
  final String content;
  final DateTime createdAt;
  final String directory;
  final String title;
  final String? url;
  final List<FileAttachment> attachments;

  Note({
    required this.content,
    required this.createdAt,
    required this.directory,
    required this.title,
    this.url,
    this.attachments = const [],
  });

  String get filename {
    // Use the title for the filename, sanitize it by replacing invalid chars
    final sanitizedTitle = title.replaceAll('/', '-').replaceAll('\\', '-')
        .replaceAll(':', '-').replaceAll('*', '-')
        .replaceAll('?', '-').replaceAll('"', '-')
        .replaceAll('<', '-').replaceAll('>', '-')
        .replaceAll('|', '-');

    return '$sanitizedTitle.md';
  }

  String get filenameWithoutExtension {
    // Get the filename without .md extension
    return filename.substring(0, filename.length - 3);
  }

  String get path => '$directory/$filename';

  Future<String> get formattedContent async {
    final StringBuffer buffer = StringBuffer();

    // Add URL if present
    if (url != null && url!.isNotEmpty) {
      buffer.write('$url\n\n');
    }

    // Add content
    buffer.write(content);

    // Add attachments if present
    if (attachments.isNotEmpty) {
      buffer.write('\n\n');

      for (final attachment in attachments) {
        final attachmentFilename = attachment.filename;
        final attachmentDir = '$directory/attachments/$filenameWithoutExtension';

        // Create attachments directory if it doesn't exist
        final attachmentDirFile = Directory(attachmentDir);
        if (!await attachmentDirFile.exists()) {
          await attachmentDirFile.create(recursive: true);
        }

        // Copy attachment to attachments directory
        final attachmentPath = '$attachmentDir/$attachmentFilename';
        await attachment.file.copy(attachmentPath);

        // Add attachment link based on type - using Obsidian's double bracket format
        final attachmentRelativePath = 'attachments/$filenameWithoutExtension/$attachmentFilename';
        switch (attachment.type) {
          case 'image':
            buffer.write('![[${attachmentRelativePath}]]\n');
            break;
          case 'audio':
            buffer.write('🔊 ![[${attachmentRelativePath}]]\n');
            break;
          case 'video':
            buffer.write('🎬 ![[${attachmentRelativePath}]]\n');
            break;
          case 'pdf':
            buffer.write('📄 ![[${attachmentRelativePath}]]\n');
            break;
          default:
            buffer.write('📎 ![[${attachmentRelativePath}]]\n');
        }
      }
    }

    return buffer.toString();
  }
}