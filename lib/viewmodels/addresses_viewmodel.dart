// lib/viewmodels/addresses_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:frontendemart/models/address_model.dart';
import 'package:frontendemart/services/address_service.dart';
import 'package:frontendemart/config/api.dart' show ApiConfig;

class AddressesViewModel extends ChangeNotifier {
  final AddressService _svc = AddressService(ApiConfig.baseUrl);

  List<Address> _list = const [];
  bool _loading = false;
  String? _error;

  List<Address> get list => _list;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> getAll({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      debugPrint('🔎 [AddrVM] getAll → call service');
      final data = await _svc.getAll();
      _list = data;
      debugPrint('✅ [AddrVM] loaded ${_list.length} addresses');
    } catch (e, st) {
      _error = e.toString();
      debugPrint('❌ [AddrVM] getAll error: $e\n$st');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Address> add(Address a) async {
    try {
      debugPrint('🚀 [AddrVM] add() start');
      final created = await _svc.create(a);
      debugPrint('✅ [AddrVM] add → id=${created.userLocationId}');

      // Si l’API a modifié d’autres lignes (ex: unique "home"), recharge.
      if (created.isHome == true) {
        await getAll(silent: true);
      } else {
        _list = [created, ..._list];
        notifyListeners();
      }
      return created;
    } catch (e, st) {
      debugPrint('❌ [AddrVM] add error: $e\n$st');
      rethrow;
    }
  }

  Future<Address> update(Address a) async {
    try {
      debugPrint('🛠️ [AddrVM] update() id=${a.userLocationId}');
      final updated = await _svc.update(a);

      // Si "home" est passé à true, l’API a probablement remis les autres à false.
      // Recharge pour refléter ces effets de bord.
      if (updated.isHome == true || a.isHome == true) {
        await getAll(silent: true);
      } else {
        _list = _list
            .map((x) => x.userLocationId == updated.userLocationId ? updated : x)
            .toList();
        notifyListeners();
      }
      return updated;
    } catch (e, st) {
      debugPrint('❌ [AddrVM] update error: $e\n$st');
      rethrow;
    }
  }

  Future<void> remove(int id) async {
    try {
      debugPrint('🗑️ [AddrVM] remove id=$id');
      await _svc.remove(id);
      _list = _list.where((x) => x.userLocationId != id).toList();
      notifyListeners();
    } catch (e, st) {
      debugPrint('❌ [AddrVM] remove error: $e\n$st');
      rethrow;
    }
  }
}
