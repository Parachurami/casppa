import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/theme/app_theme.dart';
import 'package:casppa/app/core/widgets/primary_button.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/presentation/admin/pages/admin_shell.dart';
import 'package:casppa/app/presentation/assignments/pages/student_assessments_page.dart';
import 'package:casppa/app/presentation/assignments/pages/teacher_assessments_page.dart';
import 'package:casppa/app/presentation/auth/pages/login_page.dart';
import 'package:casppa/app/presentation/auth/provider/auth_provider.dart';
import 'package:casppa/app/presentation/onboarding/pages/onboarding_page.dart';
import 'package:casppa/app/presentation/onboarding/provider/onboarding_provider.dart';

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

        return switch (user.role) {
          UserRole.teacher => const TeacherAssessmentsPage(),
          UserRole.student => const StudentAssessmentsPage(),
          UserRole.admin => const AdminShell(),
          UserRole.parent => _RoleComingSoonPage(user: user),
        };
      },
    );
  }
}

class _RoleComingSoonPage extends ConsumerStatefulWidget {
  const _RoleComingSoonPage({required this.user});

  final UserEntity user;

  @override
  ConsumerState<_RoleComingSoonPage> createState() =>
      _RoleComingSoonPageState();
}

class _RoleComingSoonPageState extends ConsumerState<_RoleComingSoonPage> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    await ref.read(authNotifierProvider.notifier).logout();

    if (!mounted) return;
    setState(() => _isLoggingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "You're signed in as ${widget.user.role.name}",
                textAlign: TextAlign.center,
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 8),
              Text(
                'This role\'s dashboard is coming soon.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Log out',
                isLoading: _isLoggingOut,
                onPressed: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
