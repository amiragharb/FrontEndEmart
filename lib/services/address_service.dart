import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontendemart/config/api.dart';
import 'package:frontendemart/models/address_model.dart';

class AddressService {
  AddressService([String? baseUrl]) : _baseUrl = baseUrl ?? ApiConfig.baseUrl;
  final String _baseUrl;

  Uri _u(String p) => Uri.parse('$_baseUrl$p');

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    String mask(String s) =>
        s.isEmpty ? 'EMPTY' : (s.length <= 16 ? 'len=${s.length}' : 'len=${s.length} ${s.substring(0, 8)}…${s.substring(s.length - 6)}');
    debugPrint('🔐 [AddrSvc] Authorization: Bearer ${mask(token)}');

    if (token.isEmpty) {
      throw Exception('[AddrSvc] No token in storage');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /* -------------------- READ: list all -------------------- */
  Future<List<Address>> getAll() async {
    final url = _u('/orders/addresses');
    debugPrint('📡 [AddrSvc] GET → $url');

    final res = await http.get(url, headers: await _headers());
    debugPrint('⬅️ [AddrSvc] ${res.statusCode} len=${res.body.length}');

    if (res.statusCode != 200) {
      throw HttpException('GET /orders/addresses → ${res.statusCode}: ${res.body}');
    }
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => Address.fromJson(e)).toList();
  }

  /* -------------------- CREATE -------------------- */
  Future<Address> create(Address a) async {
    final url = _u('/orders/addresses');
    final body = jsonEncode(a.toCreateJson()); // ✅ envoie countryName & governorateName (strings)
    debugPrint('📡 [AddrSvc] POST → $url\n🧳 body: $body');

    final res = await http.post(url, headers: await _headers(), body: body);
    debugPrint('⬅️ [AddrSvc] ${res.statusCode} ${res.body}');
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw HttpException('POST /orders/addresses → ${res.statusCode}: ${res.body}');
    }
    return Address.fromJson(jsonDecode(res.body));
  }

  /* -------------------- UPDATE -------------------- */
  Future<Address> update(Address dto) async {
    if (dto.userLocationId == 0) {
      throw Exception('[AddrSvc] Missing address id');
    }
    final url = _u('/orders/addresses/${dto.userLocationId}');
    final body = jsonEncode(dto.toUpdateJson()); // ✅ countryName/governorateName/districtId
    debugPrint('📡 [AddrSvc] PUT → $url\n🧳 body: $body');

    try {
      final res = await http.put(url, headers: await _headers(), body: body);
      debugPrint('⬅️ [AddrSvc] ${res.statusCode} ${res.body}');
      if (res.statusCode != 200) {
        throw HttpException('PUT /orders/addresses/${dto.userLocationId} → ${res.statusCode}: ${res.body}');
      }
      final updated = Address.fromJson(jsonDecode(res.body));
      debugPrint('✅ [AddrSvc] updated id=${updated.userLocationId}');
      return updated;
    } catch (e, st) {
      debugPrint('❌ [AddrSvc] update error: $e\n$st');
      rethrow;
    }
  }

  /* -------------------- DELETE -------------------- */
  Future<void> remove(int id) async {
    final url = _u('/orders/addresses/$id');
    debugPrint('📡 [AddrSvc] DELETE → $url');

    try {
      final res = await http.delete(url, headers: await _headers());
      debugPrint('⬅️ [AddrSvc] ${res.statusCode} ${res.body}');
      if (res.statusCode != 204 && res.statusCode != 200) {
        throw HttpException('DELETE /orders/addresses/$id → ${res.statusCode}: ${res.body}');
      }
      debugPrint('✅ [AddrSvc] deleted id=$id');
    } catch (e, st) {
      debugPrint('❌ [AddrSvc] delete error: $e\n$st');
      rethrow;
    }
  }
}
