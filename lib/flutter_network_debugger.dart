/// A comprehensive network debugging tool for Flutter applications.
///
/// This library provides real-time monitoring and visualization of HTTP and
/// WebSocket network calls in your Flutter app. It includes:
///
/// * [FlutterNetworkDebugger] - A wrapper widget that displays a floating debug button
/// * [FlutterNetworkDebuggerDioInterceptor] - Interceptor for Dio HTTP client
/// * [FlutterNetworkSocketMonitor] - Monitor for WebSocket connections
/// * [NetworkCall] - Model representing a single network call
///
/// ## Usage
///
/// Wrap your app with [FlutterNetworkDebugger]:
///
/// ```dart
/// FlutterNetworkDebugger(
///   child: MaterialApp(
///     home: MyApp(),
///   ),
///   isDebug: true,
/// )
/// ```
///
/// Then add the Dio interceptor to your Dio instance:
///
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(FlutterNetworkDebuggerDioInterceptor());
/// ```
///
/// And log WebSocket events:
///
/// ```dart
/// FlutterNetworkSocketMonitor.logSocketEvent(
///   url: 'ws://example.com',
///   event: 'send',
///   data: jsonEncode({'message': 'hello'}),
/// );
/// ```
library flutter_network_debugger;

export 'src/ui/monitor_widget.dart';
export 'src/ui/monitor_screen.dart';
export 'src/models/network_call.dart';
export 'src/interceptors/dio_interceptor.dart';
export 'src/interceptors/socket_monitor.dart';
export 'src/core/network_monitor.dart';
