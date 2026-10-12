import '../../core/constants.dart';
import '../../domain/entities/pending_upload.dart';
import '../../domain/services/mock_upload_mode_store.dart';
import '../../domain/services/upload_api.dart';

typedef Delay = Future<void> Function(Duration duration);

/// Stand-in for the backend: no API was provided, so the result is chosen by
/// [MockUploadMode]. The mode is read on every call so a toggle made in the UI
/// reaches the background worker.
class MockUploadApi implements UploadApi {
  MockUploadApi(this._modeStore, {this._delay = Future<void>.delayed});

  final MockUploadModeStore _modeStore;
  final Delay _delay;

  static const String offlineMessage = 'No internet connection';

  @override
  Future<void> upload(PendingUpload item) async {
    switch (await _modeStore.read()) {
      case MockUploadMode.success:
        await _delay(SyncConstants.mockLatency);
      case MockUploadMode.failure:
        await _delay(SyncConstants.mockLatency);
        throw const UploadException(offlineMessage);
      case MockUploadMode.slow:
        await _delay(SyncConstants.mockSlowLatency);
    }
  }
}

// Real implementation sketch, kept commented because no API was provided:
//
// class HttpUploadApi implements UploadApi {
//   HttpUploadApi(this._client, this._baseUrl);
//   final http.Client _client;
//   final Uri _baseUrl;
//
//   @override
//   Future<void> upload(PendingUpload item) async {
//     final request = http.MultipartRequest('POST', _baseUrl.resolve('/uploads'))
//       ..files.add(await http.MultipartFile.fromPath('image', item.filePath));
//     final response = await _client.send(request);
//     if (response.statusCode >= 400) {
//       throw UploadException('Server error ${response.statusCode}');
//     }
//   }
// }
