import 'package:workmanager/workmanager.dart';

import '../../core/constants.dart';
import '../../domain/services/sync_scheduler.dart';

class WorkmanagerSyncScheduler implements SyncScheduler {
  @override
  Future<void> requestSync({bool immediate = false}) {
    return Workmanager().registerOneOffTask(
      SyncConstants.uniqueWorkName,
      SyncConstants.syncTaskName,
      constraints: Constraints(networkType: NetworkType.connected),
      // keep: do not disturb a pending job's backoff or a running upload.
      // replace: network is back or the user asked, so retry now.
      existingWorkPolicy: immediate
          ? ExistingWorkPolicy.replace
          : ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: SyncConstants.initialBackoff,
    );
  }
}
