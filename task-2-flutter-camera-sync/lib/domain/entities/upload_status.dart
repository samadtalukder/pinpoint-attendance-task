enum UploadStatus {
  /// Queued, no attempt in flight.
  waiting,

  /// An upload attempt is running now.
  uploading,

  /// At least one attempt failed; will be retried.
  retrying,

  /// Uploaded and acknowledged by the server.
  synced;

  bool get isPending => this != synced;
}
