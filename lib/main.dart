import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontendemart/change_langue/change_language.dart';
import 'package:frontendemart/l10n/app_localizations.dart';
import 'package:frontendemart/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()), // ✅
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
  title: 'eMart',
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
    useMaterial3: true,
  ),
  locale: localeProvider.locale,
  supportedLocales: AppLocalizations.supportedLocales,          // ✅ auto-généré
  localizationsDelegates: AppLocalizations.localizationsDelegates, // ✅ auto-généré
  initialRoute: AppRoutes.splash,
  onGenerateRoute: AppRoutes.generateRoute,
);

  }
}
