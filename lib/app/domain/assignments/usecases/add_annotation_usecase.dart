import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/submission_annotation_entity.dart';
import 'package:casppa/app/domain/assignments/params/add_annotation_params.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class AddAnnotationUseCase
    extends UseCase<SubmissionAnnotationEntity, AddAnnotationParams> {
  const AddAnnotationUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultFuture<SubmissionAnnotationEntity> call(AddAnnotationParams params) {
    return _repository.addAnnotation(params);
  }
}
