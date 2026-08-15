import 'package:equatable/equatable.dart';

enum UserRole { teacher, student, parent, admin }

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;

  @override
  List<Object?> get props => [id, email, name, role];
}
