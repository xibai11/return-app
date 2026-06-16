import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';

class ApiService {
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  String? getToken() => _token;

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final resp = await http.get(
      Uri.parse('${Config.baseUrl}$path'),
      headers: _headers,
    );
    _checkResp(resp);
    return jsonDecode(resp.body);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> data) async {
    final resp = await http.post(
      Uri.parse('${Config.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _checkResp(resp);
    return jsonDecode(resp.body);
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> data) async {
    final resp = await http.put(
      Uri.parse('${Config.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _checkResp(resp);
    return jsonDecode(resp.body);
  }

  Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> data) async {
    final resp = await http.patch(
      Uri.parse('${Config.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _checkResp(resp);
    return jsonDecode(resp.body);
  }

  Future<void> _delete(String path) async {
    final resp = await http.delete(
      Uri.parse('${Config.baseUrl}$path'),
      headers: _headers,
    );
    _checkResp(resp);
  }

  void _checkResp(http.Response resp) {
    if (resp.statusCode >= 400) {
      final body = jsonDecode(resp.body);
      throw ApiException(body['error'] ?? '请求失败 (${resp.statusCode})');
    }
  }

  // 登录
  Future<User> login(String username, String password) async {
    final data = await _post('/api/auth/login', {'username': username, 'password': password});
    _token = data['token'];
    return User.fromJson(data['user']);
  }

  // 注册
  Future<User> register(String username, String password, String name) async {
    final data = await _post('/api/auth/register', {
      'username': username,
      'password': password,
      'name': name,
    });
    _token = data['token'];
    return User.fromJson(data['user']);
  }

  // 获取当前用户
  Future<User> me() async {
    final data = await _get('/api/me');
    return User.fromJson(data);
  }

  // 获取记录列表
  Future<({List<ReturnRecord> list, int total, int page, int pageSize})> listRecords({
    int page = 1,
    int pageSize = 50,
    String? status,
    bool? important,
    String? search,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (status != null && status != 'all') params['status'] = status;
    if (important == true) params['important'] = '1';
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('${Config.baseUrl}/api/records').replace(queryParameters: params);
    final resp = await http.get(uri, headers: _headers);
    _checkResp(resp);
    final body = jsonDecode(resp.body);
    return (
      list: (body['list'] as List).map((e) => ReturnRecord.fromJson(e as Map<String, dynamic>)).toList(),
      total: (body['total'] ?? 0) as int,
      page: (body['page'] ?? 1) as int,
      pageSize: (body['page_size'] ?? 50) as int,
    );
  }

  // 获取单条记录
  Future<ReturnRecord> getRecord(int id) async {
    final data = await _get('/api/records/$id');
    return ReturnRecord.fromJson(data);
  }

  // 创建记录（接收 Map）
  Future<ReturnRecord> createRecord(Map<String, dynamic> data) async {
    final resp = await _post('/api/records', data);
    return ReturnRecord.fromJson(resp);
  }

  // 更新记录（接收 Map）
  Future<ReturnRecord> updateRecord(int id, Map<String, dynamic> data) async {
    final resp = await http.put(
      Uri.parse('${Config.baseUrl}/api/records/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _checkResp(resp);
    return ReturnRecord.fromJson(jsonDecode(resp.body));
  }

  // 切换状态
  Future<ReturnRecord> toggleStatus(int id, String status) async {
    final data = await _patch('/api/records/$id/status', {'status': status});
    return ReturnRecord.fromJson(data);
  }

  // 删除记录
  Future<void> deleteRecord(int id) async {
    await _delete('/api/records/$id');
  }

  // 获取仪表盘统计
  Future<DashboardStats> dashboard() async {
    final data = await _get('/api/stats/dashboard');
    return DashboardStats.fromJson(data);
  }

  // 获取用户列表
  Future<List<User>> listUsers() async {
    final data = await _get('/api/users');
    return (data as List).map((e) => User.fromJson(e)).toList();
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
