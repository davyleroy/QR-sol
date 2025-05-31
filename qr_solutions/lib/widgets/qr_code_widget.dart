// ENHANCED: QR Code widget with better styling and animation support
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/qr_code_data.dart';

class QRCodeWidget extends StatelessWidget {
  final QRCodeData qrData;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final bool showSecurityBadge;
  final bool showExpirationBadge;
  final VoidCallback? onTap;
  final bool showShadow;

  const QRCodeWidget({
    super.key,
    required this.qrData,
    this.size = 200.0,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(12.0)),
    this.showSecurityBadge = true,
    this.showExpirationBadge = true,
    this.onTap,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // QR Code with container
          Container(
            width: size,
            height: size,
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              boxShadow:
                  showShadow
                      ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: Offset(0, 4),
                        ),
                      ]
                      : null,
            ),
            child: QrImageView(
              data: qrData.encodedData,
              version: QrVersions.auto,
              size: size - (padding.horizontal),
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              errorStateBuilder: (context, error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Error generating QR code',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Security badge
          if (showSecurityBadge && qrData.isPasswordProtected)
            Positioned(
              top: padding.top + 4,
              right: padding.right + 4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: Colors.white, size: 12),
                    SizedBox(width: 3),
                    Text(
                      'Secured',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Expiration badge
          if (showExpirationBadge && qrData.hasExpiration)
            Positioned(
              bottom: padding.bottom + 4,
              left: padding.left + 4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: qrData.isExpired ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      qrData.isExpired ? Icons.timer_off : Icons.timer,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 3),
                    Text(
                      qrData.isExpired ? 'Expired' : 'Expires',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Type indicator (optional)
          if (onTap != null)
            Positioned(
              top: padding.top + 4,
              left: padding.left + 4,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(qrData.type),
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(QRCodeType type) {
    switch (type) {
      case QRCodeType.url:
        return Icons.link;
      case QRCodeType.contact:
        return Icons.contact_page;
      case QRCodeType.text:
        return Icons.text_snippet;
      case QRCodeType.wifi:
        return Icons.wifi;
    }
  }
}

// Enhanced version with animation
class AnimatedQRCodeWidget extends StatefulWidget {
  final QRCodeData qrData;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final bool showSecurityBadge;
  final bool showExpirationBadge;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final bool showShadow;

  const AnimatedQRCodeWidget({
    super.key,
    required this.qrData,
    this.size = 200.0,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(12.0)),
    this.showSecurityBadge = true,
    this.showExpirationBadge = true,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 300),
    this.showShadow = true,
  });

  @override
  _AnimatedQRCodeWidgetState createState() => _AnimatedQRCodeWidgetState();
}

class _AnimatedQRCodeWidgetState extends State<AnimatedQRCodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: QRCodeWidget(
              qrData: widget.qrData,
              size: widget.size,
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.foregroundColor,
              padding: widget.padding,
              borderRadius: widget.borderRadius,
              showSecurityBadge: widget.showSecurityBadge,
              showExpirationBadge: widget.showExpirationBadge,
              onTap: widget.onTap,
              showShadow: widget.showShadow,
            ),
          ),
        );
      },
    );
  }
}

// Interactive QR Code widget with hover effects (for desktop/web)
class InteractiveQRCodeWidget extends StatefulWidget {
  final QRCodeData qrData;
  final double size;
  final VoidCallback? onTap;
  final bool showTooltip;

  const InteractiveQRCodeWidget({
    super.key,
    required this.qrData,
    this.size = 200.0,
    this.onTap,
    this.showTooltip = true,
  });

  @override
  _InteractiveQRCodeWidgetState createState() =>
      _InteractiveQRCodeWidgetState();
}

class _InteractiveQRCodeWidgetState extends State<InteractiveQRCodeWidget>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget qrWidget = MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _hoverController.reverse();
      },
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: QRCodeWidget(
              qrData: widget.qrData,
              size: widget.size,
              onTap: widget.onTap,
              backgroundColor: _isHovering ? Colors.grey[50]! : Colors.white,
            ),
          );
        },
      ),
    );

    if (widget.showTooltip) {
      return Tooltip(message: _getTooltipMessage(), child: qrWidget);
    }

    return qrWidget;
  }

  String _getTooltipMessage() {
    String baseMessage = 'QR Code';

    if (widget.qrData.title != null) {
      baseMessage = widget.qrData.title!;
    }

    List<String> additionalInfo = [];

    if (widget.qrData.isPasswordProtected) {
      additionalInfo.add('Password Protected');
    }

    if (widget.qrData.hasExpiration) {
      if (widget.qrData.isExpired) {
        additionalInfo.add('Expired');
      } else {
        additionalInfo.add(
          'Expires: ${widget.qrData.expirationDate?.toString().split(' ')[0]}',
        );
      }
    }

    if (additionalInfo.isNotEmpty) {
      baseMessage += '\n${additionalInfo.join(', ')}';
    }

    return baseMessage;
  }
}
