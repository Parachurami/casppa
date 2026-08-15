import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/subject_option_entity.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class GetSubjectOptionsUseCase
    extends UseCase<List<SubjectOptionEntity>, NoParams> {
  const GetSubjectOptionsUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultFuture<List<SubjectOptionEntity>> call(NoParams params) {
    return _repository.getSubjectOptions();
  }
}
