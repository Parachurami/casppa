import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/subject_option_entity.dart';

class SubjectOptionModel extends SubjectOptionEntity {
  const SubjectOptionModel({required super.id, required super.title});

  factory SubjectOptionModel.fromJson(DataMap json) {
    return SubjectOptionModel(
      id: json['id'] as String,
      title: json['title'] as String,
    );
  }
}
