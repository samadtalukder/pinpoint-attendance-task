/// What the mock API does on the next upload.
enum MockUploadMode {
  success,

  /// Fails like a lost connection.
  failure,

  /// Takes longer than the upload timeout, like very low bandwidth.
  slow,
}

/// Persists the mock mode so the background worker sees the same toggle as
/// the UI.
abstract interface class MockUploadModeStore {
  Future<MockUploadMode> read();

  Future<void> write(MockUploadMode mode);
}
