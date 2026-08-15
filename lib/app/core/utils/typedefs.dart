import 'package:fpdart/fpdart.dart';

import 'package:casppa/app/core/errors/failures.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultVoid = ResultFuture<void>;
typedef DataMap = Map<String, dynamic>;
