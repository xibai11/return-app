import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../services/api.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  User? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  AuthProvider(this._api);

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _user != null;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      _api.setToken(_token);
      try {
        _user = await _api.me();
        notifyListeners();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _api.login(username, password);
      _token = _api.getToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _api.getToken() ?? '');
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '网络错误，请检查网络连接';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String password, String name) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _api.register(username, password, name);
      _token = _api.getToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _api.getToken() ?? '');
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '网络错误，请检查网络连接';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
