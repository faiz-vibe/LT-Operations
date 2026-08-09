import 'package:flutter_test/flutter_test.dart';
import 'package:transport_supervisor_app/main.dart'; // Aapka actual app import

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Apni app ke main class ka naam yahan likhein
    await tester.pumpWidget(const TransportSupervisorApp());

    // Check karein ki HomeScreen par 'New Vehicle' button hai ya nahi
    expect(find.text('New Vehicle'), findsOneWidget);
  });
}