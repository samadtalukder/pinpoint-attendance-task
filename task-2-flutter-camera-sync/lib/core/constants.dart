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
  static const String pausePreferenceKey = 'sync_paused';

  /// Unique work name: only one sync job exists at a time, so there is a
  /// single uploader.
  static const String uniqueWorkName = 'pinpoint.upload_sync';
  static const String syncTaskName = 'upload_queue';

  /// IsolateNameServer name the UI registers to hear queue changes made by
  /// the worker.
  static const String queueChangePortName = 'pinpoint.queue_changes';
}

/// Zoom presets shown as rounded buttons.
abstract final class ZoomConstants {
  static const double ultraWide = 0.5;
  static const double main = 1.0;
  static const double telephoto = 2.0;

  /// A preset counts as active when the zoom is this close to it.
  static const double activeTolerance = 0.05;
}

abstract final class StorageConstants {
  /// Folder under the app documents directory for queued images.
  static const String capturesDirectory = 'captures';

  /// Stored images are named IMG_yyyyMMdd_HHmmss.jpg.
  static const String imageNamePrefix = 'IMG_';
  static const String defaultImageExtension = '.jpg';
}

/// Demo batch added from the Upload Manager menu, so the queue can be shown
/// without taking photos.
abstract final class SampleConstants {
  static const int imageCount = 4;
  static const int imageSizeBytes = 1800000;
  static const String pathPrefix = 'sample://';
  static const String namePrefix = 'SAMPLE_';
}
