import 'package:encrypt/encrypt.dart';
import 'dart:convert';

class EncryptionService {
  Future<String> encryptData(String data, String password) async {
    // Create a key from the password
    final key = Key.fromUtf8(password.padRight(32, '0').substring(0, 32));
    final iv = IV.fromLength(16);

    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(data, iv: iv);

    // Return base64 encoded string with IV
    return '${base64.encode(iv.bytes)}:${encrypted.base64}';
  }

  Future<String> decryptData(String encryptedData, String password) async {
    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted data format');
      }

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);

      // Create a key from the password
      final key = Key.fromUtf8(password.padRight(32, '0').substring(0, 32));

      final encrypter = Encrypter(AES(key));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }
}
