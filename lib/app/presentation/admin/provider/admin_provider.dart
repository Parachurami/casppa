import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/di/injection_container.dart';
import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/domain/admin/entities/admin_class_entity.dart';
import 'package:casppa/app/domain/admin/entities/admin_overview_entity.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';
import 'package:casppa/app/domain/admin/entities/teacher_summary_entity.dart';
import 'package:casppa/app/domain/admin/usecases/add_student_to_class_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/create_class_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/create_subject_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/delete_class_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/delete_subject_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/get_admin_classes_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/get_admin_subjects_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/get_all_assessments_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/get_class_detail_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/get_overview_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/get_student_detail_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/get_students_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/get_teacher_detail_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/get_teachers_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/remove_student_from_class_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/update_class_usecase.dart';
import 'package:casppa/app/domain/admin/usecases/update_subject_usecase.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/subject_option_entity.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';

final getOverviewUseCaseProvider = Provider<GetOverviewUseCase>((ref) => sl());
final getAdminSubjectsUseCaseProvider = Provider<GetAdminSubjectsUseCase>(
  (ref) => sl(),
);
final createSubjectUseCaseProvider = Provider<CreateSubjectUseCase>(
  (ref) => sl(),
);
final updateSubjectUseCaseProvider = Provider<UpdateSubjectUseCase>(
  (ref) => sl(),
);
final deleteSubjectUseCaseProvider = Provider<DeleteSubjectUseCase>(
  (ref) => sl(),
);
final getAdminClassesUseCaseProvider = Provider<GetAdminClassesUseCase>(
  (ref) => sl(),
);
final getClassDetailUseCaseProvider = Provider<GetClassDetailUseCase>(
  (ref) => sl(),
);
final createClassUseCaseProvider = Provider<CreateClassUseCase>((ref) => sl());
final updateClassUseCaseProvider = Provider<UpdateClassUseCase>((ref) => sl());
final deleteClassUseCaseProvider = Provider<DeleteClassUseCase>((ref) => sl());
final addStudentToClassUseCaseProvider = Provider<AddStudentToClassUseCase>(
  (ref) => sl(),
);
final removeStudentFromClassUseCaseProvider =
    Provider<RemoveStudentFromClassUseCase>((ref) => sl());
final getAllAssessmentsUseCaseProvider = Provider<GetAllAssessmentsUseCase>(
  (ref) => sl(),
);
final getTeachersUseCaseProvider = Provider<GetTeachersUseCase>(
  (ref) => sl(),
);
final getTeacherDetailUseCaseProvider = Provider<GetTeacherDetailUseCase>(
  (ref) => sl(),
);
final getStudentsUseCaseProvider = Provider<GetStudentsUseCase>(
  (ref) => sl(),
);
final getStudentDetailUseCaseProvider = Provider<GetStudentDetailUseCase>(
  (ref) => sl(),
);

final adminOverviewProvider = FutureProvider.autoDispose<AdminOverviewEntity>((
  ref,
) async {
  final result = await ref
      .read(getOverviewUseCaseProvider)
      .call(const NoParams());

  return result.fold((failure) => throw failure, (overview) => overview);
});

class AdminSubjectsNotifier
    extends AutoDisposeAsyncNotifier<List<SubjectOptionEntity>> {
  @override
  FutureOr<List<SubjectOptionEntity>> build() async {
    final result = await ref
        .read(getAdminSubjectsUseCaseProvider)
        .call(const NoParams());

    return result.fold((failure) => throw failure, (subjects) => subjects);
  }

  Future<bool> createSubject(String title) async {
    final result = await ref.read(createSubjectUseCaseProvider).call(title);
    return result.fold((failure) => false, (_) {
      ref.invalidateSelf();
      ref.invalidate(adminOverviewProvider);
      ref.invalidate(subjectOptionsProvider);
      return true;
    });
  }

  Future<bool> updateSubject(String id, String title) async {
    final result = await ref
        .read(updateSubjectUseCaseProvider)
        .call((id: id, title: title));
    return result.fold((failure) => false, (_) {
      ref.invalidateSelf();
      ref.invalidate(subjectOptionsProvider);
      return true;
    });
  }

  Future<bool> deleteSubject(String id) async {
    final result = await ref.read(deleteSubjectUseCaseProvider).call(id);
    return result.fold((failure) => false, (_) {
      ref.invalidateSelf();
      ref.invalidate(adminOverviewProvider);
      ref.invalidate(subjectOptionsProvider);
      return true;
    });
  }
}

