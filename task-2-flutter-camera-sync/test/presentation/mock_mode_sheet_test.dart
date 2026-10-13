import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinpoint_capture/core/strings.dart';
import 'package:pinpoint_capture/domain/services/mock_upload_mode_store.dart';
import 'package:pinpoint_capture/presentation/settings/mock_mode_cubit.dart';
import 'package:pinpoint_capture/presentation/settings/mock_mode_sheet.dart';

class FakeModeStore implements MockUploadModeStore {
  FakeModeStore(this.mode);

  MockUploadMode mode;

  @override
  Future<MockUploadMode> read() async => mode;

  @override
  Future<void> write(MockUploadMode mode) async => this.mode = mode;
}

void main() {
  group('MockModeCubit', () {
    test('load reads the stored mode', () async {
      final cubit = MockModeCubit(FakeModeStore(MockUploadMode.failure));
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state, MockUploadMode.failure);
    });

    test('select persists and emits', () async {
      final store = FakeModeStore(MockUploadMode.success);
      final cubit = MockModeCubit(store);
      addTearDown(cubit.close);

      await cubit.select(MockUploadMode.slow);

      expect(store.mode, MockUploadMode.slow);
      expect(cubit.state, MockUploadMode.slow);
    });
  });

  testWidgets('sheet lists the three results and switches', (tester) async {
    final store = FakeModeStore(MockUploadMode.success);
    final cubit = MockModeCubit(store);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => MockModeSheet.show(context, cubit),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.mockSuccess), findsOneWidget);
    expect(find.text(AppStrings.mockFailure), findsOneWidget);
    expect(find.text(AppStrings.mockSlow), findsOneWidget);

    await tester.tap(find.text(AppStrings.mockFailure));
    await tester.pumpAndSettle();

    expect(store.mode, MockUploadMode.failure);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
  });
}
