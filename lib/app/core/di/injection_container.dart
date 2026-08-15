import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:casppa/app/core/services/network_info.dart';
import 'package:casppa/app/core/utils/app_constants.dart';
import 'package:casppa/app/data/admin/datasources/remote/admin_remote_datasource.dart';
import 'package:casppa/app/data/admin/repositories/admin_repository_impl.dart';
import 'package:casppa/app/data/assignments/datasources/local/assignments_local_datasource.dart';
import 'package:casppa/app/data/assignments/datasources/remote/assignments_remote_datasource.dart';
import 'package:casppa/app/data/assignments/repositories/assignments_repository_impl.dart';
import 'package:casppa/app/data/auth/datasources/local/auth_local_datasource.dart';
import 'package:casppa/app/data/auth/datasources/remote/auth_remote_datasource.dart';
import 'package:casppa/app/data/auth/repositories/auth_repository_impl.dart';
import 'package:casppa/app/data/notifications/datasources/local/notifications_local_datasource.dart';
import 'package:casppa/app/data/notifications/datasources/remote/notifications_remote_datasource.dart';
import 'package:casppa/app/data/notifications/repositories/notifications_repository_impl.dart';
import 'package:casppa/app/data/onboarding/datasources/local/onboarding_local_datasource.dart';
import 'package:casppa/app/data/onboarding/repositories/onboarding_repository_impl.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';
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
import 'package:casppa/app/domain/assignments/repositories/assignments_repository.dart';
import 'package:casppa/app/domain/assignments/usecases/add_annotation_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/create_assignment_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/create_cbt_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/create_submission_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/delete_annotation_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/delete_assignment_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_all_class_options_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_assignment_submissions_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_class_options_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_questions_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_student_assignments_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_student_cbts_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_submission_annotations_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_submission_answers_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_subject_options_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_teacher_assignments_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/get_teacher_cbts_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/grade_cbt_answers_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/grade_submission_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/submit_cbt_answers_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/update_annotation_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/update_assignment_usecase.dart';
import 'package:casppa/app/domain/assignments/usecases/update_cbt_usecase.dart';
import 'package:casppa/app/domain/auth/repositories/auth_repository.dart';
import 'package:casppa/app/domain/auth/usecases/get_current_user_usecase.dart';
import 'package:casppa/app/domain/auth/usecases/login_usecase.dart';
import 'package:casppa/app/domain/auth/usecases/logout_usecase.dart';
import 'package:casppa/app/domain/auth/usecases/sign_up_usecase.dart';
import 'package:casppa/app/domain/auth/usecases/update_profile_usecase.dart';
import 'package:casppa/app/domain/notifications/repositories/notifications_repository.dart';
import 'package:casppa/app/domain/notifications/usecases/delete_notification_usecase.dart';
import 'package:casppa/app/domain/notifications/usecases/get_notifications_usecase.dart';
import 'package:casppa/app/domain/notifications/usecases/mark_all_notifications_read_usecase.dart';
import 'package:casppa/app/domain/notifications/usecases/mark_notification_read_usecase.dart';
import 'package:casppa/app/domain/notifications/usecases/watch_new_notifications_usecase.dart';
import 'package:casppa/app/domain/onboarding/repositories/onboarding_repository.dart';
import 'package:casppa/app/domain/onboarding/usecases/complete_onboarding_usecase.dart';
import 'package:casppa/app/domain/onboarding/usecases/has_completed_onboarding_usecase.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  _initCore();
  _initAuth();
  _initOnboarding();
  _initAssignments();
  _initNotifications();
  _initAdmin();
}

void _initCore() {
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<Connectivity>(Connectivity.new);
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
}

void _initAuth() {
  sl
    ..registerLazySingleton<Box<dynamic>>(
      () => Hive.box<dynamic>(HiveBoxes.authBox),
      instanceName: HiveBoxes.authBox,
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sl(instanceName: HiveBoxes.authBox)),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl(), sl(), sl()),
    )
    ..registerLazySingleton(() => LoginUseCase(sl()))
    ..registerLazySingleton(() => SignUpUseCase(sl()))
    ..registerLazySingleton(() => LogoutUseCase(sl()))
    ..registerLazySingleton(() => GetCurrentUserUseCase(sl()))
    ..registerLazySingleton(() => UpdateProfileUseCase(sl()));
}

void _initOnboarding() {
  sl
    ..registerLazySingleton<Box<dynamic>>(
      () => Hive.box<dynamic>(HiveBoxes.onboardingBox),
      instanceName: HiveBoxes.onboardingBox,
    )
    ..registerLazySingleton<OnboardingLocalDataSource>(
      () => OnboardingLocalDataSourceImpl(
        sl(instanceName: HiveBoxes.onboardingBox),
      ),
    )
    ..registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => HasCompletedOnboardingUseCase(sl()))
    ..registerLazySingleton(() => CompleteOnboardingUseCase(sl()));
}

