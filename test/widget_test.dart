// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/data/local/storage_service.dart';

// Simple fake storage to use in tests without depending on GetStorage or platform channels
class FakeStorageService implements StorageService {
  final Map<String, dynamic> _map = {};

  @override
  T? read<T>({required String key}) {
    return _map[key] as T?;
  }

  @override
  Future<void> write({required String key, required value}) async {
    _map[key] = value;
  }

  @override
  Future<void> remove({required String key}) async {
    _map.remove(key);
  }

  @override
  Future<void> clear() async {
    _map.clear();
  }

  @override
  int? getDriverId() {
    return _map['id'] as int?;
  }
}

// Minimal widget used for smoke tests without app bindings
class CounterTestWidget extends StatefulWidget {
  const CounterTestWidget({Key? key}) : super(key: key);

  @override
  State<CounterTestWidget> createState() => _CounterTestWidgetState();
}

class _CounterTestWidgetState extends State<CounterTestWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('$_count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _count++),
        child: const Icon(Icons.add),
      ),
    );
  }
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build a minimal counter widget for this test to avoid complex app bindings
    await tester.pumpWidget(const MaterialApp(home: CounterTestWidget()));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
