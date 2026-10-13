import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/mock_upload_mode_store.dart';

/// Which result the mock upload API returns. The worker reads the same store,
/// so a choice made here applies to background uploads too.
class MockModeCubit extends Cubit<MockUploadMode> {
  MockModeCubit(this._store) : super(MockUploadMode.success);

  final MockUploadModeStore _store;

  Future<void> load() async {
    final mode = await _store.read();
    if (!isClosed) emit(mode);
  }

  Future<void> select(MockUploadMode mode) async {
    await _store.write(mode);
    if (!isClosed) emit(mode);
  }
}
