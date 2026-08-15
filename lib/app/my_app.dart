import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_theme.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/presentation/admin/pages/admin_shell.dart';
import 'package:casppa/app/presentation/assignments/pages/student_assessments_page.dart';
import 'package:casppa/app/presentation/assignments/pages/teacher_assessments_page.dart';
import 'package:casppa/app/presentation/auth/pages/login_page.dart';
import 'package:casppa/app/presentation/auth/provider/auth_provider.dart';
import 'package:casppa/app/presentation/notifications/widgets/realtime_notifications_gate.dart';
import 'package:casppa/app/presentation/onboarding/pages/onboarding_page.dart';
import 'package:casppa/app/presentation/onboarding/provider/onboarding_provider.dart';
import 'package:casppa/app/presentation/parent/pages/parent_dashboard_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Casppa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppRoot(),
    );
  }
}

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingNotifierProvider);

    return onboardingState.when(
      loading: () => const DashboardSkeleton(),
      error: (error, stackTrace) => const OnboardingPage(),
      data: (hasCompleted) =>
          hasCompleted ? const _AuthGate() : const OnboardingPage(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      loading: () => const DashboardSkeleton(),
      error: (error, stackTrace) => const LoginPage(),
      data: (user) {
        if (user == null) return const LoginPage();

        final dashboard = switch (user.role) {
          UserRole.teacher => const TeacherAssessmentsPage(),
          UserRole.student => const StudentAssessmentsPage(),
          UserRole.admin => const AdminShell(),
          UserRole.parent => const ParentDashboardPage(),
        };

        return RealtimeNotificationsGate(userId: user.id, child: dashboard);
      },
    );
  }
}
