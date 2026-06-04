import 'package:dio/dio.dart';

import '../core/constants/app_constants.dart';
import 'exception_handler.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      responseType: ResponseType.json,
    ),
  );

  Future<Response?> getRequestResponse(String url, {bool applyAuth = false}) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: applyAuth
              ? {
                  'Authorization': 'Bearer ${AppConstants.authToken}',
                }
              : {},
        ),
      );
      return response;
    } on DioException catch (e) {
      ExceptionHandler.handleDioError(e);
      return null;
    }
  }

  Future<Response?> getRequestResponseWithParams(
    String url, {
    Map<String, dynamic>? queryParams,
    bool applyAuth = false,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParams,
        options: Options(
          headers: applyAuth
              ? {
                  'Authorization': 'Bearer ${AppConstants.authToken}',
                }
              : {},
        ),
      );
      return response;
    } on DioException catch (e) {
      ExceptionHandler.handleDioError(e);
      return null;
    }
  }

  Future<Response?> postRequestResponse(
    String url, {
    Map<String, dynamic>? body,
    bool applyAuth = false,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: applyAuth
              ? {
                  'Authorization': 'Bearer ${AppConstants.authToken}',
                  'Content-Type': 'application/json',
                }
              : {
                  'Content-Type': 'application/json',
                },
        ),
      );
      return response;
    } on DioException catch (e) {
      ExceptionHandler.handleDioError(e);
      return null;
    }
  }

  static bool handleResponseStatus(Response response) {
    return ExceptionHandler.isSuccessResponse(response);
  }
}
