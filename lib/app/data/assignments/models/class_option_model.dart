import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/class_option_entity.dart';

class ClassOptionModel extends ClassOptionEntity {
  const ClassOptionModel({required super.id, required super.name});

  factory ClassOptionModel.fromJson(DataMap json) {
    return ClassOptionModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
