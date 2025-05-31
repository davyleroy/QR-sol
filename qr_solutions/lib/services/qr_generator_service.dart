import 'package:flutter/material.dart';
import '../models/qr_code_data.dart';
import '../models/wifi_network.dart';
import '../services/encryption_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/contact_model.dart';

class QRGeneratorService {
  final _encryptionService = EncryptionService();

  Future<QRCodeData> generateURLQR(
    String url, {
    bool usePassword = false,
    String password = '',
    bool useExpiration = false,
    DateTime? expirationDate,
  }) async {
    String encodedData = url;

    // Apply encryption if password protection is enabled
    if (usePassword && password.isNotEmpty) {
      encodedData = await _encryptionService.encryptData(url, password);
      encodedData = 'ENCRYPTED:$encodedData';
    }

    // Add expiration if enabled
    if (useExpiration && expirationDate != null) {
      final expString = expirationDate.toIso8601String();
      encodedData = 'EXP:$expString:$encodedData';
    }

    return QRCodeData(
      encodedData: encodedData,
      isPasswordProtected: usePassword && password.isNotEmpty,
      hasExpiration: useExpiration && expirationDate != null,
      expirationDate: expirationDate,
      type: QRCodeType.url,
    );
  }

  Future<QRCodeData> generateTextQR(
    String text, {
    bool usePassword = false,
    String password = '',
    bool useExpiration = false,
    DateTime? expirationDate,
  }) async {
    String encodedData = text;

    // Encrypt if password is provided
    if (usePassword && password.isNotEmpty) {
      encodedData = await _encryptionService.encryptData(text, password);
      encodedData = 'ENCRYPTED:$encodedData';
    }

    // Add expiration if enabled
    if (useExpiration && expirationDate != null) {
      final expString = expirationDate.toIso8601String();
      encodedData = 'EXP:$expString:$encodedData';
    }

    return QRCodeData(
      encodedData: encodedData,
      isPasswordProtected: usePassword && password.isNotEmpty,
      hasExpiration: useExpiration && expirationDate != null,
      expirationDate: expirationDate,
      type: QRCodeType.text,
    );
  }

  Future<QRCodeData> generateContactQR({
    required String name,
    String phone = '',
    String email = '',
    bool usePassword = false,
    String password = '',
    bool useExpiration = false,
    DateTime? expirationDate,
  }) async {
    // Create vCard format
    final contactModel = ContactModel(
      name: name,
      phoneNumbers: phone.isNotEmpty ? [PhoneNumber(number: phone)] : [],
      emailAddresses: email.isNotEmpty ? [EmailAddress(email: email)] : [],
    );

    String vcard = contactModel.toVCard();
    String encodedData = vcard;

    // Encrypt if password is provided
    if (usePassword && password.isNotEmpty) {
      encodedData = await _encryptionService.encryptData(vcard, password);
      encodedData = 'ENCRYPTED:$encodedData';
    }

    // Add expiration if enabled
    if (useExpiration && expirationDate != null) {
      final expString = expirationDate.toIso8601String();
      encodedData = 'EXP:$expString:$encodedData';
    }

    return QRCodeData(
      encodedData: encodedData,
      isPasswordProtected: usePassword && password.isNotEmpty,
      hasExpiration: useExpiration && expirationDate != null,
      expirationDate: expirationDate,
      type: QRCodeType.contact,
    );
  }

  Future<QRCodeData> generateContactQRFromContact(
    Contact contact, {
    bool usePassword = false,
    String password = '',
    bool useExpiration = false,
    DateTime? expirationDate,
  }) async {
    // Extract contact details
    String name = contact.displayName;
    String phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    String email =
        contact.emails.isNotEmpty ? contact.emails.first.address : '';

    return generateContactQR(
      name: name,
      phone: phone,
      email: email,
      usePassword: usePassword,
      password: password,
      useExpiration: useExpiration,
      expirationDate: expirationDate,
    );
  }

  // NEW: Generate Wi-Fi QR code
  Future<QRCodeData> generateWiFiQR(
    WiFiNetwork network, {
    bool usePassword = false,
    String password = '',
    bool useExpiration = false,
    DateTime? expirationDate,
  }) async {
    // Generate Wi-Fi QR string format: WIFI:T:WPA;S:mynetwork;P:mypass;H:false;;
    String wifiQRString = network.toQRString();
    String encodedData = wifiQRString;

    // Apply encryption if password protection is enabled
    if (usePassword && password.isNotEmpty) {
      encodedData = await _encryptionService.encryptData(
        wifiQRString,
        password,
      );
      encodedData = 'ENCRYPTED:$encodedData';
    }

    // Add expiration if enabled
    if (useExpiration && expirationDate != null) {
      final expString = expirationDate.toIso8601String();
      encodedData = 'EXP:$expString:$encodedData';
    }

    return QRCodeData(
      encodedData: encodedData,
      isPasswordProtected: usePassword && password.isNotEmpty,
      hasExpiration: useExpiration && expirationDate != null,
      expirationDate: expirationDate,
      type: QRCodeType.wifi,
    );
  }

