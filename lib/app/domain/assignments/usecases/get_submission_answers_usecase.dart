import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/submission_answer_entity.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class GetSubmissionAnswersUseCase
    extends UseCase<List<SubmissionAnswerEntity>, String> {
  const GetSubmissionAnswersUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultFuture<List<SubmissionAnswerEntity>> call(String params) {
    return _repository.getSubmissionAnswers(params);
  }
}
