import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';

abstract class ParentRepository {
  ResultFuture<List<StudentSummaryEntity>> getChildren();

  ResultFuture<StudentDetailEntity> getChildDetail(String childId);
}
