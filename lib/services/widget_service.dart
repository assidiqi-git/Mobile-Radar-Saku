import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../models/transaction.dart';

/// Service terpusat untuk mengirim data ke Android Home Screen Widget.
/// Menggunakan package [home_widget] untuk menyimpan data di SharedPreferences
/// yang dapat dibaca oleh [RadarSakuWidgetProvider] di sisi Kotlin.
class WidgetService {
  static const String _androidQualifiedName =
      'com.example.mobile_radar_saku.RadarSakuWidgetProvider';

  /// Serialize transaksi terkini ke JSON dan push ke widget.
  /// Dipanggil setiap kali TransactionProvider selesai load data.
  static Future<void> updateWidget(
    List<TransactionModel> transactions,
    bool isLoggedIn,
  ) async {
    try {
      final txList = transactions
          .map((tx) => {
                'name': tx.name,
                'amount': tx.amount,
                'category_name': tx.transactionCategory?.name ?? '',
                'type_action':
                    tx.transactionCategory?.transactionType?.action ?? 'neutral',
                'created_at': tx.createdAt ?? '',
              })
          .toList();

      await HomeWidget.saveWidgetData<String>(
          'is_logged_in', isLoggedIn.toString());
      await HomeWidget.saveWidgetData<String>(
          'transactions_json', jsonEncode(txList));

      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidQualifiedName,
      );
    } catch (e) {
      // Widget update adalah best-effort; jangan crash app utama
    }
  }

  /// Clear data widget saat logout — tampilkan state Logged Out.
  static Future<void> clearWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>('is_logged_in', 'false');
      await HomeWidget.saveWidgetData<String>('transactions_json', '[]');

      await HomeWidget.updateWidget(
        qualifiedAndroidName: _androidQualifiedName,
      );
    } catch (e) {
      // best-effort
    }
  }
}
