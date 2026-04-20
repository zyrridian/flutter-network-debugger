enum NetworkCallType { http, socket }

class NetworkCall {
  final String id;
  final NetworkCallType type;
  final String url;
  final String method;
  final DateTime requestTime;

  Map<String, dynamic>? requestHeaders;
  dynamic requestBody;

  int? statusCode;
  DateTime? responseTime;
  Map<String, dynamic>? responseHeaders;
  dynamic responseBody;
  dynamic error;

  NetworkCall({
    required this.id,
    required this.type,
    required this.url,
    required this.method,
    required this.requestTime,
  });

  int get durationMilliseconds {
    if (responseTime != null) {
      return responseTime!.difference(requestTime).inMilliseconds;
    }
    return -1;
  }
}
