import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/network_call.dart';

/// Detailed view screen for a single network call.
///
/// [CallDetailsScreen] displays comprehensive information about a network call
/// including:
/// * Overview tab - URL, method, status, duration, and error info
/// * Request tab - Headers and body payload
/// * Response tab - Headers and body payload
/// * Copy as cURL button to export the request
class CallDetailsScreen extends StatefulWidget {
  final NetworkCall call;

  const CallDetailsScreen({super.key, required this.call});

  @override
  State<CallDetailsScreen> createState() => _CallDetailsScreenState();
}

class _CallDetailsScreenState extends State<CallDetailsScreen> {
  final Map<String, String> _formattedCache = {};

  String _formatJsonCached(String key, dynamic data) {
    if (_formattedCache.containsKey(key)) return _formattedCache[key]!;
    final formatted = _formatJson(data);
    _formattedCache[key] = formatted;
    return formatted;
  }

  String _formatJson(dynamic data) {
    if (data == null) return 'No data';
    try {
      if (data is String) {
        final parsed = json.decode(data);
        return const JsonEncoder.withIndent('  ').convert(parsed);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;
    // final call = widget.call;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: Colors.black,
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: isDark ? Colors.white : Colors.black,
              secondary: Colors.grey,
              surfaceTint: Colors.transparent,
            ),
        splashColor: Colors.grey.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white : Colors.black),
        ),
      ),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
            elevation: 0,
            title: const Text('CALL DETAILS',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.2)),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_all, size: 20),
                tooltip: 'Copy as cURL',
                onPressed: () => _copyAsCurl(context),
              ),
            ],
            bottom: TabBar(
              indicatorColor: isDark ? Colors.white : Colors.black,
              labelColor: isDark ? Colors.white : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0),
              tabs: const [
                Tab(text: 'OVERVIEW'),
                Tab(text: 'REQUEST'),
                Tab(text: 'RESPONSE'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              KeepAliveWrapper(child: _buildOverview(context)),
              KeepAliveWrapper(child: _buildRequest(context)),
              KeepAliveWrapper(child: _buildResponse(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    final call = widget.call;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDetailRow('URL', call.url),
        _buildDetailRow('Method', _buildMethodBadge(call.method)),
        _buildDetailRow('Status Code', call.statusCode?.toString() ?? 'N/A'),
        _buildDetailRow('Duration',
            '${call.durationMilliseconds > -1 ? call.durationMilliseconds : 'N/A'} ms'),
        _buildDetailRow('Time', call.requestTime.toString()),
        if (call.error != null)
          _buildDetailRow('Error', call.error.toString(), isError: true),
      ],
    );
  }

  Widget _buildMethodBadge(String method) {
    final color = _getMethodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green[700]!;
      case 'POST':
        return Colors.blue[700]!;
      case 'PUT':
        return Colors.orange[700]!;
      case 'PATCH':
        return Colors.indigo[400]!;
      case 'DELETE':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Widget _buildRequest(BuildContext context) {
    final call = widget.call;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader(
                  'Headers', _formatJsonCached('req_h', call.requestHeaders)),
              const SizedBox(height: 8),
              JsonCodeBlock(data: call.requestHeaders),
              const Divider(height: 32),
              _buildSectionHeader(
                'Body',
                _formatJsonCached('req_b', call.requestBody),
                subtitle: _getContentTypeLabel(call.requestHeaders),
              ),
              const SizedBox(height: 8),
              JsonCodeBlock(data: call.requestBody),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildResponse(BuildContext context) {
    final call = widget.call;
    final contentType = _getContentTypeLabel(call.responseHeaders);
    final isImage = contentType == 'IMAGE';

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              ExpandablePreviewSection(
                title: 'Headers',
                data: call.responseHeaders,
                onCopy: (content) => _copyToClipboard(context, content),
              ),
              const Divider(height: 32),
              _buildSectionHeader(
                'Body',
                isImage
                    ? call.url
                    : _formatJsonCached('res_b', call.responseBody),
                subtitle: contentType,
              ),
              const SizedBox(height: 8),
              if (isImage)
                Container(
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      call.url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text('Failed to load image preview',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                )
              else
                JsonCodeBlock(data: call.responseBody),
            ]),
          ),
        ),
      ],
    );
  }

  String? _getContentTypeLabel(Map<String, dynamic>? headers) {
    if (headers == null) return null;

    dynamic contentType;
    headers.forEach((key, value) {
      if (key.toLowerCase() == 'content-type') {
        contentType = value;
      }
    });

    if (contentType == null) return null;

    final String typeString = (contentType is List)
        ? contentType.first.toString()
        : contentType.toString();

    if (typeString.contains('application/json')) return 'JSON';
    if (typeString.contains('multipart/form-data')) return 'FormData';
    if (typeString.contains('application/x-www-form-urlencoded')) return 'Form';
    if (typeString.contains('text/plain')) return 'Text';
    if (typeString.contains('text/html')) return 'HTML';
    if (typeString.contains('application/xml')) return 'XML';
    if (typeString.contains('image/')) return 'IMAGE';

    return typeString.split(';').first.split('/').last.toUpperCase();
  }

  void _copyToClipboard(BuildContext context, String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _copyAsCurl(BuildContext context) {
    final call = widget.call;
    final buffer = StringBuffer();
    buffer.write('curl -X ${call.method} "${call.url}"');

    if (call.requestHeaders != null && call.requestHeaders is Map) {
      (call.requestHeaders as Map).forEach((key, value) {
        buffer.write(' -H "$key: $value"');
      });
    }

    if (call.requestBody != null) {
      final body = call.requestBody is String
          ? call.requestBody
          : json.encode(call.requestBody);
      buffer.write(" -d '$body'");
    }

    _copyToClipboard(context, buffer.toString());
  }

  Widget _buildDetailRow(String label, dynamic value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          if (value is Widget)
            value
          else
            SelectableText(
              value.toString(),
              style:
                  TextStyle(fontSize: 15, color: isError ? Colors.red : null),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String copyContent,
      {String? subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  subtitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Copy $title',
            onPressed: () => _copyToClipboard(context, copyContent),
          );
        }),
      ],
    );
  }
}

