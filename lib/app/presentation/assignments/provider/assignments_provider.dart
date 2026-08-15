import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/di/injection_container.dart';
import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/class_option_entity.dart';
import 'package:casppa/app/domain/assignments/entities/question_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_option_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/domain/assignments/entities/submission_annotation_entity.dart';
import 'package:casppa/app/domain/assignments/entities/submission_answer_entity.dart';
import 'package:casppa/app/domain/assignments/entities/subject_option_entity.dart';
import 'package:casppa/app/domain/assignments/params/assignment_submissions_params.dart';
import 'package:casppa/app/domain/assignments/params/cbt_input.dart';
import 'package:casppa/app/domain/assignments/params/create_assignment_params.dart';
import 'package:casppa/app/domain/assignments/params/update_assignment_params.dart';
import 'package:casppa/app/domain/assignments/usecases/add_annotation_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/create_assignment_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/create_cbt_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/create_submission_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/delete_annotation_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/delete_assignment_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_all_class_options_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_assignment_submissions_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_class_options_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_questions_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_student_assignments_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_student_cbts_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_students_in_class_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_submission_annotations_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_submission_answers_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_subject_options_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_teacher_assignments_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_teacher_cbts_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/grade_cbt_answers_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/grade_submission_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/submit_cbt_answers_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/update_annotation_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/update_assignment_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/update_cbt_usecase.dart';

final getTeacherAssignmentsUseCaseProvider =
    Provider<GetTeacherAssignmentsUseCase>((ref) => sl());
final createAssignmentUseCaseProvider = Provider<CreateAssignmentUseCase>(
  (ref) => sl(),
);
final updateAssignmentUseCaseProvider = Provider<UpdateAssignmentUseCase>(
  (ref) => sl(),
);
final deleteAssignmentUseCaseProvider = Provider<DeleteAssignmentUseCase>(
  (ref) => sl(),
);
final getClassOptionsUseCaseProvider = Provider<GetClassOptionsUseCase>(
  (ref) => sl(),
);
final getAllClassOptionsUseCaseProvider = Provider<GetAllClassOptionsUseCase>(
  (ref) => sl(),
);
final getSubjectOptionsUseCaseProvider = Provider<GetSubjectOptionsUseCase>(
  (ref) => sl(),
);

final classOptionsProvider = FutureProvider.autoDispose<List<ClassOptionEntity>>((
  ref,
) async {
  final result = await ref
      .read(getClassOptionsUseCaseProvider)
      .call(const NoParams());

  return result.fold((failure) => throw failure, (options) => options);
});

final allClassOptionsProvider =
    FutureProvider.autoDispose<List<ClassOptionEntity>>((ref) async {
      final result = await ref
          .read(getAllClassOptionsUseCaseProvider)
          .call(const NoParams());

      return result.fold((failure) => throw failure, (options) => options);
    });

final subjectOptionsProvider =
    FutureProvider.autoDispose<List<SubjectOptionEntity>>((ref) async {
      final result = await ref
          .read(getSubjectOptionsUseCaseProvider)
          .call(const NoParams());

      return result.fold((failure) => throw failure, (options) => options);
    });

final getStudentsInClassUseCaseProvider = Provider<GetStudentsInClassUseCase>(
  (ref) => sl(),
);

final studentsInClassProvider = FutureProvider.autoDispose
    .family<List<StudentOptionEntity>, String>((ref, classId) async {
      final result = await ref
          .read(getStudentsInClassUseCaseProvider)
          .call(classId);

      return result.fold((failure) => throw failure, (students) => students);
    });

final getAssignmentSubmissionsUseCaseProvider =
    Provider<GetAssignmentSubmissionsUseCase>((ref) => sl());

final assignmentSubmissionsProvider = FutureProvider.family<
  List<StudentSubmissionEntity>,
  ({String assignmentId, String? classId})
>((ref, args) async {
  final result = await ref
      .read(getAssignmentSubmissionsUseCaseProvider)
      .call(
        AssignmentSubmissionsParams(
          assignmentId: args.assignmentId,
          classId: args.classId,
        ),
      );

  return result.fold((failure) => throw failure, (submissions) => submissions);
});

