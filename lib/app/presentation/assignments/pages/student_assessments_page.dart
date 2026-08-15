import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/string_formatting.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/presentation/assignments/pages/cbt_results_page.dart';
import 'package:casppa/app/presentation/assignments/pages/cbt_taking_page.dart';
import 'package:casppa/app/presentation/assignments/pages/student_feedback_page.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessment_type_tabs.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessments_empty_state.dart';
import 'package:casppa/app/presentation/assignments/widgets/student_assignment_card.dart';
import 'package:casppa/app/presentation/assignments/widgets/student_cbt_card.dart';
import 'package:casppa/app/presentation/assignments/widgets/submit_assignment_dialog.dart';
import 'package:casppa/app/presentation/auth/pages/profile_page.dart';
import 'package:casppa/app/presentation/auth/provider/auth_provider.dart';
import 'package:casppa/app/presentation/notifications/pages/notifications_page.dart';
import 'package:casppa/app/presentation/notifications/provider/notifications_provider.dart';

class StudentAssessmentsPage extends ConsumerStatefulWidget {
  const StudentAssessmentsPage({super.key});

  @override
  ConsumerState<StudentAssessmentsPage> createState() =>
      _StudentAssessmentsPageState();
}

class _StudentAssessmentsPageState extends ConsumerState<StudentAssessmentsPage>
    with WidgetsBindingObserver {
  AssessmentTab _selectedTab = AssessmentTab.assignments;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(studentAssignmentsProvider);
      ref.invalidate(studentCbtsProvider);
    }
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfilePage()));
  }

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const NotificationsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authNotifierProvider).valueOrNull;
    final initials = currentUser == null
        ? ''
        : initialsFromName(currentUser.name);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Student', style: AppTextStyles.heading),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: _openNotifications,
                            icon: const Icon(Icons.notifications_none),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                height: 8,
                                width: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _openProfile,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Assessments', style: AppTextStyles.heading),
                  const SizedBox(height: 8),
                  Text(
                    'Assignments, exams, and quick tests',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AssessmentTypeTabs(
                    selected: _selectedTab,
                    onChanged: (tab) => setState(() => _selectedTab = tab),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case AssessmentTab.assignments:
        return const _StudentAssignmentsList();
      case AssessmentTab.cbtExams:
        return const _StudentCbtsList();
      case AssessmentTab.quickTests:
        return const AssessmentsEmptyState(
          icon: Icons.bolt_outlined,
          title: 'Quick tests coming soon',
          message: 'Formative quick tests will show up here.',
        );
    }
  }
}

class _StudentAssignmentsList extends ConsumerWidget {
  const _StudentAssignmentsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsState = ref.watch(studentAssignmentsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentAssignmentsProvider);
        await ref.read(studentAssignmentsProvider.future);
      },
      child: assignmentsState.when(
        loading: () => ShimmerList(
          itemBuilder: (context, index) => const AssignmentCardSkeleton(),
        ),
        error: (error, _) => ListView(
          children: [
            const SizedBox(height: 80),
            Center(child: Text('Could not load assignments.\n$error')),
          ],
        ),
        data: (assignments) {
          if (assignments.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                AssessmentsEmptyState(
                  title: 'No assignments yet',
                  message: "Your teacher hasn't posted anything here yet.",
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: assignments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => StudentAssignmentCard(
              assignment: assignments[index],
              onSubmit: () async {
                final submitted = await showDialog<bool>(
                  context: context,
                  builder: (_) =>
                      SubmitAssignmentDialog(assignment: assignments[index]),
                );
                if (submitted == true) {
                  ref.invalidate(studentAssignmentsProvider);
                }
              },
              onViewFeedback: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      StudentFeedbackPage(assignment: assignments[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StudentCbtsList extends ConsumerWidget {
  const _StudentCbtsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cbtsState = ref.watch(studentCbtsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentCbtsProvider);
        await ref.read(studentCbtsProvider.future);
      },
      child: cbtsState.when(
        loading: () => ShimmerList(
          itemBuilder: (context, index) => const AssignmentCardSkeleton(),
        ),
        error: (error, _) => ListView(
          children: [
            const SizedBox(height: 80),
            Center(child: Text('Could not load CBTs.\n$error')),
          ],
        ),
        data: (cbts) {
          if (cbts.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                AssessmentsEmptyState(
                  icon: Icons.quiz_outlined,
                  title: 'No CBTs yet',
                  message: "Your teacher hasn't posted a test here yet.",
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: cbts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => StudentCbtCard(
              assignment: cbts[index],
              onStart: () async {
                final submitted = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => CbtTakingPage(assignment: cbts[index]),
                  ),
                );
                if (submitted == true) {
                  ref.invalidate(studentCbtsProvider);
                }
              },
              onViewResults: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CbtResultsPage(assignment: cbts[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
