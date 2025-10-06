// services/ciConfig_Service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ciConfig_model.dart';

class ConfigService {
  final String baseUrl;
  final http.Client _client;

  static const _cacheKey = 'ci_config_cache_v1';

  ConfigService(this.baseUrl, [http.Client? client])
      : _client = client ?? http.Client();

  Future<CiconfigModel> getClientConfig() async {
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final uri = Uri.parse('$normalizedBase/ci-config');

    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final cfg = CiconfigModel.fromJson(data);

        // cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode(data));

        return cfg;
      } else {
        throw Exception('Failed to load client config (HTTP ${res.statusCode})');
      }
    } catch (e) {
      // Fallback cache si offline/erreur
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        return CiconfigModel.fromJson(jsonDecode(cached));
      }
      rethrow;
    }
  }
}
