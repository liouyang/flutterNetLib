/// lib/network/api_exception.dart
///
/// 自定义网络请求异常类，用于封装不同类型的网络错误。
class ApiException implements Exception {
  final String message; // 错误信息
  final int? code; // 错误码 (可选，根据后端约定)

  ApiException({required this.message, this.code});

  @override
  String toString() {
    if (code != null) {
      return 'ApiException: [Code: $code] $message';
    }
    return 'ApiException: $message';
  }
}