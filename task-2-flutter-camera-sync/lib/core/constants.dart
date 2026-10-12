/// Database file and table names.
abstract final class DbConstants {
  static const String fileName = 'pinpoint_capture.db';
  static const int version = 1;
  static const String batchesTable = 'batches';
  static const String uploadsTable = 'uploads';
}

/// Upload and retry tuning.
abstract final class SyncConstants {
  /// One image must finish within this, or the attempt counts as a failure
  /// (low bandwidth).
  static const Duration uploadTimeout = Duration(seconds: 15);

  /// Worker backoff: workmanager doubles the delay after each failed run.
  static const Duration initialBackoff = Duration(seconds: 10);

  static const Duration mockLatency = Duration(milliseconds: 800);

  /// Longer than [uploadTimeout], so "slow" mode always times out.
  static const Duration mockSlowLatency = Duration(seconds: 30);

  static const String modePreferenceKey = 'mock_upload_mode';
}
