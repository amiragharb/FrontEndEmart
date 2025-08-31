import 'dart:convert';
import 'package:frontendemart/config/api.dart';
import 'package:frontendemart/models/SellerItem_model.dart';
import 'package:frontendemart/models/category_model.dart';
import 'package:frontendemart/models/datasheet_model.dart';
import 'package:frontendemart/models/video_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
final String baseUrl = ApiConfig.baseUrl;

Future<List<Category>> fetchCategories() async {

    final uri = Uri.parse("$baseUrl/items/categories");
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

  final uri = Uri.parse("$baseUrl/items").replace(queryParameters: queryParams); // ✅ devient /items

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
// ✅ Récupérer les stats de rating pour un produit
Future<Map<String, dynamic>> fetchRatings(int sellerItemId) async {
  final uri = Uri.parse("$baseUrl/items/$sellerItemId/ratings");
  final response = await http.get(uri, headers: {"Content-Type": "application/json"});

  if (response.statusCode == 200) {
    return jsonDecode(response.body); // {distribution: [...], recommend: ...}
  } else {
    throw Exception("Erreur API fetchRatings: ${response.statusCode}");
  }
}

// ✅ Ajouter un rating
Future<bool> rateProduct(
  int sellerItemId,
  int userId,
  int rating, {
  String? comment,
  bool recommend = false,
}) async {
  final uri = Uri.parse("$baseUrl/items/$sellerItemId/ratings");
  final body = jsonEncode({
    "userId": userId,
    "rate": rating,
    "comment": comment,
    "recommend": recommend,
  });

  final response = await http.post(
    uri,
    headers: {"Content-Type": "application/json"},
    body: body,
  );

  return response.statusCode == 200 || response.statusCode == 201;
}


  Future<List<Datasheet>> fetchDatasheets(int medicineId) async {
  try {
    final uri = Uri.parse("$baseUrl/items/$medicineId/datasheets");
    print("📡 Appel API datasheets → $uri");

    final response = await http.get(uri, headers: {"Content-Type": "application/json"});

    print("📦 Réponse datasheets brute → ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => Datasheet.fromJson(e)).toList();
    } else {
      throw Exception("Erreur API datasheets: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Erreur fetchDatasheets: $e");
    rethrow;
  }
}
Future<List<VideoModel>> fetchVideos(int medicineId) async {
  final url = "${ApiConfig.baseUrl}/items/$medicineId/videos";
  print("🌍 [fetchVideos] GET $url");

  try {
    final response = await http.get(
      Uri.parse(url),
    );

    print("📡 [fetchVideos] StatusCode: ${response.statusCode}");
    print("📦 [fetchVideos] Raw Response: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);

      print("✅ [fetchVideos] Parsed ${jsonData.length} items");
      return jsonData.map((e) => VideoModel.fromJson(e)).toList();
    } else {
      print("⚠️ [fetchVideos] Non-200 status, returning empty list");
      return [];
    }
  } catch (e, stack) {
    print("❌ [fetchVideos] Exception: $e");
    print(stack);
    return [];
  }
}

}
