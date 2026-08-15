import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';
import 'package:casppa/app/domain/assignments/entities/subject_option_entity.dart';

class GetAdminSubjectsUseCase
    extends UseCase<List<SubjectOptionEntity>, NoParams> {
  const GetAdminSubjectsUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultFuture<List<SubjectOptionEntity>> call(NoParams params) {
    return _repository.getSubjects();
  }
}
