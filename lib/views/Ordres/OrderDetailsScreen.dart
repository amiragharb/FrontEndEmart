// lib/views/orders/order_details_screen.dart
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontendemart/viewmodels/Config_ViewModel.dart';

/* ---------------- helpers ---------------- */

Color _parseHexColor(String? hex, {Color fallback = const Color(0xFF0B1E6D)}) {
  if (hex == null) return fallback;
  var s = hex.trim();
  if (s.isEmpty) return fallback;
  if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
  if (s.length == 6) s = 'FF$s';
  final v = int.tryParse(s, radix: 16);
  return v != null ? Color(v) : fallback;
}

double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

int? _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');

IconData _faToIconData(String? fa) {
  final s = (fa ?? '').trim().toLowerCase(); // ex: "fa fa-plane"
  final last = s.split(RegExp(r'\s+')).where((e) => e.startsWith('fa-')).map((e) => e.replaceFirst('fa-', '')).lastOrNull;
  final k = last ?? s.replaceAll('fa', '').replaceAll('-', '').trim();

  switch (k) {
    case 'check':
    case 'checkcircle':
      return Icons.check_circle;
    case 'times':
    case 'close':
    case 'ban':
      return Icons.cancel;
    case 'plane':
      return Icons.flight;
    case 'truck':
    case 'shippingfast':
    case 'motorcycle':
      return Icons.local_shipping;
    case 'hourglass':
    case 'clock':
      return Icons.schedule;
    case 'box':
    case 'archive':
      return Icons.inventory_2;
    case 'shoppingcart':
    case 'cartplus':
      return Icons.add_shopping_cart;
    case 'clipboard':
    case 'file':
      return Icons.description;
    case 'home':
      return Icons.home_outlined;
    case 'store':
      return Icons.storefront;
    default:
      return Icons.info_outline;
  }
}

extension _IterableLastOrNull<T> on Iterable<T> {
  T? get lastOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    T value = it.current;
    while (it.moveNext()) {
      value = it.current;
    }
    return value;
  }
}

