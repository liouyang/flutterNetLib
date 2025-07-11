/// lib/network/dio_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter/foundation.dart'; // 用于判断是否是调试模式

import '../utils/LoggerUtil.dart';
import 'ApiException.dart';
import 'AuthInterceptor.dart';
import 'BaseResponse.dart';
import 'DioClientInitializer.dart';
import 'ErrorInterceptor.dart';
import 'LoadingInterceptor.dart';
import 'Result.dart';

/// DioClient 是一个单例类，用于配置和管理 Dio 实例，
/// 提供了统一的网络请求方法。
class DioClient {
  static final DioClient _instance = DioClient._internal();
  late Dio _dio;
  static SecurityContext? _globalSecurityContext;
  // 使用 Completer 来管理异步加载的 SecurityContext
  static Completer<SecurityContext>? _securityContextCompleter;

  DioClient._internal() {
    Log.d('正在初始化 Dio 客户端。', tag: 'DioClient'); // 中文日志
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://jsonplaceholder.typicode.com', // **替换为您的 API 基础 URL**
        connectTimeout: const Duration(seconds: 10), // 连接超时时间
        receiveTimeout: const Duration(seconds: 15), // 接收超时时间
        contentType: 'application/json; charset=utf-8', // 默认请求内容类型
      ),
    );
    // ===============================================================
    // >>>>>>>>>> 配置 SSL/TLS - 信任自定义根证书 <<<<<<<<<<
    // ===============================================================
    (_dio.httpClientAdapter as IOHttpClientAdapter)
        .onHttpClientCreate = (HttpClient client) {
      // 从辅助类中同步获取已经初始化好的 SecurityContext
      // // 我们在 main 函数中 await 了初始化过程，所以这里是安全的。
      // final SecurityContext clientSecurityContext =
      //     DioClientInitializer.getInitializedSecurityContext(); // <<<<<<<<<<< 新增/修改点
      //
      // // 创建一个新的 HttpClient 实例，并传入我们自定义的 SecurityContext
      // HttpClient newClient = HttpClient(
      //   context: clientSecurityContext,
      // ); // <<<<<<<<<<< 修改点
      //
      // // (可选) 配置 badCertificateCallback，作用于 newClient
      // newClient
      //     .badCertificateCallback = (X509Certificate cert, String host, int port) {
      //   Log.w(
      //     'HTTPS: badCertificateCallback 触发 for host: $host. 证书主题: ${cert.subject}',
      //     tag: 'DioClientCert',
      //   );
      //   return false; // 默认不信任任何额外的“不合格”证书
      // };
      client
          .badCertificateCallback = (X509Certificate cert, String host, int port) {
        Log.w(
          'HTTPS: badCertificateCallback 触发 for host: $host. 证书主题: ${cert.subject}',
          tag: 'DioClientCert',
        );
        return true; // 默认不信任任何额外的“不合格”证书
      };
      return client;
    };
    // ===============================================================
    // >>>>>>>>>> 配置 SSL/TLS 结束 <<<<<<<<<<
    // ===============================================================

    // 添加拦截器，顺序很重要！
    // 1. AuthInterceptor: 处理认证信息 (如添加 Token)
    // 2. ErrorInterceptor: 统一处理所有 DioException (包括 DioClient 内部抛出的)
    // 3. LoadingInterceptor: 用于显示/隐藏加载状态
    _dio.interceptors.addAll([AuthInterceptor(), ErrorInterceptor()]);

    // 在 Debug 模式下添加日志拦截器
    if (kDebugMode) {
      Log.d('已添加 PrettyDioLogger 拦截器。', tag: 'DioClient'); // 中文日志
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
    Log.d('Dio 客户端初始化完成。', tag: 'DioClient'); // 中文日志
  }

  /// 获取 DioClient 的单例实例
  factory DioClient() {
    return _instance;
  }

  // --- 通用请求方法 ---

  /// 内部辅助函数：处理 Dio 原始响应并转换为 Result
  /// 这里负责解析 BaseResponse 并检查业务码
  Future<Result<T, ApiException>> _handleResponse<T>(
    Response<Map<String, dynamic>> response,
    T Function(Object? json) fromJsonT,
  ) async {
    Log.d('收到 ${response.requestOptions.path} 的响应', tag: 'DioClient'); // 中文日志
    // 确保响应数据不为空
    if (response.data == null) {
      Log.w('响应数据为空：${response.requestOptions.path}', tag: 'DioClient'); // 中文日志
      return Failure(
        ApiException(
          message: response.statusMessage ?? '服务器返回数据为空。',
          code: response.statusCode,
        ),
      );
    }

    try {
      final baseResponse = BaseResponse.fromJson(response.data!, fromJsonT);
      Log.d(
        '已解析 BaseResponse，路径：${response.requestOptions.path}，业务码：${baseResponse.code}，消息：${baseResponse.message}',
        tag: 'DioClient',
      ); // 中文日志

      // <<< 核心修改：在这里检查业务码！
      if (baseResponse.code != 200) {
        Log.w(
          '检测到业务错误，路径：${response.requestOptions.path}，业务码：${baseResponse.code}，消息：${baseResponse.message}',
          tag: 'DioClient',
        ); // 中文日志
        // 如果业务码不是 200，主动抛出一个 DioException
        // 这个 DioException 会被 ErrorInterceptor 捕获并转换为 ApiException
        throw DioException(
          requestOptions: response.requestOptions,
          type: DioExceptionType.badResponse, // 标记为响应错误类型
          response: response, // 传入原始响应
          error: ApiException(
            message: baseResponse.message,
            code: baseResponse.code,
          ),
          message: baseResponse.message, // DioException 的 message
        );
      }

      // 业务码为 200，表示业务成功
      if (baseResponse.data != null) {
        Log.d(
          '请求成功并包含数据，路径：${response.requestOptions.path}',
          tag: 'DioClient',
        ); // 中文日志
        return Success(baseResponse.data as T);
      } else {
        // 业务成功但 data 为 null 的情况。
        // 根据 T 是否可空来决定返回成功 (null) 还是失败。
        if (null is T) {
          Log.i(
            '请求成功，但数据为空且类型可空，路径：${response.requestOptions.path}',
            tag: 'DioClient',
          ); // 中文日志
          return Success(null as T); // 安全地返回 null
        } else {
          Log.w(
            '请求成功，但非空数据为空，路径：${response.requestOptions.path}',
            tag: 'DioClient',
          ); // 中文日志
          // 如果 T 是非空类型，但 data 为 null，视为业务逻辑上的不完整或错误
          return Failure(
            ApiException(
              message: baseResponse.message.isNotEmpty
                  ? baseResponse.message
                  : '操作成功但未返回数据，且数据类型为非空。',
              code: baseResponse.code, // 仍然使用业务成功码 200，但提示数据缺失
            ),
          );
        }
      }
    } on TypeError catch (e, st) {
      Log.e(
        '响应解析时发生类型错误，路径：${response.requestOptions.path}',
        tag: 'DioClient',
        error: e,
        stackTrace: st,
      ); // 中文日志
      // JSON 解析失败或数据模型转换失败
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
        error: ApiException(message: '服务器返回数据格式或类型不正确: $e', code: 9996),
        message: '数据解析失败',
      );
    } catch (e, st) {
      Log.e(
        '处理服务器响应时发生未知错误，路径：${response.requestOptions.path}',
        tag: 'DioClient',
        error: e,
        stackTrace: st,
      ); // 中文日志
      // 其他未知异常
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.unknown,
        response: response,
        error: ApiException(message: '处理服务器响应时发生未知错误: $e', code: 9997),
        message: '响应处理异常',
      );
    }
  }

  /// 执行 GET 请求
  Future<Result<T, ApiException>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    required T Function(Object? json) fromJsonT, // 必须提供解析 data 的函数
  }) async {
    Log.d('发起 GET 请求到：$path', tag: 'DioClient'); // 中文日志
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      // 调用内部处理函数
      return await _handleResponse<T>(response, fromJsonT);
      // Log.d('DioClient: 请求成功并包含数据，路径：$path', tag: 'DioClient');
      //
      // final parsedData = fromJsonT(response.data);
      // return Success(parsedData);
    } on DioException catch (e, st) {
      Log.e(
        '捕获到 GET 请求的 DioException，路径：$path，消息：${e.message}',
        tag: 'DioClient',
        error: e,
        stackTrace: st,
      ); // 中文日志
      // 所有的 DioException 都会在这里被捕获。
      // 它们都已经被 ErrorInterceptor 转换成了 ApiException。
      return Failure(e.error as ApiException);
    } catch (e, st) {
      Log.e(
        '捕获到 GET 请求的通用错误，路径：$path，错误：$e',
        tag: 'DioClient',
        error: e,
        stackTrace: st,
      ); // 中文日志
      // 捕获 _handleResponse 中抛出的非 DioException 异常
      return Failure(ApiException(message: e.toString()));
    }
  }

  /// 执行 POST 请求
  Future<Result<T, ApiException>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    required T Function(Object? json) fromJsonT,
  }) async {
    Log.d('发起 POST 请求到：$path', tag: 'DioClient'); // 中文日志
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return await _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e, st) {
      Log.e(
        '捕获到 POST 请求的 DioException，路径：$path，消息：${e.message}',
        tag: 'DioClient',
        error: e,
        stackTrace: st,
      ); // 中文日志
      return Failure(e.error as ApiException);
    } catch (e, st) {
      Log.e(
        '捕获到 POST 请求的通用错误，路径：$path，错误：$e',
        tag: 'DioClient',
        error: e,
        stackTrace: st,
      ); // 中文日志
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
    required T Function(Object? json) fromJsonT,
  }) async {
    Log.d('发起 PUT 请求到：$path', tag: 'DioClient'); // 中文日志
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return await _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e, st) {
      Log.e(
        '捕获到 PUT 请求的 DioException，路径：$path，消息：${e.message}',
        tag: 'DioClient',
        error: e,
        stackTrace: st,
      ); // 中文日志
      return Failure(e.error as ApiException);
    } catch (e, st) {
      Log.e(
        '捕获到 PUT 请求的通用错误，路径：$path，错误：$e',
        tag: 'DioClient',
        error: e,
        stackTrace: st,
      ); // 中文日志
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
    required T Function(Object? json) fromJsonT,
  }) async {
    Log.d('发起 DELETE 请求到：$path', tag: 'DioClient'); // 中文日志
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return await _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e, st) {
      Log.e(
        '捕获到 DELETE 请求的 DioException，路径：$path，消息：${e.message}',
        tag: 'DioClient',
        error: e,
        stackTrace: st,
      ); // 中文日志
      return Failure(e.error as ApiException);
    } catch (e, st) {
      Log.e(
        '捕获到 DELETE 请求的通用错误，路径：$path，错误：$e',
        tag: 'DioClient',
        error: e,
        stackTrace: st,
      ); // 中文日志
      return Failure(ApiException(message: e.toString()));
    }
  }

  /// 执行文件上传
  Future<Result<T, ApiException>> upload<T>(
    String path, {
    required FormData formData,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    required T Function(Object? json) fromJsonT,
  }) async {
    Log.d('发起 UPLOAD (文件上传) 请求到：$path', tag: 'DioClient'); // 中文日志
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        options: (options ?? Options()).copyWith(
          contentType: 'multipart/form-data',
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
      return await _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e, st) {
      Log.e(
        '捕获到 UPLOAD 请求的 DioException，路径：$path，消息：${e.message}',
        tag: 'DioClient',
        error: e,
        stackTrace: st,
      ); // 中文日志
      return Failure(e.error as ApiException);
    } catch (e, st) {
      Log.e(
        '捕获到 UPLOAD 请求的通用错误，路径：$path，错误：$e',
        tag: 'DioClient',
        error: e,
        stackTrace: st,
      ); // 中文日志
      return Failure(ApiException(message: e.toString()));
    }
  }
}
