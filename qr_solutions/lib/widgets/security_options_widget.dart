import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SecurityOptionsWidget extends StatefulWidget {
  final Function(bool) onPasswordToggled;
  final Function(String) onPasswordChanged;
  final Function(bool) onExpirationToggled;
  final Function(DateTime) onExpirationDateChanged;

  const SecurityOptionsWidget({
    super.key,
    required this.onPasswordToggled,
    required this.onPasswordChanged,
    required this.onExpirationToggled,
    required this.onExpirationDateChanged,
  });

  @override
  _SecurityOptionsWidgetState createState() => _SecurityOptionsWidgetState();
}

class _SecurityOptionsWidgetState extends State<SecurityOptionsWidget> {
  bool _usePassword = false;
  bool _useExpiration = false;
  final TextEditingController _passwordController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(Duration(days: 7));
  String _customDuration = '';
  int _selectedPredefinedPeriod = 1; // 0: 24h, 1: 7d, 2: 30d
  bool _useCustomDuration = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Options:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        // Password protection
        SwitchListTile(
          title: Text('Password Protection'),
          value: _usePassword,
          onChanged: (value) {
            setState(() {
              _usePassword = value;
            });
            widget.onPasswordToggled(value);
          },
        ),

        if (_usePassword)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: widget.onPasswordChanged,
            ),
          ),

        // Expiration
        SwitchListTile(
          title: Text('Set Expiration'),
          value: _useExpiration,
          onChanged: (value) {
            setState(() {
              _useExpiration = value;
            });
            widget.onExpirationToggled(value);
            if (value) {
              _updateExpirationDate();
            }
          },
        ),

        if (_useExpiration)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Option to choose between predefined or custom
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Text('Predefined'),
                        value: false,
                        groupValue: _useCustomDuration,
                        onChanged: (value) {
                          setState(() {
                            _useCustomDuration = value!;
                          });
                          _updateExpirationDate();
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Text('Custom'),
                        value: true,
                        groupValue: _useCustomDuration,
                        onChanged: (value) {
                          setState(() {
                            _useCustomDuration = value!;
                          });
                          _updateExpirationDate();
                        },
                      ),
                    ),
                  ],
                ),

                // Predefined periods
                if (!_useCustomDuration)
                  DropdownButton<int>(
                    value: _selectedPredefinedPeriod,
                    items: [
                      DropdownMenuItem(value: 0, child: Text('24 hours')),
                      DropdownMenuItem(value: 1, child: Text('7 days')),
                      DropdownMenuItem(value: 2, child: Text('30 days')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPredefinedPeriod = value!;
                      });
                      _updateExpirationDate();
                    },
                  ),

                // Custom duration
                if (_useCustomDuration)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Duration (hours)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _customDuration = value;
                            _updateExpirationDate();
                          },
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: 8),
                Text(
                  'Expires on: ${DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate)}',
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _updateExpirationDate() {
    DateTime newDate;

    if (_useCustomDuration) {
      // Custom duration in hours
      int hours = int.tryParse(_customDuration) ?? 24;
      newDate = DateTime.now().add(Duration(hours: hours));
    } else {
      // Predefined periods
      switch (_selectedPredefinedPeriod) {
        case 0: // 24 hours
          newDate = DateTime.now().add(Duration(hours: 24));
          break;
        case 1: // 7 days
          newDate = DateTime.now().add(Duration(days: 7));
          break;
        case 2: // 30 days
          newDate = DateTime.now().add(Duration(days: 30));
          break;
        default:
          newDate = DateTime.now().add(Duration(days: 7));
      }
    }

    setState(() {
      _selectedDate = newDate;
    });

    widget.onExpirationDateChanged(newDate);
  }
}
