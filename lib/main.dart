import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/app_router.dart';
import 'core/theme/app_theme.dart';
import 'database/database_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/transaction_category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/transaction_type_provider.dart';
import 'providers/wallet_provider.dart';

/// Global navigator key — digunakan oleh HomeWidget deep link listener
/// untuk navigate dari luar widget tree.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

class RadarSakuApp extends StatefulWidget {
  const RadarSakuApp({super.key});

  @override
  State<RadarSakuApp> createState() => _RadarSakuAppState();
}

class _RadarSakuAppState extends State<RadarSakuApp> {
  StreamSubscription<Uri?>? _widgetClickedSub;

  @override
  void initState() {
    super.initState();
    _initHomeWidget();
  }

  Future<void> _initHomeWidget() async {
    // Diperlukan untuk iOS; aman dipanggil di Android (no-op)
    HomeWidget.setAppGroupId('group.radarsaku');

    // Dengarkan klik widget saat app sudah berjalan di foreground/background
    _widgetClickedSub = HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) _handleWidgetUri(uri);
    });
  }

  /// Routing berdasarkan deep link dari widget.
  /// Scheme: radarsaku://  Host: login | add_transaction
  void _handleWidgetUri(Uri uri) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    switch (uri.host) {
      case 'login':
        navigator.pushNamedAndRemoveUntil(AppRouter.login, (r) => false);
        break;
      case 'add_transaction':
        navigator.pushNamed(AppRouter.addTransaction);
        break;
    }
  }

  @override
  void dispose() {
    _widgetClickedSub?.cancel();
    super.dispose();
  }

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
        ChangeNotifierProxyProvider<AuthProvider, TransactionTypeProvider>(
          create: (_) => TransactionTypeProvider(),
          update: (_, auth, p) => p!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TransactionCategoryProvider>(
          create: (_) => TransactionCategoryProvider(),
          update: (_, auth, p) => p!..updateAuth(auth),
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
        navigatorKey: navigatorKey,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.splash,
      ),
    );
  }
}
