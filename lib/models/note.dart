class Note {
  final String content;
  final DateTime createdAt;
  final String directory;
  final String title;
  final String? url;

  Note({
    required this.content,
    required this.createdAt,
    required this.directory,
    required this.title,
    this.url,
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

  String get path => '$directory/$filename';

  String get formattedContent {
    if (url != null && url!.isNotEmpty) {
      return '$url\n\n$content';
    }
    return content;
  }
}