// New code with flutter_contacts
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  // Add this method to check and request contacts permission
  Future<bool> requestContactPermission() async {
    final permissionStatus = await Permission.contacts.status;

    if (permissionStatus.isGranted) {
      return true;
    }

    final requestStatus = await Permission.contacts.request();
    return requestStatus.isGranted;
  }

  Future<Contact?> pickContact() async {
    bool permissionGranted = await requestContactPermission();

    if (!permissionGranted) {
      throw Exception('Contacts permission not granted');
    }

    // Open contact picker
    Contact? contact = await FlutterContacts.openExternalPick();
    return contact;
  }
}
