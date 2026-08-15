import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/params/grade_submission_params.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class GradeSubmissionUseCase extends UseCase<void, GradeSubmissionParams> {
  const GradeSubmissionUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultVoid call(GradeSubmissionParams params) {
    return _repository.gradeSubmission(params);
  }
}
