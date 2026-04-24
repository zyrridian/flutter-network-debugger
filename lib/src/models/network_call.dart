/// Enumeration of supported network call types.
///
/// [http] - HTTP/HTTPS requests
/// [socket] - WebSocket connections
enum NetworkCallType { http, socket }

/// Represents a single network call with complete request and response information.
///
/// This class captures all details about a network request including:
/// * Request metadata (URL, method, headers, body)
/// * Response metadata (status code, headers, body)
/// * Timing information (request time, response time)
/// * Error information (if the request failed)
class NetworkCall {
  /// Unique identifier for this network call.
  final String id;

  /// Type of network call (HTTP or WebSocket).
  final NetworkCallType type;

  /// The URL/endpoint being called.
  final String url;

  /// The HTTP method or protocol (e.g., 'GET', 'POST', 'SOCKET').
  final String method;

  /// Timestamp when the request was initiated.
  final DateTime requestTime;

  /// Headers sent with the request.
  Map<String, dynamic>? requestHeaders;

  /// The request body payload.
  dynamic requestBody;

  /// HTTP status code of the response (e.g., 200, 404, 500).
  int? statusCode;

  /// Timestamp when the response was received.
  DateTime? responseTime;

  /// Headers received in the response.
  Map<String, dynamic>? responseHeaders;

  /// The response body payload.
  dynamic responseBody;

  /// Error information if the request failed.
  dynamic error;

  /// Creates a new [NetworkCall].
  ///
  /// The [id], [type], [url], [method], and [requestTime] are required
  /// parameters that must be provided at construction time.
  NetworkCall({
    required this.id,
    required this.type,
    required this.url,
    required this.method,
    required this.requestTime,
  });

  /// Converts this network call to a JSON-serializable map.
  ///
  /// Returns a map representation of the call suitable for export or logging.
  /// The duration in milliseconds is automatically calculated.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'url': url,
      'method': method,
      'requestTime': requestTime.toIso8601String(),
      'requestHeaders': requestHeaders,
      'requestBody': requestBody,
      'statusCode': statusCode,
      'responseTime': responseTime?.toIso8601String(),
      'responseHeaders': responseHeaders,
      'responseBody': responseBody,
      'error': error?.toString(),
      'durationMilliseconds': durationMilliseconds,
    };
  }

  /// Duration of the network call in milliseconds.
  ///
  /// Returns -1 if the response has not yet been received.
  int get durationMilliseconds {
    if (responseTime != null) {
      return responseTime!.difference(requestTime).inMilliseconds;
    }
    return -1;
  }
}
