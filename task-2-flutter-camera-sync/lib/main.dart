import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'app/di.dart';
import 'workers/sync_worker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher);
  final deps = await AppDependencies.create();
  await deps.syncCoordinator.start();
  runApp(const MaterialApp(home: Scaffold()));
}
