import 'dart:convert';
import 'package:noteswidgetapp/core/constants/app_constants.dart';
import 'package:dio/dio.dart';

class ExceptionHandler {
  static void handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        AppConstants.showToast("Connection timeout. Please try again.");
        break;

      case DioExceptionType.badCertificate:
        AppConstants.showToast("Security certificate error.");
        break;

      case DioExceptionType.badResponse:
        _handleResponseError(error.response);
        break;

      case DioExceptionType.cancel:
        // Request was cancelled, no need to show toast
        break;

      case DioExceptionType.connectionError:
        AppConstants.showToast("No internet connection. Please check your network.");
        break;

      case DioExceptionType.unknown:
        AppConstants.showToast("An unexpected error occurred. Please try again.");
        break;
    }
  }

  static void _handleResponseError(Response? response) {
    if (response == null) return;

    switch (response.statusCode) {
      case 400:
        AppConstants.showToast("Something went wrong ${_extractErrorMessage(response)}");
        break;

      case 401:
        AppConstants.showToast("unauthorized ${_extractErrorMessage(response)}");
        break;

      case 403:
        AppConstants.showToast("Forbidden: Access is denied.");
        break;

      case 404:
        AppConstants.showToast("Not Found: ${_extractErrorMessage(response)}");
        break;

      case 422:
        AppConstants.showToast("Validation Error: ${_extractErrorMessage(response)}");
        break;

      case 500:
      case 503:
        AppConstants.showToast("Server Error: Please try again later.");
        break;

      default:
        AppConstants.showToast("Unexpected error: ${response.statusCode}");
    }
  }

  static String _extractErrorMessage(Response response) {
    try {
      final decoded = response.data is String ? jsonDecode(response.data) : response.data;
      if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'];
      }
      if (decoded is Map && decoded.containsKey('error')) {
        return decoded['error'];
      }
    } catch (_) {}
    return 'No additional information';
  }

  static bool isSuccessResponse(Response response) {
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
