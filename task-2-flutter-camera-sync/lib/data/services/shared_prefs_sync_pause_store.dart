import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../domain/services/sync_pause_store.dart';

/// Async preferences read the platform store directly, so a value written in
/// the UI isolate is visible in the worker isolate.
class SharedPrefsSyncPauseStore implements SyncPauseStore {
  SharedPrefsSyncPauseStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<bool> isPaused() async =>
      await _prefs.getBool(SyncConstants.pausePreferenceKey) ?? false;

  @override
  Future<void> write(bool paused) =>
      _prefs.setBool(SyncConstants.pausePreferenceKey, paused);
}
