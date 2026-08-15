import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/params/submit_cbt_params.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class SubmitCbtAnswersUseCase extends UseCase<void, SubmitCbtParams> {
  const SubmitCbtAnswersUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultVoid call(SubmitCbtParams params) {
    return _repository.submitCbtAnswers(params);
  }
}
