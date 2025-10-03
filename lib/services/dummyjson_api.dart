import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../models/cart.dart';
import '../models/search_parameters.dart';

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
      _refreshToken = (body['refreshToken'] as String?) ?? _refreshToken;
      return true;
    }
    return false;
  }

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

  Future<List<User>> getLatestUsers({int limit = 10}) async {
    final uri = Uri.parse(
        '$baseUrl/users?limit=$limit&sortBy=id&order=desc&select=id,firstName,lastName,username,email,image,gender,age');
    var res = await _getWithRetry(uri);

    if (res.statusCode != 200) {
      final fallback = Uri.parse(
          '$baseUrl/users?limit=$limit&select=id,firstName,lastName,username,email,image,gender,age');
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

  /// Busca usuários com parâmetros combinados
  Future<List<User>> searchUsers(SearchParameters params) async {
    // Busca todos os usuários (sem limite) para aplicar filtros locais
    final uri = Uri.parse('$baseUrl/users?limit=100&select=id,firstName,lastName,username,email,image,gender,age');
    var res = await _getWithRetry(uri);

    if (res.statusCode != 200) {
      throw Exception('Erro ao buscar users: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final allUsers = (map['users'] as List).cast<Map<String, dynamic>>();
    
    // Aplica filtros locais
    List<User> filteredUsers = allUsers.map(User.fromJson).where((user) {
      return _matchesSearchCriteria(user, params);
    }).toList();

    // Ordena por ID descendente
    filteredUsers.sort((a, b) => b.id.compareTo(a.id));

    // Aplica limite
    return filteredUsers.take(params.limit).toList();
  }

  /// Verifica se um usuário atende aos critérios de busca
  bool _matchesSearchCriteria(User user, SearchParameters params) {
    // Filtro por nome (firstName ou lastName)
    if (params.nameQuery?.isNotEmpty == true) {
      final query = params.caseInsensitive 
          ? params.nameQuery!.toLowerCase() 
          : params.nameQuery!;
      
      final firstName = params.caseInsensitive 
          ? user.firstName.toLowerCase() 
          : user.firstName;
      final lastName = params.caseInsensitive 
          ? user.lastName.toLowerCase() 
          : user.lastName;
      final fullName = params.caseInsensitive 
          ? user.fullName.toLowerCase() 
          : user.fullName;
      
      if (!firstName.contains(query) && 
          !lastName.contains(query) && 
          !fullName.contains(query)) {
        return false;
      }
    }

    if (params.gender?.isNotEmpty == true) {
      final userGender = params.caseInsensitive 
          ? user.gender?.toLowerCase() 
          : user.gender;
      final searchGender = params.caseInsensitive 
          ? params.gender!.toLowerCase() 
          : params.gender!;
      
      if (userGender != searchGender) {
        return false;
      }
    }

    if (params.emailQuery?.isNotEmpty == true) {
      final query = params.caseInsensitive 
          ? params.emailQuery!.toLowerCase() 
          : params.emailQuery!;
      final email = params.caseInsensitive 
          ? user.email.toLowerCase() 
          : user.email;
      
      if (!email.contains(query)) {
        return false;
      }
    }

    if (params.minAge != null || params.maxAge != null) {
      if (user.age == null) {
        return false;
      }
      
      if (params.minAge != null && user.age! < params.minAge!) {
        return false;
      }
      
      if (params.maxAge != null && user.age! > params.maxAge!) {
        return false;
      }
    }

    return true;
  }

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
