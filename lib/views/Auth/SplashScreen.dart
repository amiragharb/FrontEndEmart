import 'package:flutter/material.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontendemart/routes/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false; // Empêche la navigation multiple

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
  print('🔹 Initialisation du SplashScreen');

  final configVM = Provider.of<ConfigViewModel>(context, listen: false);

  try {
    print('🔹 Fetching config depuis le backend...');
    await configVM.fetchConfig();
    print('✅ Config récupérée: ${configVM.config}');
    print('🔹 Logo URL: ${configVM.config?.ciLogo}');
  } catch (e) {
    print('❌ Erreur config: $e');
  }

  // ⚡ Ajouter un délai pour que le logo soit visible
  await Future.delayed(const Duration(seconds: 2));

  _checkAuth();
}


  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('🔹 Token récupéré: $token');

    if (!_navigated) {
      _navigated = true;

      if (token != null && token.isNotEmpty) {
        print('🔹 Navigating to Home');
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      } else {
        print('🔹 Navigating to Login');
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    }
  }

@override
Widget build(BuildContext context) {
  final configVM = Provider.of<ConfigViewModel>(context);
  final config = configVM.config;

  print('🔹 Build SplashScreen, config is null? ${config == null}');

  return Scaffold(
    backgroundColor: Colors.white, // 🔹 Fond blanc fixe
    body: Center(
      child: config == null
          ? const CircularProgressIndicator(color: Colors.blue) // couleur contrastante
          : Image.network(
              config.ciLogo,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  print('✅ Logo chargé avec succès');
                  return child;
                }
                print('🔹 Logo loading...');
                return const CircularProgressIndicator(color: Colors.blue);
              },
              errorBuilder: (context, error, stackTrace) {
                print('❌ Erreur chargement image: $error');
                return const Icon(Icons.error, size: 100, color: Colors.red);
              },
            ),
    ),
  );
}

}
