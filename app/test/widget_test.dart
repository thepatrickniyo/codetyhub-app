import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codetyhub_app/app/widgets/common_widgets.dart';

void main() {
  testWidgets('PrimaryButton renders label and handles tap', (WidgetTester tester) async {
    bool pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Submit Code',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Submit Code'), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    expect(pressed, isTrue);
  });

  testWidgets('PrimaryButton displays CircularProgressIndicator when isLoading is true', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Loading state',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading state'), findsNothing);
  });

  testWidgets('CustomTextField renders label and hint correctly', (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            controller: controller,
            label: 'Student Email',
            hint: 'enter your email',
          ),
        ),
      ),
    );

    expect(find.text('Student Email'), findsOneWidget);
    expect(find.text('enter your email'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'test@codetyhub.com');
    expect(controller.text, equals('test@codetyhub.com'));
  });
}
