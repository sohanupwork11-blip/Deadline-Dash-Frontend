import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/deadline_models.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._(this._preferences, this._http, this.baseUrl);

  static const _tokenKey = 'deadline_dash_access_token';
  static const _defaultBaseUrl = 'http://localhost:8000/api';

  final SharedPreferences _preferences;
  final http.Client _http;
  final String baseUrl;

  bool get isAuthenticated => _preferences.getString(_tokenKey) != null;

  static Future<ApiClient> create() async {
    final preferences = await SharedPreferences.getInstance();
    const configuredUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _defaultBaseUrl,
    );
    return ApiClient._(
      preferences,
      http.Client(),
      configuredUrl.replaceFirst(RegExp(r'/+$'), ''),
    );
  }

  Future<void> signIn(String username, String password) async {
    final result = await _send('POST', '/auth/token/', body: {
      'username': username,
      'password': password,
    });
    final token = result['access'] as String?;
    if (token == null) throw const ApiException('The API did not return an access token.');
    await _preferences.setString(_tokenKey, token);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await _send('POST', '/auth/register/', body: {
      'username': username,
      'email': email,
      'password': password,
    });
    await signIn(username, password);
  }

  Future<void> signOut() async {
    await _preferences.remove(_tokenKey);
  }

  Future<DashboardData> loadDashboard() async {
    final values = await Future.wait([
      _send('GET', '/projects/'),
      _send('GET', '/tasks/?ordering=due_date'),
      _send('GET', '/billing/subscription/'),
    ]);
    return DashboardData(
      projects: _items(values[0]).map(Project.fromJson).toList(),
      tasks: _items(values[1]).map(DeadlineTask.fromJson).toList(),
      subscription: SubscriptionInfo.fromJson(values[2]),
    );
  }

  Future<void> createProject({
    required String name,
    required String description,
    required DateTime? dueDate,
  }) async {
    await _send('POST', '/projects/', body: {
      'name': name,
      'description': description,
      'due_date': dueDate == null ? null : _dateOnly(dueDate),
      'status': 'active',
    });
  }

  Future<void> createTask({
    required int projectId,
    required String title,
    required String priority,
    required DateTime? dueDate,
  }) async {
    await _send('POST', '/tasks/', body: {
      'project': projectId,
      'title': title,
      'priority': priority,
      'due_date': dueDate == null ? null : _dateOnly(dueDate),
    });
  }

  Future<void> updateTaskStatus(int taskId, String status) async {
    await _send('PATCH', '/tasks/$taskId/', body: {'status': status});
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> response) {
    final values = response['results'] as List<dynamic>? ?? const [];
    return values.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final token = _preferences.getString(_tokenKey);
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && (authenticated || isAuthenticated)) {
      headers['Authorization'] = 'Bearer $token';
    }
    final uri = Uri.parse('$baseUrl$path');
    late final http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _http.get(uri, headers: headers);
        case 'POST':
          response = await _http.post(uri, headers: headers, body: jsonEncode(body));
        case 'PATCH':
          response = await _http.patch(uri, headers: headers, body: jsonEncode(body));
        default:
          throw const ApiException('Unsupported request method.');
      }
    } on http.ClientException {
      throw ApiException('Could not reach the API at $baseUrl. Check that the backend is running.');
    }
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = decoded['detail'] ?? decoded.values.firstOrNull;
      throw ApiException(detail?.toString() ?? 'Request failed (${response.statusCode}).');
    }
    return decoded;
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}