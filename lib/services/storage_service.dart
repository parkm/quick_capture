import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
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
  Future<String> saveNote(String content, String directory, {String? url}) async {
    // Generate a title for the note
    final title = _titleService.generateTitle(content);

    final note = Note(
      content: content,
      createdAt: DateTime.now(),
      directory: directory,
      title: title,
      url: url,
    );

    final file = File(note.path);
    await file.writeAsString(note.formattedContent);

    return file.path;
  }

  // Handle shared data received via Android intent
  static const String _sharedTextKey = 'shared_text';
  static const String _sharedUrlKey = 'shared_url';

  Future<void> saveSharedData(String? sharedText, String? sharedUrl) async {
    final prefs = await SharedPreferences.getInstance();
    if (sharedText != null) {
      await prefs.setString(_sharedTextKey, sharedText);
    }
    if (sharedUrl != null) {
      await prefs.setString(_sharedUrlKey, sharedUrl);
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
}