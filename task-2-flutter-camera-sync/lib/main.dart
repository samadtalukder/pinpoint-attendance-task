import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'workers/sync_worker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher);
  final dependencies = await AppDependencies.create();
  await dependencies.syncCoordinator.start();
  runApp(PinpointApp(dependencies: dependencies));
}
