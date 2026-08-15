import 'package:equatable/equatable.dart';

class SubjectOptionEntity extends Equatable {
  const SubjectOptionEntity({required this.id, required this.title});

  final String id;
  final String title;

  @override
  List<Object?> get props => [id, title];
}
