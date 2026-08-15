import 'package:casppa/app/core/di/injection_container.dart';
import 'package:casppa/app/core/services/hive_service.dart';
import 'package:casppa/app/core/utils/app_constants.dart';
import 'package:casppa/app/data/auth/models/user_model.dart';
import 'package:casppa/app/my_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  Hive.registerAdapter(UserModelAdapter());
  await Hive.openBox<dynamic>(HiveBoxes.authBox);
  await Hive.openBox<dynamic>(HiveBoxes.onboardingBox);
  await Hive.openBox<dynamic>(HiveBoxes.assignmentsBox);

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabasePublishableKey,
  );

  await initDependencies();

  runApp(const ProviderScope(child: MyApp()));
}
