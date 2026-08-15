import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/params/update_annotation_params.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class UpdateAnnotationUseCase extends UseCase<void, UpdateAnnotationParams> {
  const UpdateAnnotationUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultVoid call(UpdateAnnotationParams params) {
    return _repository.updateAnnotationText(params.annotationId, params.text);
  }
}
