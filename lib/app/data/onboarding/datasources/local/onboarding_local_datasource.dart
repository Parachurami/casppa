import 'package:hive/hive.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/utils/app_constants.dart';
import 'package:casppa/app/core/utils/app_logger.dart';

abstract class OnboardingLocalDataSource {
  Future<bool> hasCompletedOnboarding();

  Future<void> completeOnboarding();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  const OnboardingLocalDataSourceImpl(this._onboardingBox);

  static const _tag = 'OnboardingLocalDataSource';

  final Box<dynamic> _onboardingBox;

  @override
  Future<bool> hasCompletedOnboarding() async {
    AppLogger.request(_tag, 'hasCompletedOnboarding');
    try {
      final result =
          _onboardingBox.get(
                HiveKeys.hasCompletedOnboarding,
                defaultValue: false,
              )
              as bool;
      AppLogger.response(_tag, 'hasCompletedOnboarding', result);
      return result;
    } catch (error) {
      AppLogger.error(_tag, 'hasCompletedOnboarding', error);
      throw CacheException(error.toString());
    }
  }

  @override
  Future<void> completeOnboarding() async {
    AppLogger.request(_tag, 'completeOnboarding');
    try {
      await _onboardingBox.put(HiveKeys.hasCompletedOnboarding, true);
      AppLogger.response(_tag, 'completeOnboarding');
    } catch (error) {
      AppLogger.error(_tag, 'completeOnboarding', error);
      throw CacheException(error.toString());
    }
  }
}
