/// lib/network/interceptors/loading_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart'; // 引入 Flutter UI 相关

// 假设我们有一个全局的 Overlay 或 SnackBar 来显示加载状态
// 这是一个简化示例，实际应用中会使用 OverlayEntry 或 Provider/Bloc 来管理
OverlayEntry? _loadingOverlay;

/// 加载拦截器
/// 用于在请求开始时显示加载指示器，在请求结束时隐藏。
class LoadingInterceptor extends Interceptor {
  BuildContext? _currentContext; // 存储当前显示的上下文

  LoadingInterceptor(this._currentContext); // 构造函数传入 context

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 如果当前有 context 并且没有显示加载，则显示加载指示器
    if (_currentContext != null && _loadingOverlay == null) {
      _showLoading(_currentContext!);
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _hideLoading(); // 隐藏加载指示器
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _hideLoading(); // 隐藏加载指示器
    super.onError(err, handler);
  }

  void _showLoading(BuildContext context) {
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
  }

  void _hideLoading() {
    _loadingOverlay?.remove();
    _loadingOverlay = null;
  }
}
