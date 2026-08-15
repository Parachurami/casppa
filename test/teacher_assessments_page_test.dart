import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/class_option_entity.dart';
import 'package:casppa/app/domain/assignments/entities/subject_option_entity.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/presentation/assignments/pages/teacher_assessments_page.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';
import 'package:casppa/app/presentation/auth/provider/auth_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<UserEntity?> build() async => const UserEntity(
    id: 'teacher-1',
    email: 'mary@casppa.dev',
    name: 'Mary Adeyemi',
    role: UserRole.teacher,
  );
}

class _FakeAssignmentsNotifier extends TeacherAssignmentsNotifier {
  _FakeAssignmentsNotifier(this._assignments);

  final List<AssignmentEntity> _assignments;

  @override
  Future<List<AssignmentEntity>> build() async => _assignments;
}

AssignmentEntity _sampleAssignment({required DateTime dueDate}) {
  return AssignmentEntity(
    id: 'a1',
    type: AssignmentType.assignment,
    status: AssignmentStatus.published,
    title: 'Algebra Practice - Set 3',
    description: 'Solve exercises 1-15 from page 42 of your textbook.',
    classId: 'c1',
    className: 'JSS 1',
    subject: 'Mathematics',
    dueDate: dueDate,
    createdBy: 'teacher-1',
    expectedSubmissions: 2,
    submittedCount: 2,
  );
}

void main() {
  testWidgets('renders assignment cards when data exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          teacherAssignmentsProvider.overrideWith(
            () => _FakeAssignmentsNotifier([
              _sampleAssignment(
                dueDate: DateTime.now().subtract(const Duration(days: 2)),
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: TeacherAssessmentsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Algebra Practice - Set 3'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('MA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders empty state with CTA when there is no data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          teacherAssignmentsProvider.overrideWith(
            () => _FakeAssignmentsNotifier([]),
          ),
        ],
        child: const MaterialApp(home: TeacherAssessmentsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No assignments yet'), findsOneWidget);
    expect(find.text('+ New Assignment'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a card opens the assessment details page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          teacherAssignmentsProvider.overrideWith(
            () => _FakeAssignmentsNotifier([
              _sampleAssignment(
                dueDate: DateTime.now().add(const Duration(days: 5)),
              ),
            ]),
          ),
          assignmentSubmissionsProvider((
            assignmentId: 'a1',
            classId: 'c1',
          )).overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: TeacherAssessmentsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Algebra Practice - Set 3'));
    await tester.pumpAndSettle();

    expect(find.text('INSTRUCTIONS'), findsOneWidget);
    expect(find.text('SUBMISSIONS (0/0)'), findsOneWidget);
    expect(find.text('Edit Assignment'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the edit icon opens the edit sheet pre-filled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          teacherAssignmentsProvider.overrideWith(
            () => _FakeAssignmentsNotifier([
              _sampleAssignment(
                dueDate: DateTime.now().add(const Duration(days: 5)),
              ),
            ]),
          ),
          classOptionsProvider.overrideWith(
            (ref) async => const <ClassOptionEntity>[],
          ),
          subjectOptionsProvider.overrideWith(
            (ref) async => const <SubjectOptionEntity>[],
          ),
        ],
        child: const MaterialApp(home: TeacherAssessmentsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Edit Assignment'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Algebra Practice - Set 3'),
      findsOneWidget,
    );

    await tester.dragUntilVisible(
      find.text('Save Changes'),
      find.byType(ListView).last,
      const Offset(0, -200),
    );

    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Delete Assignment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the avatar opens the profile page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          teacherAssignmentsProvider.overrideWith(
            () => _FakeAssignmentsNotifier([]),
          ),
        ],
        child: const MaterialApp(home: TeacherAssessmentsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('MA'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('mary@casppa.dev'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
