import 'package:flutter_test/flutter_test.dart';
import 'package:lt_operations/main.dart'; // Naya project name lagaya hai

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Apni app ke main class ka naam yahan likhein
    await tester.pumpWidget(const TransportSupervisorApp());

    // Check karein ki Home screen par text hai ya nahi
    expect(find.text('Transport Supervisor'), findsOneWidget);
  });
}