// lib/views/Ordres/OrderSummaryScreen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:frontendemart/routes/routes.dart';
import 'package:frontendemart/viewmodels/PaymobViewModel.dart';
import 'package:frontendemart/viewmodels/card_input.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:frontendemart/config/api.dart'; // ApiConfig.baseUrl
import 'package:frontendemart/models/address_model.dart';
import 'package:frontendemart/viewmodels/CartViewModel.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:frontendemart/viewmodels/auth_viewmodel.dart';
import 'package:frontendemart/services/cart_service.dart';

import 'package:frontendemart/views/payment/choose_payment_method_screen.dart'
    show PaymentMethod;

/* ---------- helper logs ---------- */
DateTime _t0 = DateTime.now();
void _log(String msg) {
  final ms =
      DateTime.now().difference(_t0).inMilliseconds.toString().padLeft(5, ' ');
  debugPrint('🧾[OrderSummary+$ms] $msg');
}

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
    this.card,
  });

  final Address address;
  final PaymentMethod method;
  final CardInput? card;

  @override
  State<FinalOrderSummaryScreen> createState() =>
      _FinalOrderSummaryScreenState();
}

class _FinalOrderSummaryScreenState extends State<FinalOrderSummaryScreen> {
  final _promo = TextEditingController();
  final _notes = TextEditingController();

  bool _promoValid = false;
  String? _appliedPromoCode;

  DeliverySlot _slot = DeliverySlot.any;
  double _discount = 0;
  bool _validating = false;
  bool _submitting = false;

  int? _userId;
  bool _loadingUserId = true;

  // --- Delivery fees state ---
  bool _loadingFees = false;
  double? _deliveryFees; // frais bruts renvoyés par l'API
  double? _minFree; // seuil de gratuité
  String? _matchedState; // info debug

  // --- Country support ---
  bool get _isSupportedCountry {
    final c = (widget.address.countryName ?? '').trim().toLowerCase();
    // adapte cette liste si tu actives d'autres pays
    return c == 'egypt' || c == 'egypte' || c == 'مصر';
  }

  String get _countryDbg => (widget.address.countryName ?? '—').trim();

  @override
  void initState() {
    super.initState();
    _loadUserId();
    // On calcule les frais après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDeliveryQuote());
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
    _log('loadUserId()…');

    // 1) AuthViewModel
    final vm = _tryGetAuthVm();
    int? id = _extractUserIdFromMap(vm?.userData);
    if (id != null) {
      _log('userId from AuthViewModel = $id');
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
      _log('userId from SharedPreferences(user_id) = $id');
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
        _log('userId from JWT payload = $fromJwt');
        setState(() {
          _userId = fromJwt;
          _loadingUserId = false;
        });
        await prefs.setInt('user_id', fromJwt);
        return;
      }
      _log('JWT found but no usable id in payload');
    } else {
      _log('no token in SharedPreferences');
    }

