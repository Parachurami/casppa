import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/string_formatting.dart';
import 'package:casppa/app/core/widgets/primary_button.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/presentation/assignments/pages/assignment_details_page.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessment_type_tabs.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessments_empty_state.dart';
import 'package:casppa/app/presentation/assignments/widgets/assignment_card.dart';
import 'package:casppa/app/presentation/assignments/widgets/assignment_form_sheet.dart';
import 'package:casppa/app/presentation/assignments/widgets/cbt_form_sheet.dart';
import 'package:casppa/app/presentation/auth/pages/profile_page.dart';
import 'package:casppa/app/presentation/auth/provider/auth_provider.dart';
import 'package:casppa/app/presentation/notifications/pages/notifications_page.dart';
import 'package:casppa/app/presentation/notifications/provider/notifications_provider.dart';

class TeacherAssessmentsPage extends ConsumerStatefulWidget {
  const TeacherAssessmentsPage({super.key});

  @override
  ConsumerState<TeacherAssessmentsPage> createState() =>
      _TeacherAssessmentsPageState();
}

class _TeacherAssessmentsPageState extends ConsumerState<TeacherAssessmentsPage>
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
      ref.invalidate(teacherAssignmentsProvider);
      ref.invalidate(teacherCbtsProvider);
    }
  }

  void _openAssignmentFormSheet({AssignmentEntity? assignment}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AssignmentFormSheet(assignment: assignment),
    );
  }

  void _openCbtFormSheet({AssignmentEntity? assignment}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CbtFormSheet(assignment: assignment),
    );
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

  void _openAssignmentDetails(AssignmentEntity assignment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssignmentDetailsPage(assignment: assignment),
      ),
    );
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
                  const Text('Teacher', style: AppTextStyles.heading),
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
                  Text('Assessments', style: AppTextStyles.heading),
                  const SizedBox(height: 8),
                  Text(
                    'Assignments, CBT exams, and formative quick tests in one place',
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
      bottomNavigationBar: _selectedTab == AssessmentTab.quickTests
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: PrimaryButton(
                  label: _selectedTab == AssessmentTab.cbtExams
                      ? '+ New CBT'
                      : '+ New Assignment',
                  onPressed: _selectedTab == AssessmentTab.cbtExams
                      ? () => _openCbtFormSheet()
                      : () => _openAssignmentFormSheet(),
                ),
              ),
            ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case AssessmentTab.assignments:
        return _AssignmentsList(
          onEdit: (assignment) =>
              _openAssignmentFormSheet(assignment: assignment),
          onTap: _openAssignmentDetails,
        );
      case AssessmentTab.cbtExams:
        return _CbtsList(
          onEdit: (assignment) => _openCbtFormSheet(assignment: assignment),
          onTap: _openAssignmentDetails,
        );
      case AssessmentTab.quickTests:
        return const AssessmentsEmptyState(
          icon: Icons.bolt_outlined,
          title: 'Quick tests coming soon',
          message: 'Formative quick tests will show up here.',
        );
    }
  }
}

class _AssignmentsList extends ConsumerWidget {
  const _AssignmentsList({required this.onEdit, required this.onTap});

  final ValueChanged<AssignmentEntity> onEdit;
  final ValueChanged<AssignmentEntity> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsState = ref.watch(teacherAssignmentsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teacherAssignmentsProvider);
        await ref.read(teacherAssignmentsProvider.future);
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
              children: [
                const SizedBox(height: 80),
                const AssessmentsEmptyState(
                  title: 'No assignments yet',
                  message: 'Create your first assignment to get started.',
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: assignments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => AssignmentCard(
              assignment: assignments[index],
              onTap: () => onTap(assignments[index]),
              onEdit: () => onEdit(assignments[index]),
            ),
          );
        },
      ),
    );
  }
}

class _CbtsList extends ConsumerWidget {
  const _CbtsList({required this.onEdit, required this.onTap});

  final ValueChanged<AssignmentEntity> onEdit;
  final ValueChanged<AssignmentEntity> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cbtsState = ref.watch(teacherCbtsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teacherCbtsProvider);
        await ref.read(teacherCbtsProvider.future);
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
              children: [
                const SizedBox(height: 80),
                const AssessmentsEmptyState(
                  icon: Icons.quiz_outlined,
                  title: 'No CBTs yet',
                  message: 'Create your first computer-based test.',
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: cbts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => AssignmentCard(
              assignment: cbts[index],
              onTap: () => onTap(cbts[index]),
              onEdit: () => onEdit(cbts[index]),
            ),
          );
        },
      ),
    );
  }
}
