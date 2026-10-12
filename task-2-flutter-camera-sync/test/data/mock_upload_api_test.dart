import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint_capture/core/constants.dart';
import 'package:pinpoint_capture/data/services/mock_upload_api.dart';
import 'package:pinpoint_capture/data/services/shared_prefs_mock_upload_mode_store.dart';
import 'package:pinpoint_capture/domain/entities/pending_upload.dart';
import 'package:pinpoint_capture/domain/entities/upload_status.dart';
import 'package:pinpoint_capture/domain/services/mock_upload_mode_store.dart';
import 'package:pinpoint_capture/domain/services/upload_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeModeStore implements MockUploadModeStore {
  FakeModeStore(this.mode);

  MockUploadMode mode;

  @override
  Future<MockUploadMode> read() async => mode;

  @override
  Future<void> write(MockUploadMode mode) async => this.mode = mode;
}

void main() {
  final item = PendingUpload(
    id: 1,
    batchId: 1,
    filePath: '/img/a.jpg',
    fileName: 'a.jpg',
    sizeBytes: 10,
    status: UploadStatus.waiting,
    attempts: 0,
    createdAt: DateTime(2026, 10, 12),
  );

  group('MockUploadApi', () {
    late FakeModeStore store;
    late List<Duration> delays;
    late MockUploadApi api;

    setUp(() {
      store = FakeModeStore(MockUploadMode.success);
      delays = [];
      api = MockUploadApi(store, delay: (d) async => delays.add(d));
    });

    test('success completes after the simulated latency', () async {
      await api.upload(item);
      expect(delays, [SyncConstants.mockLatency]);
    });

    test('failure throws an offline UploadException', () async {
      store.mode = MockUploadMode.failure;
      await expectLater(
        api.upload(item),
        throwsA(
          isA<UploadException>().having(
            (e) => e.message,
            'message',
            MockUploadApi.offlineMessage,
          ),
        ),
      );
    });

    test('slow waits longer than the upload timeout', () async {
      store.mode = MockUploadMode.slow;
      await api.upload(item);
      expect(delays.single, greaterThan(SyncConstants.uploadTimeout));
    });

    test('mode is read on every call', () async {
      await api.upload(item);
      store.mode = MockUploadMode.failure;
      await expectLater(api.upload(item), throwsA(isA<UploadException>()));
    });
  });

  group('SharedPrefsMockUploadModeStore', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('defaults to success', () async {
      expect(
        await SharedPrefsMockUploadModeStore().read(),
        MockUploadMode.success,
      );
    });

    test('round trips a written mode', () async {
      final store = SharedPrefsMockUploadModeStore(SharedPreferencesAsync());
      await store.write(MockUploadMode.failure);
      expect(await store.read(), MockUploadMode.failure);
    });

    test('unknown stored value falls back to success', () async {
      await SharedPreferencesAsync().setString(
        SyncConstants.modePreferenceKey,
        'bogus',
      );
      expect(
        await SharedPrefsMockUploadModeStore().read(),
        MockUploadMode.success,
      );
    });
  });
}
