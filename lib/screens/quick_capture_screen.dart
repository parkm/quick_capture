import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/storage_service.dart';
import '../services/obsidian_service.dart';
import '../widgets/directory_selector.dart';
import '../widgets/status_message.dart';
import '../widgets/save_button.dart';

class QuickCaptureScreen extends StatefulWidget {
  const QuickCaptureScreen({super.key});

  @override
  State<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends State<QuickCaptureScreen> {
  final TextEditingController _textController = TextEditingController();
  final StorageService _storageService = StorageService();
  final ObsidianService _obsidianService = ObsidianService();

  String? _selectedDirectory;
  String? _statusMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedDirectory();
  }

  Future<void> _loadSavedDirectory() async {
    final directory = await _storageService.getSavedDirectory();
    if (mounted) {
      setState(() {
        _selectedDirectory = directory;
      });
    }
  }

  Future<void> _selectDirectory() async {
    try {
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory != null) {
        await _storageService.saveDirectory(directory);
        setState(() {
          _selectedDirectory = directory;
          _statusMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting directory: $e';
      });
    }
  }

  Future<void> _saveNote() async {
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
      // Save the note
      final filePath = await _storageService.saveNote(
        _textController.text,
        _selectedDirectory!
      );

      // Clear the text field
      _textController.clear();

      // Try to open in Obsidian (Android only)
      final obsidianResult = await _obsidianService.openInObsidian(filePath, context);

      setState(() {
        _statusMessage = obsidianResult ?? 'Saved to: $filePath';
        _isSaving = false;
      });
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
              DirectorySelector(
                selectedDirectory: _selectedDirectory,
                onSelectDirectory: _selectDirectory,
              ),

              const SizedBox(height: 16),

              // Status message
              if (_statusMessage != null) ...[
                StatusMessage(message: _statusMessage),
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
              SaveButton(
                isSaving: _isSaving,
                onSave: _saveNote,
              ),
            ],
          ),
        ),
      ),
    );
  }
}