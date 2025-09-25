// lib/routes/routes.dart
import 'package:flutter/material.dart';

import 'package:frontendemart/views/Auth/SplashScreen.dart';
import 'package:frontendemart/views/Auth/login_screen.dart';
import 'package:frontendemart/views/Auth/signup_screen.dart';

import 'package:frontendemart/models/address_model.dart';
import 'package:frontendemart/views/Items/ChooseAddressScreen.dart';
import 'package:frontendemart/views/Ordres/AddAddressScreen.dart';
import 'package:frontendemart/views/Ordres/order_history_screen.dart';
import 'package:frontendemart/views/payment/Final_order_summary_screen.dart';
import 'package:frontendemart/views/Ordres/OrderDetailsScreen.dart';
import 'package:frontendemart/views/payment/choose_payment_method_screen.dart'
    show ChoosePaymentMethodScreen, PaymentMethod;

import 'package:frontendemart/views/homeAdmin/home_screen.dart';

class AppRoutes {
  static const String splash        = '/';
  static const String login         = '/login';
  static const String signup        = '/signup';
  static const String home          = '/home';

  static const String chooseAddress = '/orders/choose-address';
  static const String addAddress    = '/orders/add-address';
  static const String editAddress   = '/orders/edit-address';

  static const String choosePayment = '/payment/choose-method';
  static const String addCard       = '/payment/add-card'; // (si tu as un écran plus tard)
  static const String orderSummary  = '/payment/order-summary';

  static const String orderSuccess  = '/orders/success';
  static const String orderDetails  = '/orders/details';
  static const String orderHistory   = '/orders/history';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    debugPrint('🧭 [Router] go → ${settings.name} | args=${settings.arguments}');

    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      /* ---------- Orders / Addresses ---------- */

      case chooseAddress:
        return MaterialPageRoute(builder: (_) => const ChooseAddressScreen());

      case addAddress:
        return MaterialPageRoute(builder: (_) => const AddEditAddressScreen());


       case orderHistory:
        return MaterialPageRoute(builder: (_) => const OrderHistoryScreen());
      case editAddress: {
        final args = settings.arguments;
        if (args is Address? || args == null) {
          return MaterialPageRoute(
            builder: (_) => AddEditAddressScreen(existing: args as Address?),
          );
        }
        return _oops('Missing Address for editAddress');
      }

      /* ---------- Payment flow ---------- */

      case choosePayment: {
        final args = settings.arguments;
        if (args is Address) {
          return MaterialPageRoute(
            builder: (_) => ChoosePaymentMethodScreen(address: args),
          );
        }
        return _oops('Missing Address for choosePayment');
      }

      case orderSummary: {
        // Attend: { address: Address, method: PaymentMethod } OU directement Address
        final args = settings.arguments;
        Address? address;
        var method = PaymentMethod.cod;

        if (args is Map) {
          address = args['address'] as Address?;
          method  = (args['method'] as PaymentMethod?) ?? PaymentMethod.cod;
        } else if (args is Address) {
          address = args;
        }

        if (address == null) return _oops('Missing Address for orderSummary');

        return MaterialPageRoute(
          builder: (_) => FinalOrderSummaryScreen(address: address!, method: method),
        );
      }

      /* ---------- Order post actions ---------- */

      case orderDetails: {
        // args peut être un int (orderId) ou une Map {orderId: ...}
        final args = settings.arguments;
        int? orderId;

        if (args is int) {
          orderId = args;
        } else if (args is Map) {
          final v = args['orderId'] ?? args['OrderID'] ?? args['id'] ?? args['Id'];
          orderId = _asInt(v);
        }

        if (orderId == null) return _oops('Missing orderId for orderDetails');

        return MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: orderId!),
        );
      }

      

      default:
        return _oops('Route not found: ${settings.name}');
    }
  }

  /* ---------- helpers ---------- */

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static MaterialPageRoute _oops(String msg) =>
      MaterialPageRoute(builder: (_) => Scaffold(body: Center(child: Text(msg))));
}
