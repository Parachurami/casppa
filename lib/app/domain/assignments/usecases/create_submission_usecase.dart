import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/params/create_submission_params.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class CreateSubmissionUseCase extends UseCase<void, CreateSubmissionParams> {
  const CreateSubmissionUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultVoid call(CreateSubmissionParams params) {
    return _repository.createSubmission(params);
  }
}
