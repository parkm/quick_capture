import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const QuickCaptureApp());
}

class QuickCaptureApp extends StatelessWidget {
  const QuickCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Capture',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[800],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const QuickCapturePage(),
    );
  }
}

class QuickCapturePage extends StatefulWidget {
  const QuickCapturePage({super.key});

  @override
  State<QuickCapturePage> createState() => _QuickCapturePageState();
}

class _QuickCapturePageState extends State<QuickCapturePage> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedDirectory;
  String? _statusMessage;
  bool _isSaving = false;

  static const String _directorySaveKey = 'selected_directory';

  @override
  void initState() {
    super.initState();
    _loadSavedDirectory();
  }

  Future<void> _loadSavedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDirectory = prefs.getString(_directorySaveKey);
    });
  }

  Future<void> _saveDirectory(String directory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_directorySaveKey, directory);
  }

  Future<void> _selectDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        // Save the selected directory to SharedPreferences
        await _saveDirectory(selectedDirectory);

        setState(() {
          _selectedDirectory = selectedDirectory;
          _statusMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting directory: $e';
      });
    }
  }

  Future<void> _saveText() async {
    if (_textController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter some text to save';
      });
      return;
    }

    if (_selectedDirectory == null) {
      setState(() {
        _statusMessage = 'Please select a directory first';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    try {
      // Create an ISO timestamp-based filename with .md extension
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final filename = '$timestamp.md';
      final file = File('$_selectedDirectory/$filename');

      // Write text to file
      await file.writeAsString(_textController.text);

      // Clear the text field and show success message
      _textController.clear();
      setState(() {
        _statusMessage = 'Saved to: ${file.path}';
        _isSaving = false;
      });

      // Launch Obsidian app (Android only)
      if (Theme.of(context).platform == TargetPlatform.android) {
        try {
          // Get the absolute path to the file we just saved
          final filePath = file.path;

          // Log the file path for debugging
          print('Attempting to open file in Obsidian: $filePath');

          // The approach depends on how the folders are structured
          // 1. Determine the vault root and the relative path within the vault

          // First, extract just the filename
          final fileName = filePath.split('/').last;
          print('File name: $fileName');

          // Get the directory path
          final directoryPath = _selectedDirectory!;

          // Extract the vault name - but we need to handle subdirectories
          final directoryParts = directoryPath.split('/');

          // Assume for now that the last part of the selected directory could be a subfolder
          final selectedDirName = directoryParts.last;
          print('Selected directory name: $selectedDirName');

          // Try to determine if we're in a subdirectory of the vault
          // by checking parent directories
          String? vaultName;
          String? relativePath;

          // Approach 1: If the selected directory is directly a vault
          vaultName = selectedDirName;
          relativePath = fileName;

          // Log our assumptions
          print('Initial assumption - Vault name: $vaultName, Relative path: $relativePath');

          // Approach 2: If the selected directory is a subdirectory within a vault
          // Assume one level up is the vault root (e.g., "VaultName/Inbox")
          String? parentDirName;
          if (directoryParts.length >= 2) {
            parentDirName = directoryParts[directoryParts.length - 2];
            print('Parent directory name: $parentDirName');
          }

          // Try multiple approaches in sequence

          // 1. First try assuming the selected directory is a subfolder in a vault
          if (parentDirName != null) {
            final alternateVaultUri = Uri.parse('obsidian://vault/$parentDirName/$selectedDirName/$fileName');
            print('Trying URI (subfolder approach): $alternateVaultUri');

            try {
              final alternateVaultLaunched = await launchUrl(
                alternateVaultUri,
                mode: LaunchMode.externalApplication,
              );

              if (alternateVaultLaunched) {
                setState(() {
                  _statusMessage = 'Saved to: $filePath\nOpened in Obsidian vault: $parentDirName, subfolder: $selectedDirName';
                });
                return;
              }
            } catch (e) {
              print('Error with subfolder approach: $e');
            }
          }

          // 2. Try assuming the selected directory is the vault itself
          final vaultUri = Uri.parse('obsidian://vault/$vaultName/$relativePath');
          print('Trying URI (direct vault approach): $vaultUri');

          try {
            final vaultLaunched = await launchUrl(
              vaultUri,
              mode: LaunchMode.externalApplication,
            );

            if (vaultLaunched) {
              setState(() {
                _statusMessage = 'Saved to: $filePath\nOpened in Obsidian vault: $vaultName';
              });
              return;
            }
          } catch (e) {
            print('Error with direct vault approach: $e');
          }

          // 3. Try with the full path as a fallback
          final simpleUri = Uri.parse('obsidian://open?path=$filePath');
          print('Trying URI (path approach): $simpleUri');

          try {
            final pathLaunched = await launchUrl(
              simpleUri,
              mode: LaunchMode.externalApplication,
            );

            if (pathLaunched) {
              setState(() {
                _statusMessage = 'Saved to: $filePath\nOpened in Obsidian using path';
              });
              return;
            }
          } catch (e) {
            print('Error with path approach: $e');
          }

          // 4. Last resort: just open Obsidian
          final obsidianUri = Uri.parse('obsidian://');
          print('Trying basic Obsidian URI: $obsidianUri');

          final appLaunched = await launchUrl(
            obsidianUri,
            mode: LaunchMode.externalApplication,
          );

          setState(() {
            _statusMessage = appLaunched
                ? 'Saved to: $filePath\nOpened Obsidian (file may need to be located manually)'
                : 'Saved to: $filePath\nCould not open Obsidian';
          });
        } catch (e) {
          setState(() {
            _statusMessage = 'Saved to: ${file.path}\nError opening in Obsidian: $e';
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error saving file: $e';
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Capture'),
        elevation: 0,
        backgroundColor: colorScheme.surfaceVariant,
        foregroundColor: colorScheme.onSurfaceVariant,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Directory selector
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Save Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.outline,
                                ),
                              ),
                              child: Text(
                                _selectedDirectory ?? 'No directory selected',
                                style: TextStyle(
                                  color: _selectedDirectory == null
                                      ? colorScheme.onSurface.withOpacity(0.6)
                                      : colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _selectDirectory,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Browse'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Status message
              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _statusMessage!.startsWith('Error')
                        ? colorScheme.errorContainer
                        : _statusMessage!.startsWith('Saved')
                            ? colorScheme.primaryContainer
                            : colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      color: _statusMessage!.startsWith('Error')
                          ? colorScheme.onErrorContainer
                          : _statusMessage!.startsWith('Saved')
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Expanding area for text input
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Enter your text here...',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Submit button
              Material(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _isSaving ? null : _saveText,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isSaving) ...[
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.save_alt,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isSaving ? 'Saving...' : 'Save Note',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
