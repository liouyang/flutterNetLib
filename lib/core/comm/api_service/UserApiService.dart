// lib/api/user_api.dart
import 'package:dio/dio.dart';

import '../bean/User.dart';
import '../net/ApiException.dart';
import '../net/DioClient.dart';
import '../net/Result.dart';
import '../utils/LoggerUtil.dart'; // 导入 Dio，因为需要使用 CancelToken

/// 用户相关的 API 服务
/// 负责封装所有与用户数据相关的网络请求。
class UserApiService {
  final DioClient _dioClient = DioClient(); // 获取 DioClient 单例实例

  /// 获取所有用户
  ///
  /// [cancelToken] 允许外部传入一个 CancelToken 来取消此请求。
  Future<Result<List<User>, ApiException>> getUsers({CancelToken? cancelToken}) async {
    Log.d('UserApiService: 准备发起获取所有用户的请求.', tag: 'UserApiService');
    final result = await _dioClient.get<List<User>>(
      '/users', // 假设后端 /users 接口返回用户列表
      cancelToken: cancelToken, // 将外部传入的 cancelToken 传递给 DioClient
      fromJsonT: (json) {
        if (json is List) {
          Log.d('UserApiService: 正在解析用户列表数据.', tag: 'UserApiService');
          return json.map((item) => User.fromJson(item as Map<String, dynamic>)).toList();
        }
        Log.w('UserApiService: 获取用户列表数据格式不符，非 List 类型，返回空列表。', tag: 'UserApiService');
        return []; // 如果 data 不是 List，返回空列表或者根据业务需求抛出异常
      },
    );
    Log.d('UserApiService: 获取所有用户请求完成.', tag: 'UserApiService');
    return result; // DioClient 已经处理了成功/失败的封装，直接返回 Result
  }

  /// 根据用户ID获取单个用户详情
  ///
  /// [userId] 用户的唯一标识符。
  /// [cancelToken] 允许外部传入一个 CancelToken 来取消此请求。
  Future<Result<User, ApiException>> getUserById(int userId, {CancelToken? cancelToken}) async {
    Log.d('UserApiService: 准备发起获取用户(ID: $userId)详情的请求.', tag: 'UserApiService');
    final result = await _dioClient.get<User>(
      '/users/$userId', // 假设后端 /users/{id} 接口返回单个用户详情
      cancelToken: cancelToken,
      fromJsonT: (json) {
        // json 应该是一个 Map<String, dynamic>
        if (json is Map<String, dynamic>) {
          Log.d('UserApiService: 正在解析用户(ID: $userId)详情数据.', tag: 'UserApiService');
          return User.fromJson(json);
        }
        // 如果这里期望单个用户对象，但得到其他类型，可以抛出解析错误
        Log.e('UserApiService: 获取用户(ID: $userId)详情数据格式不符，非 Map 类型.', tag: 'UserApiService', error: 'Unexpected JSON type: ${json.runtimeType}');
        throw FormatException('Unexpected JSON type for User: ${json.runtimeType}');
      },
    );
    Log.d('UserApiService: 获取用户(ID: $userId)详情请求完成.', tag: 'UserApiService');
    return result;
  }

  /// 创建新用户
  ///
  /// [name] 用户的姓名。
  /// [email] 用户的邮箱。
  /// [cancelToken] 允许外部传入一个 CancelToken 来取消此请求。
  Future<Result<User, ApiException>> createUser(String name, String email, {CancelToken? cancelToken}) async {
    Log.d('UserApiService: 准备发起创建新用户(姓名: $name, 邮箱: $email)的请求.', tag: 'UserApiService');
    final result = await _dioClient.post<User>(
      '/users', // 假设后端 /users 接口用于创建用户
      data: {'name': name, 'email': email}, // 请求体
      cancelToken: cancelToken,
      fromJsonT: (json) {
        if (json is Map<String, dynamic>) {
          Log.d('UserApiService: 正在解析创建用户响应数据.', tag: 'UserApiService');
          return User.fromJson(json);
        }
        Log.e('UserApiService: 创建用户响应数据格式不符，非 Map 类型.', tag: 'UserApiService', error: 'Unexpected JSON type: ${json.runtimeType}');
        throw FormatException('Unexpected JSON type for User creation response: ${json.runtimeType}');
      },
    );
    Log.d('UserApiService: 创建新用户请求完成.', tag: 'UserApiService');
    return result;
  }

