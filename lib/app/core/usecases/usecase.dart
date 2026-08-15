import 'package:equatable/equatable.dart';

import 'package:casppa/app/core/utils/typedefs.dart';

abstract class UseCase<T, Params> {
  const UseCase();

  ResultFuture<T> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
