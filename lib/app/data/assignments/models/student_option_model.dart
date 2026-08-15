import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/student_option_entity.dart';

class StudentOptionModel extends StudentOptionEntity {
  const StudentOptionModel({required super.id, required super.name});

  factory StudentOptionModel.fromJson(DataMap json) {
    return StudentOptionModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
