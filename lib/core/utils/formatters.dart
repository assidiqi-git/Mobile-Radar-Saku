import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _idrFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static final NumberFormat _compactFormatter = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 1,
  );

  /// Format a numeric string or double to IDR currency.
  /// e.g. "150000" → "Rp150.000"
  static String format(dynamic amount) {
    if (amount == null) return 'Rp0';
    final value = double.tryParse(amount.toString()) ?? 0.0;
    return _idrFormatter.format(value);
  }

  /// Compact format for large numbers.
  /// e.g. 1500000 → "Rp1,5 jt"
  static String compact(dynamic amount) {
    if (amount == null) return 'Rp0';
    final value = double.tryParse(amount.toString()) ?? 0.0;
    return _compactFormatter.format(value);
  }

  /// Parse IDR string back to double.
  static double parse(String formattedAmount) {
    if (formattedAmount.isEmpty) return 0.0;
    final cleaned = formattedAmount
        .replaceAll('Rp', '')
        .replaceAll('.', '') // Hapus pemisah ribuan
        .replaceAll(',', '.') // Just in case, replace comma with dot for decimals
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hanya biarkan digit (angka)
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final int value = int.parse(digitsOnly);
    final String newText = _formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayFormat = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'id_ID');
  static final DateFormat _fullFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _apiFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");

  static String displayDate(DateTime? date) {
    if (date == null) return '-';
    return _displayFormat.format(date.toLocal());
  }

  static String displayTime(DateTime? date) {
    if (date == null) return '-';
    return _timeFormat.format(date.toLocal());
  }

  static String displayFull(DateTime? date) {
    if (date == null) return '-';
    return _fullFormat.format(date.toLocal());
  }

  static String toApiString(DateTime date) {
    return _apiFormat.format(date.toUtc());
  }

  static DateTime? fromApiString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Returns a relative time string like "2 jam lalu", "Kemarin", etc.
  static String relativeTime(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(date.toLocal());

    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return displayDate(date);
  }
}
