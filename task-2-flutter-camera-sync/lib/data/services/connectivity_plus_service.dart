import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/services/connectivity_service.dart';

class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async =>
      _hasNetwork(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_hasNetwork).distinct();

  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
