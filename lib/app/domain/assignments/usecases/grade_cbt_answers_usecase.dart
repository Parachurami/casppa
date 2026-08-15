import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/params/cbt_answer_grade.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class GradeCbtAnswersUseCase extends UseCase<void, List<CbtAnswerGrade>> {
  const GradeCbtAnswersUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultVoid call(List<CbtAnswerGrade> params) {
    return _repository.gradeCbtAnswers(params);
  }
}
