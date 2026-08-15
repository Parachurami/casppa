import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/presentation/assignments/pages/student_assessments_page.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';
import 'package:casppa/app/presentation/auth/provider/auth_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<UserEntity?> build() async => const UserEntity(
    id: 'student-1',
    email: 'tobi@casppa.dev',
    name: 'Tobi Okafor',
    role: UserRole.student,
  );
}

void main() {
  testWidgets('renders student assignment cards with the right actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          studentAssignmentsProvider.overrideWith(
            (ref) async => [
              StudentAssignmentEntity(
                id: 'a1',
                title: 'Essay: My Future Career',
                description: 'Write a 300-word essay.',
                subject: 'English Language',
                teacherName: 'Miss Chioma Okeke',
                teacherId: 'teacher-1',
                dueDate: DateTime(2026, 7, 25),
                submissionStatus: StudentSubmissionStatus.submitted,
              ),
              StudentAssignmentEntity(
                id: 'a2',
                title: 'Linear Algebra',
                description: 'Answer section A and one from B.',
                subject: 'Mathematics',
                teacherName: 'Mr. Adamu Ibrahim',
                teacherId: 'teacher-2',
                dueDate: DateTime.now().subtract(const Duration(days: 2)),
                submissionStatus: StudentSubmissionStatus.notSubmitted,
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: StudentAssessmentsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student'), findsOneWidget);
    expect(find.text('My Assessments'), findsOneWidget);
    expect(find.text('Essay: My Future Career'), findsOneWidget);
    expect(find.text('Awaiting Grade'), findsOneWidget);
    expect(find.text('Linear Algebra'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
    expect(find.text('TO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
