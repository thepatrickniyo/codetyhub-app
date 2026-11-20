import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:codetyhub_app/app/controllers/auth_controller.dart';
import 'package:codetyhub_app/app/data/auth_service.dart';
import 'package:codetyhub_app/app/routes/app_routes.dart';
import 'package:codetyhub_app/app/views/auth/signup_view.dart';
import 'package:codetyhub_app/app/views/legal/privacy_terms_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    await GetStorage.init('PrivacyConsentTestContainer');
  });

  setUp(() {
    Get.reset();
    Get.put(AuthController(AuthService(GetStorage('PrivacyConsentTestContainer'))));
  });

  Future<void> pumpSignup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: AppRoutes.signup,
      getPages: [
        GetPage(name: AppRoutes.signup, page: () => const SignupView()),
        GetPage(name: AppRoutes.privacy, page: () => const PrivacyTermsView()),
      ],
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('PrivacyTermsView shows both tabs and switches content',
      (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: PrivacyTermsView(initialTab: 0)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.text('Information we collect'), findsOneWidget);

    await tester.tap(find.text('Terms of Use'));
    await tester.pumpAndSettle();
    expect(find.text('Acceptable use'), findsOneWidget);
  });

  testWidgets('Signup requires the consent checkbox', (tester) async {
    await pumpSignup(tester);

    expect(find.byKey(const Key('signup_terms_checkbox')), findsOneWidget);

    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    expect(
      find.text('You must accept the Privacy Policy and Terms to continue'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('signup_terms_checkbox')));
    await tester.pumpAndSettle();
    final checkbox =
        tester.widget<Checkbox>(find.byKey(const Key('signup_terms_checkbox')));
    expect(checkbox.value, isTrue);
  });

  testWidgets('Tapping the consent text links opens the privacy page',
      (tester) async {
    await pumpSignup(tester);

    final richText = find.byWidgetPredicate((w) =>
        w is RichText && w.text.toPlainText().contains('I have read and agree'));
    expect(richText, findsOneWidget);

    // Trigger the "Terms of Use" link's recognizer directly.
    final span = tester.widget<RichText>(richText).text as TextSpan;
    TextSpan? termsLink;
    span.visitChildren((child) {
      if (child is TextSpan && child.text == 'Terms of Use') termsLink = child;
      return true;
    });
    (termsLink!.recognizer as dynamic).onTap();
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyTermsView), findsOneWidget);
    expect(find.text('Acceptable use'), findsOneWidget); // Terms tab opened
  });
}
