import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  const HiveService._();

  static Future<void> init() async {
    await Hive.initFlutter();
  }
}
