# Flutter Network Debugger

A powerful and easy-to-use Flutter package to monitor HTTP requests and socket network traffic in debug mode.

It provides a floating action button that attaches to your app's UI, allowing you to view live updates of network traffic, inspect headers, body, and status codes with a single click.

## Features

- 🐛 **Debug Mode Only**: Automatically hides in production.
- 🌐 **HTTP Monitoring**: Integrates easily with `dio` to intercept and log requests.
- 🔌 **Socket Monitoring**: Exposes a simple logger for WebSocket and TCP socket events.
- 📱 **In-App Viewer**: See your requests in real-time with a floating button.
- 🔍 **Detailed Inspection**: View request/response headers, bodies, timestamps, and durations.
- 🔄 **JSON Formatting**: Automatically formats JSON payloads for readability.

## Installation

Add it to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_network_debugger: ^0.0.1
```

## Usage

### 1. Wrap your App

Wrap your root widget or `MaterialApp` builder with `FlutterNetworkDebugger`:

```dart
import 'package:flutter_network_debugger/flutter_network_debugger.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Provide the navigator key here
      title: 'Network Debugger Demo',
      // The builder provides a Navigator context to push the monitor screen
      builder: (context, child) {
        return FlutterNetworkDebugger(
          navigatorKey: navigatorKey, // And provide it here
          isDebug: true, // Set to false in production (e.g., kDebugMode)
          child: child!,
        );
      },
      home: const MyHomePage(),
    );
  }
}
```

### 2. Monitor HTTP Requests (Dio)

Attach the interceptor to your Dio instance:

```dart
final dio = Dio();
dio.interceptors.add(FlutterNetworkDebuggerDioInterceptor());

// Now just make requests!
dio.get('https://jsonplaceholder.typicode.com/posts/1');
```

### 3. Monitor Sockets

Log socket events using the `FlutterNetworkSocketMonitor`:

```dart
final socketId = 'my_socket_1';

FlutterNetworkSocketMonitor.logSocketEvent(
  id: socketId,
  url: 'ws://echo.websocket.org',
  event: 'send',
  data: {'message': 'Hello'},
);

FlutterNetworkSocketMonitor.logSocketEvent(
  id: socketId,
  url: 'ws://echo.websocket.org',
  event: 'receive',
  data: {'response': 'Hello back'},
);
```

## Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.
