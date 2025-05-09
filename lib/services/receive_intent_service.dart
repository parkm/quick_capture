import 'package:flutter/services.dart';
import 'storage_service.dart';
import '../models/file_attachment.dart';

class ReceiveIntentService {
  static const platform = MethodChannel('app.quick.capture/share');
  final StorageService _storageService = StorageService();

  Future<void> initializeReceiveIntent() async {
    // Set up method channel handler
    platform.setMethodCallHandler(_handleMethod);

    // Check if app was started from a share intent
    try {
      final Map<dynamic, dynamic>? sharedData = await platform.invokeMethod('getSharedData');
      if (sharedData != null) {
        final String? sharedText = sharedData['text'];
        final String? sharedUrl = sharedData['url'];
        final List<dynamic>? sharedFilePaths = sharedData['filePaths'];

        // Convert to list of strings
        final List<String> filePaths = sharedFilePaths?.map((path) => path.toString()).toList() ?? [];

        if (sharedText != null || sharedUrl != null || filePaths.isNotEmpty) {
          await _storageService.saveSharedData(
            sharedText,
            sharedUrl,
            sharedFilePaths: filePaths,
          );
        }
      }
    } on PlatformException catch (e) {
      print('Error getting initial shared data: ${e.message}');
    }
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'receivedSharedData':
        final Map<dynamic, dynamic> sharedData = call.arguments;
        final String? sharedText = sharedData['text'];
        final String? sharedUrl = sharedData['url'];
        final List<dynamic>? sharedFilePaths = sharedData['filePaths'];

        // Convert to list of strings
        final List<String> filePaths = sharedFilePaths?.map((path) => path.toString()).toList() ?? [];

        await _storageService.saveSharedData(
          sharedText,
          sharedUrl,
          sharedFilePaths: filePaths,
        );
        return true;
      default:
        return null;
    }
  }
}