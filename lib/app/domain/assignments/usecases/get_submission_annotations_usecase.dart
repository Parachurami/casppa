import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/submission_annotation_entity.dart';
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';

class GetSubmissionAnnotationsUseCase
    extends UseCase<List<SubmissionAnnotationEntity>, String> {
  const GetSubmissionAnnotationsUseCase(this._repository);

  final AssignmentsRepository _repository;

  @override
  ResultFuture<List<SubmissionAnnotationEntity>> call(String params) {
    return _repository.getSubmissionAnnotations(params);
  }
}
