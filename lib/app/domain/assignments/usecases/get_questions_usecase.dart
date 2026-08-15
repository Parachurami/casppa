import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/question_entity.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class GetQuestionsUseCase extends UseCase<List<QuestionEntity>, String> {
  const GetQuestionsUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultFuture<List<QuestionEntity>> call(String params) {
    return _repository.getQuestions(params);
  }
}