class ExpandablePreviewSection extends StatefulWidget {
  final String title;
  final dynamic data;
  final Function(String) onCopy;

  const ExpandablePreviewSection({
    super.key,
    required this.title,
    required this.data,
    required this.onCopy,
  });

  @override
  State<ExpandablePreviewSection> createState() =>
      _ExpandablePreviewSectionState();
}

class _ExpandablePreviewSectionState extends State<ExpandablePreviewSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final content = _formatJson(widget.data);
    final isLong = content.split('\n').length > 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Row(
              children: [
                if (isLong)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more),
                    label: Text(_isExpanded ? 'Show less' : 'Show more'),
                  ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => widget.onCopy(content),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: double.infinity,
                child: JsonCodeBlock(
                  data: widget.data,
                ),
              ),
            ),
          ),
          secondChild: JsonCodeBlock(data: widget.data),
          crossFadeState: (isLong && !_isExpanded)
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  String _formatJson(dynamic data) {
    if (data == null) return 'No data';
    try {
      if (data is String) {
        final parsed = json.decode(data);
        return const JsonEncoder.withIndent('  ').convert(parsed);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }
}

class JsonCodeBlock extends StatefulWidget {
  final dynamic data;

  const JsonCodeBlock({super.key, required this.data});

  @override
  State<JsonCodeBlock> createState() => _JsonCodeBlockState();
}

class _JsonCodeBlockState extends State<JsonCodeBlock> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isTreeView = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Delay rendering of heavy JSON block to allow tab transition animation to finish smoothly
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'SEARCH JSON...',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black26),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
              ),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
        Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                  width: 0.5,
                ),
              ),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : (_isTreeView
                      ? JsonTreeView(
                          data: widget.data,
                          searchQuery: _searchQuery,
                        )
                      : SelectableText.rich(
                          _highlightJson(
                              context, _formatJson(widget.data), isDark),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.4,
                          ),
                        )),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                        _isTreeView ? Icons.code : Icons.account_tree_outlined,
                        size: 16,
                        color: Colors.grey),
                    tooltip: _isTreeView ? 'Raw View' : 'Tree View',
                    onPressed: () {
                      setState(() {
                        _isTreeView = !_isTreeView;
                      });
                    },
                  ),
                  if (!_isSearching)
                    IconButton(
                      icon: const Icon(Icons.search,
                          size: 16, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatJson(dynamic data) {
    if (data == null) return 'No data';
    try {
      if (data is String) {
        final parsed = json.decode(data);
        return const JsonEncoder.withIndent('  ').convert(parsed);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }

  List<InlineSpan> _applySearchHighlight(String text, TextStyle baseStyle,
      {GestureRecognizer? recognizer}) {
    if (_searchQuery.isEmpty) {
      return [TextSpan(text: text, style: baseStyle, recognizer: recognizer)];
    }

    final lowerText = text.toLowerCase();
    int index = lowerText.indexOf(_searchQuery);
    if (index == -1) {
      return [TextSpan(text: text, style: baseStyle, recognizer: recognizer)];
    }

    final List<InlineSpan> spans = [];
    int start = 0;
    final highlightStyle =
        baseStyle.copyWith(backgroundColor: Colors.yellow, color: Colors.black);

    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(
            text: text.substring(start, index),
            style: baseStyle,
            recognizer: recognizer));
      }
      spans.add(TextSpan(
          text: text.substring(index, index + _searchQuery.length),
          style: highlightStyle,
          recognizer: recognizer));
      start = index + _searchQuery.length;
      index = lowerText.indexOf(_searchQuery, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(
          text: text.substring(start),
          style: baseStyle,
          recognizer: recognizer));
    }
    return spans;
  }

  TextSpan _highlightJson(BuildContext context, String source, bool isDark) {
    final List<InlineSpan> spans = [];
    final regExp = RegExp(
      r'("(?:\\"|[^"])*")(?=\s*:)|("(?:\\"|[^"])*")|(\b\d+\b)|(\btrue|false|null\b)|([\{\}\[\]\:,])',
      multiLine: true,
    );
    final defaultStyle =
        TextStyle(color: isDark ? Colors.white : Colors.black87);

    int lastIndex = 0;
    for (final match in regExp.allMatches(source)) {
      if (match.start > lastIndex) {
        spans.addAll(_applySearchHighlight(
            source.substring(lastIndex, match.start), defaultStyle));
      }

      if (match.group(1) != null) {
        spans.addAll(_applySearchHighlight(
          match.group(1)!,
          TextStyle(
              color: isDark ? Colors.lightBlueAccent : Colors.indigo,
              fontWeight: FontWeight.bold),
        ));
      } else if (match.group(2) != null) {
        final stringValue = match.group(2)!;
        final rawValue = stringValue.replaceAll('"', '');
        final isUrl =
            rawValue.startsWith('http://') || rawValue.startsWith('https://');

        if (isUrl) {
          final recognizer = TapGestureRecognizer()
            ..onTap = () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title:
                          Text(rawValue, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    body: Center(
                      child: InteractiveViewer(
                        child: Image.network(
                          rawValue,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Failed to load preview.\nThis URL might not be an image.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            };

          spans.addAll(_applySearchHighlight(
            stringValue,
            TextStyle(
              color: isDark ? Colors.blue[300] : Colors.blue[700],
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
            ),
            recognizer: recognizer,
          ));
        } else {
          spans.addAll(_applySearchHighlight(
            stringValue,
            const TextStyle(color: Colors.teal),
          ));
        }
      } else if (match.group(3) != null) {
        spans.addAll(_applySearchHighlight(
          match.group(3)!,
          const TextStyle(color: Colors.orange),
        ));
      } else if (match.group(4) != null) {
        spans.addAll(_applySearchHighlight(
          match.group(4)!,
          const TextStyle(color: Colors.redAccent),
        ));
      } else if (match.group(5) != null) {
        spans.addAll(_applySearchHighlight(
          match.group(5)!,
          TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < source.length) {
      spans.addAll(
          _applySearchHighlight(source.substring(lastIndex), defaultStyle));
    }

    return TextSpan(children: spans, style: defaultStyle);
  }
}

class JsonTreeView extends StatelessWidget {
  final dynamic data;
  final String searchQuery;

  const JsonTreeView({super.key, required this.data, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const Text('No data');

    dynamic displayData = data;
    if (displayData is String) {
      try {
        displayData = json.decode(displayData);
      } catch (e) {
        // Not a JSON string
      }
    }

    return JsonNodeView(
      value: displayData,
      searchQuery: searchQuery,
      depth: 0,
    );
  }
}

class JsonNodeView extends StatefulWidget {
  final String? keyName;
  final dynamic value;
  final int depth;
  final bool isLast;
  final String searchQuery;

  const JsonNodeView({
    super.key,
    this.keyName,
    required this.value,
    this.depth = 0,
    this.isLast = true,
    this.searchQuery = '',
  });

  @override
  State<JsonNodeView> createState() => _JsonNodeViewState();
}

class _JsonNodeViewState extends State<JsonNodeView> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    // Expand by default as requested
    _isExpanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final value = widget.value;
    final isCollection = value is Map || value is List;
    final isEmpty = isCollection &&
        (value is Map ? value.isEmpty : (value as List).isEmpty);

    if (!isCollection || isEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: widget.depth * 16.0),
        child: _buildLeaf(context, isDark),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding:
                  EdgeInsets.only(left: widget.depth * 16.0, top: 2, bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 18,
                    color: Colors.grey,
                  ),
                  _buildCollectionHeader(context, isDark),
                ],
              ),
            ),
          ),
        ),
        if (_isExpanded) ..._buildChildren(context, isDark),
        if (!_isExpanded)
          Padding(
            padding: EdgeInsets.only(left: (widget.depth * 16.0) + 20),
            child: Text(
              value is Map ? '{...}' : '[...]',
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
      ],
    );
  }

  Widget _buildLeaf(BuildContext context, bool isDark) {
    final keyPart = widget.keyName != null
        ? TextSpan(
            text: '"${widget.keyName}": ',
            style: TextStyle(
                color: isDark ? Colors.lightBlueAccent : Colors.indigo,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'monospace'))
        : null;

    final valuePart = _getValueSpan(context, widget.value, isDark);

    return SelectableText.rich(
      TextSpan(children: [
        if (keyPart != null) keyPart,
        valuePart,
        if (!widget.isLast)
          TextSpan(
              text: ',',
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                  fontFamily: 'monospace')),
      ]),
    );
  }

  Widget _buildCollectionHeader(BuildContext context, bool isDark) {
    final keyPart = widget.keyName != null ? '"${widget.keyName}": ' : '';
    final bracket = widget.value is Map ? '{' : '[';

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        children: [
          if (keyPart.isNotEmpty)
            TextSpan(
              text: keyPart,
              style: TextStyle(
                  color: isDark ? Colors.lightBlueAccent : Colors.indigo,
                  fontWeight: FontWeight.bold),
            ),
          TextSpan(
            text: bracket,
            style:
                TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChildren(BuildContext context, bool isDark) {
    final List<Widget> children = [];
    if (widget.value is Map) {
      final Map map = widget.value;
      final keys = map.keys.toList();
      for (int i = 0; i < keys.length; i++) {
        children.add(JsonNodeView(
          keyName: keys[i].toString(),
          value: map[keys[i]],
          depth: widget.depth + 1,
          isLast: i == keys.length - 1,
          searchQuery: widget.searchQuery,
        ));
      }
      children.add(Padding(
        padding: EdgeInsets.only(left: (widget.depth * 16.0) + 18),
        child: Text('}${widget.isLast ? "" : ","}',
            style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
                fontFamily: 'monospace')),
      ));
    } else if (widget.value is List) {
      final List list = widget.value;
      for (int i = 0; i < list.length; i++) {
        children.add(JsonNodeView(
          value: list[i],
          depth: widget.depth + 1,
          isLast: i == list.length - 1,
          searchQuery: widget.searchQuery,
        ));
      }
      children.add(Padding(
        padding: EdgeInsets.only(left: (widget.depth * 16.0) + 18),
        child: Text(']${widget.isLast ? "" : ","}',
            style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
                fontFamily: 'monospace')),
      ));
    }
    return children;
  }

  InlineSpan _getValueSpan(BuildContext context, dynamic value, bool isDark) {
    TextStyle style;
    String text = value.toString();

    if (value is String) {
      style = const TextStyle(color: Colors.teal);
      text = '"$value"';

      // Handle URLs
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return TextSpan(
          text: text,
          style: style.copyWith(
              color: isDark ? Colors.blue[300] : Colors.blue[700],
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'monospace'),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              // URL Preview logic (same as in raw view)
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: Text(value, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    body: Center(
                      child: InteractiveViewer(
                        child: Image.network(
                          value,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Failed to load preview.\nThis URL might not be an image.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
        );
      }
    } else if (value is num) {
      style = const TextStyle(color: Colors.orange);
    } else if (value is bool || value == null) {
      style = const TextStyle(color: Colors.redAccent);
    } else {
      style = TextStyle(color: isDark ? Colors.white : Colors.black87);
    }

    final baseStyle = style.copyWith(fontSize: 12, fontFamily: 'monospace');

    // Apply search highlight
    if (widget.searchQuery.isNotEmpty &&
        text.toLowerCase().contains(widget.searchQuery)) {
      final lowerText = text.toLowerCase();
      int index = lowerText.indexOf(widget.searchQuery);
      final List<InlineSpan> spans = [];
      int start = 0;
      final highlightStyle = baseStyle.copyWith(
          backgroundColor: Colors.yellow, color: Colors.black);

      while (index != -1) {
        if (index > start) {
          spans.add(
              TextSpan(text: text.substring(start, index), style: baseStyle));
        }
        spans.add(TextSpan(
            text: text.substring(index, index + widget.searchQuery.length),
            style: highlightStyle));
        start = index + widget.searchQuery.length;
        index = lowerText.indexOf(widget.searchQuery, start);
      }
      if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
      }
      return TextSpan(children: spans);
    }

    return TextSpan(text: text, style: baseStyle);
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
