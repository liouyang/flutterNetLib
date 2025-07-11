// lib/core/comm/net/ErrorInterceptor.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test_new/core/comm/utils/LoggerUtil.dart';
import 'package:flutter_test_new/core/comm/utils/ToastUtil.dart';

import 'ApiException.dart'; // For kDebugMode and debugPrint

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Log.e('ErrorInterceptor: 捕获到 DioException，路径：${err.requestOptions.path}',
        tag: 'ErrorInterceptor', error: err);

    // 将 DioException 转换为 ApiException，并自动弹出 Toast
    final ApiException apiException = handleDioException(err, err.stackTrace);

    // >>>>>>>>>> 在这里弹出 Toast <<<<<<<<<<
    // 可以根据 ApiException 的 code 或 message 来决定 Toast 内容和类型
    // 默认显示错误类型 Toast
    ToastUtil.showError(message: apiException.message);
    super.onError(err, handler);
  }

  // 这个方法通常是静态的，以便在 DioClient 中直接调用
  static ApiException handleDioException(DioException error, StackTrace? stackTrace) {
    String message = '未知错误';
    int code = -1; // 默认错误码
    Log.e('ErrorInterceptor: 处理 DioException: ${error.type}',
        tag: 'ErrorInterceptor.handler', error: error, stackTrace: stackTrace);

    switch (error.type) {
      case DioExceptionType.cancel:
        message = "请求取消";
        code = -100;
        break;
      case DioExceptionType.connectionTimeout:
        message = "连接超时";
        code = -200;
        break;
      case DioExceptionType.sendTimeout:
        message = "发送超时";
        code = -300;
        break;
      case DioExceptionType.receiveTimeout:
        message = "接收超时";
        code = -400;
        break;
      case DioExceptionType.badResponse:
      // 服务器返回了错误的状态码 (4xx, 5xx)
        code = error.response?.statusCode ?? -500;
        try {
          // 尝试解析后端返回的错误信息
          if (error.response?.data != null) {
            // 假设后端错误响应也是 JSON 格式，可能包含 'message' 字段
            if (error.response!.data is Map<String, dynamic> &&
                error.response!.data.containsKey('message')) {
              message = error.response!.data['message'] as String;
            } else {
              // 尝试直接使用响应体作为错误消息
              message = error.response!.data.toString();
            }
          } else {
            message = "服务器错误：${error.response?.statusCode}";
          }
        } catch (e) {
          message = "服务器错误 (${error.response?.statusCode})，解析响应失败: $e";
        }
        break;
      case DioExceptionType.badCertificate:
        message = "证书验证失败";
        code = -600;
        break;
      case DioExceptionType.connectionError:
        message = "网络连接错误，请检查您的网络。";
        code = -700;
        break;
      case DioExceptionType.unknown:
      default:
      // 这包括了网络不可用、DNS解析失败等情况
        if (error.error is SocketException) {
          message = "网络连接不可用，请检查您的网络设置。";
          code = -800;
        } else if (error.error is HandshakeException) {
          message = "SSL握手失败，可能是证书问题或网络被劫持。";
          code = -900;
        } else {
          message = "未知网络错误，请稍后重试。";
          code = -999;
        }
        break;
    }
    return ApiException(message:message, code: code);
  }
}