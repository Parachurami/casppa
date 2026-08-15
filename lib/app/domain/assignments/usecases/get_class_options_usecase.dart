import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/class_option_entity.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class GetClassOptionsUseCase
    extends UseCase<List<ClassOptionEntity>, NoParams> {
  const GetClassOptionsUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultFuture<List<ClassOptionEntity>> call(NoParams params) {
    return _repository.getClassOptions();
  }
}
