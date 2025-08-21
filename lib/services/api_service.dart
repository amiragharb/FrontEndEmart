import 'dart:convert';
import 'package:frontendemart/models/SellerItem_model.dart';
import 'package:frontendemart/models/category_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://10.0.2.2:3002/items"; // Android émulateur

Future<List<Category>> fetchCategories() async {
    final uri = Uri.parse("$baseUrl/categories");
    final response = await http.get(uri, headers: {"Content-Type": "application/json"});

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception("Erreur API categories: ${response.statusCode}");
    }
  }


Future<List<SellerItem>> fetchItems({
  String? search,
  String? category,
  String? sort,
}) async {
  try {
    final queryParams = {
      if (search != null && search.isNotEmpty) "search": search,
      if (category != null && category.isNotEmpty && category != "All") "category": category,
      if (sort != null && sort.isNotEmpty && sort != "None") "sort": sort,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    print("📡 Appel API → $uri");

    final response = await http.get(uri, headers: {"Content-Type": "application/json"});

    print("📡 StatusCode: ${response.statusCode}");
    print("📦 Réponse brute: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => SellerItem.fromJson(e)).toList();
    } else {
      throw Exception("Erreur API: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Erreur fetchItems: $e");
    rethrow;
  }
}

  
}
