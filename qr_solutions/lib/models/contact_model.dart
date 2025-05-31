// ENHANCED: Contact model with better vCard support and validation
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactModel {
  final String name;
  final String? firstName;
  final String? lastName;
  final List<PhoneNumber> phoneNumbers;
  final List<EmailAddress> emailAddresses;
  final String? organization;
  final String? jobTitle;
  final List<Address> addresses;
  final String? note;
  final String? avatar; // Base64 encoded image or path to image file
  final String? website;
  final DateTime? birthday;

  ContactModel({
    required this.name,
    this.firstName,
    this.lastName,
    this.phoneNumbers = const [],
    this.emailAddresses = const [],
    this.organization,
    this.jobTitle,
    this.addresses = const [],
    this.note,
    this.avatar,
    this.website,
    this.birthday,
  });

  // Create from system Contact object
  factory ContactModel.fromContact(Contact contact) {
    List<PhoneNumber> phones = [];
    if (contact.phones.isNotEmpty) {
      phones =
          contact.phones
              .map<PhoneNumber>(
                (phone) => PhoneNumber(
                  number: phone.number,
                  label:
                      phone.label != null ? phone.label.toString() : 'mobile',
                ),
              )
              .toList();
    }

    List<EmailAddress> emails = [];
    if (contact.emails.isNotEmpty) {
      emails =
          contact.emails
              .map<EmailAddress>(
                (email) => EmailAddress(
                  email: email.address,
                  label: email.label != null ? email.label.toString() : 'home',
                ),
              )
              .toList();
    }

    List<Address> addressList = [];
    if (contact.addresses.isNotEmpty) {
      addressList =
          contact.addresses
              .map<Address>(
                (addr) => Address(
                  street: addr.street,
                  city: addr.city,
                  region: addr.state, // Change from addr.region to addr.state
                  postcode: addr.postalCode,
                  country: addr.country,
                  label: addr.label != null ? addr.label.toString() : 'home',
                ),
              )
              .toList();
    }

    // Extract website from URLs
    String? website;
    if (contact.websites.isNotEmpty) {
      website = contact.websites.first.url;
    }

    // Extract birthday
    DateTime? birthday;
    if (contact.events.isNotEmpty) {
      final birthdayEvent = contact.events.firstWhere(
        (event) => event.label.toString().toLowerCase().contains('birthday'),
        orElse: () => contact.events.first,
      );
      if (birthdayEvent.year != null &&
          birthdayEvent.month != null &&
          birthdayEvent.day != null) {
        birthday = DateTime(
          birthdayEvent.year!,
          birthdayEvent.month!,
          birthdayEvent.day!,
        );
      }
    }

    return ContactModel(
      name: contact.displayName,
      firstName: contact.name.first,
      lastName: contact.name.last,
      phoneNumbers: phones,
      emailAddresses: emails,
      organization:
          contact.organizations.isNotEmpty
              ? contact.organizations.first.company
              : null,
      jobTitle:
          contact.organizations.isNotEmpty
              ? contact.organizations.first.title
              : null,
      addresses: addressList,
      note: contact.notes.isNotEmpty ? contact.notes.first.note : null,
      avatar:
          contact.photo != null ? String.fromCharCodes(contact.photo!) : null,
      website: website,
      birthday: birthday,
    );
  }

  // Convert to vCard format
  String toVCard() {
    StringBuffer vcard = StringBuffer();
    vcard.writeln('BEGIN:VCARD');
    vcard.writeln('VERSION:3.0');

    // Name components
    if (lastName != null || firstName != null) {
      vcard.writeln('N:${lastName ?? ''};${firstName ?? ''};;;');
    } else {
      // Split the display name as a fallback
      final nameParts = name.split(' ');
      final last = nameParts.length > 1 ? nameParts.last : '';
      final first =
          nameParts.length > 1
              ? nameParts.sublist(0, nameParts.length - 1).join(' ')
              : name;
      vcard.writeln('N:$last;$first;;;');
    }

    vcard.writeln('FN:$name');

    // Phone numbers
    for (var phone in phoneNumbers) {
      final cleanLabel = _sanitizeLabel(phone.label);
      vcard.writeln('TEL;TYPE=${cleanLabel.toUpperCase()}:${phone.number}');
    }

    // Email addresses
    for (var email in emailAddresses) {
      final cleanLabel = _sanitizeLabel(email.label);
      vcard.writeln('EMAIL;TYPE=${cleanLabel.toUpperCase()}:${email.email}');
    }

    // Organization
    if (organization != null && organization!.isNotEmpty) {
      vcard.writeln('ORG:$organization');
    }

    // Job title
    if (jobTitle != null && jobTitle!.isNotEmpty) {
      vcard.writeln('TITLE:$jobTitle');
    }

    // Website
    if (website != null && website!.isNotEmpty) {
      vcard.writeln('URL:$website');
    }

    // Birthday
    if (birthday != null) {
      final birthdayStr =
          '${birthday!.year.toString().padLeft(4, '0')}'
          '${birthday!.month.toString().padLeft(2, '0')}'
          '${birthday!.day.toString().padLeft(2, '0')}';
      vcard.writeln('BDAY:$birthdayStr');
    }

    // Addresses
    for (var address in addresses) {
      final cleanLabel = _sanitizeLabel(address.label);
      vcard.writeln(
        'ADR;TYPE=${cleanLabel.toUpperCase()}:;;${address.street};${address.city};${address.region};${address.postcode};${address.country}',
      );
    }

    // Note
    if (note != null && note!.isNotEmpty) {
      // Escape special characters in note
      final escapedNote = note!
          .replaceAll('\n', '\\n')
          .replaceAll(',', '\\,')
          .replaceAll(';', '\\;');
      vcard.writeln('NOTE:$escapedNote');
    }

    // Photo/Avatar
    if (avatar != null && avatar!.isNotEmpty) {
      vcard.writeln('PHOTO;ENCODING=BASE64;TYPE=JPEG:$avatar');
    }

    vcard.writeln('END:VCARD');
    return vcard.toString();
  }

  // Create from vCard string
  factory ContactModel.fromVCard(String vcardString) {
    final lines = vcardString.split('\n');
    String name = '';
    String? firstName;
    String? lastName;
    List<PhoneNumber> phones = [];
    List<EmailAddress> emails = [];
    String? organization;
    String? jobTitle;
    List<Address> addresses = [];
    String? note;
    String? avatar;
    String? website;
    DateTime? birthday;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('FN:')) {
        name = line.substring(3);
      } else if (line.startsWith('N:')) {
        final parts = line.substring(2).split(';');
        if (parts.isNotEmpty) lastName = parts[0];
        if (parts.length > 1) firstName = parts[1];
      } else if (line.startsWith('TEL;')) {
        final phoneInfo = _parseVCardLine(line, 'TEL');
        if (phoneInfo['value'] != null) {
          phones.add(
            PhoneNumber(
              number: phoneInfo['value']!,
              label: phoneInfo['type']?.toLowerCase() ?? 'mobile',
            ),
          );
        }
      } else if (line.startsWith('EMAIL;')) {
        final emailInfo = _parseVCardLine(line, 'EMAIL');
        if (emailInfo['value'] != null) {
          emails.add(
            EmailAddress(
              email: emailInfo['value']!,
              label: emailInfo['type']?.toLowerCase() ?? 'home',
            ),
          );
        }
      } else if (line.startsWith('ORG:')) {
        organization = line.substring(4);
      } else if (line.startsWith('TITLE:')) {
        jobTitle = line.substring(6);
      } else if (line.startsWith('URL:')) {
        website = line.substring(4);
      } else if (line.startsWith('BDAY:')) {
        try {
          final dateStr = line.substring(5);
          if (dateStr.length >= 8) {
            final year = int.parse(dateStr.substring(0, 4));
            final month = int.parse(dateStr.substring(4, 6));
            final day = int.parse(dateStr.substring(6, 8));
            birthday = DateTime(year, month, day);
          }
        } catch (e) {
          // Invalid date format, skip
        }
      } else if (line.startsWith('ADR;')) {
        final addressInfo = _parseVCardLine(line, 'ADR');
        if (addressInfo['value'] != null) {
          final addressParts = addressInfo['value']!.split(';');
          String street = '';
          String city = '';
          String region = '';
          String postcode = '';
          String country = '';

          if (addressParts.length > 2) street = addressParts[2];
          if (addressParts.length > 3) city = addressParts[3];
          if (addressParts.length > 4) region = addressParts[4];
          if (addressParts.length > 5) postcode = addressParts[5];
          if (addressParts.length > 6) country = addressParts[6];

          addresses.add(
            Address(
              street: street,
              city: city,
              region: region,
              postcode: postcode,
              country: country,
              label: addressInfo['type']?.toLowerCase() ?? 'home',
            ),
          );
        }
      } else if (line.startsWith('NOTE:')) {
        note = line
            .substring(5)
            .replaceAll('\\n', '\n')
            .replaceAll('\\,', ',')
            .replaceAll('\\;', ';');
      } else if (line.startsWith('PHOTO;')) {
        final colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
          avatar = line.substring(colonIndex + 1);
        }
      }
    }

    return ContactModel(
      name: name,
      firstName: firstName,
      lastName: lastName,
      phoneNumbers: phones,
      emailAddresses: emails,
      organization: organization,
      jobTitle: jobTitle,
      addresses: addresses,
      note: note,
      avatar: avatar,
      website: website,
      birthday: birthday,
    );
  }

  // Helper method to parse vCard lines with parameters
  static Map<String, String?> _parseVCardLine(String line, String prefix) {
    final result = <String, String?>{};

    final colonIndex = line.indexOf(':');
    if (colonIndex == -1) return result;

    final value = line.substring(colonIndex + 1);
    final headerPart = line.substring(0, colonIndex);

    result['value'] = value;

    // Extract TYPE parameter
    final typeMatch = RegExp(r'TYPE=([^;:]+)').firstMatch(headerPart);
    if (typeMatch != null) {
      result['type'] = typeMatch.group(1);
    }

    return result;
  }

  // Helper method to sanitize labels for vCard
  String _sanitizeLabel(String label) {
    // Convert common label variations to standard vCard types
    final lowerLabel = label.toLowerCase();
    switch (lowerLabel) {
      case 'cell':
      case 'cellular':
      case 'mobile':
        return 'CELL';
      case 'home':
        return 'HOME';
      case 'work':
      case 'office':
        return 'WORK';
      case 'fax':
        return 'FAX';
      case 'other':
        return 'OTHER';
      default:
        return label.toUpperCase();
    }
  }

  // Validation methods
  bool get isValid {
    return name.isNotEmpty &&
        (phoneNumbers.isNotEmpty || emailAddresses.isNotEmpty);
  }

  bool get hasPhoneNumber => phoneNumbers.isNotEmpty;
  bool get hasEmail => emailAddresses.isNotEmpty;
  bool get hasAddress => addresses.isNotEmpty;
  bool get hasOrganization => organization != null && organization!.isNotEmpty;

  // Helper methods
  String get primaryPhone =>
      phoneNumbers.isNotEmpty ? phoneNumbers.first.number : '';
  String get primaryEmail =>
      emailAddresses.isNotEmpty ? emailAddresses.first.email : '';

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return name;
  }

  // Copy with method for modifications
  ContactModel copyWith({
    String? name,
    String? firstName,
    String? lastName,
    List<PhoneNumber>? phoneNumbers,
    List<EmailAddress>? emailAddresses,
    String? organization,
    String? jobTitle,
    List<Address>? addresses,
    String? note,
    String? avatar,
    String? website,
    DateTime? birthday,
  }) {
    return ContactModel(
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      emailAddresses: emailAddresses ?? this.emailAddresses,
      organization: organization ?? this.organization,
      jobTitle: jobTitle ?? this.jobTitle,
      addresses: addresses ?? this.addresses,
      note: note ?? this.note,
      avatar: avatar ?? this.avatar,
      website: website ?? this.website,
      birthday: birthday ?? this.birthday,
    );
  }
}

