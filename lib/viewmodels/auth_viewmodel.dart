import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:frontendemart/routes/routes.dart';
import 'package:frontendemart/views/Auth/login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? error;
  DateTime? _lastResetRequestAt;

  String? _token;
  Map<String, dynamic>? _userData;

  Map<String, dynamic>? get userData => _userData;
  String? get token => _token;

  // ---------------------- LOGIN ----------------------
  Future<void> login(String email, String password, BuildContext context) async {
    isLoading = true;
    notifyListeners();

    final response = await _authService.login(email, password);
    isLoading = false;

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _token = data['access_token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      await loadUserProfile();

      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      error = 'Login failed: ${response.body}';
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error!)));
    }
  }

  // ---------------------- SIGNUP ----------------------
  Future<void> signup(UserModel user, BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.signup(user);
      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['access_token'] != null) {
        _token = data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await loadUserProfile();
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await login(user.email.trim().toLowerCase(), user.password, context);
        return;
      }

      error = 'Signup failed: ${response.body}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error!)));
    } catch (e) {
      error = 'Signup exception: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error!)));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------- PROFILE ----------------------
  Future<void> loadUserProfile() async {
    _userData = await _authService.getProfile();
    notifyListeners();
  }

  Future<void> updateUserProfile(Map<String, dynamic> newData, BuildContext context) async {
    isLoading = true;
    notifyListeners();

    final success = await _authService.updateProfile(newData);
    isLoading = false;

    if (success) {
      await loadUserProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profil mis à jour avec succès")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Erreur lors de la mise à jour")),
      );
    }
  }

  Future<void> updatePassword(String newPassword, BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token not found');

      final result = await _authService.updatePassword(token, newPassword);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Erreur: $e')));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------- GOOGLE SIGN-IN ----------------------
Future<void> signInWithGoogle(BuildContext context) async {
  isLoading = true;
  notifyListeners();

  try {
    debugPrint("[GOOGLE] Initialisation...");
    await GoogleSignIn.instance.initialize(
      clientId: "195140518965-1vejfgdando4jj2kv4nosc2h7s7qbukn.apps.googleusercontent.com", // Android
      serverClientId: "195140518965-b6rc7vt001es9nf0sl3trvk8khu6babn.apps.googleusercontent.com", // Web
    );
    debugPrint("[GOOGLE] Initialisation OK ✅");

    final signIn = GoogleSignIn.instance;

    // 🔹 Toujours déconnecter avant
    await signIn.signOut();

    GoogleSignInAccount? account;

    debugPrint("[GOOGLE] Lancement de authenticate()...");
    final sub = signIn.authenticationEvents.listen((event) {
      debugPrint("[GOOGLE] Event reçu: ${event.runtimeType}");
      if (event is GoogleSignInAuthenticationEventSignIn) {
        account = event.user;
        debugPrint("[GOOGLE] Utilisateur authentifié: ${account?.email}");
      }
    });

    await signIn.authenticate();
    debugPrint("[GOOGLE] authenticate() terminé ✅");

    // ⏳ On attend un peu pour être sûr que l’event arrive
    for (int i = 0; i < 10 && account == null; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (account == null) {
      debugPrint("[GOOGLE] Aucun compte récupéré après authenticate()");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion Google annulée ou échouée')),
        );
      }
      await sub.cancel();
      return;
    }

    debugPrint("[GOOGLE] Récupération du token...");
    final auth = await account!.authentication;
    final idToken = auth.idToken;

    if (idToken == null || idToken.isEmpty) {
      debugPrint("[GOOGLE] idToken manquant ❌");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'obtenir l'ID token Google.")),
        );
      }
      await sub.cancel();
      return;
    }
    debugPrint("[GOOGLE] idToken: OK ✅");

    // ✅ Envoi au backend
    debugPrint("[GOOGLE] Envoi du token au backend...");
    final resp = await _authService.firebaseLogin(idToken, 'google');
    debugPrint("[GOOGLE] Réponse backend: ${resp.statusCode} - ${resp.body}");

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur backend: ${resp.body}")),
        );
      }
      await sub.cancel();
      return;
    }

    // 📦 Sécuriser le jsonDecode
    if (resp.body.isEmpty) {
  debugPrint("[GOOGLE] Backend a répondu vide, pas de JSON à parser");
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Connexion réussie mais pas de token reçu.")),
    );
  }
  await sub.cancel();
  return;
}

