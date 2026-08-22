import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants/app_constants.dart';
import '../database/database_helper.dart';

class BackupRestoreService {
  BackupRestoreService._();
  static final BackupRestoreService instance = BackupRestoreService._();

  /// Exports data to a .radarsaku (ZIP) file and shares it.
  Future<void> exportData() async {
    final db = await DatabaseHelper.instance.database;

    // 1. Fetch data from tables
    final wallets = await db.query(AppConstants.tableWallets);
    final transactionTypes = await db.query(AppConstants.tableTransactionTypes);
    final transactionCategories = await db.query(AppConstants.tableTransactionCategories);
    final transactions = await db.query(AppConstants.tableTransactions);

    // 2. Format as JSON
    final Map<String, dynamic> backupData = {
      'version': '1.0',
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'data': {
        AppConstants.tableWallets: wallets,
        AppConstants.tableTransactionTypes: transactionTypes,
        AppConstants.tableTransactionCategories: transactionCategories,
        AppConstants.tableTransactions: transactions,
      }
    };

    final jsonString = jsonEncode(backupData);
    final jsonBytes = utf8.encode(jsonString);

    // 3. Archive (ZIP)
    final archive = Archive();
    final archiveFile = ArchiveFile('data.json', jsonBytes.length, jsonBytes);
    archive.addFile(archiveFile);
    
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    // 4. Save locally to temp and share
    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final fileName = 'RadarSaku_Backup_$timestamp.radarsaku';
    
    final backupFile = File('${tempDir.path}/$fileName');
    await backupFile.writeAsBytes(zipBytes);

    // Share the file
    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(backupFile.path)],
      text: 'Backup Data Radar Saku - $timestamp',
    );
  }

  /// Imports data from a .radarsaku (ZIP) file.
  Future<void> importData() async {
    // 1. Pick file
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['radarsaku'],
    );

    if (result == null || result.files.isEmpty) {
      // User canceled
      return;
    }

    final filePath = result.files.single.path;
    if (filePath == null) {
      throw Exception('Gagal membaca path file backup.');
    }

    // 2. Extract & Validate
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? jsonFile;
    for (final file in archive) {
      if (file.name == 'data.json') {
        jsonFile = file;
        break;
      }
    }

    if (jsonFile == null) {
      throw Exception('File backup tidak valid. data.json tidak ditemukan.');
    }

    final jsonContent = utf8.decode(jsonFile.content as List<int>);
    Map<String, dynamic> backupData;
    try {
      backupData = jsonDecode(jsonContent);
    } catch (e) {
      throw Exception('Gagal mem-parsing data backup.');
    }

    final data = backupData['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Struktur data backup tidak valid.');
    }

    final wallets = data[AppConstants.tableWallets] as List<dynamic>? ?? [];
    final transactionTypes = data[AppConstants.tableTransactionTypes] as List<dynamic>? ?? [];
    final transactionCategories = data[AppConstants.tableTransactionCategories] as List<dynamic>? ?? [];
    final transactions = data[AppConstants.tableTransactions] as List<dynamic>? ?? [];

    // 3. Insert into SQLite
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      for (final wallet in wallets) {
        await txn.insert(
          AppConstants.tableWallets,
          Map<String, dynamic>.from(wallet),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final type in transactionTypes) {
        await txn.insert(
          AppConstants.tableTransactionTypes,
          Map<String, dynamic>.from(type),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final category in transactionCategories) {
        await txn.insert(
          AppConstants.tableTransactionCategories,
          Map<String, dynamic>.from(category),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final transaction in transactions) {
        await txn.insert(
          AppConstants.tableTransactions,
          Map<String, dynamic>.from(transaction),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