final adminSubjectsProvider =
    AsyncNotifierProvider.autoDispose<
      AdminSubjectsNotifier,
      List<SubjectOptionEntity>
    >(AdminSubjectsNotifier.new);

class AdminClassesNotifier
    extends AutoDisposeAsyncNotifier<List<AdminClassEntity>> {
  @override
  FutureOr<List<AdminClassEntity>> build() async {
    final result = await ref
        .read(getAdminClassesUseCaseProvider)
        .call(const NoParams());

    return result.fold((failure) => throw failure, (classes) => classes);
  }

  Future<bool> createClass({required String name, String? teacherId}) async {
    final result = await ref
        .read(createClassUseCaseProvider)
        .call((name: name, teacherId: teacherId));
    return result.fold((failure) => false, (_) {
      ref.invalidateSelf();
      ref.invalidate(adminOverviewProvider);
      ref.invalidate(classOptionsProvider);
      ref.invalidate(allClassOptionsProvider);
      return true;
    });
  }

  Future<bool> updateClass({
    required String id,
    required String name,
    String? teacherId,
  }) async {
    final result = await ref
        .read(updateClassUseCaseProvider)
        .call((id: id, name: name, teacherId: teacherId));
    return result.fold((failure) => false, (_) {
      ref.invalidateSelf();
      ref.invalidate(classOptionsProvider);
      ref.invalidate(allClassOptionsProvider);
      return true;
    });
  }

  Future<bool> deleteClass(String id) async {
    final result = await ref.read(deleteClassUseCaseProvider).call(id);
    return result.fold((failure) => false, (_) {
      ref.invalidateSelf();
      ref.invalidate(adminOverviewProvider);
      ref.invalidate(classOptionsProvider);
      ref.invalidate(allClassOptionsProvider);
      return true;
    });
  }
}

final adminClassesProvider =
    AsyncNotifierProvider.autoDispose<
      AdminClassesNotifier,
      List<AdminClassEntity>
    >(AdminClassesNotifier.new);

final classDetailProvider = FutureProvider.autoDispose
    .family<AdminClassDetailEntity, String>((ref, classId) async {
      final result = await ref
          .read(getClassDetailUseCaseProvider)
          .call(classId);

      return result.fold((failure) => throw failure, (detail) => detail);
    });

final allAssessmentsProvider =
    FutureProvider.autoDispose<List<AssignmentEntity>>((ref) async {
      final result = await ref
          .read(getAllAssessmentsUseCaseProvider)
          .call(const NoParams());

      return result.fold(
        (failure) => throw failure,
        (assessments) => assessments,
      );
    });

final adminTeachersProvider =
    FutureProvider.autoDispose<List<TeacherSummaryEntity>>((ref) async {
      final result = await ref
          .read(getTeachersUseCaseProvider)
          .call(const NoParams());

      return result.fold((failure) => throw failure, (teachers) => teachers);
    });

final teacherDetailProvider = FutureProvider.autoDispose
    .family<TeacherDetailEntity, String>((ref, teacherId) async {
      final result = await ref
          .read(getTeacherDetailUseCaseProvider)
          .call(teacherId);

      return result.fold((failure) => throw failure, (detail) => detail);
    });

final adminStudentsProvider =
    FutureProvider.autoDispose<List<StudentSummaryEntity>>((ref) async {
      final result = await ref
          .read(getStudentsUseCaseProvider)
          .call(const NoParams());

      return result.fold((failure) => throw failure, (students) => students);
    });

final studentDetailProvider = FutureProvider.autoDispose
    .family<StudentDetailEntity, String>((ref, studentId) async {
      final result = await ref
          .read(getStudentDetailUseCaseProvider)
          .call(studentId);

      return result.fold((failure) => throw failure, (detail) => detail);
    });
