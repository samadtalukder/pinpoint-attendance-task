abstract interface class ConnectivityService {
  /// Whether a network interface is currently available. A reachable server
  /// is only proven by an upload succeeding.
  Future<bool> isOnline();

  /// Emits when availability changes.
  Stream<bool> get onlineChanges;
}
