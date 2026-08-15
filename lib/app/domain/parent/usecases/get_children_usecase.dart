import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';
import 'package:casppa/app/domain/parent/repositories/parent_repository.dart';

class GetChildrenUseCase extends UseCase<List<StudentSummaryEntity>, NoParams> {
  const GetChildrenUseCase(this._repository);

  final ParentRepository _repository;

  @override
  ResultFuture<List<StudentSummaryEntity>> call(NoParams params) {
    return _repository.getChildren();
  }
}
