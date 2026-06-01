import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/profile/profile_sync_screen.dart';
import '../screens/transaction/add_transaction_screen.dart';
import '../screens/transaction/all_transactions_screen.dart';
import '../screens/transaction/transaction_detail_screen.dart';
import '../screens/transfer/transfer_screen.dart';
import '../screens/wallet/wallets_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String addTransaction = '/add-transaction';
  static const String allTransactions = '/all-transactions';
  static const String transactionDetail = '/transaction-detail';
  static const String wallets = '/wallets';
  static const String transfer = '/transfer';
  static const String profile = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (ctx) => _SplashGate(),
        );
      case login:
        return _slideRoute(const LoginScreen(), settings);
      case register:
        return _slideRoute(const RegisterScreen(), settings);
      case dashboard:
        return _fadeRoute(const DashboardScreen(), settings);
      case addTransaction:
        return _bottomSlideRoute(const AddTransactionScreen(), settings);
      case allTransactions:
        return _slideRoute(const AllTransactionsScreen(), settings);
      case transactionDetail:
        final id = settings.arguments as String;
        return _slideRoute(TransactionDetailScreen(transactionId: id), settings);
      case wallets:
        return _slideRoute(const WalletsScreen(), settings);
      case transfer:
        return _bottomSlideRoute(const TransferScreen(), settings);
      case profile:
        return _slideRoute(const ProfileSyncScreen(), settings);
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }

  static PageRoute _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween =
            Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRoute _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  static PageRoute _bottomSlideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween =
            Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

/// Splash gate — checks auth and redirects accordingly.
class _SplashGate extends StatefulWidget {
  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.init();

    if (!mounted) return;

    if (auth.isAuthenticated) {
      // Trigger data loading
      Navigator.pushReplacementNamed(context, AppRouter.dashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
