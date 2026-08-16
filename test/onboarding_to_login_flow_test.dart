import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/domain/auth/params/auth_login_params.dart';
import 'package:casppa/app/domain/notifications/entities/notification_entity.dart';
import 'package:casppa/app/my_app.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';
import 'package:casppa/app/presentation/auth/provider/auth_provider.dart';
import 'package:casppa/app/presentation/notifications/provider/notifications_provider.dart';
import 'package:casppa/app/presentation/onboarding/provider/onboarding_provider.dart';

const _teacher = UserEntity(
  id: 'teacher-1',
  email: 'chioma@casppa.dev',
  name: 'Chioma Okeke',
  role: UserRole.teacher,
);

/// Starts signed out, then hands back [_teacher] on login — mirroring the real
/// notifier, which sets `AsyncData(user)` and leaves the routing to
/// `_AuthGate`.
class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<UserEntity?> build() async => null;

  @override
  Future<void> login(AuthLoginParams params) async {
    state = const AsyncData(_teacher);
  }
}

class _FakeOnboardingNotifier extends OnboardingNotifier {
  @override
  Future<bool> build() async => false;

  @override
  Future<void> complete() async {
    state = const AsyncData(true);
  }
}

class _EmptyAssignmentsNotifier extends TeacherAssignmentsNotifier {
  @override
  Future<List<AssignmentEntity>> build() async => const [];
}

class _EmptyCbtsNotifier extends TeacherCbtsNotifier {
  @override
  Future<List<AssignmentEntity>> build() async => const [];
}

class _EmptyNotificationsNotifier extends NotificationsNotifier {
  @override
  Future<List<NotificationEntity>> build() async => const [];
}

void main() {
  testWidgets('logging in right after onboarding routes to the dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          onboardingNotifierProvider.overrideWith(_FakeOnboardingNotifier.new),
          teacherAssignmentsProvider.overrideWith(
            _EmptyAssignmentsNotifier.new,
          ),
          teacherCbtsProvider.overrideWith(_EmptyCbtsNotifier.new),
          notificationsProvider.overrideWith(_EmptyNotificationsNotifier.new),
          newNotificationsStreamProvider(
            _teacher.id,
          ).overrideWith((ref) => const Stream<NotificationEntity>.empty()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Walk the three onboarding slides.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'chioma@casppa.dev',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    // Regression: onboarding used to pushReplacement a LoginPage over the root
    // route, ripping AppRoot (and _AuthGate) out of the tree — so a successful
    // login left the user staring at the login form.
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Assessments'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
