import 'package:equatable/equatable.dart';

class ClassOptionEntity extends Equatable {
  const ClassOptionEntity({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
