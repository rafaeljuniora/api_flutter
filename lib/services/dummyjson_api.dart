import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../models/cart.dart';

/// Serviço leve para consumir DummyJSON:
/// - Autenticação: POST /auth/login -> accessToken/refreshToken
/// - Refresh:     POST /auth/refresh -> novo accessToken (e possivelmente novo refreshToken)
/// - Recursos:    /users, /carts
class DummyJsonApi {
  DummyJsonApi({http.Client? client, this.baseUrl = 'https://dummyjson.com'})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;

  Map<String, String> get _baseHeaders => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  /// Faz login e guarda o accessToken/refreshToken (Bearer).
  Future<void> login({
    required String username,
    required String password,
    int expiresInMins = 30,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': expiresInMins,
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      _accessToken = body['accessToken'] as String?;
      _refreshToken = body['refreshToken'] as String?;
    } else {
      throw Exception('Falha no login (${res.statusCode}): ${res.body}');
    }
  }

  /// Tenta renovar o accessToken usando o refreshToken.
  Future<bool> _tryRefresh({int expiresInMins = 30}) async {
    if (_refreshToken == null) return false;
    final uri = Uri.parse('$baseUrl/auth/refresh');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'refreshToken': _refreshToken,
        'expiresInMins': expiresInMins,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      _accessToken = body['accessToken'] as String?;
      // pode vir um novo refreshToken
      _refreshToken = (body['refreshToken'] as String?) ?? _refreshToken;
      return true;
    }
    return false;
  }

  /// GET com tentativa de refresh automático em caso de 401/403.
  Future<http.Response> _getWithRetry(Uri uri) async {
    var res = await _client.get(uri, headers: _baseHeaders);
    if (res.statusCode == 401 || res.statusCode == 403) {
      final ok = await _tryRefresh();
      if (ok) {
        res = await _client.get(uri, headers: _baseHeaders);
      }
    }
    return res;
  }

  /// Obtém os últimos N usuários (ordem por id desc se disponível).
  Future<List<User>> getLatestUsers({int limit = 10}) async {
    final uri = Uri.parse(
        '$baseUrl/users?limit=$limit&sortBy=id&order=desc&select=id,firstName,lastName,username,email,image');
    var res = await _getWithRetry(uri);

    if (res.statusCode != 200) {
      // fallback simples sem sortBy/order
      final fallback = Uri.parse(
          '$baseUrl/users?limit=$limit&select=id,firstName,lastName,username,email,image');
      res = await _getWithRetry(fallback);
      if (res.statusCode != 200) {
        throw Exception('Erro ao buscar users: ${res.statusCode} ${res.body}');
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (map['users'] as List).cast<Map<String, dynamic>>();
      list.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      return list.map(User.fromJson).toList();
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (map['users'] as List).cast<Map<String, dynamic>>();
    return list.map(User.fromJson).toList();
  }

  /// Obtém os últimos N carrinhos.
  /// Se sortBy/order não estiver disponível, ordena localmente por id desc.
  Future<List<Cart>> getLatestCarts({int limit = 10}) async {
    final trySorted =
        Uri.parse('$baseUrl/carts?limit=$limit&sortBy=id&order=desc');
    var res = await _getWithRetry(trySorted);

    if (res.statusCode != 200) {
      // fallback sem sort, depois ordena localmente
      final fallback = Uri.parse('$baseUrl/carts?limit=$limit');
      res = await _getWithRetry(fallback);
      if (res.statusCode != 200) {
        throw Exception('Erro ao buscar carts: ${res.statusCode} ${res.body}');
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (map['carts'] as List).cast<Map<String, dynamic>>();
      list.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      return list.map(Cart.fromJson).toList();
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (map['carts'] as List).cast<Map<String, dynamic>>();
    return list.map(Cart.fromJson).toList();
  }
}