  /// 更新用户
  ///
  /// [user] 包含更新后用户信息的 User 对象。
  /// [cancelToken] 允许外部传入一个 CancelToken 来取消此请求。
  Future<Result<User, ApiException>> updateUser(User user, {CancelToken? cancelToken}) async {
    Log.d('UserApiService: 准备发起更新用户(ID: ${user.id}, 姓名: ${user.name})的请求.', tag: 'UserApiService');
    final result = await _dioClient.put<User>(
      '/users/${user.id}', // 假设后端 /users/{id} 接口用于更新用户
      data: user.toJson(), // 将 User 对象转换为 JSON 发送
      cancelToken: cancelToken,
      fromJsonT: (json) {
        if (json is Map<String, dynamic>) {
          Log.d('UserApiService: 正在解析更新用户响应数据.', tag: 'UserApiService');
          return User.fromJson(json);
        }
        Log.e('UserApiService: 更新用户响应数据格式不符，非 Map 类型.', tag: 'UserApiService', error: 'Unexpected JSON type: ${json.runtimeType}');
        throw FormatException('Unexpected JSON type for User update response: ${json.runtimeType}');
      },
    );
    Log.d('UserApiService: 更新用户请求完成.', tag: 'UserApiService');
    return result;
  }

  /// 删除用户
  ///
  /// [userId] 待删除用户的ID。
  /// [cancelToken] 允许外部传入一个 CancelToken 来取消此请求。
  Future<Result<String, ApiException>> deleteUser(int userId, {CancelToken? cancelToken}) async {
    Log.d('UserApiService: 准备发起删除用户(ID: $userId)的请求.', tag: 'UserApiService');
    // 对于删除操作，后端可能只返回成功状态码，不返回具体数据，或者返回一个简单的消息字符串。
    // 这里我们假设它返回一个简单的字符串消息。
    final result = await _dioClient.delete<String>(
      '/users/$userId', // 假设后端 /users/{id} 接口用于删除用户
      cancelToken: cancelToken,
      fromJsonT: (json) {
        // 假设服务器成功时可能返回一个空对象 {} 或一个包含消息的 JSON
        if (json == null) {
          Log.d('UserApiService: 删除用户成功，服务器未返回数据.', tag: 'UserApiService');
          return '删除成功'; // 或者返回你认为合适的默认成功消息
        }
        // 如果服务器返回一个JSON对象，尝试解析其中的消息字段
        if (json is Map<String, dynamic> && json.containsKey('message')) {
          Log.d('UserApiService: 删除用户成功，消息：${json['message']}', tag: 'UserApiService');
          return json['message'].toString();
        }
        // 否则，直接将整个响应体转换为字符串（如果适用）
        Log.d('UserApiService: 删除用户成功，将响应数据转换为字符串.', tag: 'UserApiService');
        return json.toString();
      },
    );
    Log.d('UserApiService: 删除用户请求完成.', tag: 'UserApiService');
    return result;
  }

  /// 模拟一个会返回业务错误（非200业务码）的 API
  /// 用于测试 `ErrorInterceptor` 对业务错误的统一处理。
  Future<Result<String, ApiException>> simulateTokenInvalid({CancelToken? cancelToken}) async {
    Log.d('UserApiService: 准备发起模拟 Token 失效的请求.', tag: 'UserApiService');
    final result = await _dioClient.get<String>(
      '/simulate_token_invalid', // 假设此接口会返回非 200 的业务码，如 401
      cancelToken: cancelToken,
      fromJsonT: (json) => json.toString(), // 假设返回一个简单的消息字符串
    );
    Log.d('UserApiService: 模拟 Token 失效请求完成.', tag: 'UserApiService');
    return result;
  }
}