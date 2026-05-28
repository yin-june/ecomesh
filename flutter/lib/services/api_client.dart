import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:async';

class ApiClient {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  final String baseUrl;
  final http.Client httpClient;
  final FlutterSecureStorage secureStorage;
  
  String? _cachedToken;

  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : httpClient = httpClient ?? http.Client(),
        secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Store token securely after login
  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await secureStorage.write(key: _tokenKey, value: token);
  }

  /// Retrieve cached or stored token
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await secureStorage.read(key: _tokenKey);
    return _cachedToken;
  }

  /// Clear token on logout
  Future<void> clearToken() async {
    _cachedToken = null;
    await secureStorage.delete(key: _tokenKey);
    await secureStorage.delete(key: _refreshTokenKey);
  }

  /// Build headers with authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      
      final response = await httpClient.get(url, headers: headers).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw RequestTimeoutException('Request timeout'),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ServerException('GET $endpoint failed: $e');
    }
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await httpClient
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw RequestTimeoutException('Request timeout'),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ServerException('POST $endpoint failed: $e');
    }
  }

  /// POST request with form encoding (for OAuth2PasswordRequestForm)
  Future<dynamic> postForm(
    String endpoint, {
    required Map<String, String> body,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      headers['Content-Type'] = 'application/x-www-form-urlencoded';

      final response = await httpClient
          .post(url, headers: headers, body: body)
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw RequestTimeoutException('Request timeout'),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ServerException('POST $endpoint failed: $e');
    }
  }

  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await httpClient
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw RequestTimeoutException('Request timeout'),
      );

      return _handleResponse(response);
    } catch (e) {
      throw ServerException('PUT $endpoint failed: $e');
    }
  }

  /// Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    try {
      // Handle empty body (204 No Content etc.)
      final body = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return body;
      } else if (response.statusCode == 204) {
        return null;
      } else if (response.statusCode == 401) {
        _cachedToken = null; // Clear invalid token
        final detail = (body is Map) ? (body['detail'] ?? body['message']) : null;
        throw UnauthorizedException('Unauthorized: ${detail ?? 'Unknown error'}');
      } else if (response.statusCode == 404) {
        final detail = (body is Map) ? (body['detail'] ?? body['message']) : null;
        throw NotFoundException('Resource not found: ${detail ?? 'Unknown error'}');
      } else if (response.statusCode >= 400) {
        final detail = (body is Map) ? (body['detail'] ?? body['message']) : response.body;
        throw ServerException('HTTP ${response.statusCode}: ${detail ?? 'Unknown error'}');
      }

      return body;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ServerException('Failed to parse response: $e');
    }
  }
}

// Custom exceptions
abstract class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}

class RequestTimeoutException extends ApiException {
  RequestTimeoutException(super.message);
}
