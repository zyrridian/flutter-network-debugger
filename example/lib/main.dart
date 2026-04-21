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

  void _makeRequest() async {
    try {
      await dio.get('https://jsonplaceholder.typicode.com/posts/1');
    } catch (e) {
      debugPrint(e.toString());
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
              onPressed: _makeRequest,
              child: const Text('Make HTTP Request'),
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
