import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/errors/failures.dart';
import 'package:casppa/app/core/services/network_info.dart';
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

  final AdminRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<AdminOverviewEntity> getOverview() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _remoteDataSource.getOverview());
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<SubjectOptionEntity>> getSubjects() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _remoteDataSource.getSubjects());
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid createSubject(String title) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      await _remoteDataSource.createSubject(title);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid updateSubject(({String id, String title}) params) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      await _remoteDataSource.updateSubject(params);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid deleteSubject(String id) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      await _remoteDataSource.deleteSubject(id);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<AdminClassEntity>> getClasses() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _remoteDataSource.getClasses());
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<AdminClassDetailEntity> getClassDetail(String classId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _remoteDataSource.getClassDetail(classId));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid createClass(({String name, String? teacherId}) params) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      await _remoteDataSource.createClass(params);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid updateClass(
    ({String id, String name, String? teacherId}) params,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      await _remoteDataSource.updateClass(params);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid deleteClass(String id) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      await _remoteDataSource.deleteClass(id);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid addStudentToClass(
    ({String classId, String studentId}) params,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      await _remoteDataSource.addStudentToClass(params);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultVoid removeStudentFromClass(
    ({String classId, String studentId}) params,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      await _remoteDataSource.removeStudentFromClass(params);
      return const Right(null);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<AssignmentEntity>> getAllAssessments() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _remoteDataSource.getAllAssessments());
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<TeacherSummaryEntity>> getTeachers() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _remoteDataSource.getTeachers());
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<TeacherDetailEntity> getTeacherDetail(String teacherId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _remoteDataSource.getTeacherDetail(teacherId));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<List<StudentSummaryEntity>> getStudents() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _remoteDataSource.getStudents());
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }

  @override
  ResultFuture<StudentDetailEntity> getStudentDetail(String studentId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection.'));
    }
    try {
      return Right(await _remoteDataSource.getStudentDetail(studentId));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    }
  }
}
