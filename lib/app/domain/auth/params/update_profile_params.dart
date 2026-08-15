import 'package:equatable/equatable.dart';

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({required this.fullName});

  final String fullName;

  @override
  List<Object?> get props => [fullName];
}
