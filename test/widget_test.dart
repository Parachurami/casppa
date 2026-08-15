import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:casppa/app/domain/assignments/entities/class_option_entity.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/my_app.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';
import 'package:casppa/app/presentation/auth/provider/auth_provider.dart';
import 'package:casppa/app/presentation/onboarding/provider/onboarding_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<UserEntity?> build() async => null;
}

class _FakeOnboardingNotifier extends OnboardingNotifier {
  _FakeOnboardingNotifier({this.hasCompleted = true});

  final bool hasCompleted;

  @override
  Future<bool> build() async => hasCompleted;

  @override
  Future<void> complete() async {
    state = const AsyncData(true);
  }
}

void main() {
  testWidgets('renders the login page', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          onboardingNotifierProvider.overrideWith(
            _FakeOnboardingNotifier.new,
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('renders the onboarding page on first run', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          onboardingNotifierProvider.overrideWith(
            () => _FakeOnboardingNotifier(hasCompleted: false),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('walks through onboarding -> login -> sign up', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          onboardingNotifierProvider.overrideWith(
            () => _FakeOnboardingNotifier(hasCompleted: false),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assignments & CBT, in one place'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Mark with inline comments'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Everyone stays in the loop'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Parent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-up only shows the class picker for the student role', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          onboardingNotifierProvider.overrideWith(
            () => _FakeOnboardingNotifier(hasCompleted: false),
          ),
          allClassOptionsProvider.overrideWith(
            (ref) async => const [
              ClassOptionEntity(id: 'c1', name: 'Primary 1'),
            ],
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Teacher'));
    await tester.pumpAndSettle();
    expect(find.text('Class'), findsNothing);

    await tester.tap(find.text('Student'));
    await tester.pumpAndSettle();
    expect(find.text('Class'), findsOneWidget);
    expect(
      find.byType(DropdownButtonFormField<ClassOptionEntity>),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
