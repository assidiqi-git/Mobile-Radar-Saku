class AppConstants {
  // SharedPreferences keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String lastSyncedAtKey = 'last_synced_at';

  // SQLite table names
  static const String tableUsers = 'users';
  static const String tableWallets = 'wallets';
  static const String tableTransactionTypes = 'transaction_types';
  static const String tableTransactionCategories = 'transaction_categories';
  static const String tableTransactions = 'transactions';
  static const String tableTransfers = 'transfers';
  static const String tableSyncMeta = 'sync_meta';

  // Wallet types
  static const List<String> walletTypes = [
    'checking',
    'savings',
    'cash',
    'investment',
  ];

  // Transaction action types
  static const String actionAddition = 'addition';
  static const String actionDeduction = 'deduction';
  static const String actionNeutral = 'neutral';

  // Sync batch size
  static const int syncBatchSize = 500;

  // API client type header
  static const String clientTypeHeader = 'X-Client-Type';
  static const String clientTypeMobile = 'mobile';

  // Sync status values (stored in SQLite sync_status column)
  static const String syncStatusPending = 'pending';
  static const String syncStatusSynced  = 'synced';
  static const String syncStatusError   = 'error';

  // Validation limits (mirrors OpenAPI spec)
  static const int maxNameLength    = 255;
  static const double minAmount     = 0.01;
  static const int maxPhotoBytes    = 2 * 1024 * 1024; // 2 MB
}
