import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/app_router.dart';
import 'core/theme/app_theme.dart';
import 'database/database_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/wallet_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize SQLite database
  await DatabaseHelper.instance.database;

  // Initialize locale data for Indonesian date formatting
  await initializeDateFormatting('id_ID', null);

  runApp(const RadarSakuApp());
}

class RadarSakuApp extends StatelessWidget {
  const RadarSakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
          create: (_) => WalletProvider(),
          update: (_, auth, wallet) => wallet!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (_) => TransactionProvider(),
          update: (_, auth, tx) => tx!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SyncProvider>(
          create: (_) => SyncProvider(),
          update: (_, auth, sync) => sync!..updateAuth(auth),
        ),
      ],
      child: MaterialApp(
        title: 'Radar Saku',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.splash,
      ),
    );
  }
}
