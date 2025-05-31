import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/qr_generator_service.dart';
import '../services/contact_service.dart';
import '../widgets/security_options_widget.dart';
import 'qr_preview_screen.dart';

class ContactQRScreen extends StatefulWidget {
  const ContactQRScreen({super.key});

  @override
  _ContactQRScreenState createState() => _ContactQRScreenState();
}

class _ContactQRScreenState extends State<ContactQRScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _usePassword = false;
  bool _useExpiration = false;
  String _password = '';
  DateTime? _expirationDate;
  final ContactService _contactService = ContactService();
  bool _hasContactPermission = false;

  @override
  void initState() {
    super.initState();
    _checkContactPermission();
  }

  Future<void> _checkContactPermission() async {
    final hasPermission = await _contactService.requestContactPermission();
    setState(() {
      _hasContactPermission = hasPermission;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Manual contact input section (unchanged)
            Text(
              'Enter Contact Details:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _generateManualContactQR(),
              child: Text('Generate QR from Input'),
            ),

            Divider(height: 32),

            // Select from contacts
            Text(
              'Or Select from Contacts:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed:
                  _hasContactPermission ? _pickContact : _requestPermission,
              child: Text(
                _hasContactPermission
                    ? 'Select Contact'
                    : 'Grant Contact Access',
              ),
            ),

            // Rest of the UI (unchanged)
            SizedBox(height: 24),
            SecurityOptionsWidget(
              onPasswordToggled: (value) {
                setState(() {
                  _usePassword = value;
                });
              },
              onPasswordChanged: (value) {
                _password = value;
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
    );
  }

  Future<void> _requestPermission() async {
    final hasPermission = await _contactService.requestContactPermission();
    setState(() {
      _hasContactPermission = hasPermission;
    });

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please grant contacts permission to select contacts'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
  }

  void _generateManualContactQR() async {
    // Existing code (unchanged)
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter at least a name')));
      return;
    }

    final qrData = await QRGeneratorService().generateContactQR(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      usePassword: _usePassword,
      password: _password,
      useExpiration: _useExpiration,
      expirationDate: _expirationDate,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRPreviewScreen(qrData: qrData)),
    );
  }

  void _pickContact() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final Contact? contact = await _contactService.pickContact();

      // Close loading indicator
      Navigator.pop(context);

      if (contact != null) {
        final qrData = await QRGeneratorService().generateContactQRFromContact(
          contact,
          usePassword: _usePassword,
          password: _password,
          useExpiration: _useExpiration,
          expirationDate: _expirationDate,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRPreviewScreen(qrData: qrData),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error accessing contacts: $e')));
    }
  }
}
