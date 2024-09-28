import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_app/main.dart'; // Ensure this path is correct

void main() {
  testWidgets('CanvasPainting smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(CanvasPainting());

    // Check if the specific CustomPaint is displayed.
    expect(find.byKey(Key('drawingCanvas')), findsOneWidget);

    // Check if the clear button is present.
    expect(find.byIcon(Icons.clear), findsOneWidget);
  });
}
