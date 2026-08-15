import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';
import 'package:casppa/app/domain/parent/repositories/parent_repository.dart';

class GetChildDetailUseCase extends UseCase<StudentDetailEntity, String> {
  const GetChildDetailUseCase(this._repository);

  final ParentRepository _repository;

  @override
  ResultFuture<StudentDetailEntity> call(String params) {
    return _repository.getChildDetail(params);
  }
}
