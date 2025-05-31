import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import '../models/qr_code_data.dart';

class QRPreviewScreen extends StatefulWidget {
  final QRCodeData qrData;

  const QRPreviewScreen({super.key, required this.qrData});

  @override
  _QRPreviewScreenState createState() => _QRPreviewScreenState();
}

class _QRPreviewScreenState extends State<QRPreviewScreen> {
  final GlobalKey _qrKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Code Preview')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code display
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: QrImageView(
                  data: widget.qrData.encodedData,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ),

            SizedBox(height: 16),

            // Show security info if applicable
            if (widget.qrData.isPasswordProtected ||
                widget.qrData.hasExpiration)
              Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (widget.qrData.isPasswordProtected)
                      Text(
                        'Password Protected: Yes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    if (widget.qrData.hasExpiration)
                      Text(
                        'Expires on: ${widget.qrData.expirationDate?.toString().split(' ')[0]}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),

            SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveQRCode,
                  icon: Icon(Icons.download),
                  label: Text('Save'),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _shareQRCode,
                  icon: Icon(Icons.share),
                  label: Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQRCode() async {
    try {
      // Convert QR widget to image
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to gallery
      final result = await ImageGallerySaver.saveImage(pngBytes);

      if (result['isSuccess']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('QR Code saved to gallery')));
      } else {
        throw Exception('Failed to save image');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving QR Code: $e')));
    }
  }

  Future<void> _shareQRCode() async {
    try {
      // Convert QR widget to image
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Share image
      await Share.shareXFiles([
        XFile.fromData(pngBytes, mimeType: 'image/png', name: 'qr_code.png'),
      ], subject: 'QR Code');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing QR Code: $e')));
    }
  }
}
