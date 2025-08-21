import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontendemart/config/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
final String baseUrl = ApiConfig.baseUrl;
  /// -------------------- LOGIN --------------------
  /// identifier = email ou numéro de téléphone égyptien
  Future<http.Response> login(String identifier, String password) async {
    try {
      print("🔹 [LOGIN] Identifier: $identifier");
      final response = await http.post(
        Uri.parse('$baseUrl/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      );
      print("⬅️ [LOGIN] Status: ${response.statusCode}");
      print("⬅️ [LOGIN] Body: ${response.body}");
      return response;
    } catch (e) {
      print('⛔ [LOGIN] Erreur: $e');
      return http.Response('Error: $e', 500);
    }
  }

  /// -------------------- SIGNUP --------------------
  Future<http.Response> signup(UserModel user) async {
    print("🔹 [SIGNUP] Data: ${user.toJson()}");
    final response = await http.post(
      Uri.parse('$baseUrl/user/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );
    print("⬅️ [SIGNUP] Status: ${response.statusCode}");
    print("⬅️ [SIGNUP] Body: ${response.body}");
    return response;
  }

  /// -------------------- TOKEN --------------------
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print("🔑 [TOKEN] Récupéré: $token");
    return token;
  }

  /// -------------------- GET PROFILE --------------------
  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    if (token == null) {
      print('❌ [GET PROFILE] Aucun token trouvé');
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print("⬅️ [GET PROFILE] Status: ${response.statusCode}");
    print("⬅️ [GET PROFILE] Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  /// -------------------- UPDATE PROFILE --------------------
  Future<bool> updateProfile(Map<String, dynamic> updatedData) async {
    final token = await getToken();
    print("📦 [UPDATE PROFILE] TOKEN envoyé: $token");

    final response = await http.patch(
      Uri.parse('$baseUrl/user/update'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updatedData),
    );

    print("⬅️ [UPDATE PROFILE] Status: ${response.statusCode}");
    print("⬅️ [UPDATE PROFILE] Body: ${response.body}");

    return response.statusCode == 200;
  }

  /// -------------------- UPDATE PASSWORD --------------------
  Future<Map<String, dynamic>> updatePassword(String token, String newPassword) async {
    print("📦 [UPDATE PASSWORD] TOKEN envoyé: $token");

    final url = Uri.parse('$baseUrl/user/update-password');
    final body = {'newPassword': newPassword};

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    print("⬅️ [UPDATE PASSWORD] Status: ${response.statusCode}");
    print("⬅️ [UPDATE PASSWORD] Body: ${response.body}");

    final data = jsonDecode(response.body);
    return {
      'success': response.statusCode == 200,
      'message': data['message'] ?? 'Erreur inattendue'
    };
  }

  /// -------------------- FORGET PASSWORD --------------------
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    print("📩 [FORGET PASSWORD] Email envoyé: $email");

    final response = await http.post(
      Uri.parse('$baseUrl/user/forget-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    print("⬅️ [FORGET PASSWORD] Status: ${response.statusCode}");
    print("⬅️ [FORGET PASSWORD] Body: ${response.body}");

    final data = jsonDecode(response.body);
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    return {
      'success': ok,
      'message': data['message'] ?? (ok ? 'Email envoyé' : 'Erreur lors de la réinitialisation'),
    };
  }

  /// -------------------- VERIFY TEMP PASSWORD --------------------
  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    print("✅ [VERIFY CODE] email=$email, code=$code");

    final response = await http.post(
      Uri.parse('$baseUrl/user/verify-temp-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase(), 'tempPassword': code}),
    );

    print("⬅️ [VERIFY CODE] Status: ${response.statusCode}");
    print("⬅️ [VERIFY CODE] Body: ${response.body}");

    Map<String, dynamic> data = {};
    try { data = jsonDecode(response.body); } catch (_) {}

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    return {
      'success': ok,
      'message': data['message'] ?? (ok ? 'Vérification effectuée' : 'Échec vérification'),
    };
  }
  Future<http.Response> firebaseLogin(String idToken, String provider) async {
  final resp = await http.post(
    Uri.parse('$baseUrl/user/firebase-login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'idToken': idToken,
      'provider': provider,
    }),
  );

  print("[GOOGLE] Réponse backend: ${resp.statusCode} - ${resp.body}");
  return resp;
}


  Future<bool> logout(String token) async {
  final url = Uri.parse('$baseUrl/user/logout');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    print('Erreur logout: ${response.body}');
    return false;
  }
}



}
