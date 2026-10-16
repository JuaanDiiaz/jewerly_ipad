import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:p_a_jewerly/config/environment.dart';

class ApiService {
  ApiService._internal();

  static final ApiService _instance = ApiService._internal();

  static ApiService get instance => _instance;

  factory ApiService() {
    return _instance;
  }

  static const Duration _defaultTimeout = Duration(seconds: 30);

  String get _baseUrl => Environment.baseUrl;

  /// Método GET para un recurso específico
  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    return _send(http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
    ));
  }

  /// Método GET para listar recursos
  Future<dynamic> getAll(String endpoint,
      {Map<String, String>? headers}) async {
    return _send(http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
    ));
  }

  /// Método POST
  Future<dynamic> post(String endpoint,
      {Map<String, String>? headers, dynamic body}) async {
    return _send(http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers ?? {"Content-Type": "application/json"},
      body: jsonEncode(body),
    ));
  }

  /// Método PUT
  Future<dynamic> put(String endpoint,
      {Map<String, String>? headers, dynamic body}) async {
    return _send(http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers ?? {"Content-Type": "application/json"},
      body: jsonEncode(body),
    ));
  }

  /// Método DELETE
  Future<dynamic> delete(String endpoint,
      {Map<String, String>? headers}) async {
    return _send(http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
    ));
  }

  /// GET with query parameters
  Future<dynamic> getWithParams(String endpoint,
      {Map<String, String>? params, Map<String, String>? headers}) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: params ?? {});
    return _send(http.get(uri, headers: headers));
  }

  /// GET for paged endpoints returning the { data, page, pageSize, totalCount }
  /// envelope. With ReferenceHandler.Preserve the data array arrives wrapped
  /// as {"$id":"2","$values":[...]}, so it is unwrapped here.
  Future<PagedEnvelope> getPaged(String endpoint,
      {Map<String, String>? params, Map<String, String>? headers}) async {
    final result = await getWithParams(endpoint, params: params, headers: headers);
    final map = result as Map;
    final dataField = map['data'];
    final items = dataField is Map && dataField.containsKey('\$values')
        ? (dataField['\$values'] as List)
        : (dataField is List ? dataField : <dynamic>[]);
    return PagedEnvelope(
      data: items,
      page: (map['page'] as num?)?.toInt() ?? 1,
      pageSize: (map['pageSize'] as num?)?.toInt() ?? 50,
      totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// POST with form data
  Future<dynamic> postFormData(String endpoint,
      {Map<String, String>? headers, Map<String, dynamic>? formData}) async {
    return _send(http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers ?? {"Content-Type": "application/x-www-form-urlencoded"},
      body: formData,
    ));
  }

  /// PUT with multipart
  Future<dynamic> putMultipart(String endpoint,
      {Map<String, String>? headers, Map<String, dynamic>? body}) async {
    return _send(http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers ?? {"Content-Type": "application/json"},
      body: jsonEncode(body),
    ));
  }

  /// Awaits a request with a timeout and maps it through the central handler.
  /// A timeout is NOT proof of failure — the server may still complete the
  /// action afterwards, so callers must verify before blindly retrying.
  Future<dynamic> _send(Future<http.Response> request) async {
    try {
      final response = await request.timeout(_defaultTimeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'Connection timed out (30s): the server took too long to respond. '
        'The action may still have completed server-side — verify before retrying.',
      );
    }
  }

  /// Centralized response handling
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        // Non-JSON body (e.g. HTML error page from a proxy) — keep raw text
        body = response.body;
      }
    }
    final bodyMessage = body is Map ? body['message'] : null;

    if (statusCode >= 200 && statusCode < 300) {
      if (body == null) {
        // 2xx with an empty body (e.g. 204 No Content): the operation
        // SUCCEEDED. Returning `true` (not null) so callers don't mistake
        // it for a failure and retry — retrying would duplicate the record.
        return true;
      }
      // Handle ASP.NET Core ReferenceHandler.Preserve format
      // Response may be wrapped as {"$id":"1","$values":[...]}
      if (body is Map && body.containsKey('\$values')) {
        body = body['\$values'];
      }
      return body;
    } else if (statusCode == 401) {
      throw UnauthorizedException('Unauthorized: ${bodyMessage ?? 'Invalid credentials'}');
    } else if (statusCode == 403) {
      throw ForbiddenException('Forbidden: ${bodyMessage ?? 'Access denied'}');
    } else if (statusCode == 404) {
      throw NotFoundException('Not found: ${bodyMessage ?? 'Resource not found'}');
    } else if (statusCode >= 500) {
      throw ServerException('Server error: ${bodyMessage ?? 'Internal server error'}');
    } else {
      throw ApiException(
          'Error ${response.statusCode}: ${bodyMessage ?? response.reasonPhrase ?? 'Unknown error'}');
    }
  }
}

/// Envelope returned by the paged API endpoints.
class PagedEnvelope {
  final List<dynamic> data;
  final int page;
  final int pageSize;
  final int totalCount;
  PagedEnvelope({
    required this.data,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });
  bool get hasMore => page * pageSize < totalCount;
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
