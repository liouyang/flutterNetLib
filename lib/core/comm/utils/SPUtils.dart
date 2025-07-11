/// lib/utils/sp_util.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart'; // 用于 JSON 编解码

/// SharedPreferences 工具类。
/// 采用单例模式，确保 SharedPreferences 实例只被初始化一次。
class SpUtil {
  // 私有静态实例，用于实现单例
  static final SpUtil _instance = SpUtil._internal();
  // SharedPreferences 实例
  static SharedPreferences? _prefs;

  // 私有构造函数，阻止外部直接实例化
  SpUtil._internal();

  /// 获取 SpUtil 的单例实例。
  /// 请确保在调用此方法之前已通过 [SpUtil.init()] 完成初始化。
  factory SpUtil() {
    return _instance;
  }

  /// 初始化 SharedPreferences 实例。
  /// 这是一个异步操作，**必须在应用程序启动时（例如 main 函数中）调用一次**，
  /// 确保在使用 SpUtil 之前已准备好。
  ///
  /// 示例：`await SpUtil.init();`
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    // print('SharedPreferences 初始化成功！'); // 可以在调试模式下打印
  }

  /// 内部方法：获取 SharedPreferences 实例，未初始化则抛出异常。
  SharedPreferences _getPrefs() {
    if (_prefs == null) {
      // 在生产环境中，此异常应被捕获并妥善处理（例如，崩溃上报），
      // 因为这意味着 SpUtil.init() 未被正确调用。
      throw Exception('SpUtil 尚未初始化。请在应用启动时调用 SpUtil.init()。');
    }
    return _prefs!;
  }

  // --- 核心存取方法 ---

  /// 存储布尔值。
  Future<bool> setBool(String key, bool value) => _getPrefs().setBool(key, value);

  /// 获取布尔值。
  /// [defaultValue] 当键不存在或类型不匹配时返回。
  bool getBool(String key, {bool defaultValue = false}) => _getPrefs().getBool(key) ?? defaultValue;

  /// 存储整数。
  Future<bool> setInt(String key, int value) => _getPrefs().setInt(key, value);

  /// 获取整数。
  int getInt(String key, {int defaultValue = 0}) => _getPrefs().getInt(key) ?? defaultValue;

  /// 存储双精度浮点数。
  Future<bool> setDouble(String key, double value) => _getPrefs().setDouble(key, value);

  /// 获取双精度浮点数。
  double getDouble(String key, {double defaultValue = 0.0}) => _getPrefs().getDouble(key) ?? defaultValue;

  /// 存储字符串。
  Future<bool> setString(String key, String value) => _getPrefs().setString(key, value);

  /// 获取字符串。
  String getString(String key, {String defaultValue = ''}) => _getPrefs().getString(key) ?? defaultValue;

  /// 存储字符串列表。
  Future<bool> setStringList(String key, List<String> value) => _getPrefs().setStringList(key, value);

  /// 获取字符串列表。
  List<String> getStringList(String key, {List<String> defaultValue = const []}) => _getPrefs().getStringList(key) ?? defaultValue;

  // --- 自定义对象存储 (JSON 序列化) ---

  /// 存储自定义对象。
  /// 对象必须提供一个 `toJson()` 方法将其转换为 `Map<String, dynamic>`。
  ///
  /// [key] 键名。
  /// [value] 要存储的对象实例。
  /// [toJson] 将对象转换为 `Map<String, dynamic>` 的回调函数。
  ///
  /// 示例：
  /// ```dart
  /// class MyObject {
  ///   String name;
  ///   MyObject({required this.name});
  ///   Map<String, dynamic> toJson() => {'name': name};
  /// }
  /// SpUtil().setObject('my_object_key', MyObject(name: 'Test'), (obj) => obj.toJson());
  /// ```
  Future<bool> setObject<T>(String key, T value, Map<String, dynamic> Function(T object) toJson) {
    final String jsonString = jsonEncode(toJson(value));
    return _getPrefs().setString(key, jsonString);
  }

  /// 获取自定义对象。
  /// 对象必须提供一个 `fromJson()` 构造函数或工厂方法从 `Map<String, dynamic>` 创建。
  ///
  /// [key] 键名。
  /// [fromJson] 从 `Map<String, dynamic>` 创建对象的工厂函数或回调函数。
  ///
  /// 示例：
  /// ```dart
  /// MyObject? obj = SpUtil().getObject('my_object_key', (json) => MyObject.fromJson(json));
  /// ```
  T? getObject<T>(String key, T Function(Map<String, dynamic> json) fromJson) {
    final String? jsonString = _getPrefs().getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(jsonMap);
    } catch (e) {
      // 可以在这里添加日志或错误上报
      // debugPrint('SpUtil Error: Failed to decode object for key "$key": $e');
      return null;
    }
  }

  /// 存储自定义对象列表。
  /// 列表中每个对象都必须提供 `toJson()` 方法。
  ///
  /// [key] 键名。
  /// [value] 要存储的对象列表。
  /// [toJson] 将单个对象转换为 `Map<String, dynamic>` 的回调函数。
  ///
  /// 示例：
  /// ```dart
  /// List<MyObject> list = [MyObject(name: 'A'), MyObject(name: 'B')];
  /// SpUtil().setObjectList('my_object_list_key', list, (obj) => obj.toJson());
  /// ```
  Future<bool> setObjectList<T>(String key, List<T> value, Map<String, dynamic> Function(T object) toJson) {
    final List<String> jsonList = value.map((e) => jsonEncode(toJson(e))).toList();
    return _getPrefs().setStringList(key, jsonList);
  }

  /// 获取自定义对象列表。
  /// 列表中每个对象都必须提供 `fromJson()` 构造函数或工厂方法。
  ///
  /// [key] 键名。
  /// [fromJson] 从 `Map<String, dynamic>` 创建对象的工厂函数或回调函数。
  ///
  /// 示例：
  /// ```dart
  /// List<MyObject>? list = SpUtil().getObjectList('my_object_list_key', (json) => MyObject.fromJson(json));
  /// ```
  List<T>? getObjectList<T>(String key, T Function(Map<String, dynamic> json) fromJson) {
    final List<String>? jsonStringList = _getPrefs().getStringList(key);
    if (jsonStringList == null || jsonStringList.isEmpty) {
      return null;
    }
    try {
      return jsonStringList.map((jsonString) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return fromJson(jsonMap);
      }).toList();
    } catch (e) {
      // 可以在这里添加日志或错误上报
      // debugPrint('SpUtil Error: Failed to decode object list for key "$key": $e');
      return null;
    }
  }

  // --- 其他操作 ---

  /// 检查是否存在某个键。
  bool containsKey(String key) => _getPrefs().containsKey(key);

  /// 移除指定键的数据。
  Future<bool> remove(String key) => _getPrefs().remove(key);

  /// 清除所有数据。
  Future<bool> clear() => _getPrefs().clear();

  /// 同步数据到磁盘（通常不需要手动调用，SharedPreferences 会自动处理）。
  Future<void>? reload() => _getPrefs().reload();
}