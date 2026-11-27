import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:lab11/core/error/exceptions.dart';

/// Единый HTTP-клиент. Знает базовый URL, таймауты и превращает
/// ошибки Dio в исключения Data Layer (NetworkException, ServerException…).
class RestClient {
  RestClient({HttpClientAdapter? adapter})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          responseType: ResponseType.json,
          headers: {'Accept': 'application/json', 'X-Client': 'TaskFlow'},
        ),
      ) {
    if (adapter != null) _dio.httpClientAdapter = adapter; // для тестов
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(responseBody: false, logPrint: (o) => debugPrint('$o')),
      );
    }
  }

  static const baseUrl = 'https://jsonplaceholder.typicode.com';

  final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: query);
      return response.data;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  static DataException _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(e.message);
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code == 401) return UnauthorizedException('HTTP 401');
        if (code == 404) return NotFoundException('HTTP 404');
        if (code >= 500) return ServerException(code, 'HTTP $code');
        return BadRequestException('HTTP $code');
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        if (e.error is FormatException) return ParseException('${e.error}');
        return NetworkException('${e.type}: ${e.message}');
    }
  }
}
