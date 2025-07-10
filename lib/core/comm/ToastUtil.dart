/// lib/utils/toast_util.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Toast 消息工具类。
/// 封装了 Fluttertoast，用于统一 Toast 样式和简化使用。
class ToastUtil {
  // 私有构造函数，防止外部实例化
  ToastUtil._();

  /// 显示一个通用的 Toast 消息。
  ///
  /// [message] 要显示的消息文本。
  /// [gravity] Toast 的位置。默认为 [ToastGravity.BOTTOM]。
  /// [toastLength] Toast 的显示时长。默认为 [Toast.LENGTH_SHORT]。
  /// [backgroundColor] Toast 的背景颜色。默认为半透明黑色。
  /// [textColor] Toast 消息文本的颜色。默认为白色。
  /// [fontSize] Toast 消息文本的字体大小。默认为 16.0。
  static Future<bool?> showToast({
    required String message,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Toast toastLength = Toast.LENGTH_SHORT,
    Color backgroundColor = Colors.black54,
    Color textColor = Colors.white,
    double fontSize = 16.0,
  }) {
    return Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      // iOS 和 Web 的时长需要单独设置，这里根据 Android 的 short/long 做了个简单映射
      timeInSecForIosWeb: toastLength == Toast.LENGTH_SHORT ? 1 : 3,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: fontSize,
    );
  }

  /// 显示一个成功的 Toast 消息（例如，绿色背景）。
  static Future<bool?> showSuccess({
    required String message,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Toast toastLength = Toast.LENGTH_SHORT,
  }) {
    return showToast(
      message: message,
      gravity: gravity,
      toastLength: toastLength,
      backgroundColor: Colors.green.shade600, // 成功消息的绿色
      textColor: Colors.white,
    );
  }

  /// 显示一个错误的 Toast 消息（例如，红色背景）。
  static Future<bool?> showError({
    required String message,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Toast toastLength = Toast.LENGTH_LONG, // 错误消息通常需要更长的显示时间
  }) {
    return showToast(
      message: message,
      gravity: gravity,
      toastLength: toastLength,
      backgroundColor: Colors.red.shade600, // 错误消息的红色
      textColor: Colors.white,
    );
  }

  /// 显示一个警告的 Toast 消息（例如，橙色背景）。
  static Future<bool?> showWarning({
    required String message,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Toast toastLength = Toast.LENGTH_SHORT,
  }) {
    return showToast(
      message: message,
      gravity: gravity,
      toastLength: toastLength,
      backgroundColor: Colors.orange.shade600, // 警告消息的橙色
      textColor: Colors.white,
    );
  }

  /// 立即取消并隐藏当前正在显示的 Toast。
  static Future<void> cancel() async {
    await Fluttertoast.cancel();
  }
}