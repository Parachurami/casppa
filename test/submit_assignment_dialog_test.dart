import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/domain/assignments/params/create_submission_params.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';
import 'package:casppa/app/domain/assignments/usecases/create_submission_usecase.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';
import 'package:casppa/app/presentation/assignments/widgets/submit_assignment_dialog.dart';

class _DummyAssignmentsRepository implements AssignmentsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeCreateSubmissionUseCase extends CreateSubmissionUseCase {
  _FakeCreateSubmissionUseCase() : super(_DummyAssignmentsRepository());

  CreateSubmissionParams? lastParams;

  @override
  ResultVoid call(CreateSubmissionParams params) async {
    lastParams = params;
    return const Right(null);
  }
}

void main() {
  testWidgets('attaching a file simulates loading then shows the uploaded state', (
    WidgetTester tester,
  ) async {
    final fakeUseCase = _FakeCreateSubmissionUseCase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createSubmissionUseCaseProvider.overrideWithValue(fakeUseCase),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => SubmitAssignmentDialog(
                    assignment: StudentAssignmentEntity(
                      id: 'a1',
                      title: 'Linear Algebra',
                      description: 'desc',
                      subject: 'Mathematics',
                      teacherName: 'Mr. Adamu',
                      teacherId: 'teacher-1',
                      dueDate: DateTime(2026, 7, 23),
                      submissionStatus: StudentSubmissionStatus.notSubmitted,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Submit Assignment'), findsOneWidget);
    expect(
      find.text('Click to attach photo, PDF, or document (max 5MB)'),
      findsOneWidget,
    );

    final attachFinder = find.text(
      'Click to attach photo, PDF, or document (max 5MB)',
    );
    await tester.ensureVisible(attachFinder);
    await tester.pumpAndSettle();
    await tester.tap(attachFinder);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    final submitFinder = find.text('Submit');
    await tester.ensureVisible(submitFinder);
    await tester.pumpAndSettle();
    await tester.tap(submitFinder);
    await tester.pumpAndSettle();

    expect(fakeUseCase.lastParams?.assignmentId, 'a1');
    expect(tester.takeException(), isNull);

    // Let toastification's own auto-dismiss timers finish so they don't
    // trip "pending timer" assertions when the test tears down.
    await tester.pump(const Duration(seconds: 4));
  });
}
