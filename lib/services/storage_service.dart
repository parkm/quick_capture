import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class StorageService {
  static const String _directorySaveKey = 'selected_directory';

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
    final note = Note(
      content: content,
      createdAt: DateTime.now(),
      directory: directory,
    );

    final file = File(note.path);
    await file.writeAsString(content);

    return file.path;
  }
}