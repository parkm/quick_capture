import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../models/file_attachment.dart';
import 'title_generation_service.dart';

class StorageService {
  static const String _directorySaveKey = 'selected_directory';
  final TitleGenerationService _titleService = TitleGenerationService();

  // Get the saved directory path from SharedPreferences
  Future<String?> getSavedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_directorySaveKey);
  }

  // Save the directory path to SharedPreferences
  Future<void> saveDirectory(String directory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_directorySaveKey, directory);
  }

  // Save a note to the filesystem
  Future<String> saveNote(
    String content,
    String directory, {
    String? url,
    List<FileAttachment> attachments = const [],
  }) async {
    // Generate a title for the note
    final title = _titleService.generateTitle(content);

    final note = Note(
      content: content,
      createdAt: DateTime.now(),
      directory: directory,
      title: title,
      url: url,
      attachments: attachments,
    );

    final file = File(note.path);
    final formattedContent = await note.formattedContent;
    await file.writeAsString(formattedContent);

    return file.path;
  }

  // Handle shared data received via Android intent
  static const String _sharedTextKey = 'shared_text';
  static const String _sharedUrlKey = 'shared_url';
  static const String _sharedFilePathsKey = 'shared_file_paths';

  Future<void> saveSharedData(
    String? sharedText,
    String? sharedUrl, {
    List<String>? sharedFilePaths,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (sharedText != null) {
      await prefs.setString(_sharedTextKey, sharedText);
    }
    if (sharedUrl != null) {
      await prefs.setString(_sharedUrlKey, sharedUrl);
    }
    if (sharedFilePaths != null && sharedFilePaths.isNotEmpty) {
      await prefs.setStringList(_sharedFilePathsKey, sharedFilePaths);
    }
  }

  Future<String?> getSharedText() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_sharedTextKey);
    if (text != null) {
      // Clear after retrieving
      await prefs.remove(_sharedTextKey);
    }
    return text;
  }

  Future<String?> getSharedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_sharedUrlKey);
    if (url != null) {
      // Clear after retrieving
      await prefs.remove(_sharedUrlKey);
    }
    return url;
  }

  Future<List<String>> getSharedFilePaths() async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList(_sharedFilePathsKey) ?? [];
    if (paths.isNotEmpty) {
      // Clear after retrieving
      await prefs.remove(_sharedFilePathsKey);
    }
    return paths;
  }

  Future<List<FileAttachment>> getSharedFileAttachments() async {
    final paths = await getSharedFilePaths();
    final attachments = <FileAttachment>[];

    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        final filename = file.path.split('/').last;
        if (FileAttachment.isSupported(filename)) {
          attachments.add(
            FileAttachment(
              file: file,
              originalFilename: filename,
            ),
          );
        }
      }
    }

    return attachments;
  }
}