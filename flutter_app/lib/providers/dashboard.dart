import 'package:flutter/foundation.dart';
import '../models.dart';
import '../services/api.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api;
  DashboardStats? _stats;
  bool _loading = false;
  String? _error;

  DashboardProvider(this._api);

  DashboardStats? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _stats = await _api.dashboard();
      _loading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = '网络错误';
      _loading = false;
      notifyListeners();
    }
  }
}
