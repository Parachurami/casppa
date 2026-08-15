import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/class_option_entity.dart';
import 'package:casppa/app/domain/assignments/entities/question_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/domain/assignments/entities/submission_annotation_entity.dart';
import 'package:casppa/app/domain/assignments/entities/submission_answer_entity.dart';
import 'package:casppa/app/domain/assignments/entities/subject_option_entity.dart';
import 'package:casppa/app/domain/assignments/params/add_annotation_params.dart';
import 'package:casppa/app/domain/assignments/params/assignment_submissions_params.dart';
import 'package:casppa/app/domain/assignments/params/cbt_answer_grade.dart';
import 'package:casppa/app/domain/assignments/params/cbt_input.dart';
import 'package:casppa/app/domain/assignments/params/create_assignment_params.dart';
import 'package:casppa/app/domain/assignments/params/create_submission_params.dart';
import 'package:casppa/app/domain/assignments/params/grade_submission_params.dart';
import 'package:casppa/app/domain/assignments/params/submit_cbt_params.dart';

abstract class AssignmentsRepository {
  ResultFuture<List<AssignmentEntity>> getTeacherAssignments();

  ResultFuture<AssignmentEntity> createAssignment(
    CreateAssignmentParams params,
  );

  ResultFuture<AssignmentEntity> updateAssignment(
    String id,
    CreateAssignmentParams params,
  );

  ResultVoid deleteAssignment(String id);

  ResultFuture<List<ClassOptionEntity>> getClassOptions();

  /// All classes, unfiltered by teacher — used by the student sign-up
  /// picker, where there's no "my classes" scope to filter by yet.
  ResultFuture<List<ClassOptionEntity>> getAllClassOptions();

  ResultFuture<List<SubjectOptionEntity>> getSubjectOptions();

  ResultFuture<List<StudentSubmissionEntity>> getAssignmentSubmissions(
    AssignmentSubmissionsParams params,
  );

  ResultFuture<List<StudentAssignmentEntity>> getStudentAssignments();

  ResultVoid createSubmission(CreateSubmissionParams params);

  ResultFuture<List<SubmissionAnnotationEntity>> getSubmissionAnnotations(
    String submissionId,
  );

  ResultFuture<SubmissionAnnotationEntity> addAnnotation(
    AddAnnotationParams params,
  );

  ResultVoid updateAnnotationText(String annotationId, String text);

  ResultVoid deleteAnnotation(String annotationId);

  ResultVoid gradeSubmission(GradeSubmissionParams params);

  ResultFuture<List<AssignmentEntity>> getTeacherCbts();

  ResultFuture<List<StudentAssignmentEntity>> getStudentCbts();

  ResultFuture<AssignmentEntity> createCbt(CreateCbtInput input);

  ResultFuture<AssignmentEntity> updateCbt(UpdateCbtInput input);

  ResultFuture<List<QuestionEntity>> getQuestions(String assignmentId);

  ResultVoid submitCbtAnswers(SubmitCbtParams params);

  ResultFuture<List<SubmissionAnswerEntity>> getSubmissionAnswers(
    String submissionId,
  );

  ResultVoid gradeCbtAnswers(List<CbtAnswerGrade> grades);
}
