class Note {
  final String content;
  final DateTime createdAt;
  final String directory;

  Note({
    required this.content,
    required this.createdAt,
    required this.directory,
  });

  String get filename {
    final timestamp = createdAt.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    return '$timestamp.md';
  }

  String get path => '$directory/$filename';
}