import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_network_debugger/flutter_network_debugger.dart';

void main() {
  runApp(const MyApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Network Debugger Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      builder: (context, child) {
        return FlutterNetworkDebugger(
          isDebug: true,
          navigatorKey: navigatorKey,
          child: child!,
        );
      },
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final dio = Dio();

  @override
  void initState() {
    super.initState();
    dio.interceptors.add(FlutterNetworkDebuggerDioInterceptor());
  }

  void _makeRequests() async {
    final options = Options(
      validateStatus: (status) => true,
      headers: {
        "Content-Type": "application/json",
        "User-Agent": "PostmanRuntime/7.28.4",
      },
    );

    try {
      // GET
      debugPrint('Making GET request...');
      await dio.get(
        'https://jsonplaceholder.typicode.com/posts/1',
        options: options,
      );

      // POST
      debugPrint('Making POST request...');
      await dio.post(
        'https://jsonplaceholder.typicode.com/posts',
        data: {"title": "test", "body": "debug", "userId": 1},
        options: options,
      );

      // PUT
      debugPrint('Making PUT request...');
      await dio.put(
        'https://jsonplaceholder.typicode.com/posts/1',
        data: {
          "id": 1,
          "title": "updated",
          "body": "debug update",
          "userId": 1
        },
        options: options,
      );

      // PATCH
      debugPrint('Making PATCH request...');
      await dio.patch(
        'https://jsonplaceholder.typicode.com/posts/1',
        data: {"title": "patched"},
        options: options,
      );

      // DELETE
      debugPrint('Making DELETE request...');
      await dio.delete(
        'https://jsonplaceholder.typicode.com/posts/1',
        options: options,
      );

      // FORMDATA
      debugPrint('Making FormData request...');
      final formData = FormData.fromMap({
        'name': 'johndoe',
        'type': 'package_test',
        'version': '0.0.1',
        'file': MultipartFile.fromString('test content', filename: 'test.txt'),
      });
      await dio.post(
        'https://jsonplaceholder.typicode.com/posts',
        data: formData,
        options: options,
      );
    } catch (e) {
      debugPrint('Error in _makeRequests: $e');
    }
  }

  void _logSocket() {
    final socketId = 'my_socket_${DateTime.now().millisecondsSinceEpoch}';
    FlutterNetworkSocketMonitor.logSocketEvent(
      id: socketId,
      url: 'ws://echo.websocket.org',
      event: 'send',
      data: {'message': 'Hello from Flutter!'},
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      FlutterNetworkSocketMonitor.logSocketEvent(
        id: socketId,
        url: 'ws://echo.websocket.org',
        event: 'receive',
        data: {'response': 'Hello from Flutter!'},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Monitor Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _makeRequests,
              child: const Text('Run Dummy HTTP Requests'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _logSocket,
              child: const Text('Simulate Socket Event'),
            ),
          ],
        ),
      ),
    );
  }
}
