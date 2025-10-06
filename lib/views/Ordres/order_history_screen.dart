// lib/views/orders/order_history_screen.dart
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontendemart/routes/routes.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';

Color _parseHexColor(String? hex, {Color fallback = const Color(0xFF0B1E6D)}) {
  if (hex == null) return fallback;
  var s = hex.trim().replaceAll('#', '');
  if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
  if (s.length == 6) s = 'FF$s';
  final v = int.tryParse(s, radix: 16);
  return v != null ? Color(v) : fallback;
}

double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;
int? _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');
String _toStr(dynamic v) => (v ?? '').toString();

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<int?> _userId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  /// Essaie plusieurs endpoints et normalise la réponse
  Future<void> _load() async {
  setState(() { _loading = true; _error = null; });

  try {
    final headers = await _headers();
    final uid = await _userId();

    http.Response? res;
    Uri? used;

    // ✅ 1) /orders/mine en premier (si token ok, pas besoin de userId)
    used = Uri.parse('http://10.0.2.2:3001/orders/mine');
    var rMine = await http.get(used, headers: headers);
    if (rMine.statusCode >= 200 && rMine.statusCode < 300) {
      res = rMine;
    } else {
      // 2) /orders?userId= (fallback)
      if (uid != null) {
        used = Uri.parse('http://10.0.2.2:3001/orders?userId=$uid');
        var rQ = await http.get(used, headers: headers);
        if (rQ.statusCode >= 200 && rQ.statusCode < 300) {
          res = rQ;
        } else if (rQ.statusCode != 404 && rQ.statusCode != 400) {
          // garde la dernière erreur utile
          res = rQ;
        }
      }

      // 3) /orders/user/:id (deuxième fallback)
      if (res == null && uid != null) {
        used = Uri.parse('http://10.0.2.2:3001/orders/user/$uid');
        var rUser = await http.get(used, headers: headers);
        if (rUser.statusCode >= 200 && rUser.statusCode < 300) {
          res = rUser;
        } else if (rUser.statusCode != 404 && rUser.statusCode != 400) {
          res = rUser;
        }
      }
    }

    if (res == null) {
      _error = 'No working endpoint for orders list';
    } else if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = res.body;
      print('[OrderHistory] GET $used → ${res.statusCode} body=${body.substring(0, body.length.clamp(0, 800))}');

      dynamic decoded;
      try { decoded = jsonDecode(body); } catch (_) {
        _orders = [];
        if (mounted) setState(() => _loading = false);
        return;
      }

      List<Map<String, dynamic>> norm = [];
      List<Map<String, dynamic>> _castList(dynamic x) => (x as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      Map<String, dynamic> _castMap(dynamic x) => Map<String, dynamic>.from(x);

      if (decoded is List) {
        norm = _castList(decoded);
      } else if (decoded is Map) {
        final m = _castMap(decoded);
        final keys = ['orders','data','items','rows','recordset','results','value'];
        bool picked = false;
        for (final k in keys) {
          final v = m[k];
          if (v is List) { norm = _castList(v); picked = true; break; }
        }
        if (!picked && m['order'] is Map) { norm = [_castMap(m['order'])]; picked = true; }
        if (!picked) {
          for (final entry in m.entries) {
            final v = entry.value;
            if (v is List && v.isNotEmpty && v.first is Map && (v.first as Map).containsKey('orderId')) {
              norm = _castList(v); picked = true; break;
            }
          }
        }
        if (!picked && (m.containsKey('orderId') || m.containsKey('OrderID'))) {
          norm = [m]; picked = true;
        }
        if (!picked) throw Exception('Unexpected response shape for list');
      } else {
        throw Exception('Unexpected response shape for list');
      }

      _orders = norm;
    } else {
      // Montre l’erreur HTTP utile (401, 403, etc.)
      _error = 'HTTP ${res.statusCode}: ${res.body}';
    }
  } catch (e) {
    _error = e.toString();
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final primary = _parseHexColor(context.watch<ConfigViewModel>().config?.ciPrimaryColor);

    return Scaffold
    (
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: Text('my_orders'.tr(args: [], namedArgs: const {}) == 'my_orders'
            ? 'my_orders'.tr()
            : 'my_orders'.tr()),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_error!, textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  )
                : (_orders.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('— No orders —')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: _orders.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          if (i == 0) {
                            return _HeaderCapsule(
                              primaryColor: primary,
                              title: 'my_orders'.tr() == 'my_orders'
                                  ? 'my_orders'.tr()
                                  : 'my_orders'.tr(),
                              subtitle: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                            );
                          }

                          final o = _orders[i - 1];

                          // normalisation d’un ordre
                          final id = _toInt(o['orderId'] ?? o['OrderID'] ?? o['id']);
                          final number = _toStr(o['orderNumber'] ?? o['OrderNumber'] ?? o['number']);
                          final dateStr = _toStr(o['orderDate'] ?? o['OrderDate'] ?? o['date'] ?? o['CreationDate'] ?? o['createdAt']);
                          final date = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) : null;
                          final total = _toDouble(o['total'] ?? o['TotalOrder'] ?? o['Total'] ?? o['TotalOrderWithoutDeliveryFees']);
                          final status = _toStr(o['statusNameAr'] ?? o['statusNameEn'] ?? o['status'] ?? o['OrderStatusName'] ?? '');

                          return _OrderTile(
                            primary: primary,
                            orderId: id,
                            orderNumber: number,
                            date: date,
                            total: total,
                            statusText: status,
                            onTap: id == null
                                ? null
                                : () => Navigator.pushNamed(context, AppRoutes.orderDetails, arguments: id),
                          );
                        },
                      )),
      ),
              bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),

    );
  }
}

/* -------- UI widgets -------- */

class _HeaderCapsule extends StatelessWidget {
  const _HeaderCapsule({
    required this.primaryColor,
    required this.title,
    required this.subtitle,
  });

  final Color primaryColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) 
  {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [primaryColor.withOpacity(.85), primaryColor.withOpacity(.65)],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.shopping_bag, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(.35)),
                  ),
                  child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
      
    );
    
  }
  
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.primary,
    required this.orderId,
    required this.orderNumber,
    required this.date,
    required this.total,
    required this.statusText,
    this.onTap,
  });

  final Color primary;
  final int? orderId;
  final String orderNumber;
  final DateTime? date;
  final double total;
  final String statusText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) 
  {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: primary.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.receipt_long, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (orderNumber.isNotEmpty ? '#$orderNumber' : (orderId != null ? '#$orderId' : '#—')),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date!.toLocal()) : '—',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(total.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(statusText.isEmpty ? '—' : statusText,
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right),
          ],
        ),
        
      ),
      
    );
  }
}
