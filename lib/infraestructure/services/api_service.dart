import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:p_a_jewerly/config/environment.dart';

class ApiService {
  final String baseUrl;

  ApiService._internal() : baseUrl = Environment.baseUrl;

  static final ApiService _instance = ApiService._internal();

  static ApiService get instance => _instance;

  factory ApiService() {
    return _instance;
  }

  /// Método GET para un recurso específico
  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  /// Método GET para listar recursos
  Future<dynamic> getAll(String endpoint,
      {Map<String, String>? headers}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  /// Método POST
  Future<dynamic> post(String endpoint,
      {Map<String, String>? headers, dynamic body}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers ?? {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// Método PUT
  Future<dynamic> put(String endpoint,
      {Map<String, String>? headers, dynamic body}) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers ?? {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// Método DELETE
  Future<dynamic> delete(String endpoint,
      {Map<String, String>? headers}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  /// GET with query parameters
  Future<dynamic> getWithParams(String endpoint,
      {Map<String, String>? params, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: params ?? {});
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  /// POST with form data
  Future<dynamic> postFormData(String endpoint,
      {Map<String, String>? headers, Map<String, dynamic>? formData}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers ?? {"Content-Type": "application/x-www-form-urlencoded"},
      body: formData,
    );
    return _handleResponse(response);
  }

  /// PUT with multipart
  Future<dynamic> putMultipart(String endpoint,
      {Map<String, String>? headers, Map<String, dynamic>? body}) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers ?? {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// Centralized response handling
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (statusCode >= 200 && statusCode < 300) {
      // Handle ASP.NET Core ReferenceHandler.Preserve format
      // Response may be wrapped as {"$id":"1","$values":[...]}
      if (body is Map && body.containsKey('\$values')) {
        body = body['\$values'];
      }
      return body;
    } else if (statusCode == 401) {
      throw UnauthorizedException('Unauthorized: ${body?['message'] ?? 'Invalid credentials'}');
    } else if (statusCode == 403) {
      throw ForbiddenException('Forbidden: ${body?['message'] ?? 'Access denied'}');
    } else if (statusCode == 404) {
      throw NotFoundException('Not found: ${body?['message'] ?? 'Resource not found'}');
    } else if (statusCode >= 500) {
      throw ServerException('Server error: ${body?['message'] ?? 'Internal server error'}');
    } else {
      throw ApiException(
          'Error ${response.statusCode}: ${body?['message'] ?? response.reasonPhrase ?? 'Unknown error'}');
    }
  }
}

/// Custom exceptions for better error handling
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}
