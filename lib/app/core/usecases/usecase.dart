import 'package:equatable/equatable.dart';

import 'package:casppa/app/core/utils/typedefs.dart';

abstract class UseCase<T, Params> {
  const UseCase();

  ResultFuture<T> call(Params params);
}

/// For long-lived, push-driven data (e.g. a Supabase Realtime channel)
/// that doesn't fit the one-shot `ResultFuture` shape above.
abstract class StreamUseCase<T, Params> {
  const StreamUseCase();

  Stream<T> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
