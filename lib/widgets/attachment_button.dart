import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/file_attachment.dart';

class AttachmentButton extends StatelessWidget {
  final Function(List<FileAttachment>) onAttachmentsAdded;

  const AttachmentButton({
    super.key,
    required this.onAttachmentsAdded,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.attach_file),
      label: const Text('Add Files'),
      onPressed: () => _pickFiles(context),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _pickFiles(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _getAllowedExtensions(),
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
              if (context.mounted) {
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
          onAttachmentsAdded(attachments);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<String> _getAllowedExtensions() {
    // Convert extensions to format needed by FilePicker (without the dot)
    final extensions = <String>[];

    for (final ext in FileAttachment.supportedExtensions) {
      // Remove the leading dot from the extension
      extensions.add(ext.substring(1));
    }

    return extensions;
  }
}