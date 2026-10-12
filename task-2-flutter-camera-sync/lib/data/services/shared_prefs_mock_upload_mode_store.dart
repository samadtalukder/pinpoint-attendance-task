import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../domain/services/mock_upload_mode_store.dart';

/// Uses the async preferences API, which reads the platform store directly,
/// so a value written in the UI isolate is visible in the worker isolate.
class SharedPrefsMockUploadModeStore implements MockUploadModeStore {
  SharedPrefsMockUploadModeStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<MockUploadMode> read() async {
    final name = await _prefs.getString(SyncConstants.modePreferenceKey);
    return MockUploadMode.values.asNameMap()[name] ?? MockUploadMode.success;
  }

  @override
  Future<void> write(MockUploadMode mode) =>
      _prefs.setString(SyncConstants.modePreferenceKey, mode.name);
}
