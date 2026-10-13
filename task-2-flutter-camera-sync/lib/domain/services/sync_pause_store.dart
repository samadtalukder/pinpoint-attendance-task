/// Persists the user's "pause all" choice so the background worker honors the
/// same flag as the UI.
abstract interface class SyncPauseStore {
  Future<bool> isPaused();

  Future<void> write(bool paused);
}