class TeacherAssignmentsNotifier
    extends AutoDisposeAsyncNotifier<List<AssignmentEntity>> {
  @override
  FutureOr<List<AssignmentEntity>> build() async {
    final result = await ref
        .read(getTeacherAssignmentsUseCaseProvider)
        .call(const NoParams());

    return result.fold((failure) => throw failure, (assignments) => assignments);
  }

  Future<bool> createAssignment(CreateAssignmentParams params) async {
    try {
      final result = await ref
          .read(createAssignmentUseCaseProvider)
          .call(params);

      return result.fold((failure) => false, (_) {
        ref.invalidateSelf();
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAssignment(String id, CreateAssignmentParams data) async {
    try {
      final result = await ref
          .read(updateAssignmentUseCaseProvider)
          .call(UpdateAssignmentParams(id: id, data: data));

      return result.fold((failure) => false, (_) {
        ref.invalidateSelf();
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAssignment(String id) async {
    try {
      final result = await ref.read(deleteAssignmentUseCaseProvider).call(id);

      return result.fold((failure) => false, (_) {
        ref.invalidateSelf();
        return true;
      });
    } catch (_) {
      return false;
    }
  }
}

final teacherAssignmentsProvider =
    AsyncNotifierProvider.autoDispose<
      TeacherAssignmentsNotifier,
      List<AssignmentEntity>
    >(TeacherAssignmentsNotifier.new);

final getStudentAssignmentsUseCaseProvider =
    Provider<GetStudentAssignmentsUseCase>((ref) => sl());

final studentAssignmentsProvider =
    FutureProvider.autoDispose<List<StudentAssignmentEntity>>((ref) async {
      final result = await ref
          .read(getStudentAssignmentsUseCaseProvider)
          .call(const NoParams());

      return result.fold(
        (failure) => throw failure,
        (assignments) => assignments,
      );
    });

final createSubmissionUseCaseProvider = Provider<CreateSubmissionUseCase>(
  (ref) => sl(),
);

final getSubmissionAnnotationsUseCaseProvider =
    Provider<GetSubmissionAnnotationsUseCase>((ref) => sl());

final addAnnotationUseCaseProvider = Provider<AddAnnotationUseCase>(
  (ref) => sl(),
);

final updateAnnotationUseCaseProvider = Provider<UpdateAnnotationUseCase>(
  (ref) => sl(),
);

final deleteAnnotationUseCaseProvider = Provider<DeleteAnnotationUseCase>(
  (ref) => sl(),
);

final gradeSubmissionUseCaseProvider = Provider<GradeSubmissionUseCase>(
  (ref) => sl(),
);

final submissionAnnotationsProvider = FutureProvider.family<
  List<SubmissionAnnotationEntity>,
  String
>((ref, submissionId) async {
  final result = await ref
      .read(getSubmissionAnnotationsUseCaseProvider)
      .call(submissionId);

  return result.fold((failure) => throw failure, (annotations) => annotations);
});

final getTeacherCbtsUseCaseProvider = Provider<GetTeacherCbtsUseCase>(
  (ref) => sl(),
);
final getStudentCbtsUseCaseProvider = Provider<GetStudentCbtsUseCase>(
  (ref) => sl(),
);
final createCbtUseCaseProvider = Provider<CreateCbtUseCase>((ref) => sl());
final updateCbtUseCaseProvider = Provider<UpdateCbtUseCase>((ref) => sl());
final getQuestionsUseCaseProvider = Provider<GetQuestionsUseCase>(
  (ref) => sl(),
);
final submitCbtAnswersUseCaseProvider = Provider<SubmitCbtAnswersUseCase>(
  (ref) => sl(),
);
final getSubmissionAnswersUseCaseProvider =
    Provider<GetSubmissionAnswersUseCase>((ref) => sl());
final gradeCbtAnswersUseCaseProvider = Provider<GradeCbtAnswersUseCase>(
  (ref) => sl(),
);

class TeacherCbtsNotifier
    extends AutoDisposeAsyncNotifier<List<AssignmentEntity>> {
  @override
  FutureOr<List<AssignmentEntity>> build() async {
    final result = await ref
        .read(getTeacherCbtsUseCaseProvider)
        .call(const NoParams());

    return result.fold((failure) => throw failure, (cbts) => cbts);
  }

  Future<bool> createCbt(CreateCbtInput input) async {
    try {
      final result = await ref.read(createCbtUseCaseProvider).call(input);

      return result.fold((failure) => false, (_) {
        ref.invalidateSelf();
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCbt(UpdateCbtInput input) async {
    try {
      final result = await ref.read(updateCbtUseCaseProvider).call(input);

      return result.fold((failure) => false, (_) {
        ref.invalidateSelf();
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCbt(String id) async {
    try {
      final result = await ref.read(deleteAssignmentUseCaseProvider).call(id);

      return result.fold((failure) => false, (_) {
        ref.invalidateSelf();
        return true;
      });
    } catch (_) {
      return false;
    }
  }
}

final teacherCbtsProvider =
    AsyncNotifierProvider.autoDispose<
      TeacherCbtsNotifier,
      List<AssignmentEntity>
    >(TeacherCbtsNotifier.new);

final studentCbtsProvider = FutureProvider.autoDispose<
  List<StudentAssignmentEntity>
>((
  ref,
) async {
  final result = await ref
      .read(getStudentCbtsUseCaseProvider)
      .call(const NoParams());

  return result.fold((failure) => throw failure, (cbts) => cbts);
});

final questionsProvider = FutureProvider.family<List<QuestionEntity>, String>((
  ref,
  assignmentId,
) async {
  final result = await ref
      .read(getQuestionsUseCaseProvider)
      .call(assignmentId);

  return result.fold((failure) => throw failure, (questions) => questions);
});

final submissionAnswersProvider = FutureProvider.family<
  List<SubmissionAnswerEntity>,
  String
>((ref, submissionId) async {
  final result = await ref
      .read(getSubmissionAnswersUseCaseProvider)
      .call(submissionId);

  return result.fold((failure) => throw failure, (answers) => answers);
});
