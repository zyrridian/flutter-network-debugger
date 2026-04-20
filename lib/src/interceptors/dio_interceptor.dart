import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/network_monitor.dart';
import '../models/network_call.dart';

class FlutterNetworkDebuggerDioInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final call = NetworkCall(
      id: '${DateTime.now().millisecondsSinceEpoch}_${options.hashCode}',
      type: NetworkCallType.http,
      url: options.uri.toString(),
      method: options.method,
      requestTime: DateTime.now(),
    );

    call.requestHeaders = options.headers;
    call.requestBody = _tryParse(options.data);

    options.extra['network_monitor_id'] = call.id;
    NetworkMonitorCore.instance.addCall(call);

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final id = response.requestOptions.extra['network_monitor_id'];
    if (id != null) {
      final call = NetworkMonitorCore.instance.calls.value.firstWhere(
        (c) => c.id == id,
        orElse: () => _createFallbackCall(response.requestOptions, id),
      );

      call.statusCode = response.statusCode;
      call.responseTime = DateTime.now();
      call.responseHeaders = response.headers.map;
      call.responseBody = _tryParse(response.data);

      NetworkMonitorCore.instance.updateCall(call);
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final id = err.requestOptions.extra['network_monitor_id'];
    if (id != null) {
      final call = NetworkMonitorCore.instance.calls.value.firstWhere(
        (c) => c.id == id,
        orElse: () => _createFallbackCall(err.requestOptions, id),
      );

      call.statusCode = err.response?.statusCode;
      call.responseTime = DateTime.now();
      call.responseHeaders = err.response?.headers.map;
      call.responseBody = _tryParse(err.response?.data);
      call.error = err.message;

      NetworkMonitorCore.instance.updateCall(call);
    }
    super.onError(err, handler);
  }

  dynamic _tryParse(dynamic data) {
    if (data is String) {
      try {
        return json.decode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  NetworkCall _createFallbackCall(RequestOptions options, String id) {
    final call = NetworkCall(
      id: id,
      type: NetworkCallType.http,
      url: options.uri.toString(),
      method: options.method,
      requestTime: DateTime.now(),
    );
    NetworkMonitorCore.instance.addCall(call);
    return call;
  }
}
