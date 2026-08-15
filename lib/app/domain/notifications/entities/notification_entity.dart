import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.isRead,
    required this.createdAt,
    this.body,
    this.assignmentId,
    this.submissionId,
  });

  final String id;
  final String type;
  final String title;
  final String? body;
  final String? assignmentId;
  final String? submissionId;
  final bool isRead;
  final DateTime createdAt;

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      type: type,
      title: title,
      body: body,
      assignmentId: assignmentId,
      submissionId: submissionId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    body,
    assignmentId,
    submissionId,
    isRead,
    createdAt,
  ];
}
