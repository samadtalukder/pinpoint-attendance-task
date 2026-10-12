/// Schedules the background job that drains the upload queue.
abstract interface class SyncScheduler {
  /// Ensures a sync job is queued. It runs once a network is available and
  /// retries with exponential backoff while uploads fail.
  ///
  /// With [immediate] an already scheduled job is replaced so its backoff
  /// restarts at zero (network came back, or the user asked to retry).
  Future<void> requestSync({bool immediate = false});
}
