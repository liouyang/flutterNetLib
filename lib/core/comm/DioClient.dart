/// lib/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart'; // 日志打印
import 'package:flutter/foundation.dart'; // 用于判断是否是调试模式
import 'package:flutter/material.dart'; // 用于 LoadingInterceptor 的 BuildContext

import 'ApiException.dart';
import 'AuthInterceptor.dart';
import 'ErrorInterceptor.dart';
import 'LoadingInterceptor.dart';
import 'Result.dart';



/// DioClient 是一个单例类，用于配置和管理 Dio 实例，
/// 提供了统一的网络请求方法。
class DioClient {
  static final DioClient _instance = DioClient._internal();
  late Dio _dio;

  // 私有构造函数，保证单例
  DioClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.example.com', // 替换为您的 API 基础 URL
      connectTimeout: const Duration(seconds: 10), // 连接超时时间
      receiveTimeout: const Duration(seconds: 15), // 接收超时时间
      contentType: 'application/json; charset=utf-8', // 默认请求内容类型
    ));

    // 添加拦截器
    _dio.interceptors.addAll([
      AuthInterceptor(),    // 认证拦截器 (处理 Token)
      ErrorInterceptor(),   // 错误处理拦截器
      // LoadingInterceptor(null), // 可以在这里初始化 LoadingInterceptor，但需要传入 BuildContext
      // 更好的方式是在具体使用时动态传入 Context 或通过事件总线管理加载状态
    ]);

    // 在 Debug 模式下添加日志拦截器
    if (kDebugMode) {
      _dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ));
    }
  }

  /// 获取 DioClient 的单例实例
  factory DioClient() {
    return _instance;
  }

  /// 在需要时动态添加或移除 LoadingInterceptor
  /// 例如在特定的请求中需要显示加载动画
  void addLoadingInterceptor(BuildContext context) {
    // 避免重复添加
    if (!_dio.interceptors.any((i) => i is LoadingInterceptor)) {
      _dio.interceptors.add(LoadingInterceptor(context));
    }
  }

  void removeLoadingInterceptor() {
    _dio.interceptors.removeWhere((i) => i is LoadingInterceptor);
  }


  /// 执行 GET 请求
  /// [path] 请求路径
  /// [queryParameters] 查询参数
  /// [options] 请求选项
  /// [cancelToken] 取消令牌
  /// [onReceiveProgress] 接收进度回调
  Future<Result<T, ApiException>> get<T>(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return Success(response.data as T);
    } on DioException catch (e) {
      // DioException 已经被 ErrorInterceptor 处理并转换为 ApiException
      // 所以这里的 e.error 应该就是 ApiException
      return Failure(e.error as ApiException);
    } catch (e) {
      // 处理其他未知异常
      return Failure(ApiException(message: e.toString()));
    }
  }

  /// 执行 POST 请求
  /// [path] 请求路径
  /// [data] 请求体数据
  /// [queryParameters] 查询参数
  /// [options] 请求选项
  /// [cancelToken] 取消令牌
  /// [onSendProgress] 发送进度回调
  /// [onReceiveProgress] 接收进度回调
  Future<Result<T, ApiException>> post<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return Success(response.data as T);
    } on DioException catch (e) {
      return Failure(e.error as ApiException);
    } catch (e) {
      return Failure(ApiException(message: e.toString()));
    }
  }

  /// 执行 PUT 请求
  Future<Result<T, ApiException>> put<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return Success(response.data as T);
    } on DioException catch (e) {
      return Failure(e.error as ApiException);
    } catch (e) {
      return Failure(ApiException(message: e.toString()));
    }
  }

  /// 执行 DELETE 请求
  Future<Result<T, ApiException>> delete<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return Success(response.data as T);
    } on DioException catch (e) {
      return Failure(e.error as ApiException);
    } catch (e) {
      return Failure(ApiException(message: e.toString()));
    }
  }

  /// 执行文件上传
  /// [path] 上传路径
  /// [formData] 文件数据，使用 FormData 封装
  /// [options] 请求选项
  /// [cancelToken] 取消令牌
  /// [onSendProgress] 发送进度回调
  Future<Result<T, ApiException>> upload<T>(
      String path, {
        required FormData formData,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
      }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: formData,
        options: (options ?? Options()).copyWith(
          contentType: 'multipart/form-data', // 文件上传必须设置此类型
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
      return Success(response.data as T);
    } on DioException catch (e) {
      return Failure(e.error as ApiException);
    } catch (e) {
      return Failure(ApiException(message: e.toString()));
    }
  }
}