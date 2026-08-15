import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';

class GetAllAssessmentsUseCase
    extends UseCase<List<AssignmentEntity>, NoParams> {
  const GetAllAssessmentsUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultFuture<List<AssignmentEntity>> call(NoParams params) {
    return _repository.getAllAssessments();
  }
}
