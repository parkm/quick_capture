import 'dart:io';
import 'package:path/path.dart' as path;

class FileAttachment {
  final File file;
  final String originalFilename;

  FileAttachment({
    required this.file,
    required this.originalFilename,
  });

  String get extension => path.extension(originalFilename).toLowerCase();

  String get filename => originalFilename;

  static const List<String> supportedImageExtensions = [
    '.bmp', '.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.avif'
  ];

  static const List<String> supportedAudioExtensions = [
    '.mp3', '.wav', '.m4a', '.3gp', '.flac', '.ogg', '.oga', '.opus'
  ];

  static const List<String> supportedVideoExtensions = [
    '.mp4', '.webm', '.ogv', '.mov', '.mkv'
  ];

  static const List<String> supportedPdfExtensions = [
    '.pdf'
  ];

  static const List<String> supportedExtensions = [
    ...supportedImageExtensions,
    ...supportedAudioExtensions,
    ...supportedVideoExtensions,
    ...supportedPdfExtensions,
  ];

  static bool isSupported(String filename) {
    final ext = path.extension(filename).toLowerCase();
    return supportedExtensions.contains(ext);
  }

  String get type {
    final ext = extension;
    if (supportedImageExtensions.contains(ext)) return 'image';
    if (supportedAudioExtensions.contains(ext)) return 'audio';
    if (supportedVideoExtensions.contains(ext)) return 'video';
    if (supportedPdfExtensions.contains(ext)) return 'pdf';
    return 'unknown';
  }
}