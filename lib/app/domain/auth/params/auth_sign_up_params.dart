import 'package:equatable/equatable.dart';

import 'package:casppa/app/domain/auth/entities/user_entity.dart';

class AuthSignUpParams extends Equatable {
  const AuthSignUpParams({
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    this.classId,
    this.childIds,
  });

  final String email;
  final String password;
  final String fullName;
  final UserRole role;

  /// Only meaningful (and required by the sign-up form) when [role] is
  /// [UserRole.student] — which class they belong to.
  final String? classId;

  /// Only meaningful (and required by the sign-up form) when [role] is
  /// [UserRole.parent] — the student(s) to link as their children,
  /// possibly spanning more than one class.
  final List<String>? childIds;

  @override
  List<Object?> get props => [
    email,
    password,
    fullName,
    role,
    classId,
    childIds,
  ];
}
