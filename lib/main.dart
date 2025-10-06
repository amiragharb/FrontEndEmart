// lib/main.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:frontendemart/services/InitPaymobResponse_service.dart';
import 'package:frontendemart/viewmodels/PaymobViewModel.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:frontendemart/change_langue/change_language.dart';
import 'package:frontendemart/config/api.dart';
import 'package:frontendemart/routes/routes.dart';

// Services & ViewModels
import 'package:frontendemart/services/ciConfig_Service.dart';
       // ✅ nouveau VM

import 'package:frontendemart/viewmodels/CartViewModel.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:frontendemart/viewmodels/addresses_viewmodel.dart';
import 'package:frontendemart/viewmodels/wishlist_viewmodel_tmp.dart';
import 'package:frontendemart/viewmodels/auth_viewmodel.dart';
import 'package:frontendemart/viewmodels/items_viewmodel.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();

  // 🔹 Charger la config backend (couleurs, langue par défaut, etc.)
  final configService = ConfigService(ApiConfig.baseUrl);
  final config = await configService.getClientConfig();

  // 🔹 Déterminer la langue forcée éventuelle
  String? forcedLanguage;
  if (config.ciDefaultLanguage != null) {
    final lang = config.ciDefaultLanguage!.toLowerCase();
    if (lang == 'ar' || lang == 'en') {
      forcedLanguage = lang;
    }
  }
  // Logs (optionnels)
  // print('Backend default language: ${config.ciDefaultLanguage}');
  // print('Forced locale: $forcedLanguage');

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: forcedLanguage != null ? Locale(forcedLanguage) : null,
      child: MultiProvider(
        providers: [
          // ⚙️ Providers “simples” / services
          Provider<PaymobApi>(
            create: (_) => PaymobApi(ApiConfig.baseUrl), // ⬅️ adapte si besoin
          ),

          // 🧠 ViewModels
          ChangeNotifierProvider(create: (_) => ConfigViewModel()),
          ChangeNotifierProvider(create: (_) => ItemsViewModel()
            ..loadItems()
            ..loadCategories()),
          ChangeNotifierProvider(create: (_) => WishlistViewModeltep()..hydrate()),
          ChangeNotifierProvider(create: (_) => CartViewModel()..hydrate()),
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ChangeNotifierProvider(create: (_) => AddressesViewModel()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),

          // 💳 Paymob VM dépend de PaymobApi (il doit être APRES Provider<PaymobApi>)
          ChangeNotifierProvider(
            create: (ctx) => PaymobViewModel(api: ctx.read<PaymobApi>()),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'eMart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
