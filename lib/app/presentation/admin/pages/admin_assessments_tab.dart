import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/widgets/skeleton_loader.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/presentation/admin/provider/admin_provider.dart';
import 'package:casppa/app/presentation/assignments/pages/assignment_details_page.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessment_type_tabs.dart';
import 'package:casppa/app/presentation/assignments/widgets/assessments_empty_state.dart';
import 'package:casppa/app/presentation/assignments/widgets/assignment_card.dart';

class AdminAssessmentsTab extends StatefulWidget {
  const AdminAssessmentsTab({super.key});

  @override
  State<AdminAssessmentsTab> createState() => _AdminAssessmentsTabState();
}

class _AdminAssessmentsTabState extends State<AdminAssessmentsTab> {
  AssessmentTab _selectedTab = AssessmentTab.assignments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assessments', style: AppTextStyles.heading),
                  const SizedBox(height: 8),
                  Text(
                    'School-wide assignments and CBTs — view only',
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
            Expanded(child: _AssessmentsList(tab: _selectedTab)),
          ],
        ),
      ),
    );
  }
}

class _AssessmentsList extends ConsumerWidget {
  const _AssessmentsList({required this.tab});

  final AssessmentTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsState = ref.watch(allAssessmentsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allAssessmentsProvider);
        await ref.read(allAssessmentsProvider.future);
      },
      child: assessmentsState.when(
        loading: () => _loadingContent,
        error: (error, _) => assessmentsState.isLoading
            ? _loadingContent
            : ListView(
                children: [
                  const SizedBox(height: 80),
                  AssessmentsEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load assessments',
                    message: 'Check your connection and try again.',
                    ctaLabel: 'Retry',
                    onPressed: () => ref.invalidate(allAssessmentsProvider),
                  ),
                ],
              ),
        data: (assessments) {
          final filtered = assessments
              .where((assessment) => _matchesTab(assessment.type))
              .toList();

          if (filtered.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                AssessmentsEmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'Nothing here yet',
                  message: 'Teachers haven\'t posted any of these yet.',
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => AssignmentCard(
              assignment: filtered[index],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AssignmentDetailsPage(
                    assignment: filtered[index],
                    readOnly: true,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget get _loadingContent =>
      ShimmerList(itemBuilder: (context, index) => const AssignmentCardSkeleton());

  bool _matchesTab(AssignmentType type) {
    switch (tab) {
      case AssessmentTab.assignments:
        return type == AssignmentType.assignment;
      case AssessmentTab.cbtExams:
        return type == AssignmentType.cbt;
      case AssessmentTab.quickTests:
        return type == AssignmentType.quickTest;
    }
  }
}