class PhoneNumber {
  final String number;
  final String label; // mobile, home, work, etc.

  PhoneNumber({required this.number, this.label = 'mobile'});

  @override
  String toString() => '$label: $number';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneNumber &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          label == other.label;

  @override
  int get hashCode => number.hashCode ^ label.hashCode;
}

class EmailAddress {
  final String email;
  final String label; // home, work, etc.

  EmailAddress({required this.email, this.label = 'home'});

  @override
  String toString() => '$label: $email';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailAddress &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          label == other.label;

  @override
  int get hashCode => email.hashCode ^ label.hashCode;
}

class Address {
  final String street;
  final String city;
  final String region;
  final String postcode;
  final String country;
  final String label; // home, work, etc.

  Address({
    this.street = '',
    this.city = '',
    this.region = '',
    this.postcode = '',
    this.country = '',
    this.label = 'home',
  });

  @override
  String toString() {
    final parts =
        [
          street,
          city,
          region,
          postcode,
          country,
        ].where((part) => part.isNotEmpty).toList();
    return parts.join(', ');
  }

  bool get isEmpty =>
      street.isEmpty &&
      city.isEmpty &&
      region.isEmpty &&
      postcode.isEmpty &&
      country.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          runtimeType == other.runtimeType &&
          street == other.street &&
          city == other.city &&
          region == other.region &&
          postcode == other.postcode &&
          country == other.country &&
          label == other.label;

  @override
  int get hashCode =>
      street.hashCode ^
      city.hashCode ^
      region.hashCode ^
      postcode.hashCode ^
      country.hashCode ^
      label.hashCode;
}
