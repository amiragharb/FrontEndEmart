import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:frontendemart/change_langue/change_language.dart';
import 'package:frontendemart/config/api.dart';
import 'package:frontendemart/services/ciConfig_Service.dart';
import 'package:frontendemart/viewmodels/CartViewModel.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:frontendemart/viewmodels/addresses_viewmodel.dart';
import 'package:frontendemart/viewmodels/wishlist_viewmodel_tmp.dart';
import 'package:frontendemart/viewmodels/auth_viewmodel.dart';
import 'package:frontendemart/viewmodels/items_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/routes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();

  // 🔹 Créer le service avec la base URL
  final configService = ConfigService(ApiConfig.baseUrl);

  // 🔹 Récupérer la config backend
  final config = await configService.getClientConfig();

  // 🔹 Déterminer la langue forcée (si unique)
  String? forcedLanguage;
  if (config.ciDefaultLanguage != null) {
    final lang = config.ciDefaultLanguage!.toLowerCase();
    if (lang == 'ar' || lang == 'en') {
      forcedLanguage = lang; // appliquer directement
    }
  }
print('Backend default language: ${config.ciDefaultLanguage}');
print('Forced locale: $forcedLanguage');

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: forcedLanguage != null ? Locale(forcedLanguage) : null,
      child: MultiProvider(
        providers: [

        ChangeNotifierProvider(create: (_) => WishlistViewModeltep()..hydrate()), // 👈 ICI
    ChangeNotifierProvider(create: (_) => CartViewModel()..hydrate()),
    ChangeNotifierProvider(create: (_) => ConfigViewModel()),
    ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => AddressesViewModel()),

    ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ChangeNotifierProvider(create: (_) => ItemsViewModel()),


// 👈 hydrate ici


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
      builder: (context, child) {
        // ✅ Assure que tout l’arbre voit les providers
        return child!;
      },
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
