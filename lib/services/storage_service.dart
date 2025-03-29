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
  Future<String> saveNote(String content, String directory) async {
    // Generate a title for the note
    final title = _titleService.generateTitle(content);

    final note = Note(
      content: content,
      createdAt: DateTime.now(),
      directory: directory,
      title: title,
    );

    final file = File(note.path);
    await file.writeAsString(content);

    return file.path;
  }
}