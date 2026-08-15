import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';

class GetStudentsUseCase extends UseCase<List<StudentSummaryEntity>, NoParams> {
  const GetStudentsUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultFuture<List<StudentSummaryEntity>> call(NoParams params) {
    return _repository.getStudents();
  }
}