/* ---------------- Screen ---------------- */

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? _root;            // /orders/:id
  Map<String, dynamic>? _status;          // /orders/:id/status
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      // NB: 10.0.2.2 = localhost (Android emulator)
      final uriOrder  = Uri.parse('http://10.0.2.2:3001/orders/${widget.orderId}');
      final uriStatus = Uri.parse('http://10.0.2.2:3001/orders/${widget.orderId}/status');

      final responses = await Future.wait<http.Response>([
        http.get(uriOrder,  headers: headers),
        http.get(uriStatus, headers: headers), // route non protégée, header ok quand même
      ]);

      final resOrder  = responses[0];
      final resStatus = responses[1];

      if (resOrder.statusCode < 200 || resOrder.statusCode >= 300) {
        throw Exception('Order HTTP ${resOrder.statusCode}: ${resOrder.body}');
      }
      final decoded = jsonDecode(resOrder.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected order response shape');
      }
      _root = decoded;

      if (resStatus.statusCode >= 200 && resStatus.statusCode < 300) {
        final s = jsonDecode(resStatus.body);
        if (s is Map<String, dynamic>) _status = s;
      } else {
        // Pas bloquant — on affiche juste sans statut
        _status = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<ConfigViewModel>().config;
    final primary = _parseHexColor(cfg?.ciPrimaryColor);
    final isAr = context.locale.languageCode.toLowerCase().startsWith('ar');

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('order_details'.tr())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _root == null) {
      return Scaffold(
        appBar: AppBar(title: Text('order_details'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final root = _root!;
    final order = Map<String, dynamic>.from(root['order'] ?? const {});
    final items = (root['items'] as List? ?? const [])
        .whereType<dynamic>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
    final totals = Map<String, dynamic>.from(root['totals'] ?? const {});

    final orderNumber = (order['orderNumber'] ?? '').toString();
    final orderDateStr = (order['orderDate'] ?? '').toString();
    final orderDate =
        orderDateStr.isNotEmpty ? DateTime.tryParse(orderDateStr) : null;

    final addressTitle = (order['addressTitle'] ?? '').toString();
    final address = (order['address'] ?? '').toString();
    final governorateName = (order['governorateName'] ?? '').toString();
    final countryName = (order['countryName'] ?? '').toString();

    final subTotal = _toDouble(totals['subTotal'] ?? order['subTotal']);
    final deliveryFees =
        _toDouble(totals['deliveryFees'] ?? order['deliveryFees']);
    final discountAmount =
        _toDouble(totals['discountAmount'] ?? order['discountAmount']);
    final total = _toDouble(
        totals['total'] ?? order['total'] ?? (subTotal + deliveryFees - discountAmount));

    final hasBrandColumn = items.any((it) =>
        ((it['brandNameAr'] ?? '').toString().trim().isNotEmpty) ||
        ((it['brandNameEn'] ?? '').toString().trim().isNotEmpty));

    // -------- status bits --------
    final st = _status;
    final statusName = () {
      if (st == null) return '—';
      final en = (st['statusNameEn'] ?? '').toString();
      final ar = (st['statusNameAr'] ?? '').toString();
      return isAr ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);
    }();
    final statusIcon = _faToIconData((st?['icon'] ?? '').toString());
    final statusAt = () {
      final s = (st?['at'] ?? '').toString();
      final dt = s.isNotEmpty ? DateTime.tryParse(s) : null;
      return dt != null ? DateFormat('HH:mm dd/MM/yyyy').format(dt.toLocal()) : '—';
    }();
    final isFinished = st?['isOrderFinished'] == true;
    final isCanceled = st?['isCanceled'] == true;
    final statusColor = isCanceled
        ? Colors.red
        : (isFinished ? Colors.teal : primary);

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text('order_details'.tr())),
      backgroundColor: const Color(0xFFF6F6F8),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _HeaderCapsule(
              primaryColor: primary,
              title: '${'order'.tr()} #$orderNumber',
              subtitle: orderDate != null
                  ? DateFormat('HH:mm dd/MM/yyyy').format(orderDate.toLocal())
                  : '—',
            ),

            const SizedBox(height: 16),

            // ---------- NEW: order status card ----------
            _SectionCard(
              primaryColor: primary,
              title: 'order_status'.tr(), // si la clé manque, il affichera la clé
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(statusName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              statusAt,
                              style: const TextStyle(
                                  color: Colors.black54, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (isCanceled)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(.09),
                                border: Border.all(color: Colors.red.withOpacity(.25)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('canceled'.tr(),
                                  style: const TextStyle(
                                      color: Colors.red, fontWeight: FontWeight.w700)),
                            ),
                          )
                        else if (isFinished)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(.09),
                                border: Border.all(color: Colors.teal.withOpacity(.25)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('done'.tr(),
                                  style: const TextStyle(
                                      color: Colors.teal, fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _SectionCard(
              primaryColor: primary,
              title: 'status_new_order'.tr(), // (ton ancien titre pour la section adresse)
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.place_outlined, color: primary),
                ),
                title: Text(
                  addressTitle.isNotEmpty ? addressTitle : 'address'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  [
                    if (address.trim().isNotEmpty) address.trim(),
                    if (governorateName.trim().isNotEmpty) governorateName.trim(),
                    if (countryName.trim().isNotEmpty) countryName.trim(),
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(Icons.location_pin, color: primary),
              ),
            ),

            const SizedBox(height: 16),

            _SectionCard(
              primaryColor: primary,
              title: 'items'.tr(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: hasBrandColumn ? 5 : 6,
                          child: Text('item'.tr(),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        if (hasBrandColumn)
                          Expanded(
                            flex: 3,
                            child: Text('brand'.tr(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        Expanded(
                          flex: 2,
                          child: Text('quantity'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('price'.tr(),
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('total'.tr(),
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('no_items'.tr(),
                            style: TextStyle(color: Colors.grey.shade700)),
                      ),
                    )
                  else
                    ...items.map((it) {
                      final nameEn = (it['nameEn'] ?? '').toString();
                      final nameAr = (it['nameAr'] ?? '').toString();
                      final name =
                          isAr ? (nameAr.isNotEmpty ? nameAr : nameEn) : (nameEn.isNotEmpty ? nameEn : nameAr);
                      final brand = isAr
                          ? (it['brandNameAr'] ?? '').toString()
                          : (it['brandNameEn'] ?? '').toString();
                      final qty =
                          (it['quantity'] as num?)?.toInt() ?? _toInt(it['quantity']) ?? 0;
                      final price = _toDouble(it['price']);
                      final line = _toDouble(it['lineTotal'] ?? (price * qty));

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: hasBrandColumn ? 5 : 6,
                              child: Text(name),
                            ),
                            if (hasBrandColumn)
                              Expanded(
                                flex: 3,
                                child: Text(brand, textAlign: TextAlign.center),
                              ),
                            Expanded(
                              flex: 2,
                              child: Text('$qty', textAlign: TextAlign.center),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(price.toStringAsFixed(2),
                                  textAlign: TextAlign.end),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(line.toStringAsFixed(2),
                                  textAlign: TextAlign.end),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _SectionCard(
              primaryColor: primary,
              title: 'summary'.tr(),
              child: Column(
                children: [
                  _kv(context, 'sub_total'.tr() + ' :', subTotal),
                  _kv(context, 'discount'.tr() + ' :', -discountAmount, isDiscount: true),
                  _kv(context, 'shipping_cost'.tr() + ' :', deliveryFees),
                  Divider(color: Colors.brown.shade200, height: 18),
                  _kv(context, 'total'.tr() + ' :', total, bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _kv(BuildContext ctx, String k, double v,
      {bool bold = false, bool isDiscount = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      color: isDiscount ? Colors.red : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k, style: style, textAlign: TextAlign.right)),
          Text(v.toStringAsFixed(2), style: style),
        ],
      ),
    );
  }
}

/* ------------- widgets ------------- */

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
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor.withOpacity(.85), primaryColor.withOpacity(.65)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.receipt_long, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(.35)),
                  ),
                  child: Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.primaryColor,
    required this.title,
    required this.child,
  });

  final Color primaryColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: primaryColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xFF3B3B3B))),
              ],
            ),
          ),
          Divider(color: Colors.brown.shade200, height: 1),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), child: child),
        ],
      ),
    );
  }
}
