import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../app/di.dart';
import '../core/constants.dart';
import '../domain/usecases/process_upload_queue_use_case.dart';

/// Entry point the OS calls to run background work, also when the app is
/// closed. Must be a top-level function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != SyncConstants.syncTaskName) return true;
    try {
      final deps = await AppDependencies.create();
      final result = await deps.processUploadQueue();
      // false asks the OS to retry with the exponential backoff set when
      // the work was scheduled.
      return result != SyncResult.failed;
    } catch (error, stack) {
      debugPrint('Sync worker failed: $error\n$stack');
      return false;
    }
  });
}
