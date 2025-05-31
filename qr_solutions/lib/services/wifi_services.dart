import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../models/wifi_network.dart';
import '../models/qr_code_data.dart';
import 'encryption_service.dart';

class WiFiService {
  static const String _savedNetworksKey = 'saved_wifi_networks';
  static const String _lastScanKey = 'last_wifi_scan';
  static const MethodChannel _wifiChannel = MethodChannel(
    'com.qrsolutions.wifi',
  );

  final EncryptionService _encryptionService = EncryptionService();

  // ============================================================================
  // NETWORK STORAGE MANAGEMENT
  // ============================================================================

  /// Get all saved Wi-Fi networks
  Future<List<WiFiNetwork>> getSavedNetworks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final networksJson = prefs.getStringList(_savedNetworksKey) ?? [];

      return networksJson
          .map((json) => WiFiNetwork.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.lastConnected.compareTo(a.lastConnected));
    } catch (e) {
      throw Exception('Failed to load saved networks: $e');
    }
  }

  /// Save a Wi-Fi network
  Future<void> saveNetwork(WiFiNetwork network) async {
    try {
      final networks = await getSavedNetworks();

      // Remove existing network with same SSID if it exists
      networks.removeWhere((existing) => existing.ssid == network.ssid);

      // Add the new/updated network
      networks.insert(0, network);

      // Keep only the last 50 networks to prevent storage bloat
      if (networks.length > 50) {
        networks.removeRange(50, networks.length);
      }

      final prefs = await SharedPreferences.getInstance();
      final networksJson =
          networks.map((network) => jsonEncode(network.toJson())).toList();

      await prefs.setStringList(_savedNetworksKey, networksJson);
    } catch (e) {
      throw Exception('Failed to save network: $e');
    }
  }

  /// Delete a saved Wi-Fi network by SSID
  Future<void> deleteNetwork(String ssid) async {
    try {
      final networks = await getSavedNetworks();
      networks.removeWhere((network) => network.ssid == ssid);

      final prefs = await SharedPreferences.getInstance();
      final networksJson =
          networks.map((network) => jsonEncode(network.toJson())).toList();

      await prefs.setStringList(_savedNetworksKey, networksJson);
    } catch (e) {
      throw Exception('Failed to delete network: $e');
    }
  }

  /// Update last connected time for a network
  Future<void> updateLastConnected(String ssid) async {
    try {
      final networks = await getSavedNetworks();
      final networkIndex = networks.indexWhere((n) => n.ssid == ssid);

      if (networkIndex != -1) {
        final updatedNetwork = WiFiNetwork(
          ssid: networks[networkIndex].ssid,
          password: networks[networkIndex].password,
          securityType: networks[networkIndex].securityType,
          hidden: networks[networkIndex].hidden,
          lastConnected: DateTime.now(),
        );

        networks[networkIndex] = updatedNetwork;
        await _saveNetworkList(networks);
      }
    } catch (e) {
      throw Exception('Failed to update last connected: $e');
    }
  }

  /// Clear all saved networks
  Future<void> clearAllNetworks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedNetworksKey);
    } catch (e) {
      throw Exception('Failed to clear networks: $e');
    }
  }

  // ============================================================================
  // WI-FI NETWORK DETECTION
  // ============================================================================

  /// Get currently available Wi-Fi networks (requires platform implementation)
  Future<List<WiFiNetwork>> getAvailableNetworks() async {
    try {
      if (Platform.isAndroid) {
        return await _getAndroidNetworks();
      } else if (Platform.isIOS) {
        return await _getIOSNetworks();
      } else {
        // For other platforms, return empty list or throw unsupported
        return [];
      }
    } catch (e) {
      throw Exception('Failed to scan networks: $e');
    }
  }

  /// Get currently connected Wi-Fi network info
  Future<WiFiNetwork?> getCurrentNetwork() async {
    try {
      if (Platform.isAndroid) {
        final result = await _wifiChannel.invokeMethod('getCurrentNetwork');
        if (result != null) {
          return _parseNetworkFromPlatform(result);
        }
      } else if (Platform.isIOS) {
        // iOS has limited Wi-Fi access, might not be available
        final result = await _wifiChannel.invokeMethod('getCurrentNetwork');
        if (result != null) {
          return _parseNetworkFromPlatform(result);
        }
      }
      return null;
    } catch (e) {
      // Silently fail for unsupported platforms or permission issues
      return null;
    }
  }

  /// Auto-save currently connected network
  Future<void> autoSaveCurrentNetwork({String? password}) async {
    try {
      final currentNetwork = await getCurrentNetwork();
      if (currentNetwork != null) {
        // Create a copy with the provided password if available
        final networkToSave = WiFiNetwork(
          ssid: currentNetwork.ssid,
          password: password ?? currentNetwork.password,
          securityType: currentNetwork.securityType,
          hidden: currentNetwork.hidden,
          lastConnected: DateTime.now(),
        );

        await saveNetwork(networkToSave);
      }
    } catch (e) {
      throw Exception('Failed to auto-save current network: $e');
    }
  }

  // ============================================================================
  // QR CODE INTEGRATION
  // ============================================================================

  /// Generate Wi-Fi QR code data
  Future<QRCodeData> generateWiFiQR(
    WiFiNetwork network, {
    bool usePassword = false,
    String password = '',
    bool useExpiration = false,
    DateTime? expirationDate,
  }) async {
    try {
      String qrString = network.toQRString();
      String encodedData = qrString;

      // Apply encryption if password protection is enabled
      if (usePassword && password.isNotEmpty) {
        encodedData = await _encryptionService.encryptData(qrString, password);
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
        title: 'Wi-Fi: ${network.ssid}',
      );
    } catch (e) {
      throw Exception('Failed to generate Wi-Fi QR: $e');
    }
  }

  /// Parse Wi-Fi QR code data
  Future<WiFiNetwork?> parseWiFiQR(String qrData, {String? password}) async {
    try {
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

      // Parse Wi-Fi QR format: WIFI:T:WPA;S:mynetwork;P:mypass;H:false;;
      if (dataToProcess.startsWith('WIFI:')) {
        return _parseWiFiQRString(dataToProcess);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to parse Wi-Fi QR: $e');
    }
  }

  // ============================================================================
  // NETWORK MANAGEMENT HELPERS
  // ============================================================================

  /// Check if a network with given SSID exists
  Future<bool> networkExists(String ssid) async {
    final networks = await getSavedNetworks();
    return networks.any((network) => network.ssid == ssid);
  }

  /// Get network by SSID
  Future<WiFiNetwork?> getNetworkBySSID(String ssid) async {
    final networks = await getSavedNetworks();
    try {
      return networks.firstWhere((network) => network.ssid == ssid);
    } catch (e) {
      return null;
    }
  }

  /// Search networks by SSID pattern
  Future<List<WiFiNetwork>> searchNetworks(String query) async {
    final networks = await getSavedNetworks();
    final queryLower = query.toLowerCase();

    return networks
        .where((network) => network.ssid.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Get networks by security type
  Future<List<WiFiNetwork>> getNetworksBySecurityType(
    WiFiSecurityType type,
  ) async {
    final networks = await getSavedNetworks();
    return networks.where((network) => network.securityType == type).toList();
  }

  /// Import networks from a backup
  Future<void> importNetworks(List<Map<String, dynamic>> networksData) async {
    try {
      final networks =
          networksData.map((data) => WiFiNetwork.fromJson(data)).toList();

      for (var network in networks) {
        await saveNetwork(network);
      }
    } catch (e) {
      throw Exception('Failed to import networks: $e');
    }
  }

  /// Export networks for backup
  Future<List<Map<String, dynamic>>> exportNetworks() async {
    try {
      final networks = await getSavedNetworks();
      return networks.map((network) => network.toJson()).toList();
    } catch (e) {
      throw Exception('Failed to export networks: $e');
    }
  }

  /// Get network statistics
  Future<Map<String, dynamic>> getNetworkStatistics() async {
    try {
      final networks = await getSavedNetworks();

      final stats = {
        'totalNetworks': networks.length,
        'openNetworks':
            networks
                .where((n) => n.securityType == WiFiSecurityType.nopass)
                .length,
        'securedNetworks':
            networks
                .where((n) => n.securityType != WiFiSecurityType.nopass)
                .length,
        'hiddenNetworks': networks.where((n) => n.hidden).length,
        'recentlyUsed':
            networks
                .where(
                  (n) => DateTime.now().difference(n.lastConnected).inDays <= 7,
                )
                .length,
      };

      return stats;
    } catch (e) {
      throw Exception('Failed to get network statistics: $e');
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  Future<void> _saveNetworkList(List<WiFiNetwork> networks) async {
    final prefs = await SharedPreferences.getInstance();
    final networksJson =
        networks.map((network) => jsonEncode(network.toJson())).toList();

    await prefs.setStringList(_savedNetworksKey, networksJson);
  }

  Future<List<WiFiNetwork>> _getAndroidNetworks() async {
    try {
      final result = await _wifiChannel.invokeMethod('scanNetworks');
      if (result is List) {
        return result
            .map((networkData) => _parseNetworkFromPlatform(networkData))
            .where((network) => network != null)
            .cast<WiFiNetwork>()
            .toList();
      }
      return [];
    } catch (e) {
      // Platform method not implemented or permission denied
      return [];
    }
  }

  Future<List<WiFiNetwork>> _getIOSNetworks() async {
    try {
      // iOS has very limited Wi-Fi scanning capabilities
      // This would require special entitlements and might not work in most cases
      final result = await _wifiChannel.invokeMethod('scanNetworks');
      if (result is List) {
        return result
            .map((networkData) => _parseNetworkFromPlatform(networkData))
            .where((network) => network != null)
            .cast<WiFiNetwork>()
            .toList();
      }
      return [];
    } catch (e) {
      // iOS doesn't allow Wi-Fi scanning for most apps
      return [];
    }
  }

  WiFiNetwork? _parseNetworkFromPlatform(dynamic networkData) {
    try {
      if (networkData is Map) {
        final ssid = networkData['ssid']?.toString() ?? '';
        final securityTypeStr = networkData['security']?.toString() ?? 'WPA';
        final hidden = networkData['hidden'] == true;

        WiFiSecurityType securityType;
        switch (securityTypeStr.toUpperCase()) {
          case 'NONE':
          case 'OPEN':
            securityType = WiFiSecurityType.nopass;
            break;
          case 'WEP':
            securityType = WiFiSecurityType.WEP;
            break;
          default:
            securityType = WiFiSecurityType.WPA;
            break;
        }

        return WiFiNetwork(
          ssid: ssid,
          password: '', // Platform scanning doesn't provide passwords
          securityType: securityType,
          hidden: hidden,
          lastConnected: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  WiFiNetwork? _parseWiFiQRString(String qrString) {
    try {
      // Parse WIFI:T:WPA;S:mynetwork;P:mypass;H:false;;
      final regex = RegExp(r'WIFI:T:([^;]*);S:([^;]*);P:([^;]*);H:([^;]*);');
      final match = regex.firstMatch(qrString);

      if (match != null) {
        final securityStr = match.group(1) ?? 'WPA';
        final ssid = match.group(2) ?? '';
        final password = match.group(3) ?? '';
        final hiddenStr = match.group(4) ?? 'false';

        WiFiSecurityType securityType;
        switch (securityStr.toUpperCase()) {
          case 'NOPASS':
            securityType = WiFiSecurityType.nopass;
            break;
          case 'WEP':
            securityType = WiFiSecurityType.WEP;
            break;
          default:
            securityType = WiFiSecurityType.WPA;
            break;
        }

        return WiFiNetwork(
          ssid: ssid,
          password: password,
          securityType: securityType,
          hidden: hiddenStr.toLowerCase() == 'true',
          lastConnected: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

// Extension methods for enhanced functionality
extension WiFiNetworkExtensions on WiFiNetwork {
  /// Check if this network requires a password
  bool get requiresPassword => securityType != WiFiSecurityType.nopass;

  /// Get a display-friendly security type name
  String get securityDisplayName {
    switch (securityType) {
      case WiFiSecurityType.nopass:
        return 'Open';
      case WiFiSecurityType.WEP:
        return 'WEP';
      case WiFiSecurityType.WPA:
        return 'WPA/WPA2';
    }
  }

  /// Get an icon name for the security type
  String get securityIcon {
    switch (securityType) {
      case WiFiSecurityType.nopass:
        return 'wifi';
      case WiFiSecurityType.WEP:
      case WiFiSecurityType.WPA:
        return 'wifi_lock';
    }
  }

  /// Create a copy with updated last connected time
  WiFiNetwork copyWithUpdatedTime() {
    return WiFiNetwork(
      ssid: ssid,
      password: password,
      securityType: securityType,
      hidden: hidden,
      lastConnected: DateTime.now(),
    );
  }

  /// Check if network was used recently (within last 7 days)
  bool get isRecentlyUsed {
    return DateTime.now().difference(lastConnected).inDays <= 7;
  }

  /// Get time since last connection as human-readable string
  String get timeSinceLastConnection {
    final difference = DateTime.now().difference(lastConnected);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${lastConnected.day}/${lastConnected.month}/${lastConnected.year}';
    }
  }
}
