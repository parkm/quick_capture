import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/storage_service.dart';
import '../services/obsidian_service.dart';
import '../services/receive_intent_service.dart';
import '../widgets/directory_selector.dart';
import '../widgets/status_message.dart';
import '../widgets/save_button.dart';
import '../widgets/url_input_field.dart';
import '../widgets/attachment_button.dart';
import '../widgets/attachment_list.dart';
import '../models/file_attachment.dart';

class QuickCaptureScreen extends StatefulWidget {
  const QuickCaptureScreen({super.key});

  @override
  State<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends State<QuickCaptureScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final StorageService _storageService = StorageService();
  final ObsidianService _obsidianService = ObsidianService();
  final ReceiveIntentService _receiveIntentService = ReceiveIntentService();

  String? _selectedDirectory;
  String? _statusMessage;
  bool _isSaving = false;
  List<FileAttachment> _attachments = [];
  bool _isDirectoryExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedDirectory();
    _initializeIntentHandling();
  }

  Future<void> _initializeIntentHandling() async {
    await _receiveIntentService.initializeReceiveIntent();
    _checkForSharedContent();
  }

  Future<void> _checkForSharedContent() async {
    final sharedText = await _storageService.getSharedText();
    final sharedUrl = await _storageService.getSharedUrl();
    final sharedFileAttachments = await _storageService.getSharedFileAttachments();

    if (mounted) {
      if (sharedText != null && sharedText.isNotEmpty) {
        _textController.text = sharedText;
      }

      if (sharedUrl != null && sharedUrl.isNotEmpty) {
        _urlController.text = sharedUrl;
      }

      if (sharedFileAttachments.isNotEmpty) {
        setState(() {
          _attachments = sharedFileAttachments;
        });
      }
    }
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
      // Save the note with URL and attachments if available
      final url = _urlController.text.isNotEmpty ? _urlController.text : null;
      final filePath = await _storageService.saveNote(
        _textController.text,
        _selectedDirectory!,
        url: url,
        attachments: _attachments,
      );

      // Clear the fields
      _textController.clear();
      _urlController.clear();
      setState(() {
        _attachments = [];
      });

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

  void _handleAttachmentsAdded(List<FileAttachment> newAttachments) {
    setState(() {
      _attachments.addAll(newAttachments);
    });
  }

  // Direct implementation of file picking functionality
  Future<void> _pickAttachments() async {
    try {
      // Get the allowed extensions from the FileAttachment model
      final allowedExtensions = FileAttachment.supportedExtensions
          .map((ext) => ext.substring(1)) // Remove leading dot
          .toList();

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final attachments = <FileAttachment>[];

        for (final file in result.files) {
          if (file.path != null && file.name.isNotEmpty) {
            // Check if file is supported
            if (FileAttachment.isSupported(file.name)) {
              attachments.add(
                FileAttachment(
                  file: File(file.path!),
                  originalFilename: file.name,
                ),
              );
            } else {
              // Show error for unsupported file type
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Unsupported file type: ${file.name}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }
        }

        if (attachments.isNotEmpty) {
          _handleAttachmentsAdded(attachments);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _toggleDirectoryExpanded() {
    setState(() {
      _isDirectoryExpanded = !_isDirectoryExpanded;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quick Capture', style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        )),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top section with directory selector
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: _toggleDirectoryExpanded,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDirectory ?? 'Select Directory',
                            style: textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          _isDirectoryExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Expandable directory section
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isDirectoryExpanded ? 56 : 0,
                curve: Curves.easeInOut,
                child: _isDirectoryExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: DirectorySelector(
                          selectedDirectory: _selectedDirectory,
                          onSelectDirectory: _selectDirectory,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 12),

              // URL input field - always visible
              UrlInputField(
                controller: _urlController,
              ),

              const SizedBox(height: 12),

              // Main content area with text field
              Expanded(
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: textTheme.bodyLarge,
                      decoration: InputDecoration.collapsed(
                        hintText: 'Enter your text here...',
                        hintStyle: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Attachments section (always reserve space for it)
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 12),

                // Attachment header
                Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Attachments (${_attachments.length})',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Attachment list with horizontally scrollable squares
                AttachmentList(
                  attachments: _attachments,
                  onRemove: _removeAttachment,
                ),
              ],

              // Status message
              if (_statusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                  child: StatusMessage(message: _statusMessage),
                ),

              const SizedBox(height: 12),

              // Action buttons row
              Row(
                children: [
                  // Attachment button
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Add Files'),
                      onPressed: _pickAttachments,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12.0),

                  // Save button
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          )
                        : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Note'),
                      onPressed: _isSaving ? null : _saveNote,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}