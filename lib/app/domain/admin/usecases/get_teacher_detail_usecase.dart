import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/entities/teacher_summary_entity.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';

class GetTeacherDetailUseCase extends UseCase<TeacherDetailEntity, String> {
  const GetTeacherDetailUseCase(this._repository);

  final AdminRepository _repository;

  @override
  ResultFuture<TeacherDetailEntity> call(String params) {
    return _repository.getTeacherDetail(params);
  }
}
