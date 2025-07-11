// lib/network/interceptors/loading_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../utils/LoggerUtil.dart'; // 导入这个用于 addPostFrameCallback

// 导入你的 LoggerUtil，确保路径正确

OverlayEntry? _loadingOverlay;
BuildContext? _currentGlobalContext; // 全局上下文引用，需要外部传入

/// 设置全局上下文，在 MaterialApp 的 builder 中传入
/// 注意：确保只在 MaterialApp 的 builder 中调用一次，且该 context 稳定
void setGlobalContext(BuildContext context) {
  if (_currentGlobalContext == null || _currentGlobalContext != context) {
    _currentGlobalContext = context;
    Log.d('LoadingInterceptor: 全局 Context 已设置/更新。', tag: 'LoadingInterceptor');
  }
}

/// 加载拦截器
/// 用于在请求开始时显示加载指示器，在请求结束时隐藏。
class LoadingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Log.d('LoadingInterceptor: 收到请求：${options.path}', tag: 'LoadingInterceptor');

    // 确保上下文有效且已挂载，并且当前没有加载框显示
    if (_currentGlobalContext != null && _currentGlobalContext!.mounted && _loadingOverlay == null) {
      // 使用 addPostFrameCallback 确保在当前帧绘制完成后再显示 Overlay
      // 避免在 Dio 拦截器链中同步操作 UI 导致的潜在问题
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // 在回调中再次检查 context 的有效性，以防万一
        if (_currentGlobalContext != null && _currentGlobalContext!.mounted && _loadingOverlay == null) {
          _showLoading(_currentGlobalContext!);
        } else {
          Log.w('LoadingInterceptor: 尝试显示加载时，条件不满足。_currentGlobalContext=${_currentGlobalContext != null}, mounted=${_currentGlobalContext?.mounted}, _loadingOverlay=${_loadingOverlay != null}', tag: 'LoadingInterceptor');
        }
      });
    } else {
      Log.w('LoadingInterceptor: 不显示加载指示器。_currentGlobalContext=${_currentGlobalContext != null}, mounted=${_currentGlobalContext?.mounted}, _loadingOverlay=${_loadingOverlay != null}', tag: 'LoadingInterceptor');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    Log.d('LoadingInterceptor: 收到响应：${response.requestOptions.path}', tag: 'LoadingInterceptor');
    // 使用 addPostFrameCallback 确保在当前帧绘制完成后再隐藏 Overlay
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _hideLoading(); // 隐藏加载指示器
    });
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Log.e('LoadingInterceptor: 请求出错：${err.requestOptions.path}，错误类型：${err.type}', tag: 'LoadingInterceptor', error: err);
    // 使用 addPostFrameCallback 确保在当前帧绘制完成后再隐藏 Overlay
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _hideLoading(); // 隐藏加载指示器
    });
    super.onError(err, handler);
  }

  void _showLoading(BuildContext context) {
    // 再次确认 overlay 不存在，防止重复插入
    if (_loadingOverlay != null) {
      Log.w('LoadingInterceptor: _showLoading 尝试显示时，_loadingOverlay 已存在，跳过。', tag: 'LoadingInterceptor');
      return;
    }
    try {
      _loadingOverlay = OverlayEntry(
        builder: (context) => Container(
          color: Colors.black54, // 半透明背景
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_loadingOverlay!);
      Log.i('LoadingInterceptor: 加载指示器已显示。', tag: 'LoadingInterceptor');
    } catch (e, st) {
      Log.e('LoadingInterceptor: 显示加载指示器时发生错误！', tag: 'LoadingInterceptor', error: e, stackTrace: st);
      // 如果插入失败，确保将 _loadingOverlay 置为 null，以免下次请求时误判
      _loadingOverlay = null;
    }
  }

  void _hideLoading() {
    if (_loadingOverlay != null) {
      try {
        _loadingOverlay!.remove();
        _loadingOverlay = null;
        Log.i('LoadingInterceptor: 加载指示器已隐藏。', tag: 'LoadingInterceptor');
      } catch (e, st) {
        Log.e('LoadingInterceptor: 隐藏加载指示器时发生错误！', tag: 'LoadingInterceptor', error: e, stackTrace: st);
        _loadingOverlay = null; // 确保置为 null，防止未来操作无效的 overlay
      }
    } else {
      Log.w('LoadingInterceptor: _hideLoading 尝试隐藏时，_loadingOverlay 为空，跳过。', tag: 'LoadingInterceptor');
    }
  }
}