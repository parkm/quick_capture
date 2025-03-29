import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ObsidianService {
  // Try to open a file in Obsidian with different approaches
  Future<String?> openInObsidian(String filePath, BuildContext context) async {
    // Only applicable for Android
    if (Theme.of(context).platform != TargetPlatform.android) {
      return null;
    }

    // Log the file path for debugging
    print('Attempting to open file in Obsidian: $filePath');

    // First, extract just the filename
    final fileName = filePath.split('/').last;
    print('File name: $fileName');

    // Get the directory path
    final directoryPath = filePath.substring(0, filePath.lastIndexOf('/'));

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

    try {
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
            return 'Saved to: $filePath\nOpened in Obsidian vault: $parentDirName, subfolder: $selectedDirName';
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
          return 'Saved to: $filePath\nOpened in Obsidian vault: $vaultName';
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
          return 'Saved to: $filePath\nOpened in Obsidian using path';
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

      return appLaunched
          ? 'Saved to: $filePath\nOpened Obsidian (file may need to be located manually)'
          : 'Saved to: $filePath\nCould not open Obsidian';
    } catch (e) {
      return 'Saved to: $filePath\nError opening in Obsidian: $e';
    }
  }

  // For backward compatibility
  Future<String?> openFileInObsidian(String filePath, BuildContext context) {
    return openInObsidian(filePath, context);
  }
}