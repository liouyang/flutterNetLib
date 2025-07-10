/// lib/network/interceptors/error_interceptor.dart
import 'package:dio/dio.dart';

import 'ApiException.dart';

/// 错误拦截器
/// 统一处理 Dio 请求过程中发生的各种错误，并转化为自定义的 ApiException。
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage = '未知错误';
    int? errorCode;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = '连接超时，请检查网络或稍后重试。';
        errorCode = 10001;
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = '请求发送超时。';
        errorCode = 10002;
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = '响应接收超时。';
        errorCode = 10003;
        break;
      case DioExceptionType.badResponse: // 4xx, 5xx 状态码
        errorCode = err.response?.statusCode;
        switch (errorCode) {
          case 400:
            errorMessage = '请求参数错误。';
            break;
          case 401:
            errorMessage = '未授权，请重新登录。';
            // 可以在这里触发重新登录逻辑
            break;
          case 403:
            errorMessage = '禁止访问。';
            break;
          case 404:
            errorMessage = '请求的资源不存在。';
            break;
          case 405:
            errorMessage = '请求方法不允许。';
            break;
          case 408:
            errorMessage = '请求超时。';
            break;
          case 500:
            errorMessage = '服务器内部错误。';
            break;
          case 502:
            errorMessage = '网关错误。';
            break;
          case 503:
            errorMessage = '服务不可用。';
            break;
          case 504:
            errorMessage = '网关超时。';
            break;
          default:
            errorMessage = err.response?.statusMessage ?? '服务器错误。';
            break;
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = '请求已取消。';
        errorCode = 10004;
        break;
      case DioExceptionType.badCertificate:
        errorMessage = 'SSL证书验证失败。';
        errorCode = 10005;
        break;
      case DioExceptionType.connectionError:
        errorMessage = '网络连接错误，请检查您的网络。';
        errorCode = 10006;
        break;
      case DioExceptionType.unknown:
        if (err.error is ApiException) { // 如果已经是 ApiException，直接传递
          handler.next(err);
          return;
        }
        errorMessage = err.message ?? '未知网络错误。';
        break;
    }
    // 将 DioException 转换为自定义的 ApiException
    handler.next(DioException(
      requestOptions: err.requestOptions,
      error: ApiException(message: errorMessage, code: errorCode),
      response: err.response,
      type: err.type,
      message: errorMessage,
    ));
  }
}