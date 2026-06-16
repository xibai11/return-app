import 'package:flutter/foundation.dart';
import '../models.dart';
import '../services/api.dart';

class RecordsProvider extends ChangeNotifier {
  final ApiService _api;
  List<Record> _records = [];
  int _total = 0;
  int _page = 1;
  bool _loading = false;
  String? _error;
  String? _statusFilter;
  bool? _importantFilter;
  String? _searchQuery;

  RecordsProvider(this._api);

  List<Record> get records => _records;
  int get total => _total;
  int get page => _page;
  bool get loading => _loading;
  String? get error => _error;
  String? get statusFilter => _statusFilter;
  bool? get importantFilter => _importantFilter;
  String? get searchQuery => _searchQuery;

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _records = [];
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.listRecords(
        page: _page,
        status: _statusFilter,
        important: _importantFilter,
        search: _searchQuery,
      );
      if (refresh) {
        _records = result.list;
      } else {
        _records.addAll(result.list);
      }
      _total = result.total;
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

  Future<Record?> createRecord(Map<String, dynamic> data) async {
    try {
      final newRecord = await _api.createRecord(data);
      _records.insert(0, newRecord);
      _total++;
      notifyListeners();
      return newRecord;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateRecord(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _api.updateRecord(id, data);
      final idx = _records.indexWhere((r) => r.id == id);
      if (idx >= 0) _records[idx] = updated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleStatus(int id, String newStatus) async {
    try {
      final updated = await _api.toggleStatus(id, newStatus);
      final idx = _records.indexWhere((r) => r.id == id);
      if (idx >= 0) _records[idx] = updated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecord(int id) async {
    try {
      await _api.deleteRecord(id);
      _records.removeWhere((r) => r.id == id);
      _total--;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  void setFilter({String? status, bool? important, String? search}) {
    _statusFilter = status;
    _importantFilter = important;
    _searchQuery = search;
    load(refresh: true);
  }

  void clearFilters() {
    _statusFilter = null;
    _importantFilter = null;
    _searchQuery = null;
    load(refresh: true);
  }

  void clear() {
    _records = [];
    _total = 0;
    _page = 1;
    _error = null;
    notifyListeners();
  }
}
