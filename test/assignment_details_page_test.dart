import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/presentation/assignments/pages/assignment_details_page.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';

void main() {
  testWidgets('renders the roster with submission status', (
    WidgetTester tester,
  ) async {
    final assignment = AssignmentEntity(
      id: 'a1',
      type: AssignmentType.assignment,
      status: AssignmentStatus.published,
      title: 'Linear Algebra',
      description: 'Answer question one to question 5 in section A.',
      classId: 'c1',
      className: 'Primary 1',
      subject: 'Mathematics',
      dueDate: DateTime(2026, 8, 3),
      createdBy: 'teacher-1',
      expectedSubmissions: 2,
      submittedCount: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assignmentSubmissionsProvider((
            assignmentId: 'a1',
            classId: 'c1',
          )).overrideWith(
            (ref) async => const [
              StudentSubmissionEntity(
                studentId: 's1',
                studentName: 'Daniel Eze',
                status: StudentSubmissionStatus.notSubmitted,
              ),
              StudentSubmissionEntity(
                studentId: 's2',
                studentName: 'Ibrahim Musa',
                status: StudentSubmissionStatus.notSubmitted,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          home: AssignmentDetailsPage(assignment: assignment),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Linear Algebra'), findsOneWidget);
    expect(find.text('SUBMISSIONS (0/2)'), findsOneWidget);
    expect(find.text('Daniel Eze'), findsOneWidget);
    expect(find.text('Ibrahim Musa'), findsOneWidget);
    expect(find.text('Not submitted'), findsNWidgets(2));
    expect(find.text('Pending'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
