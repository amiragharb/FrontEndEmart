// lib/views/Ordres/OrderSummaryScreen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:frontendemart/routes/routes.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontendemart/models/address_model.dart';
import 'package:frontendemart/viewmodels/CartViewModel.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:frontendemart/viewmodels/auth_viewmodel.dart';
import 'package:frontendemart/services/cart_service.dart';
import 'package:frontendemart/views/payment/choose_payment_method_screen.dart'
    show PaymentMethod;

/* --------- helpers UI --------- */
Color _parseHexColor(String? hex, {Color fallback = const Color(0xFF0B1E6D)}) {
  if (hex == null) return fallback;
  var s = hex.trim().replaceAll('#', '');
  if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
  if (s.length == 6) s = 'FF$s';
  final v = int.tryParse(s, radix: 16);
  return v != null ? Color(v) : fallback;
}

/* --------- delivery slots --------- */
enum DeliverySlot { any, morning, afternoon, evening }

class FinalOrderSummaryScreen extends StatefulWidget {
  const FinalOrderSummaryScreen({
    super.key,
    required this.address,
    required this.method,
  });

  final Address address;
  final PaymentMethod method;

  @override
  State<FinalOrderSummaryScreen> createState() => _FinalOrderSummaryScreenState();
}

class _FinalOrderSummaryScreenState extends State<FinalOrderSummaryScreen> {
  final _promo = TextEditingController();
  final _notes = TextEditingController();

  DeliverySlot _slot = DeliverySlot.any;
  double _discount = 0;
  bool _validating = false;
  bool _submitting = false;

  int? _userId;
  bool _loadingUserId = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  @override
  void dispose() {
    _promo.dispose();
    _notes.dispose();
    super.dispose();
  }

  /* ====================== USER ID ====================== */

