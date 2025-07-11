// lib/core/comm/net/ApiCode.dart

/// 应用程序中使用的 API 错误码定义。
/// 包含了 Dio 异常类型映射、HTTP 状态码以及可能的自定义业务码。
class ApiCode {
  // --- 通用/默认错误 ---
  static const int UNKNOWN_ERROR = -1; // 默认未知错误码

  // --- DioExceptionType 映射的网络错误码 ---
  static const int REQUEST_CANCELLED = -100; // 请求取消
  static const int CONNECTION_TIMEOUT = -200; // 连接超时
  static const int SEND_TIMEOUT = -300;     // 发送数据超时
  static const int RECEIVE_TIMEOUT = -400;   // 接收数据超时
  static const int BAD_CERTIFICATE = -600;   // 证书验证失败
  static const int CONNECTION_ERROR = -700;  // 网络连接错误 (Dio 5.x 引入，表示底层连接失败)

  // --- 基于 DioExceptionType.unknown 且 error 详细类型的网络错误 ---
  static const int NETWORK_UNAVAILABLE = -800; // 网络连接不可用 (例如：设备未连接网络)
  static const int SSL_HANDSHAKE_FAILED = -900; // SSL/TLS 握手失败 (可能是证书不受信任、网络劫持等)
  static const int OTHER_UNKNOWN_NETWORK_ERROR = -999; // 其他未知网络错误

  // --- HTTP 状态码 (来自 DioExceptionType.badResponse，当后端没有提供业务码时回退使用) ---
  // 注意：这些是标准的 HTTP 状态码，可能与你的后端返回的业务码重合。
  // 在 handleDioException 中，会优先尝试解析后端返回的业务码。
  static const int BAD_REQUEST = 400;             // 客户端请求语法错误，服务器无法理解
  static const int UNAUTHORIZED = 401;            // 未授权：请求需要用户身份验证，或身份验证失败
  static const int FORBIDDEN = 403;               // 禁止访问：服务器理解请求，但拒绝执行（权限不足）
  static const int NOT_FOUND = 404;               // 未找到：服务器找不到请求的资源
  static const int METHOD_NOT_ALLOWED = 405;      // 方法不允许：请求方法不被允许
  static const int CONFLICT = 409;                // 冲突：请求与服务器当前状态冲突（如资源重复）
  static const int TOO_MANY_REQUESTS = 429;       // 请求过多：客户端在给定时间内发送了太多请求

  static const int INTERNAL_SERVER_ERROR = 500;   // 服务器内部错误
  static const int BAD_GATEWAY = 502;             // 错误网关：网关或代理服务器从上游服务器收到无效响应
  static const int SERVICE_UNAVAILABLE = 503;     // 服务不可用：服务器暂时无法处理请求（如过载或维护）
  static const int GATEWAY_TIMEOUT = 504;         // 网关超时：网关或代理服务器未能及时从上游服务器收到响应

  // --- 自定义业务错误码 (根据你的后端 API 文档定义) ---
  // 这些是后端 API 返回的特定业务逻辑错误码。
  // 在 `handleDioException` 中，如果 `responseData` 包含 `code` 字段，
  // 且其值为这些常量之一，则会优先使用它们。
  static const int LOGIN_EXPIRED = 10001;         // 示例：登录失效 (根据你之前提到的后端返回)
// static const int USER_NOT_FOUND = 10002;     // 示例：用户不存在
// static const int INVALID_PARAMS = 10003;     // 示例：参数无效
// ... 根据你的后端 API 文档添加更多业务错误码，建议使用注释说明其含义
}