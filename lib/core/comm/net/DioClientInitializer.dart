// ============== 内部辅助类：用于管理 SecurityContext 的初始化和缓存 ==============
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:async';

import '../utils/LoggerUtil.dart';
// 假设你有 Log 工具类，如果没有请自行添加或替换为 debugPrint
//建议启动app 时候初始化
class DioClientInitializer {
  static Completer<SecurityContext>? _completer;
  static SecurityContext? _cachedSecurityContext; // <<<<<<<<<<< 新增：用于缓存已加载的 SecurityContext

  static Future<void> initializeSecurityContext() async { // <<<<<<<<<<< 新增：异步初始化方法
    if (_completer != null) {
      if (!_completer!.isCompleted) {
        await _completer!.future; // 等待正在进行的初始化
      }
      return; // 已经完成或正在进行，直接返回
    }

    _completer = Completer<SecurityContext>();
    Log.d('DioClientInitializer: 开始异步加载和初始化 SecurityContext。', tag: 'DioClientCert');

    SecurityContext customSecurityContext = SecurityContext.defaultContext;
    try {
      final ByteData data = await rootBundle.load('assets/certs/my_root_ca.pem'); // 异步加载证书文件
      customSecurityContext.setTrustedCertificatesBytes(data.buffer.asUint8List());
      Log.i('HTTPS: 证书已加载并添加到 SecurityContext。', tag: 'DioClientCert');

      // 如果需要客户端证书认证，在这里加载客户端证书和私钥
      // final ByteData clientCertData = await rootBundle.load('assets/certs/client_cert.pem');
      // final ByteData clientKeyData = await rootBundle.load('assets/certs/client_key.pem');
      // customSecurityContext.useCertificateChainBytes(clientCertData.buffer.asUint8List());
      // customSecurityContext.usePrivateKeyBytes(clientKeyData.buffer.asUint8List());
      // Log.i('HTTPS: 客户端证书和私钥已加载。', tag: 'DioClientCert');

      _cachedSecurityContext = customSecurityContext; // <<<<<<<<<<< 关键：缓存结果
      _completer!.complete(customSecurityContext);
    } catch (e, st) {
      Log.e('HTTPS: 异步加载或配置证书失败: $e', tag: 'DioClientCert', error: e, stackTrace: st);
      _completer!.completeError(e, st);
      rethrow;
    }
  }

  // 同步获取已完成的 SecurityContext
  // ！！！仅在确保 initializeSecurityContext 已被 await 调用后才能安全调用！！！
  static SecurityContext getInitializedSecurityContext() { // <<<<<<<<<<< 新增：同步获取方法
    if (_cachedSecurityContext == null) {
      Log.e('DioClientInitializer: SecurityContext 未初始化或初始化失败，返回默认上下文。', tag: 'DioClientCert');
      // 这表示调用顺序有问题，或者初始化确实失败了
      return SecurityContext.defaultContext;
    }
    return _cachedSecurityContext!;
  }
}