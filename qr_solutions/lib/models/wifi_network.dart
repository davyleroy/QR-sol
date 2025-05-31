// NEW: Wi-Fi network model
// Wi-Fi network model
class WiFiNetwork {
  final String ssid;
  final String password;
  final WiFiSecurityType securityType;
  final bool hidden;
  final DateTime lastConnected;

  WiFiNetwork({
    required this.ssid,
    required this.password,
    required this.securityType,
    this.hidden = false,
    required this.lastConnected,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'password': password,
      'securityType': securityType.toString(),
      'hidden': hidden,
      'lastConnected': lastConnected.toIso8601String(),
    };
  }

  // Create from JSON
  factory WiFiNetwork.fromJson(Map<String, dynamic> json) {
    return WiFiNetwork(
      ssid: json['ssid'],
      password: json['password'],
      securityType: WiFiSecurityType.values.firstWhere(
        (e) => e.toString() == json['securityType'],
        orElse: () => WiFiSecurityType.WPA,
      ),
      hidden: json['hidden'] ?? false,
      lastConnected: DateTime.parse(json['lastConnected']),
    );
  }

  // Generate Wi-Fi QR code string format
  String toQRString() {
    String security =
        securityType == WiFiSecurityType.nopass
            ? 'nopass'
            : securityType == WiFiSecurityType.WEP
            ? 'WEP'
            : 'WPA';
    String hiddenStr = hidden ? 'true' : 'false';

    // Wi-Fi QR format: WIFI:T:WPA;S:mynetwork;P:mypass;H:false;;
    return 'WIFI:T:$security;S:$ssid;P:$password;H:$hiddenStr;;';
  }
}

enum WiFiSecurityType {
  nopass, // No password
  WEP, // WEP encryption
  WPA, // WPA/WPA2 encryption
}
