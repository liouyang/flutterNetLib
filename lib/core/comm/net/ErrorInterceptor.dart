import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test_new/core/comm/utils/LoggerUtil.dart';
import 'package:flutter_test_new/core/comm/utils/ToastUtil.dart';

import 'ApiException.dart';
import 'ApiCode.dart'; // <<<<<<<<<< 新增导入 ApiCode

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Log.e('ErrorInterceptor: 捕获到 DioException，路径：${err.requestOptions.path}',
        tag: 'ErrorInterceptor', error: err);

    // 将 DioException 转换为 ApiException
    final ApiException apiException = handleDioException(err, err.stackTrace);

    // >>>>>>>>>> 根据 ApiException 的 code 进行不同的操作 (包括弹出 Toast) <<<<<<<<<<
    _handleApiCodeOperations(apiException); // <<<<<<<<<< 调用新的处理方法

    super.onError(err, handler);
  }

  // 新增一个私有方法来处理不同 ApiCode 的操作，包括 Toast 提示
  void _handleApiCodeOperations(ApiException apiException) {
    String toastMessage = apiException.message; // 默认Toast消息

    switch (apiException.code) {

      case ApiCode.FORBIDDEN: // HTTP 403
        toastMessage = "您没有权限访问此资源。";
        break;
      case ApiCode.NOT_FOUND: // HTTP 404
        toastMessage = "请求的资源不存在。";
        break;
      case ApiCode.INTERNAL_SERVER_ERROR: // HTTP 500
      case ApiCode.SERVICE_UNAVAILABLE:   // HTTP 503
        toastMessage = "服务器开小差了，请稍后再试。";
        break;

    // <<<<<<<<<< 处理后端自定义业务错误码，例如 10001 (LOGIN_EXPIRED)
      case ApiCode.LOGIN_EXPIRED: // 业务码 10001
        toastMessage = "登录状态已失效，请重新登录。"; // 更明确的提示
        Log.i('ErrorInterceptor: 捕获到业务码 ${ApiCode.LOGIN_EXPIRED} 登录失效，执行登出逻辑。', tag: 'Auth');
        // 示例：清除Token (伪代码)
        // AuthManager.clearToken();
        // 示例：跳转到登录页
        // Navigator.of(ToastUtil.getGlobalContext()).pushAndRemoveUntil(
        //   MaterialPageRoute(builder: (context) => LoginPage()),
        //   (Route<dynamic> route) => false,
        // );
        break;


      case ApiCode.CONNECTION_TIMEOUT:
      case ApiCode.SEND_TIMEOUT:
      case ApiCode.RECEIVE_TIMEOUT:
        toastMessage = "网络连接超时，请稍后重试。";
        break;
      case ApiCode.NETWORK_UNAVAILABLE:
      case ApiCode.CONNECTION_ERROR: // Dio 5.x 的网络连接错误
        toastMessage = "网络连接不可用，请检查您的网络设置。";
        break;
      case ApiCode.SSL_HANDSHAKE_FAILED:
      case ApiCode.BAD_CERTIFICATE:
        toastMessage = "证书验证失败，请联系管理员。";
        break;
      case ApiCode.REQUEST_CANCELLED:
      // 请求取消通常不需要弹出Toast，或者可以给出轻量提示
        return; // 不弹Toast，直接返回
      case ApiCode.OTHER_UNKNOWN_NETWORK_ERROR:
        toastMessage = "发生未知网络错误，请稍后重试。";
        break;
      default:
      // 对于未特殊处理的错误码，使用 ApiException 的 message
        break;
    }

    // 统一弹出 Toast，使用处理后的消息
    ToastUtil.showToast(message: toastMessage);
  }


  // 这个方法通常是静态的，以便在 DioClient 中直接调用
  static ApiException handleDioException(DioException error, StackTrace? stackTrace) {
    String message = '未知错误';
    int code = ApiCode.UNKNOWN_ERROR; // <<<<<<<<<< 替换默认错误码
    Log.e('ErrorInterceptor: 处理 DioException: ${error.type}',
        tag: 'ErrorInterceptor.handler', error: error, stackTrace: stackTrace);

    switch (error.type) {
      case DioExceptionType.cancel:
        message = "请求取消";
        code = ApiCode.REQUEST_CANCELLED; // <<<<<<<<<< 替换硬编码
        break;
      case DioExceptionType.connectionTimeout:
        message = "连接超时";
        code = ApiCode.CONNECTION_TIMEOUT; // <<<<<<<<<< 替换硬编码
        break;
      case DioExceptionType.sendTimeout:
        message = "发送超时";
        code = ApiCode.SEND_TIMEOUT; // <<<<<<<<<< 替换硬编码
        break;
      case DioExceptionType.receiveTimeout:
        message = "接收超时";
        code = ApiCode.RECEIVE_TIMEOUT; // <<<<<<<<<< 替换硬编码
        break;
      case DioExceptionType.badResponse:
        final responseData = error.response?.data;
        if (responseData != null && responseData is Map<String, dynamic>) {
          if (responseData.containsKey('code') && responseData['code'] is int) {
            code = responseData['code'] as int;
          } else if (responseData.containsKey('code') && responseData['code'] is String) {
            try {
              code = int.parse(responseData['code'] as String);
            } catch (_) {
              Log.w('ErrorInterceptor: 后端 code 字段不是 int 类型或无法解析为 int。', tag: 'ErrorInterceptor.handler');
              code = error.response?.statusCode ?? ApiCode.UNKNOWN_ERROR;
            }
          } else {
            code = error.response?.statusCode ?? ApiCode.UNKNOWN_ERROR; // <<<<<<<<<< 替换硬编码
          }

          if (responseData.containsKey('message') && responseData['message'] is String) {
            message = responseData['message'] as String;
          } else if (responseData.containsKey('msg') && responseData['msg'] is String) {
            message = responseData['msg'] as String;
          } else {
            message = "服务器错误：${error.response?.statusCode}";
          }
        } else {
          code = error.response?.statusCode ?? ApiCode.UNKNOWN_ERROR; // <<<<<<<<<< 替换硬编码
          if (error.response?.data != null) {
            message = error.response!.data.toString();
          } else {
            message = "服务器错误：${error.response?.statusCode}";
          }
        }
        break;
      case DioExceptionType.badCertificate:
        message = "证书验证失败";
        code = ApiCode.BAD_CERTIFICATE; // <<<<<<<<<< 替换硬编码
        break;
      case DioExceptionType.connectionError: // Dio 5.x 引入的连接错误
        message = "网络连接错误，请检查您的网络。";
        code = ApiCode.CONNECTION_ERROR; // <<<<<<<<<< 替换硬编码
        break;
      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          message = "网络连接不可用，请检查您的网络设置。";
          code = ApiCode.NETWORK_UNAVAILABLE; // <<<<<<<<<< 替换硬编码
        } else if (error.error is HandshakeException) {
          message = "SSL握手失败，可能是证书问题或网络被劫持。";
          code = ApiCode.SSL_HANDSHAKE_FAILED; // <<<<<<<<<< 替换硬编码
        } else {
          message = "未知网络错误，请稍后重试。";
          code = ApiCode.OTHER_UNKNOWN_NETWORK_ERROR; // <<<<<<<<<< 替换硬编码
        }
        break;
    }
    return ApiException(message:message, code: code); // <<<<<<<<<< 增加 stackTrace 参数
  }
}