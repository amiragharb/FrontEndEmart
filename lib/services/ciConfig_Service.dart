import 'dart:convert';
import 'package:frontendemart/models/ciConfig_model.dart';
import 'package:http/http.dart' as http;

class ConfigService {
  final String baseUrl;

  ConfigService(this.baseUrl);

  Future<CiconfigModel> getClientConfig() async {
    final response = await http.get(Uri.parse('$baseUrl/ci-config'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CiconfigModel.fromJson(data);
    } else {
      throw Exception('Failed to load client config');
    }
  }
}
