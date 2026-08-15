import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/di/injection_container.dart';
import 'package:casppa/app/core/usecases/usecase.dart';
import 'package:casppa/app/domain/admin/entities/student_summary_entity.dart';
import 'package:casppa/app/domain/parent/usecases/get_child_detail_usecase.dart';
import 'package:casppa/app/domain/parent/usecases/get_children_usecase.dart';

final getChildrenUseCaseProvider = Provider<GetChildrenUseCase>((ref) => sl());
final getChildDetailUseCaseProvider = Provider<GetChildDetailUseCase>(
  (ref) => sl(),
);

final parentChildrenProvider =
    FutureProvider.autoDispose<List<StudentSummaryEntity>>((ref) async {
      final result = await ref
          .read(getChildrenUseCaseProvider)
          .call(const NoParams());

      return result.fold((failure) => throw failure, (children) => children);
    });

final childDetailProvider = FutureProvider.autoDispose
    .family<StudentDetailEntity, String>((ref, childId) async {
      final result = await ref
          .read(getChildDetailUseCaseProvider)
          .call(childId);

      return result.fold((failure) => throw failure, (detail) => detail);
    });
