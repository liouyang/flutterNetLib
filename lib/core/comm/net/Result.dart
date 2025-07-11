/// lib/network/result.dart
///
/// 统一结果封装，用于表示操作的成功或失败。
/// [S] 表示成功时的数据类型。
/// [F] 表示失败时的数据类型（通常是 ApiException）。
abstract class Result<S, F> {
  const Result();

  T when<T>({
    required T Function(S value) success,
    required T Function(F exception) failure,
  });
}

/// 成功的结果。
final class Success<S, F> extends Result<S, F> {
  const Success(this.value);
  final S value; // 成功时携带的数据

  @override
  T when<T>({
    required T Function(S value) success,
    required T Function(F exception) failure,
  }) {
    return success(value); // 成功时调用 success 回调
  }
}

/// 失败的结果。
final class Failure<S, F> extends Result<S, F> {
  const Failure(this.exception);
  final F exception; // 失败时携带的异常信息

  @override
  T when<T>({
    required T Function(S value) success,
    required T Function(F exception) failure,
  }) {
    return failure(exception); // 失败时调用 failure 回调
  }
}