  // NEW: Generate multiple contact QR codes with different formats
  Future<List<QRCodeData>> generateMultipleContactQRs(
    Contact contact, {
    bool includeBasic = true,
    bool includeDetailed = true,
    bool includePhoneOnly = false,
    bool includeEmailOnly = false,
    bool usePassword = false,
    String password = '',
    bool useExpiration = false,
    DateTime? expirationDate,
  }) async {
    List<QRCodeData> qrCodes = [];

    if (includeBasic) {
      // Basic contact info
      final basicQR = await generateContactQRFromContact(
        contact,
        usePassword: usePassword,
        password: password,
        useExpiration: useExpiration,
        expirationDate: expirationDate,
      );
      qrCodes.add(basicQR);
    }

    if (includePhoneOnly && contact.phones.isNotEmpty) {
      // Phone number only
      final phoneQR = await generateContactQR(
        name: contact.displayName,
        phone: contact.phones.first.number,
        usePassword: usePassword,
        password: password,
        useExpiration: useExpiration,
        expirationDate: expirationDate,
      );
      qrCodes.add(phoneQR);
    }

    if (includeEmailOnly && contact.emails.isNotEmpty) {
      // Email only
      final emailQR = await generateContactQR(
        name: contact.displayName,
        email: contact.emails.first.address,
        usePassword: usePassword,
        password: password,
        useExpiration: useExpiration,
        expirationDate: expirationDate,
      );
      qrCodes.add(emailQR);
    }

    if (includeDetailed) {
      // Detailed vCard with all information
      final contactModel = ContactModel.fromContact(contact);
      String detailedVCard = contactModel.toVCard();

      String encodedData = detailedVCard;

      // Encrypt if password is provided
      if (usePassword && password.isNotEmpty) {
        encodedData = await _encryptionService.encryptData(
          detailedVCard,
          password,
        );
        encodedData = 'ENCRYPTED:$encodedData';
      }

      // Add expiration if enabled
      if (useExpiration && expirationDate != null) {
        final expString = expirationDate.toIso8601String();
        encodedData = 'EXP:$expString:$encodedData';
      }

      final detailedQR = QRCodeData(
        encodedData: encodedData,
        isPasswordProtected: usePassword && password.isNotEmpty,
        hasExpiration: useExpiration && expirationDate != null,
        expirationDate: expirationDate,
        type: QRCodeType.contact,
      );
      qrCodes.add(detailedQR);
    }

    return qrCodes;
  }

  // NEW: Parse and decrypt QR code data
  Future<String> parseQRCode(String qrData, {String? password}) async {
    String dataToProcess = qrData;

    // Handle expiration
    if (dataToProcess.startsWith('EXP:')) {
      final parts = dataToProcess.split(':');
      if (parts.length >= 3) {
        final expirationDate = DateTime.parse(parts[1]);
        if (DateTime.now().isAfter(expirationDate)) {
          throw Exception('QR code has expired');
        }
        dataToProcess = parts.sublist(2).join(':');
      }
    }

    // Handle encryption
    if (dataToProcess.startsWith('ENCRYPTED:')) {
      if (password == null || password.isEmpty) {
        throw Exception('Password required to decrypt QR code');
      }
      final encryptedData = dataToProcess.substring(10);
      dataToProcess = await _encryptionService.decryptData(
        encryptedData,
        password,
      );
    }

    return dataToProcess;
  }

  // NEW: Validate QR code format
  bool validateQRFormat(String qrData) {
    // Remove encryption and expiration wrappers
    String cleanData = qrData;

    if (cleanData.startsWith('EXP:')) {
      final parts = cleanData.split(':');
      if (parts.length >= 3) {
        cleanData = parts.sublist(2).join(':');
      }
    }

    if (cleanData.startsWith('ENCRYPTED:')) {
      // Can't validate encrypted data without decryption
      return true;
    }

    // Check common formats
    if (cleanData.startsWith('http://') || cleanData.startsWith('https://')) {
      return _isValidUrl(cleanData);
    } else if (cleanData.startsWith('BEGIN:VCARD')) {
      return _isValidVCard(cleanData);
    } else if (cleanData.startsWith('WIFI:')) {
      return _isValidWiFiQR(cleanData);
    }

    // For plain text, always valid
    return true;
  }

  // Helper methods for validation
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  bool _isValidVCard(String vcard) {
    return vcard.contains('BEGIN:VCARD') &&
        vcard.contains('END:VCARD') &&
        vcard.contains('FN:');
  }

  bool _isValidWiFiQR(String wifiString) {
    // Check for basic Wi-Fi QR format
    final regex = RegExp(r'WIFI:T:[^;]*;S:[^;]*;P:[^;]*;H:[^;]*;');
    return regex.hasMatch(wifiString);
  }
}
