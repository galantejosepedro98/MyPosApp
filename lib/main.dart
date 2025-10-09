import 'package:essenciacompany_mobile/presentation/view/auth/login_view.dart';
// import 'package:essenciacompany_mobile/presentation/view/checkin_checkout/checkin_checkout_view.dart';
import 'package:essenciacompany_mobile/presentation/view/enter_code_view.dart';
import 'package:essenciacompany_mobile/presentation/view/my_wallet/physical_qr_view.dart';
import 'package:essenciacompany_mobile/presentation/view/my_wallet/wallet_view.dart';
import 'package:essenciacompany_mobile/presentation/view/pos/check_qr_view.dart';
import 'package:essenciacompany_mobile/presentation/view/pos/orders_view.dart';
import 'package:essenciacompany_mobile/presentation/view/pos/pos_shop_view.dart';
import 'package:essenciacompany_mobile/presentation/view/staff_withdraw/staff_withdraw_view.dart';
import 'package:essenciacompany_mobile/presentation/pos2/screens/pos2_dashboard_view.dart';
import 'package:essenciacompany_mobile/presentation/pos2/screens/pos2_modern_dashboard.dart';
import 'package:essenciacompany_mobile/presentation/pos2/providers/pos2_cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => POS2CartProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const LoginView(),
      routes: {
        '/login': (context) => const LoginView(),
        '/enter-code': (context) => const EnterCodeView(),
        '/pos/shop': (context) => const PosShopView(),
        '/pos/orders': (context) => const OrdersView(),
        '/wallet': (context) => const WalletView(),
        '/physical-qr': (context) => const PhysicalQrView(),
        '/check-qr': (context) => const CheckQrView(),
        '/staff-withdraw': (context) => const StaffWithdrawView(),
        
        // ROTAS POS2
        '/pos2/dashboard': (context) => const POS2DashboardView(),
        '/pos2/modern': (context) => const POS2ModernDashboard(),
      },
      ),
    );
  }
}
