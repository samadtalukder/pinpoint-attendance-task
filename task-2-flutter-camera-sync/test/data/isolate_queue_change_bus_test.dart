import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint_capture/data/services/isolate_queue_change_bus.dart';

void main() {
  test('notify reaches a listening bus', () async {
    final listener = IsolateQueueChangeBus();
    final worker = IsolateQueueChangeBus();
    final received = expectLater(listener.changes, emits(null));

    worker.notify();

    await received;
  });

  test('notify without a listener is a no-op', () {
    expect(IsolateQueueChangeBus().notify, returnsNormally);
  });
}
