// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_test_new/core/comm/utils/SPUtils.dart';
import 'package:http/http.dart' as http;

import 'core/comm/api_service/UserApiService.dart';
import 'core/comm/bean/User.dart';
import 'core/comm/net/ApiException.dart';
import 'core/comm/net/LoadingInterceptor.dart';
import 'core/comm/net/Result.dart';
import 'core/comm/utils/LoggerUtil.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SpUtil.init();

    return MaterialApp(
      title: 'Loading Interceptor Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // 在这里设置全局 Context
      builder: (context, child) {
        return child!;
      },
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserApiService _userApiService = UserApiService();
  String _message = '点击按钮测试加载';

  Future<void> _testLoadingInterceptor() async {
    setState(() {
      _message = '正在请求...';
    });

    Log.d('HomeScreen: 开始测试 LoadingInterceptor.', tag: 'HomeScreen');

    // 假设你的 API 会有一定延迟，模拟网络请求
    final Result<List<User>, ApiException> result = await _userApiService.getUsers();

    result.when(
      success: (users) {
        setState(() {
          _message = '请求成功，获取到 ${users.length} 个用户！';
        });
        Log.i('HomeScreen: 获取用户成功，数量：${users.length}', tag: 'HomeScreen');
      },
      failure: (error) {
        setState(() {
          _message = '请求失败: ${error.message}';
        });
        Log.e('HomeScreen: 获取用户失败', tag: 'HomeScreen', error: error);
      },
    );
  }

  Future<void> _testHttpPackage() async {
    setState(() {
      _message = '正在使用 http 包测试网络...';
    });
    try {
      final uri = Uri.parse('http://jsonplaceholder.typicode.com/users');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          _message = 'http 包请求成功！状态码: ${response.statusCode}, 数据长度: ${response.body.length}';
        });
        Log.i('http包测试成功: ${response.body.substring(0, 100)}...', tag: 'HttpTest');
      } else {
        setState(() {
          _message = 'http 包请求失败！状态码: ${response.statusCode}, 错误: ${response.body}';
        });
        Log.e('http包测试失败: ${response.statusCode} - ${response.body}', tag: 'HttpTest');
      }
    } catch (e, st) {
      setState(() {
        _message = 'http 包请求发生异常: $e';
      });
      Log.e('http包测试异常', tag: 'HttpTest', error: e, stackTrace: st);
    }
  }

  // 模拟一个较长时间的请求，以便观察加载效果
  Future<void> _testLongRequest() async {
    setState(() {
      _message = '正在进行长时间请求...';
    });
    Log.d('HomeScreen: 开始长时间请求测试.', tag: 'HomeScreen');
    try {
      // 模拟一个带延迟的 GET 请求，可以指向一个真实但响应慢的接口，
      // 或者你的 DioClient 的 baseUrl 已经配置好了，这里直接用一个不存在的路径来触发 onError
      // 为了测试加载，我们可以让这个请求延迟一点。
      // 注意：直接在这里用 DioClient 是为了快速测试，实际项目中仍通过 UserApiService 封装。
      // 这里只是为了方便演示长时间请求。
      await Future.delayed(const Duration(seconds: 3)); // 模拟3秒网络延迟
      // 触发一个可能失败的请求，或者你有一个真实的慢速API
      // final result = await _userApiService.someLongRunningApiCall();
      // 为了演示，我们再次调用getUsers，但知道它可能被延迟
      final result = await _userApiService.getUsers();


      result.when(
        success: (users) {
          setState(() {
            _message = '长时间请求成功，获取到 ${users.length} 个用户！';
          });
          Log.i('HomeScreen: 长时间请求成功，数量：${users.length}', tag: 'HomeScreen');
        },
        failure: (error) {
          setState(() {
            _message = '长时间请求失败: ${error.message}';
          });
          Log.e('HomeScreen: 长时间请求失败', tag: 'HomeScreen', error: error);
        },
      );
    } catch (e, st) {
      setState(() {
        _message = '长时间请求发生异常: $e';
      });
      Log.e('HomeScreen: 长时间请求捕获到异常', tag: 'HomeScreen', error: e, stackTrace: st);
    }
  }


  @override
  Widget build(BuildContext context) {
    setGlobalContext(context); // 调用 LoadingInterceptor 中的 setGlobalContext

    return Scaffold(
      appBar: AppBar(
        title: const Text('加载拦截器测试'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testLoadingInterceptor,
              child: const Text('测试加载拦截器 (快速请求)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testLongRequest,
              child: const Text('测试加载拦截器 (模拟长时间请求)'),
            ),
          ],
        ),
      ),
    );
  }
}