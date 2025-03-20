import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/core/Presentation/app.dart';

Future<void> main() async {
  await Hive.initFlutter();
  await Hive.openBox('settings');
  return runApp(const App());
}
