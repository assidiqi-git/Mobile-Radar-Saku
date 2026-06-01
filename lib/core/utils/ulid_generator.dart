import 'package:ulid/ulid.dart';

class UlidGenerator {
  UlidGenerator._();

  /// Generates a new ULID string.
  static String generate() {
    return Ulid().toString();
  }

  /// Validates whether the given string is a valid ULID.
  static bool isValid(String id) {
    if (id.length != 26) return false;
    final validChars = RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$');
    return validChars.hasMatch(id);
  }
}
