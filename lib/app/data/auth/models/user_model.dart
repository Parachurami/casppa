import 'package:hive/hive.dart';

import 'package:casppa/app/core/utils/hive_type_ids.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';

part 'user_model.g.dart';

@HiveType(typeId: HiveTypeIds.userModel)
class UserModel extends UserEntity {
  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.roleName,
  }) : super(
         id: id,
         email: email,
         name: name,
         role: UserRole.values.byName(roleName),
       );

  factory UserModel.fromJson(DataMap json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['full_name'] as String,
      roleName: json['role'] as String,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      roleName: entity.role.name,
    );
  }

  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String email;

  @HiveField(2)
  @override
  final String name;

  @HiveField(3)
  final String roleName;

  DataMap toJson() {
    return {'id': id, 'email': email, 'name': name, 'role': roleName};
  }
}