final data = jsonDecode(resp.body);
    if (data is! Map<String, dynamic>) {
      debugPrint("[GOOGLE] Réponse backend invalide, pas un JSON valide");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Réponse du serveur invalide.")),
        );
      }
      await sub.cancel();
      return;
    }
    _token = (data['access_token'] ?? '').toString();

    if (_token!.isEmpty) {
      debugPrint("[GOOGLE] Token backend manquant ❌");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Token manquant dans la réponse du serveur.")),
        );
      }
      await sub.cancel();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);

    await loadUserProfile();

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);

    await sub.cancel();
  } catch (e, st) {
    debugPrint("[GOOGLE] EXCEPTION: $e");
    debugPrint("[GOOGLE] STACKTRACE: $st");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connexion Google échouée : $e')),
      );
    }
  } finally {
    isLoading = false;
    notifyListeners();
  }
}


  // ---------------------- FACEBOOK SIGN-IN ----------------------
  Future<void> signInWithFacebook(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      final result = await FacebookAuth.instance.login(permissions: const ['public_profile', 'email']);
      if (result.status != LoginStatus.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connexion Facebook annulée/échouée')),
          );
        }
        return;
      }

      final fbData = await FacebookAuth.instance.getUserData(fields: 'name,email,picture.width(200)');
      final email = (fbData['email'] ?? '').toString().trim().toLowerCase();
      if (email.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Email Facebook introuvable.")),
          );
        }
        return;
      }

      final socialPassword = 'FACEBOOK:${result.accessToken!.userId}';

      var loginRes = await _authService.login(email, socialPassword);
      if (loginRes.statusCode >= 200 && loginRes.statusCode < 300) {
        final body = jsonDecode(loginRes.body);
        _token = (body['access_token'] ?? '').toString();
        if (_token!.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          await loadUserProfile();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
          return;
        }
      }

      final displayName = (fbData['name'] ?? '').toString().trim();
      String first = displayName, last = '';
      if (displayName.contains(' ')) {
        final parts = displayName.split(RegExp(r'\s+'));
        first = parts.first;
        last = parts.sublist(1).join(' ');
      }
      if (first.isEmpty) first = 'Facebook';

      final user = UserModel(
        email: email,
        password: socialPassword,
        firstName: first,
        lastName: last.isEmpty ? 'User' : last,
        mobile: '+201000000000',
        dateOfBirth: '1990-01-01',
      );

      final signupRes = await _authService.signup(user);
      if (signupRes.statusCode == 200 || signupRes.statusCode == 201) {
        loginRes = await _authService.login(email, socialPassword);
      }

      if (loginRes.statusCode >= 200 && loginRes.statusCode < 300) {
        final body = jsonDecode(loginRes.body);
        _token = (body['access_token'] ?? '').toString();
        if (_token!.isEmpty) throw 'Token manquant';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await loadUserProfile();
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connexion Facebook échouée : $e')));
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------- LOGOUT ----------------------
Future<void> logout(BuildContext context) async {
  if (_token != null) {
    // On tente quand même d'informer le backend
    try {
      await _authService.logout(_token!);
    } catch (e) {
      print('Erreur logout API: $e');
    }
  }

  // On vide toujours la session locale
  _token = null;
  _userData = null;

  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  notifyListeners();

  // Navigation vers login
  if (context.mounted) {
    Navigator.of(context).pushReplacementNamed('/login');
  }
}




  // ---------------------- RESET PASSWORD ----------------------
  Future<bool> requestPasswordReset(BuildContext ctx, String email) async {
    final now = DateTime.now();
    if (_lastResetRequestAt != null &&
        now.difference(_lastResetRequestAt!) < const Duration(seconds: 5)) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Please wait a moment before retrying.')),
      );
      return false;
    }
    _lastResetRequestAt = now;

    try {
      final result = await _authService.requestPasswordReset(email);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Email envoyé')),
      );
      return result['success'] == true;
    } catch (e) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e')),
      );
      return false;
    }
  }

  Future<bool> verifyResetCode(BuildContext context, String email, String code) async {
    final normEmail = email.trim().toLowerCase();

    try {
      final result = await _authService.verifyResetCode(normEmail, code);
      final verified = result['success'] == true;

      if (!verified) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Code invalide')),
          );
        }
        return false;
      }

      final loginRes = await _authService.login(normEmail, code);
      final body = jsonDecode(loginRes.body);
      _token = (body['access_token'] ?? '').toString();

      if (_token!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Token manquant')),
          );
        }
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await loadUserProfile();

      if (!context.mounted) return true;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e')),
        );
      }
      return false;
    }
  }
}