void _initAssignments() {
  sl
    ..registerLazySingleton<Box<dynamic>>(
      () => Hive.box<dynamic>(HiveBoxes.assignmentsBox),
      instanceName: HiveBoxes.assignmentsBox,
    )
    ..registerLazySingleton<AssignmentsRemoteDataSource>(
      () => AssignmentsRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AssignmentsLocalDataSource>(
      () => AssignmentsLocalDataSourceImpl(
        sl(instanceName: HiveBoxes.assignmentsBox),
      ),
    )
    ..registerLazySingleton<AssignmentsRepository>(
      () => AssignmentsRepositoryImpl(sl(), sl(), sl()),
    )
    ..registerLazySingleton(() => GetTeacherAssignmentsUseCase(sl()))
    ..registerLazySingleton(() => CreateAssignmentUseCase(sl()))
    ..registerLazySingleton(() => UpdateAssignmentUseCase(sl()))
    ..registerLazySingleton(() => DeleteAssignmentUseCase(sl()))
    ..registerLazySingleton(() => GetClassOptionsUseCase(sl()))
    ..registerLazySingleton(() => GetAllClassOptionsUseCase(sl()))
    ..registerLazySingleton(() => GetSubjectOptionsUseCase(sl()))
    ..registerLazySingleton(() => GetAssignmentSubmissionsUseCase(sl()))
    ..registerLazySingleton(() => GetStudentAssignmentsUseCase(sl()))
    ..registerLazySingleton(() => CreateSubmissionUseCase(sl()))
    ..registerLazySingleton(() => GetSubmissionAnnotationsUseCase(sl()))
    ..registerLazySingleton(() => AddAnnotationUseCase(sl()))
    ..registerLazySingleton(() => UpdateAnnotationUseCase(sl()))
    ..registerLazySingleton(() => DeleteAnnotationUseCase(sl()))
    ..registerLazySingleton(() => GradeSubmissionUseCase(sl()))
    ..registerLazySingleton(() => GetTeacherCbtsUseCase(sl()))
    ..registerLazySingleton(() => GetStudentCbtsUseCase(sl()))
    ..registerLazySingleton(() => CreateCbtUseCase(sl()))
    ..registerLazySingleton(() => UpdateCbtUseCase(sl()))
    ..registerLazySingleton(() => GetQuestionsUseCase(sl()))
    ..registerLazySingleton(() => SubmitCbtAnswersUseCase(sl()))
    ..registerLazySingleton(() => GetSubmissionAnswersUseCase(sl()))
    ..registerLazySingleton(() => GradeCbtAnswersUseCase(sl()));
}

void _initNotifications() {
  sl
    ..registerLazySingleton<Box<dynamic>>(
      () => Hive.box<dynamic>(HiveBoxes.notificationsBox),
      instanceName: HiveBoxes.notificationsBox,
    )
    ..registerLazySingleton<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<NotificationsLocalDataSource>(
      () => NotificationsLocalDataSourceImpl(
        sl(instanceName: HiveBoxes.notificationsBox),
      ),
    )
    ..registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(sl(), sl(), sl()),
    )
    ..registerLazySingleton(() => GetNotificationsUseCase(sl()))
    ..registerLazySingleton(() => MarkNotificationReadUseCase(sl()))
    ..registerLazySingleton(() => MarkAllNotificationsReadUseCase(sl()))
    ..registerLazySingleton(() => DeleteNotificationUseCase(sl()))
    ..registerLazySingleton(() => WatchNewNotificationsUseCase(sl()));
}

void _initAdmin() {
  sl
    ..registerLazySingleton<AdminRemoteDataSource>(
      () => AdminRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AdminRepository>(
      () => AdminRepositoryImpl(sl(), sl()),
    )
    ..registerLazySingleton(() => GetOverviewUseCase(sl()))
    ..registerLazySingleton(() => GetAdminSubjectsUseCase(sl()))
    ..registerLazySingleton(() => CreateSubjectUseCase(sl()))
    ..registerLazySingleton(() => UpdateSubjectUseCase(sl()))
    ..registerLazySingleton(() => DeleteSubjectUseCase(sl()))
    ..registerLazySingleton(() => GetAdminClassesUseCase(sl()))
    ..registerLazySingleton(() => GetClassDetailUseCase(sl()))
    ..registerLazySingleton(() => CreateClassUseCase(sl()))
    ..registerLazySingleton(() => UpdateClassUseCase(sl()))
    ..registerLazySingleton(() => DeleteClassUseCase(sl()))
    ..registerLazySingleton(() => AddStudentToClassUseCase(sl()))
    ..registerLazySingleton(() => RemoveStudentFromClassUseCase(sl()))
    ..registerLazySingleton(() => GetAllAssessmentsUseCase(sl()))
    ..registerLazySingleton(() => GetTeachersUseCase(sl()))
    ..registerLazySingleton(() => GetTeacherDetailUseCase(sl()))
    ..registerLazySingleton(() => GetStudentsUseCase(sl()))
    ..registerLazySingleton(() => GetStudentDetailUseCase(sl()));
}
