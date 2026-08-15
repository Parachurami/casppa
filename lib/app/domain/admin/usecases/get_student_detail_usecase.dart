import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';

class GetStudentDetailUseCase extends UseCase<StudentDetailEntity, String> {
  const GetStudentDetailUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultFuture<StudentDetailEntity> call(String params) {
    return _repository.getStudentDetail(params);
  }
}
