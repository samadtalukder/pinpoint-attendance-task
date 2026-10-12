import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import '../../core/constants.dart';
import '../../domain/services/queue_change_bus.dart';

/// Carries "queue changed" from the worker isolate to the UI isolate through
/// a named port. Only an instance that is listened to registers the port, so
/// the worker's instance never steals the UI's mapping.
class IsolateQueueChangeBus implements QueueChangeBus {
  IsolateQueueChangeBus() {
    _controller = StreamController<void>.broadcast(
      onListen: _register,
      onCancel: _unregister,
    );
  }

  late final StreamController<void> _controller;
  ReceivePort? _port;

  @override
  Stream<void> get changes => _controller.stream;

  @override
  void notify() {
    IsolateNameServer.lookupPortByName(SyncConstants.queueChangePortName)
        ?.send(null);
  }

  void _register() {
    final port = ReceivePort()..listen((_) => _controller.add(null));
    IsolateNameServer.removePortNameMapping(SyncConstants.queueChangePortName);
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      SyncConstants.queueChangePortName,
    );
    _port = port;
  }

  void _unregister() {
    IsolateNameServer.removePortNameMapping(SyncConstants.queueChangePortName);
    _port?.close();
    _port = null;
  }
}
