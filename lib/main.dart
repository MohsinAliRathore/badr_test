import 'package:flutter/material.dart';

import 'app.dart';
import 'di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deps = await AppDependencies.create();
  runApp(BadrgoApp(deps: deps));
}
