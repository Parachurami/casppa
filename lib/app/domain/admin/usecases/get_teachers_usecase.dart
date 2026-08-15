import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/entities/teacher_summary_entity.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';

class GetTeachersUseCase extends UseCase<List<TeacherSummaryEntity>, NoParams> {
  const GetTeachersUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultFuture<List<TeacherSummaryEntity>> call(NoParams params) {
    return _repository.getTeachers();
  }
}
