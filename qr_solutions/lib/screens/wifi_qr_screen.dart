// Enhanced Wi-Fi QR code generation screen with correct imports
import 'package:flutter/material.dart';
import '../services/wifi_services.dart'; // FIXED: Correct import path
import '../services/qr_generator_service.dart';
import '../models/wifi_network.dart';
import '../widgets/security_options_widget.dart';
import 'qr_preview_screen.dart';

class WiFiQRScreen extends StatefulWidget {
  const WiFiQRScreen({super.key});

  @override
  _WiFiQRScreenState createState() => _WiFiQRScreenState();
}

class _WiFiQRScreenState extends State<WiFiQRScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  WiFiSecurityType _securityType = WiFiSecurityType.WPA;
  bool _isHidden = false;
  bool _usePassword = false;
  bool _useExpiration = false;
  String _qrPassword = '';
  DateTime? _expirationDate;

  final WiFiService _wifiService = WiFiService(); // This should now work
  List<WiFiNetwork> _savedNetworks = [];
  List<WiFiNetwork> _filteredNetworks = [];
  bool _isLoading = false;
  bool _showSavedNetworks = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    _loadSavedNetworks();
    _detectCurrentNetwork();
    _searchController.addListener(_filterNetworks);
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedNetworks() async {
    setState(() => _isLoading = true);
    try {
      final networks = await _wifiService.getSavedNetworks();
      setState(() {
        _savedNetworks = networks;
        _filteredNetworks = networks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load saved networks: $e');
    }
  }

  Future<void> _detectCurrentNetwork() async {
    try {
      final currentNetwork = await _wifiService.getCurrentNetwork();
      if (currentNetwork != null && mounted) {
        setState(() {
          _ssidController.text = currentNetwork.ssid;
          _securityType = currentNetwork.securityType;
          _isHidden = currentNetwork.hidden;
        });
        _showSnackBar('Current network detected: ${currentNetwork.ssid}');
      }
    } catch (e) {
      // Silently fail - current network detection is optional
      print('Network detection failed: $e');
    }
  }

  void _filterNetworks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNetworks =
          _savedNetworks.where((network) {
            return network.ssid.toLowerCase().contains(query);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Column(
      children: [
        // Search and controls
        _buildControlsSection(),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Manual Wi-Fi input section
                _buildManualInputSection(),

                SizedBox(height: 24),

                // Saved networks section
                if (_showSavedNetworks) ...[
                  _buildSavedNetworksSection(),
                  SizedBox(height: 24),
                ],

                // Security options
                SecurityOptionsWidget(
                  onPasswordToggled: (value) {
                    setState(() {
                      _usePassword = value;
                    });
                  },
                  onPasswordChanged: (value) {
                    _qrPassword = value;
                  },
                  onExpirationToggled: (value) {
                    setState(() {
                      _useExpiration = value;
                    });
                  },
                  onExpirationDateChanged: (date) {
                    _expirationDate = date;
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Quick actions row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _detectCurrentNetwork,
                  icon: Icon(Icons.wifi_find, size: 16),
                  label: Text('Detect Current'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _clearForm,
                icon: Icon(Icons.clear, size: 16),
                label: Text('Clear'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSavedNetworks = !_showSavedNetworks;
                  });
                },
                icon: Icon(
                  _showSavedNetworks ? Icons.visibility_off : Icons.visibility,
                ),
                tooltip: _showSavedNetworks ? 'Hide Saved' : 'Show Saved',
              ),
            ],
          ),

          // Search bar (only show when saved networks are visible)
          if (_showSavedNetworks && _savedNetworks.isNotEmpty) ...[
            SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search networks...',
                prefixIcon: Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManualInputSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  'Wi-Fi Network Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),

            // SSID input
            TextField(
              controller: _ssidController,
              decoration: InputDecoration(
                labelText: 'Network Name (SSID) *',
                border: OutlineInputBorder(),
                hintText: 'Enter Wi-Fi network name',
                prefixIcon: Icon(Icons.wifi),
                suffixIcon:
                    _ssidController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _ssidController.clear();
                          },
                        )
                        : null,
              ),
            ),
            SizedBox(height: 12),

            // Security type selection
            DropdownButtonFormField<WiFiSecurityType>(
              value: _securityType,
              decoration: InputDecoration(
                labelText: 'Security Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              items:
                  WiFiSecurityType.values.map((type) {
                    String displayName;
                    IconData icon;
                    switch (type) {
                      case WiFiSecurityType.nopass:
                        displayName = 'No Password (Open)';
                        icon = Icons.wifi;
                        break;
                      case WiFiSecurityType.WEP:
                        displayName = 'WEP';
                        icon = Icons.wifi_lock;
                        break;
                      case WiFiSecurityType.WPA:
                        displayName = 'WPA/WPA2';
                        icon = Icons.wifi_lock;
                        break;
                    }
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(icon, size: 16),
                          SizedBox(width: 8),
                          Text(displayName),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _securityType = value!;
                  if (_securityType == WiFiSecurityType.nopass) {
                    _passwordController.clear();
                  }
                });
              },
            ),
            SizedBox(height: 12),

            // Password input (only if not open network)
            if (_securityType != WiFiSecurityType.nopass)
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Wi-Fi Password *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter Wi-Fi password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),

            if (_securityType != WiFiSecurityType.nopass) SizedBox(height: 12),

            // Hidden network toggle
            Card(
              color: Colors.grey[50],
              child: SwitchListTile(
                title: Text('Hidden Network'),
                subtitle: Text('Check if this is a hidden Wi-Fi network'),
                value: _isHidden,
                onChanged: (value) {
                  setState(() {
                    _isHidden = value;
                  });
                },
                secondary: Icon(Icons.visibility_off),
              ),
            ),

            SizedBox(height: 16),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canGenerateQR() ? _generateManualWiFiQR : null,
                icon: Icon(Icons.qr_code),
                label: Text('Generate Wi-Fi QR Code'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedNetworksSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Theme.of(context).primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Saved Networks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_savedNetworks.isNotEmpty) ...[
                      SizedBox(width: 8),
                      Chip(
                        label: Text('${_filteredNetworks.length}'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: _loadSavedNetworks,
                      tooltip: 'Refresh',
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _showAddNetworkDialog,
                      tooltip: 'Add Network Manually',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),

            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading networks...'),
                    ],
                  ),
                ),
              )
            else if (_filteredNetworks.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      _savedNetworks.isEmpty
                          ? Icons.wifi_off
                          : Icons.search_off,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _savedNetworks.isEmpty
                          ? 'No saved networks found'
                          : 'No networks match your search',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (_savedNetworks.isEmpty) ...[
                      SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showAddNetworkDialog,
                        icon: Icon(Icons.add),
                        label: Text('Add Network Manually'),
                      ),
                    ],
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _filteredNetworks.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final network = _filteredNetworks[index];
                  return _buildNetworkCard(network);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard(WiFiNetwork network) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(
          _getSecurityIcon(network.securityType),
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(network.ssid, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getSecurityDisplayName(network.securityType)),
          if (network.hidden)
            Text(
              'Hidden Network',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          Text(
            'Last used: ${_formatDate(network.lastConnected)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => _handleNetworkAction(action, network),
        itemBuilder:
            (context) => [
              PopupMenuItem(
                value: 'use',
                child: Row(
                  children: [
                    Icon(Icons.input),
                    SizedBox(width: 8),
                    Text('Use This Network'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'qr',
                child: Row(
                  children: [
                    Icon(Icons.qr_code),
                    SizedBox(width: 8),
                    Text('Generate QR'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
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
      onTap: () => _useNetwork(network),
      isThreeLine: true,
    );
  }

  // Helper methods
  IconData _getSecurityIcon(WiFiSecurityType type) {
    switch (type) {
      case WiFiSecurityType.nopass:
        return Icons.wifi;
      case WiFiSecurityType.WEP:
      case WiFiSecurityType.WPA:
        return Icons.wifi_lock;
    }
  }

  String _getSecurityDisplayName(WiFiSecurityType type) {
    switch (type) {
      case WiFiSecurityType.nopass:
        return 'Open Network';
      case WiFiSecurityType.WEP:
        return 'WEP Security';
      case WiFiSecurityType.WPA:
        return 'WPA/WPA2 Security';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _canGenerateQR() {
    if (_ssidController.text.isEmpty) return false;
    if (_securityType != WiFiSecurityType.nopass &&
        _passwordController.text.isEmpty) {
      return false;
    }
    return true;
  }

  void _clearForm() {
    setState(() {
      _ssidController.clear();
      _passwordController.clear();
      _securityType = WiFiSecurityType.WPA;
      _isHidden = false;
    });
  }

  void _useNetwork(WiFiNetwork network) {
    setState(() {
      _ssidController.text = network.ssid;
      _passwordController.text = network.password;
      _securityType = network.securityType;
      _isHidden = network.hidden;
    });
    _showSnackBar('Network loaded: ${network.ssid}');
  }

  void _handleNetworkAction(String action, WiFiNetwork network) {
    switch (action) {
      case 'use':
        _useNetwork(network);
        break;
      case 'qr':
        _generateNetworkQR(network);
        break;
      case 'edit':
        _editNetwork(network);
        break;
      case 'delete':
        _deleteNetwork(network);
        break;
    }
  }

  // Action methods
  void _generateManualWiFiQR() async {
    if (!_canGenerateQR()) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    try {
      final network = WiFiNetwork(
        ssid: _ssidController.text,
        password: _passwordController.text,
        securityType: _securityType,
        hidden: _isHidden,
        lastConnected: DateTime.now(),
      );

      // Save network for future use
      await _wifiService.saveNetwork(network);
      await _loadSavedNetworks();

      await _generateNetworkQR(network);
    } catch (e) {
      _showErrorSnackBar('Error generating Wi-Fi QR: $e');
    }
  }

  Future<void> _generateNetworkQR(WiFiNetwork network) async {
    try {
      final qrData = await QRGeneratorService().generateWiFiQR(
        network,
        usePassword: _usePassword,
        password: _qrPassword,
        useExpiration: _useExpiration,
        expirationDate: _expirationDate,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRPreviewScreen(qrData: qrData),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error generating QR code: $e');
    }
  }

  void _editNetwork(WiFiNetwork network) {
    _useNetwork(network);
  }

  void _showAddNetworkDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AddWiFiNetworkDialog(
            onNetworkAdded: (network) async {
              await _wifiService.saveNetwork(network);
              await _loadSavedNetworks();
            },
          ),
    );
  }

  void _deleteNetwork(WiFiNetwork network) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Network'),
            content: Text('Are you sure you want to delete "${network.ssid}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _wifiService.deleteNetwork(network.ssid);
        await _loadSavedNetworks();
        _showSuccessSnackBar('Network deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Error deleting network: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

// Dialog for manually adding Wi-Fi networks
class AddWiFiNetworkDialog extends StatefulWidget {
  final Function(WiFiNetwork) onNetworkAdded;

  const AddWiFiNetworkDialog({Key? key, required this.onNetworkAdded})
    : super(key: key);

  @override
  _AddWiFiNetworkDialogState createState() => _AddWiFiNetworkDialogState();
}

class _AddWiFiNetworkDialogState extends State<AddWiFiNetworkDialog> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  WiFiSecurityType _securityType = WiFiSecurityType.WPA;
  bool _isHidden = false;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Wi-Fi Network'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ssidController,
              decoration: InputDecoration(
                labelText: 'Network Name (SSID)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),

            DropdownButtonFormField<WiFiSecurityType>(
              value: _securityType,
              decoration: InputDecoration(
                labelText: 'Security Type',
                border: OutlineInputBorder(),
              ),
              items:
                  WiFiSecurityType.values.map((type) {
                    String displayName;
                    switch (type) {
                      case WiFiSecurityType.nopass:
                        displayName = 'No Password (Open)';
                        break;
                      case WiFiSecurityType.WEP:
                        displayName = 'WEP';
                        break;
                      case WiFiSecurityType.WPA:
                        displayName = 'WPA/WPA2';
                        break;
                    }
                    return DropdownMenuItem(
                      value: type,
                      child: Text(displayName),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _securityType = value!;
                });
              },
            ),
            SizedBox(height: 12),

            if (_securityType != WiFiSecurityType.nopass)
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),

            if (_securityType != WiFiSecurityType.nopass) SizedBox(height: 12),

            SwitchListTile(
              title: Text('Hidden Network'),
              value: _isHidden,
              onChanged: (value) {
                setState(() {
                  _isHidden = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(onPressed: _addNetwork, child: Text('Add')),
      ],
    );
  }

  void _addNetwork() {
    if (_ssidController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter network name')));
      return;
    }

    if (_securityType != WiFiSecurityType.nopass &&
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter password')));
      return;
    }

    final network = WiFiNetwork(
      ssid: _ssidController.text,
      password: _passwordController.text,
      securityType: _securityType,
      hidden: _isHidden,
      lastConnected: DateTime.now(),
    );

    widget.onNetworkAdded(network);
    Navigator.pop(context);
  }
}
