import 'package:flutter/material.dart';
import '../services/qr_generator_service.dart';
import '../widgets/security_options_widget.dart';
import 'qr_preview_screen.dart';

class URLQRScreen extends StatefulWidget {
  const URLQRScreen({super.key});

  @override
  _URLQRScreenState createState() => _URLQRScreenState();
}

class _URLQRScreenState extends State<URLQRScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _usePassword = false;
  bool _useExpiration = false;
  String _password = '';
  DateTime? _expirationDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'Enter URL',
              hintText: 'https://example.com',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          SizedBox(height: 16),

          // Security options
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

          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_urlController.text.isNotEmpty) {
                _generateQRCode();
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Please enter a URL')));
              }
            },
            child: Text('Generate QR Code'),
          ),
        ],
      ),
    );
  }

  void _generateQRCode() async {
    final qrData = await QRGeneratorService().generateURLQR(
      _urlController.text,
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
}