  AuthViewModel? _tryGetAuthVm() {
    try {
      return Provider.of<AuthViewModel>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  int? _extractInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  int? _extractUserIdFromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    for (final k in const ['userId', 'UserID', 'id', 'Id', 'ID']) {
      final got = _extractInt(data[k]);
      if (got != null) return got;
    }
    return null;
  }

  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final jsonStr = utf8.decode(base64Url.decode(normalized));
      final obj = json.decode(jsonStr);
      return (obj is Map<String, dynamic>) ? obj : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadUserId() async {
    debugPrint('[OrderSummary] loadUserId()…');

    // 1) AuthViewModel
    final vm = _tryGetAuthVm();
    int? id = _extractUserIdFromMap(vm?.userData);
    if (id != null) {
      debugPrint('[OrderSummary] userId from AuthViewModel = $id');
      setState(() {
        _userId = id;
        _loadingUserId = false;
      });
      return;
    }

    // 2) SharedPreferences user_id
    final prefs = await SharedPreferences.getInstance();
    id = prefs.getInt('user_id');
    if (id != null) {
      debugPrint('[OrderSummary] userId from SharedPreferences(user_id) = $id');
      setState(() {
        _userId = id;
        _loadingUserId = false;
      });
      return;
    }

    // 3) Decode JWT
    final token = prefs.getString('token');
    if (token != null && token.contains('.')) {
      final payload = _decodeJwt(token);
      final fromJwt = _extractInt(
        payload?['userId'] ??
            payload?['UserID'] ??
            payload?['nameid'] ??
            payload?['uid'] ??
            payload?['sub'],
      );
      if (fromJwt != null) {
        debugPrint('[OrderSummary] userId from JWT payload = $fromJwt');
        setState(() {
          _userId = fromJwt;
          _loadingUserId = false;
        });
        await prefs.setInt('user_id', fromJwt);
        return;
      }
      debugPrint('[OrderSummary] JWT found but no usable id in payload');
    } else {
      debugPrint('[OrderSummary] no token in SharedPreferences');
    }

    debugPrint('[OrderSummary] userId not found');
    if (mounted) setState(() => _loadingUserId = false);
  }

  /* ====================== PROMO & SLOTS ====================== */

  Future<void> _applyPromo(double subtotal) async {
    setState(() => _validating = true);
    try {
      final code = _promo.text.trim();
      debugPrint('[OrderSummary] applyPromo code="$code" subtotal=$subtotal');
      if (code.isEmpty) {
        setState(() => _discount = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('enter_promo_code_first'.tr())),
        );
        return;
      }
      // Exemple local: SAVE10 = -10%
      final rate = code.toUpperCase() == 'SAVE10' ? 0.10 : 0.0;
      final d = subtotal * rate;
      debugPrint('[OrderSummary] promo → rate=$rate discount=$d');
      setState(() => _discount = d);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(rate > 0 ? 'promo_applied'.tr() : 'invalid_promo'.tr())),
      );
    } finally {
      setState(() => _validating = false);
    }
  }

  String _slotLabel(DeliverySlot s) {
    switch (s) {
      case DeliverySlot.morning:
        return 'morning_9_11'.tr();
      case DeliverySlot.afternoon:
        return 'afternoon_12_3'.tr();
      case DeliverySlot.evening:
        return 'evening_4_10'.tr();
      case DeliverySlot.any:
      default:
        return 'any_time'.tr();
    }
  }

  DateTime _slotStart(DateTime d) {
    switch (_slot) {
      case DeliverySlot.morning:
        return DateTime(d.year, d.month, d.day, 9, 0);
      case DeliverySlot.afternoon:
        return DateTime(d.year, d.month, d.day, 12, 0);
      case DeliverySlot.evening:
        return DateTime(d.year, d.month, d.day, 16, 0);
      case DeliverySlot.any:
      default:
        return DateTime(d.year, d.month, d.day, 9, 0);
    }
  }

  DateTime _slotEnd(DateTime d) {
    switch (_slot) {
      case DeliverySlot.morning:
        return DateTime(d.year, d.month, d.day, 11, 0);
      case DeliverySlot.afternoon:
        return DateTime(d.year, d.month, d.day, 15, 0);
      case DeliverySlot.evening:
        return DateTime(d.year, d.month, d.day, 22, 0);
      case DeliverySlot.any:
      default:
        return DateTime(d.year, d.month, d.day, 22, 0);
    }
  }

  /* ====================== POPUP SUCCÈS ====================== */
  Future<void> _showOrderSuccessDialog({
    required int? orderId,
    required String orderNumber,
    required Color primary,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 72, color: primary),
            const SizedBox(height: 12),
            Text(
              tr('order_success_title'),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${tr('order_number')} ${orderNumber.isEmpty ? '—' : orderNumber}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: orderId == null
                    ? null
                    : () {
                        Navigator.of(ctx).pop(); // ferme le popup
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.orderDetails,
                          arguments: orderId,
                        );
                      },
                icon: const Icon(Icons.local_shipping_rounded,
                    color: Colors.white),
                label: Text(tr('track_your_order')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // ferme le popup
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.home, (_) => false);
              },
              child: Text(tr('back_to_home')),
            ),
          ],
        ),
      ),
    );
  }

  /// Appelé après création de commande : vide le panier, sauvegarde id/numéro,
  /// et affiche le popup de succès.
  Future<void> _onOrderCreated(
      Map<String, dynamic> res, Color primary) async {
    int? _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');
    String _toStr(dynamic v) => (v ?? '').toString();

    final orderId =
        _toInt(res['orderId'] ?? res['OrderID'] ?? res['order']?['orderId']);
    final orderNumber = _toStr(
        res['orderNumber'] ?? res['OrderNumber'] ?? res['order']?['orderNumber']);

    // Fallback dans SharedPrefs
    final prefs = await SharedPreferences.getInstance();
    if (orderId != null) await prefs.setInt('last_order_id', orderId);
    await prefs.setString('last_order_number', orderNumber);

    // Vider le panier
    context.read<CartViewModel>().clear();
    debugPrint('[Cart] cleared after order (orderId=$orderId)');

    if (!mounted) return;
    await _showOrderSuccessDialog(
      orderId: orderId,
      orderNumber: orderNumber,
      primary: primary,
    );
  }

  /* ====================== UI ====================== */

  @override
  Widget build(BuildContext context) {
    // rebuild si langue change
    final _ = context.locale;

    final config = context.watch<ConfigViewModel>().config;
    final primary = _parseHexColor(config?.ciPrimaryColor);
    final isAr = context.locale.languageCode.toLowerCase().startsWith('ar');

    // 🛒 Panier persistant via ViewModel
    final cart = context.watch<CartViewModel>();
    final items = cart.items;
    final units = items.fold<int>(0, (s, it) => s + it.qty);
    final subtotal =
        items.fold<double>(0, (s, it) => s + (it.price * it.qty));

    // ✅ pour l’instant ces coûts sont à 0.00
    const double deliveryFee = 0.0;
    const double shipping = 0.0;

    final total =
        (subtotal + deliveryFee + shipping - _discount).clamp(0, double.infinity);

    // Logs build
    debugPrint(
      '[OrderSummary] build: userId=${_userId ?? "—"} | items=${items.length}, units=$units, '
      'sub=$subtotal, delivery=$deliveryFee, shipping=$shipping, discount=$_discount, total=$total '
      '| addrId=${widget.address.userLocationId}, method=${widget.method}',
    );

    if (_loadingUserId) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold
    (
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        centerTitle: true,
        title: Text('order_summary'.tr(),
            style:
                TextStyle(color: primary, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _HeaderCapsule(
            primaryColor: primary,
            title: 'order_summary'.tr(),
            subtitle: 'review_your_order'.tr(),
          ),
          const SizedBox(height: 16),

          /* ---- Delivery address ---- */
          _SectionCard(
            primaryColor: primary,
            title: 'delivery_address'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.place_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [
                        if ((widget.address.title ?? '').trim().isNotEmpty)
                          widget.address.title!.trim(),
                        if ((widget.address.address ?? '').trim().isNotEmpty)
                          widget.address.address!.trim(),
                        if ((widget.address.governorateName ?? '')
                            .trim()
                            .isNotEmpty)
                          widget.address.governorateName!.trim(),
                        if ((widget.address.countryName ?? '').trim().isNotEmpty)
                          widget.address.countryName!.trim(),
                      ].join(' · '),
                      style:
                          const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(.12),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: primary.withOpacity(.25)),
                    ),
                    child: Text(
                      widget.method == PaymentMethod.cod
                          ? 'cash_on_delivery'.tr()
                          : 'card'.tr(),
                      style: TextStyle(
                          color: primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /* ---- Items ---- */
          _SectionCard(
            primaryColor: primary,
            title: 'items'.tr(),
            child: Column(
              children: [
                _tableHeader(context),
                const Divider(height: 1),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('no_items'.tr(),
                          style: TextStyle(
                              color: Colors.grey.shade700)),
                    ),
                  )
                else
                  ...items.map((it) {
                    final name = isAr
                        ? (it.nameAr?.trim().isNotEmpty == true
                            ? it.nameAr!
                            : (it.nameEn ?? ''))
                        : (it.nameEn?.trim().isNotEmpty == true
                            ? it.nameEn!
                            : (it.nameAr ?? ''));
                    final line = it.price * it.qty;
                    debugPrint(
                        '[OrderSummary] line: id=${it.sellerItemID}, qty=${it.qty}, price=${it.price}');
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                      child: Row(
                        children: [
                          Expanded(flex: 5, child: Text(name)),
                          Expanded(
                              flex: 2,
                              child: Text('${it.qty}',
                                  textAlign: TextAlign.center)),
                          Expanded(
                              flex: 3,
                              child: Text(it.price.toStringAsFixed(2),
                                  textAlign: TextAlign.end)),
                          Expanded(
                              flex: 3,
                              child: Text(line.toStringAsFixed(2),
                                  textAlign: TextAlign.end)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /* ---- Promo code ---- */
          _SectionCard(
            primaryColor: primary,
            title: 'enter_promo_code'.tr(),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promo,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed:
                      _validating ? null : () => _applyPromo(subtotal),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white),
                  child: Text(_validating ? '...' : 'apply'.tr()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /* ---- Delivery instructions ---- */
          _SectionCard(
            primaryColor: primary,
            title: 'delivery_instructions'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('best_time_to_deliver'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ...[
                  DeliverySlot.any,
                  DeliverySlot.morning,
                  DeliverySlot.afternoon,
                  DeliverySlot.evening
                ].map((slot) {
                  final label = switch (slot) {
                    DeliverySlot.any => 'any_time'.tr(),
                    DeliverySlot.morning => 'morning_9_11'.tr(),
                    DeliverySlot.afternoon => 'afternoon_12_3'.tr(),
                    DeliverySlot.evening => 'evening_4_10'.tr(),
                  };
                  return RadioListTile<DeliverySlot>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: slot,
                    groupValue: _slot,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _slot = v);
                      debugPrint(
                          '[OrderSummary] slot changed → ${_slotLabel(v)}');
                    },
                    title: Text(label),
                  );
                }),
                const SizedBox(height: 8),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'delivery_notes'.tr(),
                    hintText: 'notes_optional'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /* ---- Summary ---- */
          _SectionCard(
            primaryColor: primary,
            title: 'summary'.tr(),
            child: Column(
              children: [
                _kv('subtotal'.tr(), subtotal),
                _kv('delivery'.tr(), deliveryFee),
                _kv('shipping_cost'.tr(), shipping),
                if (_discount > 0) _kv('discount'.tr(), -_discount),
                Divider(color: Colors.brown.shade200, height: 18),
                _kv('total'.tr(), total.toDouble(), bold: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /* ---- Checkout ---- */
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      final userId = _userId;
                      if (userId == null) {
                        debugPrint(
                            '[OrderSummary] checkout blocked → no userId');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text(tr('please_login_first'))),
                        );
                        return;
                      }

                      final now = DateTime.now();
                      final start = _slotStart(now).toUtc();
                      final end = _slotEnd(now).toUtc();
                      final int userLocationId =
                          widget.address.userLocationId;

                      // transforme le panier en lignes pour l’API
                      final itemsPayload = context
                          .read<CartViewModel>()
                          .toOrderItemsPayload();

                      final payloadLog = {
                        "userId": userId,
                        "userLocationId": userLocationId,
                        "invoicePaymentMethodId":
                            widget.method == PaymentMethod.cod ? 1 : 2,
                        "deliveryStartTime": start.toIso8601String(),
                        "deliveryEndTime": end.toIso8601String(),
                        "discountAmount": _discount,
                        "deliveryFees": 0.0,
                        "total": total.toDouble(),
                        "itemsCount": itemsPayload.length,
                      };
                      debugPrint(
                          '[OrderSummary] → placeOrder payload (preview) $payloadLog');

                      setState(() => _submitting = true);
                      try {
                        final res = await CartService.placeOrder(
                          userId: userId,
                          userLocationId: userLocationId,
                          method: widget.method,
                          deliveryStart: start,
                          deliveryEnd: end,
                          total: total.toDouble(),
                          deliveryFees: 0,
                          discountAmount: _discount,
                          userPromoCodeId: null,
                          additionalNotes: _notes.text.trim().isEmpty
                              ? null
                              : _notes.text.trim(),
                          items: itemsPayload,
                        );
                        debugPrint('✅ ORDER CREATED OK → $res');

                        if (!mounted) return;
                        await _onOrderCreated(res, primary);
                      } catch (e) {
                        debugPrint('❌ placeOrder error: $e');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('something_went_wrong'.tr())),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _submitting = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(_submitting ? '...' : 'checkout'.tr()),
            ),
          ),
        ],
      ),
              bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),

    );
  }

  /* ---------- small UI pieces ---------- */

  Widget _tableHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          Expanded(
              flex: 5,
              child: Text('items'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(
              flex: 2,
              child:
                  Text('qty'.tr(), textAlign: TextAlign.center)),
          Expanded(
              flex: 3,
              child: Text('price'.tr(), textAlign: TextAlign.end)),
          Expanded(
              flex: 3,
              child: Text('total'.tr(), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _kv(String k, double v, {bool bold = false}) {
    final style =
        TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k, style: style)),
          Text(v.toStringAsFixed(2), style: style),
        ],
      ),
    );
  }
}

/* ======================  Widgets “profil style”  ====================== */

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
          colors: [
            primaryColor.withOpacity(.85),
            primaryColor.withOpacity(.65)
          ],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.07),
              blurRadius: 16,
              offset: const Offset(0, 8))
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
                borderRadius: BorderRadius.circular(14)),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(.35)),
                  ),
                  child: Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
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
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B3B3B))),
              ],
            ),
          ),
          Divider(color: Colors.brown.shade200, height: 1),
          Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: child),
        ],
      ),
    );
  }
}
