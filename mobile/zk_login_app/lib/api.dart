import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient(this.baseUrl);
  String baseUrl; // e.g., http://localhost:3000 or http://10.0.2.2:3000

  Future<Map<String, dynamic>> register({
    required String username,
    required String commitment,
    String? salt,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'commitment': commitment,
        if (salt != null) 'salt': salt,
      }),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> nonce({required String username}) async {
    final res = await http.get(Uri.parse('$baseUrl/auth/nonce?username=$username'));
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? salt,
  }) async {
    final payload = <String, dynamic>{'username': username, 'password': password};
    if (salt != null && salt.isNotEmpty) payload['salt'] = salt;
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<String> commitment({
    required String password,
    required String salt,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/commitment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password, 'salt': salt}),
    );
    _ensureOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['commitment'] as String;
  }

  void _ensureOk(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ApiError('HTTP ${r.statusCode}: ${r.body}');
    }
  }
}

class ApiError implements Exception {
  final String message;
  ApiError(this.message);
  @override
  String toString() => message;
}