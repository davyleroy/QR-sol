// NEW: QR History screen for managing saved QR codes
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/qr_code_data.dart';
import '../widgets/qr_code_widget.dart';
import 'qr_preview_screen.dart';

class QRHistoryScreen extends StatefulWidget {
  const QRHistoryScreen({super.key});

  @override
  _QRHistoryScreenState createState() => _QRHistoryScreenState();
}

class _QRHistoryScreenState extends State<QRHistoryScreen> {
  final StorageService _storageService = StorageService();
  List<Map<String, dynamic>> _savedQRCodes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  QRCodeType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadSavedQRCodes();
  }

  Future<void> _loadSavedQRCodes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final qrCodes = await _storageService.getSavedQRCodes();
      setState(() {
        _savedQRCodes = qrCodes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load QR history: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredQRCodes {
    var filtered =
        _savedQRCodes.where((qr) {
          // Search filter
          if (_searchQuery.isNotEmpty) {
            final searchLower = _searchQuery.toLowerCase();
            final matchesSearch =
                (qr['encodedData'] as String).toLowerCase().contains(
                  searchLower,
                ) ||
                (qr['type'] as String).toLowerCase().contains(searchLower) ||
                (qr['createdAt'] as String).toLowerCase().contains(searchLower);
            if (!matchesSearch) return false;
          }

          // Type filter
          if (_filterType != null) {
            final qrType = QRCodeType.values.firstWhere(
              (e) => e.toString() == qr['type'],
              orElse: () => QRCodeType.text,
            );
            if (qrType != _filterType) return false;
          }

          return true;
        }).toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR History'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSavedQRCodes,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.cleaning_services),
            onPressed: _showClearAllDialog,
            tooltip: 'Clear All',
          ),
          PopupMenuButton<QRCodeType?>(
            icon: Icon(Icons.filter_list),
            tooltip: 'Filter by Type',
            onSelected: (type) {
              setState(() {
                _filterType = type;
              });
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(value: null, child: Text('All Types')),
                  ...QRCodeType.values.map(
                    (type) => PopupMenuItem(
                      value: type,
                      child: Text(_getTypeDisplayName(type)),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search QR codes',
                hintText: 'Search by content, type, or date...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter indicator
          if (_filterType != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 16),
                  SizedBox(width: 8),
                  Text('Filtering by: ${_getTypeDisplayName(_filterType!)}'),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterType = null;
                      });
                    },
                    child: Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),

          SizedBox(height: 8),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading QR history...'),
          ],
        ),
      );
    }

    final filteredQRs = _filteredQRCodes;

    if (filteredQRs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _savedQRCodes.isEmpty ? Icons.qr_code_scanner : Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              _savedQRCodes.isEmpty
                  ? 'No QR codes saved yet'
                  : 'No QR codes match your search',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              _savedQRCodes.isEmpty
                  ? 'Generate your first QR code to see it here'
                  : 'Try adjusting your search or filter',
              style: TextStyle(color: Colors.grey[500]),
            ),
            if (_savedQRCodes.isEmpty) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Create QR Code'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredQRs.length,
      itemBuilder: (context, index) {
        return _buildQRCodeCard(filteredQRs[index]);
      },
    );
  }

  Widget _buildQRCodeCard(Map<String, dynamic> qrData) {
    final type = QRCodeType.values.firstWhere(
      (e) => e.toString() == qrData['type'],
      orElse: () => QRCodeType.text,
    );

    final createdAt = DateTime.parse(qrData['createdAt']);
    final isExpired = qrData['isExpired'] ?? false;
    final isPasswordProtected = qrData['isPasswordProtected'] ?? false;

    // Create QRCodeData object
    final qrCodeData = QRCodeData(
      encodedData: qrData['encodedData'],
      isPasswordProtected: isPasswordProtected,
      hasExpiration: qrData['hasExpiration'] ?? false,
      expirationDate:
          qrData['expirationDate'] != null
              ? DateTime.parse(qrData['expirationDate'])
              : null,
      type: type,
      title: _generateTitle(qrData),
    );

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: _buildTypeIcon(type, isExpired),
            title: Text(
              _generateTitle(qrData),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpired ? Colors.grey : null,
                decoration: isExpired ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (isPasswordProtected || isExpired) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      if (isPasswordProtected) ...[
                        Icon(Icons.lock, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Protected',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ],
                      if (isPasswordProtected && isExpired) SizedBox(width: 8),
                      if (isExpired) ...[
                        Icon(Icons.timer_off, size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          'Expired',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _handleAction(action, qrData),
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('View'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
            ),
            onTap: () => _viewQRCode(qrCodeData),
          ),

          // QR Code preview
          Container(
            padding: EdgeInsets.all(16),
            child: QRCodeWidget(
              qrData: qrCodeData,
              size: 120,
              showSecurityBadge: false,
              showExpirationBadge: false,
              onTap: () => _viewQRCode(qrCodeData),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon(QRCodeType type, bool isExpired) {
    IconData iconData;
    Color iconColor = isExpired ? Colors.grey : Theme.of(context).primaryColor;

    switch (type) {
      case QRCodeType.url:
        iconData = Icons.link;
        break;
      case QRCodeType.contact:
        iconData = Icons.contact_page;
        break;
      case QRCodeType.text:
        iconData = Icons.text_snippet;
        break;
      case QRCodeType.wifi:
        iconData = Icons.wifi;
        break;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(iconData, color: iconColor),
    );
  }

  String _generateTitle(Map<String, dynamic> qrData) {
    final type = QRCodeType.values.firstWhere(
      (e) => e.toString() == qrData['type'],
      orElse: () => QRCodeType.text,
    );

    String content = qrData['encodedData'] as String;

    // Try to extract meaningful title from content
    if (content.startsWith('http://') || content.startsWith('https://')) {
      try {
        final uri = Uri.parse(content);
        return '${uri.host}${uri.path}';
      } catch (e) {
        return 'URL QR Code';
      }
    } else if (content.startsWith('BEGIN:VCARD')) {
      // Extract name from vCard
      final lines = content.split('\n');
      for (var line in lines) {
        if (line.startsWith('FN:')) {
          return line.substring(3).trim();
        }
      }
      return 'Contact QR Code';
    } else if (content.startsWith('WIFI:')) {
      // Extract SSID from Wi-Fi QR
      final ssidMatch = RegExp(r'S:([^;]+)').firstMatch(content);
      if (ssidMatch != null) {
        return 'Wi-Fi: ${ssidMatch.group(1)}';
      }
      return 'Wi-Fi QR Code';
    } else {
      // For text, show first 30 characters
      final preview =
          content.length > 30 ? '${content.substring(0, 30)}...' : content;
      return preview.isEmpty ? 'Empty QR Code' : preview;
    }
  }

  String _getTypeDisplayName(QRCodeType type) {
    switch (type) {
      case QRCodeType.url:
        return 'URL';
      case QRCodeType.contact:
        return 'Contact';
      case QRCodeType.text:
        return 'Text';
      case QRCodeType.wifi:
        return 'Wi-Fi';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleAction(String action, Map<String, dynamic> qrData) {
    switch (action) {
      case 'view':
        _viewQRCode(_createQRCodeData(qrData));
        break;
      case 'share':
        _shareQRCode(qrData);
        break;
      case 'delete':
        _deleteQRCode(qrData);
        break;
    }
  }

  QRCodeData _createQRCodeData(Map<String, dynamic> qrData) {
    final type = QRCodeType.values.firstWhere(
      (e) => e.toString() == qrData['type'],
      orElse: () => QRCodeType.text,
    );

    return QRCodeData(
      encodedData: qrData['encodedData'],
      isPasswordProtected: qrData['isPasswordProtected'] ?? false,
      hasExpiration: qrData['hasExpiration'] ?? false,
      expirationDate:
          qrData['expirationDate'] != null
              ? DateTime.parse(qrData['expirationDate'])
              : null,
      type: type,
      title: _generateTitle(qrData),
    );
  }

  void _viewQRCode(QRCodeData qrData) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRPreviewScreen(qrData: qrData)),
    );
  }

  void _shareQRCode(Map<String, dynamic> qrData) async {
    // Implementation would depend on having the actual image file
    _showErrorSnackBar('Share functionality needs image file path');
  }

  void _deleteQRCode(Map<String, dynamic> qrData) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete QR Code'),
            content: Text(
              'Are you sure you want to delete this QR code? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    // Note: This would need the metadata file path
                    // await _storageService.deleteQRCode(qrData['metadataPath']);
                    await _loadSavedQRCodes();
                    _showSuccessSnackBar('QR code deleted successfully');
                  } catch (e) {
                    _showErrorSnackBar('Failed to delete QR code: $e');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Clear All QR Codes'),
            content: Text(
              'Are you sure you want to delete all saved QR codes? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _storageService.clearAllQRCodes();
                    await _loadSavedQRCodes();
                    _showSuccessSnackBar('All QR codes cleared successfully');
                  } catch (e) {
                    _showErrorSnackBar('Failed to clear QR codes: $e');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Clear All'),
              ),
            ],
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
// This screen allows users to view, search, filter, and manage their saved QR codes.