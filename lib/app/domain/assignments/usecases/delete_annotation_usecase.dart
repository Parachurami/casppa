import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class DeleteAnnotationUseCase extends UseCase<void, String> {
  const DeleteAnnotationUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultVoid call(String params) {
    return _repository.deleteAnnotation(params);
  }
}
