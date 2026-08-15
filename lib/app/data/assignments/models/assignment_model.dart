import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/rubric_criterion_entity.dart';

class AssignmentModel extends AssignmentEntity {
  const AssignmentModel({
    required super.id,
    required super.type,
    required super.status,
    required super.title,
    required super.description,
    required super.classId,
    required super.className,
    required super.subject,
    required super.dueDate,
    required super.createdBy,
    required super.expectedSubmissions,
    required super.submittedCount,
    super.rubricCriteria,
  });

  factory AssignmentModel.fromJson(DataMap json) {
    final classJoin = json['class'] as DataMap?;
    final subjectJoin = json['subject'] as DataMap?;
    final rawDueDate = json['due_date'] as String?;
    final rawType = json['type'] as String?;
    final rawRubricCriteria = json['rubric_criteria'] as List<dynamic>?;

    return AssignmentModel(
      id: json['id'] as String,
      type: rawType == null
          ? AssignmentType.assignment
          : AssignmentType.values.byName(rawType),
      status: AssignmentStatus.values.byName(json['status'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      classId: json['class_id'] as String?,
      className: classJoin?['name'] as String?,
      subject: subjectJoin?['title'] as String?,
      dueDate: rawDueDate == null ? null : DateTime.parse(rawDueDate),
      createdBy: json['created_by'] as String,
      expectedSubmissions: json['expected_submissions'] as int? ?? 0,
      submittedCount: json['_submitted_count'] as int? ?? 0,
      rubricCriteria: (rawRubricCriteria ?? const [])
          .map(
            (item) => RubricCriterionEntity(
              name: (item as DataMap)['name'] as String,
              maxPoints: item['max_points'] as int,
            ),
          )
          .toList(),
    );
  }
}
