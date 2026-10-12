import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_network_debugger/flutter_network_debugger.dart';

void main() {
  setUp(() {
    NetworkMonitorCore.instance.clear();
  });

  tearDown(() {
    NetworkMonitorCore.instance.clear();
  });

  group('NetworkCall toCurl tests', () {
    test('generates basic GET curl command', () {
      final call = NetworkCall(
        id: '1',
        type: NetworkCallType.http,
        url: 'https://example.com/api/users',
        method: 'GET',
        requestTime: DateTime(2026, 1, 1),
      );

      expect(call.toCurl(), 'curl -X GET "https://example.com/api/users"');
    });

    test('generates curl command with headers and body', () {
      final call = NetworkCall(
        id: '2',
        type: NetworkCallType.http,
        url: 'https://example.com/api/login',
        method: 'POST',
        requestTime: DateTime(2026, 1, 1),
      );
      call.requestHeaders = {'Authorization': 'Bearer test-token'};
      call.requestBody = {'username': 'test_user'};

      final curl = call.toCurl();
      expect(curl, contains('curl -X POST "https://example.com/api/login"'));
      expect(curl, contains('-H "Authorization: Bearer test-token"'));
      expect(curl, contains("-d '{\"username\":\"test_user\"}'"));
    });
  });

  group('NetworkMonitorCore tests', () {
    test('removeCall deletes call by id and notifies listeners', () {
      final call1 = NetworkCall(
        id: 'call-1',
        type: NetworkCallType.http,
        url: 'https://example.com/1',
        method: 'GET',
        requestTime: DateTime.now(),
      );
      final call2 = NetworkCall(
        id: 'call-2',
        type: NetworkCallType.http,
        url: 'https://example.com/2',
        method: 'GET',
        requestTime: DateTime.now(),
      );

      NetworkMonitorCore.instance.addCall(call1);
      NetworkMonitorCore.instance.addCall(call2);
      expect(NetworkMonitorCore.instance.calls.value.length, 2);

      NetworkMonitorCore.instance.removeCall('call-1');
      expect(NetworkMonitorCore.instance.calls.value.length, 1);
      expect(NetworkMonitorCore.instance.calls.value.first.id, 'call-2');
    });

    test('insertCall restores call at specific index', () {
      final call1 = NetworkCall(
        id: 'call-1',
        type: NetworkCallType.http,
        url: 'https://example.com/1',
        method: 'GET',
        requestTime: DateTime.now(),
      );
      final call2 = NetworkCall(
        id: 'call-2',
        type: NetworkCallType.http,
        url: 'https://example.com/2',
        method: 'GET',
        requestTime: DateTime.now(),
      );

      NetworkMonitorCore.instance.addCall(call1);
      NetworkMonitorCore.instance.insertCall(0, call2);

      expect(NetworkMonitorCore.instance.calls.value.length, 2);
      expect(NetworkMonitorCore.instance.calls.value[0].id, 'call-2');
      expect(NetworkMonitorCore.instance.calls.value[1].id, 'call-1');
    });
  });

  group('NetworkMonitorScreen swipe actions tests', () {
    testWidgets('Swipe to delete removes item from monitor and allows undo',
        (WidgetTester tester) async {
      final call1 = NetworkCall(
        id: 'call-1',
        type: NetworkCallType.http,
        url: 'https://example.com/posts',
        method: 'GET',
        requestTime: DateTime.now(),
      );
      final call2 = NetworkCall(
        id: 'call-2',
        type: NetworkCallType.http,
        url: 'https://example.com/users',
        method: 'POST',
        requestTime: DateTime.now(),
      );

      NetworkMonitorCore.instance.addCall(call1);
      NetworkMonitorCore.instance.addCall(call2);

      await tester.pumpWidget(
        const MaterialApp(
          home: NetworkMonitorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('/users'), findsOneWidget);
      expect(find.text('/posts'), findsOneWidget);

      // Swipe right-to-left on /users (first item) to delete
      await tester.drag(find.text('/users'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Verified removed from UI and core list
      expect(find.text('/users'), findsNothing);
      expect(find.text('/posts'), findsOneWidget);
      expect(NetworkMonitorCore.instance.calls.value.length, 1);

      // Verify SnackBar and UNDO button appear
      expect(find.text('UNDO'), findsOneWidget);

      // Tap UNDO
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();

      // Call is restored
      expect(find.text('/users'), findsOneWidget);
      expect(NetworkMonitorCore.instance.calls.value.length, 2);
    });

    testWidgets('Swipe left-to-right copies cURL and does not delete item',
        (WidgetTester tester) async {
      final List<String> clipboardLog = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          clipboardLog.add(methodCall.arguments['text'] as String);
          return null;
        }
        return null;
      });

      final call = NetworkCall(
        id: 'curl-call',
        type: NetworkCallType.http,
        url: 'https://example.com/feed',
        method: 'GET',
        requestTime: DateTime.now(),
      );
      NetworkMonitorCore.instance.addCall(call);

      await tester.pumpWidget(
        const MaterialApp(
          home: NetworkMonitorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe left-to-right
      await tester.drag(find.text('/feed'), const Offset(500, 0));
      await tester.pumpAndSettle();

      // Clipboard was called with curl
      expect(clipboardLog, isNotEmpty);
      expect(clipboardLog.last, contains('curl -X GET "https://example.com/feed"'));

      // Item should still remain in list
      expect(find.text('/feed'), findsOneWidget);
      expect(NetworkMonitorCore.instance.calls.value.length, 1);
    });

    testWidgets('enableSwipeToDelete: false disables swipe-to-delete',
        (WidgetTester tester) async {
      final call = NetworkCall(
        id: 'no-delete-call',
        type: NetworkCallType.http,
        url: 'https://example.com/protected',
        method: 'GET',
        requestTime: DateTime.now(),
      );
      NetworkMonitorCore.instance.addCall(call);

      await tester.pumpWidget(
        const MaterialApp(
          home: NetworkMonitorScreen(enableSwipeToDelete: false, enableSwipeToCopy: false),
        ),
      );
      await tester.pumpAndSettle();

      // Try dragging right to left
      await tester.drag(find.text('/protected'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Item must still exist
      expect(find.text('/protected'), findsOneWidget);
      expect(NetworkMonitorCore.instance.calls.value.length, 1);
    });
  });
}
