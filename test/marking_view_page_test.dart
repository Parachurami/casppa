import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/domain/assignments/entities/submission_annotation_entity.dart';
import 'package:casppa/app/domain/assignments/params/add_annotation_params.dart';
import 'package:casppa/app/domain/assignments/params/update_annotation_params.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';
import 'package:casppa/app/domain/assignments/usecases/add_annotation_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/delete_annotation_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/update_annotation_usecase.dart';
import 'package:casppa/app/presentation/assignments/pages/marking_view_page.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';

class _DummyAssignmentsRepository implements AssignmentsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeAddAnnotationUseCase extends AddAnnotationUseCase {
  _FakeAddAnnotationUseCase() : super(_DummyAssignmentsRepository());

  AddAnnotationParams? lastParams;

  @override
  ResultFuture<SubmissionAnnotationEntity> call(
    AddAnnotationParams params,
  ) async {
    lastParams = params;
    return Right(
      SubmissionAnnotationEntity(
        id: 'ann1',
        xPercent: params.xPercent,
        yPercent: params.yPercent,
        text: params.text,
        createdAt: DateTime(2026),
      ),
    );
  }
}

class _FakeUpdateAnnotationUseCase extends UpdateAnnotationUseCase {
  _FakeUpdateAnnotationUseCase() : super(_DummyAssignmentsRepository());

  UpdateAnnotationParams? lastParams;

  @override
  ResultVoid call(UpdateAnnotationParams params) async {
    lastParams = params;
    return const Right(null);
  }
}

class _FakeDeleteAnnotationUseCase extends DeleteAnnotationUseCase {
  _FakeDeleteAnnotationUseCase() : super(_DummyAssignmentsRepository());

  String? lastId;

  @override
  ResultVoid call(String params) async {
    lastId = params;
    return const Right(null);
  }
}

void main() {
  testWidgets('dropping a comment pin and saving calls addAnnotation', (
    WidgetTester tester,
  ) async {
    final fakeUseCase = _FakeAddAnnotationUseCase();

    const submission = StudentSubmissionEntity(
      studentId: 's1',
      studentName: 'Daniel Eze',
      status: StudentSubmissionStatus.submitted,
      submissionId: 'sub1',
      bodyText: 'the work is done',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addAnnotationUseCaseProvider.overrideWithValue(fakeUseCase),
          submissionAnnotationsProvider(
            'sub1',
          ).overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          home: MarkingViewPage(
            assignmentTitle: 'Linear Algebra',
            assignmentId: 'a1',
            classId: 'c1',
            submissions: const [submission],
            initialIndex: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daniel Eze'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('Score / 100'), findsOneWidget);

    // The canvas is much taller than the test viewport (it mirrors the
    // source image's aspect ratio), so its true center sits off-screen
    // even after scrolling it into view — tap near its visible top-left
    // corner instead of using tester.tap()'s (off-screen) center point.
    final canvasFinder = find.byKey(const Key('markingCanvas'));
    await tester.ensureVisible(canvasFinder);
    await tester.pumpAndSettle();
    final topLeft = tester.getTopLeft(canvasFinder);
    await tester.tapAt(topLeft + const Offset(40, 40));
    await tester.pumpAndSettle();

    expect(find.text('Add comment'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Check row 2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fakeUseCase.lastParams?.submissionId, 'sub1');
    expect(fakeUseCase.lastParams?.text, 'Check row 2');
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an existing pin opens edit mode with a delete option', (
    WidgetTester tester,
  ) async {
    final fakeUpdateUseCase = _FakeUpdateAnnotationUseCase();
    final fakeDeleteUseCase = _FakeDeleteAnnotationUseCase();

    const submission = StudentSubmissionEntity(
      studentId: 's1',
      studentName: 'Daniel Eze',
      status: StudentSubmissionStatus.submitted,
      submissionId: 'sub1',
      bodyText: 'the work is done',
    );

    final existingAnnotation = SubmissionAnnotationEntity(
      id: 'ann1',
      xPercent: 10,
      yPercent: 5,
      text: 'Original comment',
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateAnnotationUseCaseProvider.overrideWithValue(
            fakeUpdateUseCase,
          ),
          deleteAnnotationUseCaseProvider.overrideWithValue(
            fakeDeleteUseCase,
          ),
          submissionAnnotationsProvider(
            'sub1',
          ).overrideWith((ref) async => [existingAnnotation]),
        ],
        child: MaterialApp(
          home: MarkingViewPage(
            assignmentTitle: 'Linear Algebra',
            assignmentId: 'a1',
            classId: 'c1',
            submissions: const [submission],
            initialIndex: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final canvasFinder = find.byKey(const Key('markingCanvas'));
    await tester.ensureVisible(canvasFinder);
    await tester.pumpAndSettle();
    final topLeft = tester.getTopLeft(canvasFinder);
    final size = tester.getSize(canvasFinder);
    final pinPoint =
        topLeft + Offset(size.width * 0.10, size.height * 0.05);

    await tester.tapAt(pinPoint);
    await tester.pumpAndSettle();

    expect(find.text('Edit comment'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Original comment'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(fakeDeleteUseCase.lastId, 'ann1');
    expect(tester.takeException(), isNull);
  });
}
