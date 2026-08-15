import 'package:hive/hive.dart';

import 'package:casppa/app/core/errors/exceptions.dart';
import 'package:casppa/app/core/utils/app_constants.dart';

abstract class OnboardingLocalDataSource {
  Future<bool> hasCompletedOnboarding();

  Future<void> completeOnboarding();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  const OnboardingLocalDataSourceImpl(this._onboardingBox);

  final Box<dynamic> _onboardingBox;

  @override
  Future<bool> hasCompletedOnboarding() async {
    try {
      return _onboardingBox.get(
        HiveKeys.hasCompletedOnboarding,
        defaultValue: false,
      ) as bool;
    } catch (error) {
      throw CacheException(error.toString());
    }
  }

  @override
  Future<void> completeOnboarding() async {
    try {
      await _onboardingBox.put(HiveKeys.hasCompletedOnboarding, true);
    } catch (error) {
      throw CacheException(error.toString());
    }
  }
}
