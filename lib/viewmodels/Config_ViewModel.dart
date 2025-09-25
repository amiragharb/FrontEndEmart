// viewmodels/Config_ViewModel.dart
import 'package:flutter/material.dart';
import 'package:frontendemart/services/ciConfig_Service.dart';
import 'package:frontendemart/models/ciConfig_model.dart';
import 'package:frontendemart/models/app_theme.dart';
import 'package:frontendemart/config/api.dart';

class ConfigViewModel extends ChangeNotifier {
  final ConfigService _configService;
  CiconfigModel? _config;
  bool _isLoading = false;
  String? _error;

  ConfigViewModel([ConfigService? service])
      : _configService = service ?? ConfigService(ApiConfig.baseUrl) {
    fetchConfig();
  }

  CiconfigModel? get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Thème construit depuis la config (null tant que non chargée)
  AppTheme? get theme => _config == null ? null : AppTheme.fromConfig(_config!);

  /// Langues
  List<String> get supportedLanguages {
    final langs = _config?.ciDefaultLanguage?.toLowerCase().split(',') ?? [];
    return langs.where((l) => l == 'ar' || l == 'en').toList();
  }

  bool get showLanguageIcon => supportedLanguages.length > 1;

  String? get forcedLanguage =>
      supportedLanguages.length == 1 ? supportedLanguages.first : null;

  Future<void> fetchConfig() async {
    _isLoading = true;
    notifyListeners();
    try {
      _config = await _configService.getClientConfig();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
