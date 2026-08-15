import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/errors/failures.dart';
import 'package:casppa/app/core/services/network_info.dart';
import 'package:casppa/app/core/utils/app_logger.dart';
import 'package:casppa/app/core/utils/typedefs.dart';
import 'package:casppa/app/data/admin/datasources/remote/admin_remote_datasource.dart';
import 'package:casppa/app/domain/admin/entities/admin_class_entity.dart';
import 'package:casppa/app/domain/admin/entities/admin_overview_entity.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';
import 'package:casppa/app/domain/admin/entities/teacher_summary_entity.dart';
import 'package:casppa/app/domain/admin/repositories/admin_repository.dart';
import 'package:casppa/app/domain/assignments/entities/assignment_entity.dart';
import 'package:casppa/app/domain/assignments/entities/subject_option_entity.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remoteDataSource, this._networkInfo);

  static const _tag = 'AdminRepository';

  final AdminRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  Future<T> _guard<T>(String method, Future<T> Function() call) async {
    AppLogger.state(_tag, '$method: online, calling remote');
    return call();
  }

  @override
  ResultFuture<AdminOverviewEntity> getOverview() async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getOverview: offline, no admin cache');
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _guard('getOverview', _remoteDataSource.getOverview));
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getOverview', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<SubjectOptionEntity>> getSubjects() async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getSubjects: offline, no admin cache');
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _guard('getSubjects', _remoteDataSource.getSubjects));
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getSubjects', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid createSubject(String title) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'createSubject: offline, cannot create');
      return const Left(NetworkFailure('No internet connection.'));
    }
    AppLogger.state(_tag, 'createSubject($title): online, calling remote');
    try {
      await _remoteDataSource.createSubject(title);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'createSubject', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid updateSubject(({String id, String title}) params) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'updateSubject: offline, cannot update');
      return const Left(NetworkFailure('No internet connection.'));
    }
    AppLogger.state(_tag, 'updateSubject(${params.id}): online, calling remote');
    try {
      await _remoteDataSource.updateSubject(params);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'updateSubject', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid deleteSubject(String id) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'deleteSubject: offline, cannot delete');
      return const Left(NetworkFailure('No internet connection.'));
    }
    AppLogger.state(_tag, 'deleteSubject($id): online, calling remote');
    try {
      await _remoteDataSource.deleteSubject(id);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'deleteSubject', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<AdminClassEntity>> getClasses() async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getClasses: offline, no admin cache');
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _guard('getClasses', _remoteDataSource.getClasses));
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getClasses', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<AdminClassDetailEntity> getClassDetail(String classId) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getClassDetail: offline, no admin cache');
      return const Left(NetworkFailure('No internet connection.'));
    }
    AppLogger.state(_tag, 'getClassDetail($classId): online, calling remote');
    try {
      return Right(await _remoteDataSource.getClassDetail(classId));
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getClassDetail', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid createClass(({String name, String? teacherId}) params) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'createClass: offline, cannot create');
      return const Left(NetworkFailure('No internet connection.'));
    }
    AppLogger.state(_tag, 'createClass(${params.name}): online, calling remote');
    try {
      await _remoteDataSource.createClass(params);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'createClass', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid updateClass(
    ({String id, String name, String? teacherId}) params,
  ) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'updateClass: offline, cannot update');
      return const Left(NetworkFailure('No internet connection.'));
    }
    AppLogger.state(_tag, 'updateClass(${params.id}): online, calling remote');
    try {
      await _remoteDataSource.updateClass(params);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'updateClass', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid deleteClass(String id) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'deleteClass: offline, cannot delete');
      return const Left(NetworkFailure('No internet connection.'));
    }
    AppLogger.state(_tag, 'deleteClass($id): online, calling remote');
    try {
      await _remoteDataSource.deleteClass(id);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'deleteClass', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid addStudentToClass(
    ({String classId, String studentId}) params,
  ) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'addStudentToClass: offline, cannot update');
      return const Left(NetworkFailure('No internet connection.'));
    }
    AppLogger.state(
      _tag,
      'addStudentToClass(${params.studentId} -> ${params.classId}): '
      'online, calling remote',
    );
    try {
      await _remoteDataSource.addStudentToClass(params);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'addStudentToClass', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid removeStudentFromClass(
    ({String classId, String studentId}) params,
  ) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'removeStudentFromClass: offline, cannot update');
      return const Left(NetworkFailure('No internet connection.'));
    }
    AppLogger.state(
      _tag,
      'removeStudentFromClass(${params.studentId} from ${params.classId}): '
      'online, calling remote',
    );
    try {
      await _remoteDataSource.removeStudentFromClass(params);
      return const Right(null);
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'removeStudentFromClass', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<AssignmentEntity>> getAllAssessments() async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getAllAssessments: offline, no admin cache');
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(
        await _guard('getAllAssessments', _remoteDataSource.getAllAssessments),
      );
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getAllAssessments', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<TeacherSummaryEntity>> getTeachers() async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getTeachers: offline, no admin cache');
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _guard('getTeachers', _remoteDataSource.getTeachers));
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getTeachers', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<TeacherDetailEntity> getTeacherDetail(String teacherId) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getTeacherDetail: offline, no admin cache');
      return const Left(NetworkFailure('No internet connection.'));
    }
    AppLogger.state(_tag, 'getTeacherDetail($teacherId): online, calling remote');
    try {
      return Right(await _remoteDataSource.getTeacherDetail(teacherId));
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getTeacherDetail', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<StudentSummaryEntity>> getStudents() async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getStudents: offline, no admin cache');
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _guard('getStudents', _remoteDataSource.getStudents));
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getStudents', error);
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<StudentDetailEntity> getStudentDetail(String studentId) async {
    if (!await _networkInfo.isConnected) {
      AppLogger.state(_tag, 'getStudentDetail: offline, no admin cache');
      return const Left(NetworkFailure('No internet connection.'));
    }
    AppLogger.state(_tag, 'getStudentDetail($studentId): online, calling remote');
    try {
      return Right(await _remoteDataSource.getStudentDetail(studentId));
    } on ServerException catch (error) {
      AppLogger.error(_tag, 'getStudentDetail', error);
      return Left(ServerFailure(error.message));
    }
  }
}
