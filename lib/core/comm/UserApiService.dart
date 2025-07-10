import 'ApiException.dart';
import 'DioClient.dart';
import 'Result.dart';

/// lib/api/user_api.dart

// 假设我们有一个用户模型
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

/// 用户相关的 API 服务
class UserApiService {
  final DioClient _dioClient = DioClient();

  /// 获取所有用户
  Future<Result<List<User>, ApiException>> getUsers() async {
    final result = await _dioClient.get('/users');
    return result.when(
      success: (data) {
        // 假设返回的数据是 List<Map<String, dynamic>>
        final users = (data as List).map((json) => User.fromJson(json)).toList();
        return Success(users);
      },
      failure: (error) => Failure(error),
    );
  }

  /// 获取单个用户详情
  Future<Result<User, ApiException>> getUserById(int userId) async {
    final result = await _dioClient.get('/users/$userId');
    return result.when(
      success: (data) => Success(User.fromJson(data as Map<String, dynamic>)),
      failure: (error) => Failure(error),
    );
  }

  /// 创建新用户
  Future<Result<User, ApiException>> createUser(String name, String email) async {
    final result = await _dioClient.post(
      '/users',
      data: {'name': name, 'email': email},
    );
    return result.when(
      success: (data) => Success(User.fromJson(data as Map<String, dynamic>)),
      failure: (error) => Failure(error),
    );
  }

}