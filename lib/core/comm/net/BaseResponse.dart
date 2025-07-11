// lib/network/base_response.dart
class BaseResponse<T> {
  final int code;
  final String message;
  final T? data; // data 可能是泛型类型 T

  BaseResponse({required this.code, required this.message, this.data});

  factory BaseResponse.fromJson(Map<String, dynamic> json, T Function(Object? json)? fromJsonT) {
    return BaseResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      data: fromJsonT != null && json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}