    _log('userId not found');
    if (mounted) setState(() => _loadingUserId = false);
  }

  /* ====================== DELIVERY FEES (API) ====================== */

  double _currentSubTotal() {
    final cart = Provider.of<CartViewModel>(context, listen: false);
    return cart.items.fold<double>(0, (s, it) => s + (it.price * it.qty));
  }

  // Frais effectifs (0 si gratuité) – ATTENTION: gratuité seulement si minFree > 0
  double _effectiveDeliveryFee(double subtotal) {
    final fees = _deliveryFees ?? 0.0;
    final min = _minFree;
    if (min != null && min > 0 && subtotal >= min) return 0.0;
    return fees;
  }

  // --- helpers ---
  String _numStr(double n) {
    // valeur canonique attendue par le back: "1234.56"
    final s = n.toStringAsFixed(2); // pas de locale -> déjà avec un point
    return s.replaceAll(',', '.'); // sécurité si une lib a injecté des virgules
  }

  double _toDoubleAny(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    final s = ('$v').trim().replaceAll(',', '.');
    return double.tryParse(s) ?? fallback;
  }

  // --- fetch fees ---
  Future<void> _fetchDeliveryQuote() async {
    try {
      setState(() {
        _loadingFees = true;
        _deliveryFees = null;
        _minFree = null;
        _matchedState = null;
      });

      final sub = _currentSubTotal();
      final addrId = widget.address.userLocationId;

      // 1) Pays supporté ?
      _log('fees: country="$_countryDbg", supported=$_isSupportedCountry, subtotal=$sub');
      if (!_isSupportedCountry) {
        _log('fees: country not supported → skip API, set fees=0');
        setState(() {
          _deliveryFees = 0.0;
          _minFree = null;
          _matchedState = null;
        });
        return;
      }

      // 2) Appel API (Egypte)
      final qp = <String, String>{
        'userLocationId': addrId.toString(), // toujours string
        'subTotal': _numStr(sub), // ← **string numérique** "220.00"
      };
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/orders/delivery-quote').replace(
        queryParameters: qp,
      );

      _log(
          'fees: qp -> userLocationId=${qp['userLocationId']} subTotal=${qp['subTotal']}');
      _log('fees: GET $uri');
      _log('fees: uri.query="${uri.query}"');

      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      _log('fees: response ${res.statusCode} body=${res.body}');
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('delivery-quote failed: ${res.statusCode}');
      }

      final map = json.decode(res.body) as Map<String, dynamic>;
      final fees = _toDoubleAny(map['deliveryFees']);
      final minFree = _toDoubleAny(map['minFree']);
      final stateName = (map['matchedState'] as String?)?.trim();

      setState(() {
        _deliveryFees = fees;
        _minFree = minFree;
        _matchedState = (stateName?.isEmpty ?? true) ? null : stateName;
      });

      final freeNow = (minFree > 0) && sub >= minFree;
      _log(
          'fees: parsed → fees=$fees, minFree=$minFree, state="${_matchedState ?? '—'}", freeNow=$freeNow, subtotal=$sub');

      if (freeNow && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('free_delivery'.tr()),
              backgroundColor: Colors.green),
        );
      }
    } catch (e, st) {
      _log('fees: ERROR → $e\n$st');
      // fallback safe
      setState(() {
        _deliveryFees = 0.0;
        _minFree = null;
        _matchedState = null;
      });
    } finally {
      if (mounted) setState(() => _loadingFees = false);
    }
  }

  /* ====================== PROMO (via backend) & SLOTS ====================== */

  Future<void> _applyPromo(double subtotal) async {
  setState(() => _validating = true);
  try {
    final code = _promo.text.trim();
    if (code.isEmpty) {
      setState(() {
        _discount = 0;
        _promoValid = false;
        _appliedPromoCode = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('enter_promo_code_first'.tr())),
      );
      return;
    }

    _log('applyPromo → code="$code" subtotal=$subtotal');

    final res = await CartService.previewPromo(
      code: code,
      subTotal: subtotal,
    );

    final valid = (res['valid'] == true);
    final discount = _toDoubleAny(res['discount'], fallback: 0.0);
    final reason = (res['reason'] as String?)?.toUpperCase() ?? '';

    if (valid && discount > 0) {
      setState(() {
        _promoValid = true;
        _appliedPromoCode = code;
        _discount = discount; // montant validé serveur
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('promo_applied'.tr())));
    } else {
      setState(() {
        _promoValid = false;
        _appliedPromoCode = null;
        _discount = 0;
      });

      String msg = 'invalid_promo'.tr();
      switch (reason) {
        case 'EXPIRED':
          msg = 'promo_expired'.tr();
          break;
        case 'MIN_ORDER_NOT_REACHED':
          msg = 'promo_min_order_not_reached'.tr();
          break;
        case 'MAX_USERS_REACHED':
          msg = 'promo_max_users_reached'.tr();
          break;
        case 'USER_USAGE_LIMIT':
          msg = 'promo_usage_limit_reached'.tr();
          break;
        case 'NOT_FOUND':
        case 'INACTIVE':
        case 'ZERO_DISCOUNT':
        default:
          msg = 'invalid_promo'.tr();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  } catch (e, st) {
    _log('promo: ERROR → $e\n$st');
    setState(() {
      _promoValid = false;
      _appliedPromoCode = null;
      _discount = 0;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('something_went_wrong'.tr())));
  } finally {
    if (mounted) setState(() => _validating = false);
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
                        Navigator.of(ctx).pop();
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
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

  Future<void> _onOrderCreated(
      Map<String, dynamic> res, Color primary) async {
    int? _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');
    String _toStr(dynamic v) => (v ?? '').toString();

    final orderId = _toInt(
        res['orderId'] ?? res['OrderID'] ?? res['order']?['orderId']);
    final orderNumber = _toStr(res['orderNumber'] ??
        res['OrderNumber'] ??
        res['order']?['orderNumber']);

    final prefs = await SharedPreferences.getInstance();
    if (orderId != null) await prefs.setInt('last_order_id', orderId);
    await prefs.setString('last_order_number', orderNumber);

    context.read<CartViewModel>().clear();
    _log('[Cart] cleared after order (orderId=$orderId)');

    if (!mounted) return;
    await _showOrderSuccessDialog(
        orderId: orderId, orderNumber: orderNumber, primary: primary);
  }

  /* ====================== UI ====================== */

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;

    final config = context.watch<ConfigViewModel>().config;
    final primary = _parseHexColor(config?.ciPrimaryColor);
    final isAr = context.locale.languageCode.toLowerCase().startsWith('ar');

    final cart = context.watch<CartViewModel>();
    final items = cart.items;
    final units = items.fold<int>(0, (s, it) => s + it.qty);
    final subtotal =
        items.fold<double>(0, (s, it) => s + (it.price * it.qty));

    // Frais effectifs selon le seuil
    final deliveryFee = _effectiveDeliveryFee(subtotal);
    const double shipping = 0.0;

    final total =
        (subtotal + deliveryFee + shipping - _discount).clamp(0, double.infinity);

    _log(
      'build: uid=${_userId ?? "—"} | items=${items.length}, units=$units, '
      'sub=$subtotal, rawFees=${_deliveryFees ?? "—"}, minFree=${_minFree ?? "—"}, effective=${deliveryFee}, '
      'discount=$_discount, total=$total | addrId=${widget.address.userLocationId}, method=${widget.method}, '
      'country="$_countryDbg", supported=$_isSupportedCountry',
    );

    if (_loadingUserId) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
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
              subtitle: 'review_your_order'.tr()),
          const SizedBox(height: 16),

          /* ---- Delivery address & Payment Method ---- */
          _SectionCard(
            primaryColor: primary,
            title: 'delivery_address'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Adresse
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.place_outlined,
                          size: 20, color: primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          if ((widget.address.title ?? '')
                              .trim()
                              .isNotEmpty)
                            Text(
                              widget.address.title!.trim(),
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2B2B2B)),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if ((widget.address.address ?? '')
                                  .trim()
                                  .isNotEmpty)
                                widget.address.address!.trim(),
                              if ((widget.address.governorateName ?? '')
                                  .trim()
                                  .isNotEmpty)
                                widget.address.governorateName!.trim(),
                              if ((widget.address.countryName ?? '')
                                  .trim()
                                  .isNotEmpty)
                                widget.address.countryName!.trim(),
                            ].join(', '),
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bandeau frais / gratuité
                const SizedBox(height: 12),
                if (_loadingFees) ...[
                  Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text('calculating_delivery_fees'.tr(),
                          style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                ] else ...[
                  Builder(builder: (_) {
                    final isFree = (_minFree != null &&
                        _minFree! > 0 &&
                        subtotal >= _minFree!);
                    final isUnsupported = !_isSupportedCountry;

                    _log(
                        'fees: banner → isFree=$isFree isUnsupported=$isUnsupported usedFee=$deliveryFee');

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUnsupported
                            ? Colors.orange.withOpacity(.08)
                            : (isFree
                                ? Colors.green.withOpacity(.06)
                                : primary.withOpacity(.06)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isUnsupported
                              ? Colors.orange.withOpacity(.5)
                              : (isFree
                                  ? Colors.green.withOpacity(.4)
                                  : primary.withOpacity(.3)),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isUnsupported
                                ? Icons.public_off
                                : (isFree
                                    ? Icons.local_shipping
                                    : Icons.local_shipping_outlined),
                            size: 18,
                            color: isUnsupported
                                ? Colors.orange
                                : (isFree ? Colors.green : primary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isUnsupported
                                  ? '${'delivery'.tr()}: ${'not_available'.tr()}'
                                  : (isFree
                                      ? 'free_delivery'.tr()
                                      : '${'delivery'.tr()}: ${deliveryFee.toStringAsFixed(2)}'),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isUnsupported
                                    ? Colors.orange
                                    : (isFree
                                        ? Colors.green
                                        : primary),
                              ),
                            ),
                          ),
                          if (!isUnsupported &&
                              _minFree != null &&
                              _minFree! > 0 &&
                              !isFree)
                            Text(
                              '${'free_over'.tr()} ${_minFree!.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    );
                  }),
                  if ((_matchedState ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('${'region'.tr()}: ${_matchedState!}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ],

                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 16),

                // Mode de paiement
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.method == PaymentMethod.cod
                            ? Icons.money_rounded
                            : Icons.credit_card_rounded,
                        size: 20,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('payment_method'.tr(),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: primary.withOpacity(.3),
                                  width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    widget.method ==
                                            PaymentMethod.cod
                                        ? Icons.payments_outlined
                                        : Icons.credit_card,
                                    size: 16,
                                    color: primary),
                                const SizedBox(width: 8),
                                Text(
                                  widget.method ==
                                          PaymentMethod.cod
                                      ? 'cash_on_delivery'.tr()
                                      : 'card_payment'.tr(),
                                  style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),

                          if (widget.method ==
                                  PaymentMethod.card &&
                              widget.card != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.credit_card,
                                      size: 18,
                                      color: Colors.grey.shade600),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                            horizontal: 8,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                          color:
                                              Colors.green.shade200),
                                    ),
                                    child: Text(
                                      'verified'.tr(),
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              Colors.green.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
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
                          style: TextStyle(color: Colors.grey.shade700)),
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
                    _log(
                        'line: id=${it.sellerItemID}, qty=${it.qty}, price=${it.price}');
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
                      _log('slot changed → ${_slotLabel(v)}');
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
                      _log('--- CHECKOUT TAPPED ---');
                      _log(
                          'method=${widget.method} | submitting=$_submitting | loadingUserId=$_loadingUserId');
                      _log(
                          'checkout: will send → deliveryFees=$deliveryFee discount=$_discount total=$total');

                      final userId = _userId;
                      if (userId == null) {
                        _log('⛔ userId is null → ask login');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('please_login_first'.tr())),
                        );
                        return;
                      }

                      final now = DateTime.now();
                      final start = _slotStart(now).toUtc();
                      final end = _slotEnd(now).toUtc();
                      final int userLocationId =
                          widget.address.userLocationId;
                      final itemsPayload = context
                          .read<CartViewModel>()
                          .toOrderItemsPayload();

                      // code promo (seulement si validé par l’API)
                      final appliedCode =
                          (_promoValid && (_appliedPromoCode ?? '').isNotEmpty)
                              ? _appliedPromoCode!.trim()
                              : null;

                      _log(
                          'payload preview → userId=$userId, addrId=$userLocationId, items=${itemsPayload.length}, discount=$_discount, start=$start, end=$end, promo="$appliedCode"');

                      setState(() => _submitting = true);

                      try {
                        if (widget.method == PaymentMethod.cod) {
                          _log(
                              '🟠 COD mode → calling CartService.placeOrder()');
                          final res = await CartService.placeOrder(
                            userId: userId,
                            userLocationId: userLocationId,
                            method: widget.method,
                            deliveryStart: start,
                            deliveryEnd: end,
                            total: total.toDouble(),
                            deliveryFees: deliveryFee, // frais effectifs
                            discountAmount: _discount,
                            userPromoCodeId: null,
                            additionalNotes: _notes.text.trim().isEmpty
                                ? null
                                : _notes.text.trim(),
                            items: itemsPayload,
                            promoCode: appliedCode, // 👈 passe le code
                          );
                          _log('✅ placeOrder (COD) OK → $res');
                          if (!mounted) return;
                          await _onOrderCreated(
                              res,
                              _parseHexColor(context
                                  .read<ConfigViewModel>()
                                  .config
                                  ?.ciPrimaryColor));
                          _log('🎉 Success flow done (COD)');
                        } else {
                          _log(
                              '🔵 CARD mode → via PaymobViewModel.payWithCard()');
                          if (widget.card == null) {
                            _log(
                                '⚠️ widget.card == null (UI a permis card mode sans card?)');
                          } else {
                            final nb = widget.card!.number;
                            final last4 = nb.isNotEmpty
                                ? nb.substring(nb.length - 4)
                                : '????';
                            _log(
                                'card.masked=**** **** **** $last4 exp=${widget.card!.expMonth}/${widget.card!.expYear}');
                          }

                          final paymobVm =
                              context.read<PaymobViewModel>();
                          _log('[VM] payWithCard() → CALL');
                          final result =
                              await paymobVm.payWithCard(
                            userId: userId,
                            userLocationId: userLocationId,
                            total: total.toDouble(),
                            items: itemsPayload,
                            additionalNotes: _notes.text.trim().isEmpty
                                ? null
                                : _notes.text.trim(),
                            deliveryFees: deliveryFee, // frais effectifs
                            discountAmount: _discount,
                            userPromoCodeId: null,
                            promoCode: appliedCode, // 👈 passe le code
                            deliveryStartTime: start,
                            deliveryEndTime: end,
                            appName: 'Ma Boutique',
                            buttonBackgroundColor: _parseHexColor(
                                context
                                    .read<ConfigViewModel>()
                                    .config
                                    ?.ciPrimaryColor),
                            buttonTextColor: Colors.white,
                            saveCardDefault: true,
                            showSaveCard: true,
                          );
                          _log('[VM] payWithCard() → RETURN result="$result"');

                          if (!mounted) return;
                          switch (result) {
                            case 'Successfull':
                              _log('🏁 SDK says Successfull');
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text('payment_success'.tr())));
                              break;
                            case 'Rejected':
                              _log('🟥 SDK says Rejected');
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text('payment_rejected'.tr())));
                              break;
                            case 'Pending':
                              _log('🟨 SDK says Pending');
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text('payment_pending'.tr())));
                              break;
                            default:
                              _log(
                                  '❔ SDK returned unknown="$result" (channel non implémenté ?)');
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text(
                                          'something_went_wrong'.tr())));
                          }
                        }
                      } catch (e, st) {
                        _log('💥 Exception during checkout: $e');
                        _log('stacktrace:\n$st');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('something_went_wrong'.tr())),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _submitting = false);
                          _log('--- CHECKOUT FINISHED (submitting=false) ---');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
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
              child: Text('qty'.tr(), textAlign: TextAlign.center)),
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
    final style = TextStyle(
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600);
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
          colors: [primaryColor.withOpacity(.85), primaryColor.withOpacity(.65)],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.07),
              blurRadius: 16,
              offset: const Offset(0, 8)),
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
                        color: Colors.white, fontWeight: FontWeight.w600)),
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
            padding:
                const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle)),
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
