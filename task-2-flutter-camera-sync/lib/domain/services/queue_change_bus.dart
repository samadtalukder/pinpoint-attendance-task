/// Tells the UI that the queue changed outside its own actions, e.g. the
/// background worker uploaded an image. The database stays the source of
/// truth; listeners reload from it.
abstract interface class QueueChangeBus {
  Stream<void> get changes;

  void notify();
}
