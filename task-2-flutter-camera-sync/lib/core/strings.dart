/// User-facing text. One place so wording stays consistent and can be moved
/// to localization later.
abstract final class AppStrings {
  static const String appName = 'Pinpoint Capture';

  // Camera
  static const String cameraStarting = 'Starting camera…';
  static const String takePhoto = 'Take photo';
  static const String openUploads = 'Open upload manager';
  static const String uploadsTitle = 'Upload Manager';
  static const String zoomSlider = 'Zoom';
  static const String focusHint = 'Tap the preview to focus';
  static const String batchEmptyLabel = 'No photos in this batch';
  static const String uploadBatchEmpty = 'Take photos to start a batch';

  static String uploadBatch(int count) => 'Upload batch ($count)';
  static String zoomPreset(String label) => 'Zoom $label';
  static String zoomValue(String value) => '${value}x';
  static String batchPhotoCount(int count) =>
      count == 1 ? '1 photo in this batch' : '$count photos in this batch';
  static String batchQueued(int count) => count == 1
      ? '1 photo queued for upload'
      : '$count photos queued for upload';

  static const String captureFailed = 'Could not take the photo. Try again.';
  static const String queueFailed =
      'Could not queue the batch. Your photos are kept, try again.';

  // Camera blocked states
  static const String permissionDeniedTitle = 'Camera access needed';
  static const String permissionDeniedBody =
      'Pinpoint Capture needs the camera to take photos for upload.';
  static const String grantPermission = 'Allow camera';
  static const String permissionBlockedTitle = 'Camera access is blocked';
  static const String permissionBlockedBody =
      'Allow the camera for Pinpoint Capture in system settings, then come back.';
  static const String openSettings = 'Open settings';
  static const String noCameraTitle = 'No camera found';
  static const String noCameraBody =
      'This device has no back camera, so photos cannot be taken.';
  static const String cameraErrorTitle = 'Camera unavailable';
  static const String cameraErrorBody =
      'The camera could not start. Close other apps using it and try again.';
  static const String tryAgain = 'Try again';

  // Upload Manager
  static const String pendingUploadsHeader = 'Pending uploads';
  static const String syncedHeader = 'Synced';
  static const String batchSyncProgress = 'Batch sync progress';
  static const String online = 'Online';
  static const String offline = 'Offline';
  static const String retryNow = 'Retry now';
  static const String startNewBatch = 'Start new upload batch';
  static const String emptyTitle = 'No uploads yet';
  static const String emptyBody =
      'Photos you capture are queued here and uploaded automatically, even '
      'after you close the app.';
  static const String menuMockMode = 'Mock upload result';
  static const String mockSuccess = 'Success';
  static const String mockFailure = 'Failure (no internet)';
  static const String mockSlow = 'Slow connection (times out)';
  static const String addSampleBatch = 'Add sample batch';
  static const String clearSynced = 'Clear synced';
  static const String moreOptions = 'More options';
  static const String loadingQueue = 'Loading uploads…';

  static const String statusWaitingOffline = 'Waiting for connection';
  static const String statusWaiting = 'Waiting to upload';
  static const String statusUploading = 'Uploading…';
  static const String statusSynced = 'Synced';
  static String statusRetrying(int attempt) => 'Retrying… (attempt $attempt)';
  static String uploadedCount(int synced, int total) =>
      '$synced of $total uploaded';
  static String progressSemantics(int percent) =>
      'Upload progress $percent percent';
  static String sizeProgress(String done, String total) => '$done / $total';

  static const String feedbackRetrying = 'Retrying uploads now';
  static const String feedbackCleared = 'Synced uploads cleared';
  static const String feedbackSampleAdded = 'Sample batch queued';
  static const String feedbackActionFailed =
      'That did not work. Please try again.';
}
