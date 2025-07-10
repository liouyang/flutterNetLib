/// lib/network/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';

/// 认证拦截器
/// 用于在请求头中添加认证 Token。
class AuthInterceptor extends Interceptor {
  // 假设这里有一个方法可以获取用户的认证 Token
  String? _getAuthToken() {
    // 实际应用中，您会从 SharedPreferences, SecureStorage 或状态管理中获取 Token
    // 例如：return 'your_jwt_token_here';
    return null; // 暂时返回 null
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token'; // JWT 格式
      // 或者其他认证头，例如：
      // options.headers['X-Auth-Token'] = token;
    }
    handler.next(options); // 继续请求
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 如果是 401 未授权错误，可以尝试刷新 Token 或跳转登录页
    if (err.response?.statusCode == 401) {
      // 可以在这里添加刷新 Token 的逻辑
      // 例如：Router.push('/login');
      print('Token 无效或已过期，请重新登录');
    }
    super.onError(err, handler);
  }
}