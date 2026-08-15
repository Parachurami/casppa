import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/student_submission_entity.dart';
import 'package:casppa/app/domain/assignments/params/assignment_submissions_params.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class GetAssignmentSubmissionsUseCase
    extends
        UseCase<List<StudentSubmissionEntity>, AssignmentSubmissionsParams> {
  const GetAssignmentSubmissionsUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultFuture<List<StudentSubmissionEntity>> call(
    AssignmentSubmissionsParams params,
  ) {
    return _repository.getAssignmentSubmissions(params);
  }
}
