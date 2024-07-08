import 'package:crop_lib_dart/crop_your_image.dart';
import '../lib/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Show Crop', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CropSample(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Crop), findsOneWidget);
  });
}
