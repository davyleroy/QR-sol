import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/qr_code_data.dart';

class StorageService {
  // Configure secure storage with proper iOS accessibility
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Save QR code data to local storage
  Future<String> saveQRCode(QRCodeData qrData, Uint8List imageBytes) async {
    try {
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'qr_code_$timestamp.png';
      final filePath = path.join(directory.path, fileName);

      // Save image file
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Save metadata
      final metadataFileName = 'qr_code_$timestamp.json';
      final metadataFilePath = path.join(directory.path, metadataFileName);
      final metadataFile = File(metadataFilePath);

      final metadata = {
        'encodedData': qrData.encodedData,
        'isPasswordProtected': qrData.isPasswordProtected,
        'hasExpiration': qrData.hasExpiration,
        'expirationDate': qrData.expirationDate?.toIso8601String(),
        'type': qrData.type.toString(),
        'title': qrData.title,
        'createdAt': DateTime.now().toIso8601String(),
        'imagePath': filePath,
        'metadataPath': metadataFilePath,
      };

      await metadataFile.writeAsString(jsonEncode(metadata));

      // If password protected, store password securely
      if (qrData.isPasswordProtected) {
        // Note: In a real implementation, you'd extract the password used for encryption
        // This is just a placeholder - you'll need to implement actual password extraction
        final passwordKey = 'qr_password_$timestamp';
        // await _secureStorage.write(key: passwordKey, value: extractedPassword);
      }

      return filePath;
    } catch (e) {
      throw Exception('Failed to save QR code: $e');
    }
  }

  // Get all saved QR codes
  Future<List<Map<String, dynamic>>> getSavedQRCodes() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = directory.listSync();

      List<Map<String, dynamic>> qrCodes = [];

      for (var file in files) {
        if (file is File &&
            file.path.endsWith('.json') &&
            file.path.contains('qr_code_')) {
          try {
            final content = await File(file.path).readAsString();
            final metadata = jsonDecode(content) as Map<String, dynamic>;

            // Check if the QR code has expired
            bool isExpired = false;
            if (metadata['hasExpiration'] == true &&
                metadata['expirationDate'] != null) {
              final expirationDate = DateTime.parse(metadata['expirationDate']);
              isExpired = DateTime.now().isAfter(expirationDate);
            }

            // Add expiration status to metadata
            metadata['isExpired'] = isExpired;
            metadata['metadataPath'] = file.path;

            // Check if image file exists
            final imagePath = metadata['imagePath'];
            if (imagePath != null) {
              final imageFile = File(imagePath);
              if (await imageFile.exists()) {
                qrCodes.add(metadata);
              } else {
                // Clean up orphaned metadata file
                await file.delete();
              }
            }
          } catch (e) {
            // Skip corrupted metadata files
            print('Error reading metadata file ${file.path}: $e');
            try {
              await file.delete();
            } catch (deleteError) {
              print('Error deleting corrupted file: $deleteError');
            }
          }
        }
      }

      // Sort by creation date (newest first)
      qrCodes.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['createdAt']);
          final dateB = DateTime.parse(b['createdAt']);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      return qrCodes;
    } catch (e) {
      throw Exception('Failed to get saved QR codes: $e');
    }
  }

  // Delete a saved QR code
  Future<void> deleteQRCode(String metadataPath) async {
    try {
      final metadataFile = File(metadataPath);
      if (await metadataFile.exists()) {
        // Read metadata to get image path
        final content = await metadataFile.readAsString();
        final metadata = jsonDecode(content) as Map<String, dynamic>;

        // Delete image file
        final imagePath = metadata['imagePath'];
        if (imagePath != null) {
          final imageFile = File(imagePath);
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
        }

        // Delete metadata file
        await metadataFile.delete();

        // Delete password if exists
        final timestamp = path
            .basenameWithoutExtension(metadataPath)
            .replaceAll('qr_code_', '');
        await _secureStorage.delete(key: 'qr_password_$timestamp');
      }
    } catch (e) {
      throw Exception('Failed to delete QR code: $e');
    }
  }

  // Get password for a password-protected QR code
  Future<String?> getQRCodePassword(String timestamp) async {
    try {
      return await _secureStorage.read(key: 'qr_password_$timestamp');
    } catch (e) {
      throw Exception('Failed to get QR code password: $e');
    }
  }

  // Clear all saved QR codes
  Future<void> clearAllQRCodes() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = directory.listSync();

      for (var file in files) {
        if (file is File &&
            (file.path.contains('qr_code_') &&
                (file.path.endsWith('.png') || file.path.endsWith('.json')))) {
          try {
            await file.delete();
          } catch (e) {
            print('Error deleting file ${file.path}: $e');
          }
        }
      }

      // Clear all passwords
      try {
        await _secureStorage.deleteAll();
      } catch (e) {
        print('Error clearing secure storage: $e');
      }
    } catch (e) {
      throw Exception('Failed to clear QR codes: $e');
    }
  }

  // Clean up expired QR codes
  Future<void> cleanupExpiredQRCodes() async {
    try {
      final qrCodes = await getSavedQRCodes();

      for (var qrCode in qrCodes) {
        if (qrCode['isExpired'] == true) {
          final metadataPath = qrCode['metadataPath'];
          if (metadataPath != null) {
            await deleteQRCode(metadataPath);
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to cleanup expired QR codes: $e');
    }
  }

  // Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final qrCodes = await getSavedQRCodes();
      final directory = await getApplicationDocumentsDirectory();

      int totalSize = 0;
      int imageFiles = 0;
      int metadataFiles = 0;

      final files = directory.listSync();
      for (var file in files) {
        if (file is File && file.path.contains('qr_code_')) {
          final stat = await file.stat();
          totalSize += stat.size;

          if (file.path.endsWith('.png')) {
            imageFiles++;
          } else if (file.path.endsWith('.json')) {
            metadataFiles++;
          }
        }
      }

      return {
        'totalQRCodes': qrCodes.length,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'imageFiles': imageFiles,
        'metadataFiles': metadataFiles,
        'expiredQRCodes': qrCodes.where((qr) => qr['isExpired'] == true).length,
        'passwordProtectedQRCodes':
            qrCodes.where((qr) => qr['isPasswordProtected'] == true).length,
      };
    } catch (e) {
      throw Exception('Failed to get storage statistics: $e');
    }
  }

  // Save arbitrary secure data
  Future<void> saveSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      throw Exception('Failed to save secure data: $e');
    }
  }

  // Get secure data
  Future<String?> getSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      throw Exception('Failed to get secure data: $e');
    }
  }

  // Delete secure data
  Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      throw Exception('Failed to delete secure data: $e');
    }
  }

  // Check if storage directory exists and is writable
  Future<bool> checkStorageHealth() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final testFile = File(path.join(directory.path, 'test_write.tmp'));

      // Try to write a test file
      await testFile.writeAsString('test');

      // Try to read it back
      final content = await testFile.readAsString();

      // Clean up
      await testFile.delete();

      return content == 'test';
    } catch (e) {
      return false;
    }
  }

  // Export QR codes data for backup
  Future<Map<String, dynamic>> exportQRCodes() async {
    try {
      final qrCodes = await getSavedQRCodes();
      final stats = await getStorageStats();

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'stats': stats,
        'qrCodes':
            qrCodes.map((qr) {
              // Remove file paths for export
              final exportQR = Map<String, dynamic>.from(qr);
              exportQR.remove('imagePath');
              exportQR.remove('metadataPath');
              return exportQR;
            }).toList(),
      };
    } catch (e) {
      throw Exception('Failed to export QR codes: $e');
    }
  }
}
