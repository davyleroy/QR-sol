// UPDATED: Added WiFi type and enhanced QRCodeData model
enum QRCodeType { url, contact, text, wifi }

class QRCodeData {
  final String encodedData;
  final bool isPasswordProtected;
  final bool hasExpiration;
  final DateTime? expirationDate;
  final QRCodeType type;
  final String? title; // NEW: For displaying QR code names
  final Map<String, dynamic>? metadata; // NEW: For storing additional info

  QRCodeData({
    required this.encodedData,
    this.isPasswordProtected = false,
    this.hasExpiration = false,
    this.expirationDate,
    required this.type,
    this.title,
    this.metadata,
  });

  bool get isExpired {
    if (!hasExpiration || expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  // NEW: Copy with method for creating variations
  QRCodeData copyWith({
    String? encodedData,
    bool? isPasswordProtected,
    bool? hasExpiration,
    DateTime? expirationDate,
    QRCodeType? type,
    String? title,
    Map<String, dynamic>? metadata,
  }) {
    return QRCodeData(
      encodedData: encodedData ?? this.encodedData,
      isPasswordProtected: isPasswordProtected ?? this.isPasswordProtected,
      hasExpiration: hasExpiration ?? this.hasExpiration,
      expirationDate: expirationDate ?? this.expirationDate,
      type: type ?? this.type,
      title: title ?? this.title,
      metadata: metadata ?? this.metadata,
    );
  }
}
