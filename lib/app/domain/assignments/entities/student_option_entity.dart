import 'package:equatable/equatable.dart';

class StudentOptionEntity extends Equatable {
  const StudentOptionEntity({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
