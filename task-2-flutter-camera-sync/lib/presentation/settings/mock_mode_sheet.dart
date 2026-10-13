import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/strings.dart';
import '../../domain/services/mock_upload_mode_store.dart';
import 'mock_mode_cubit.dart';

/// Bottom sheet to pick the mock upload result. Expects a [MockModeCubit].
class MockModeSheet extends StatelessWidget {
  const MockModeSheet({super.key});

  static Future<void> show(BuildContext context, MockModeCubit cubit) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const MockModeSheet()),
    );
  }

  static const _labels = {
    MockUploadMode.success: AppStrings.mockSuccess,
    MockUploadMode.failure: AppStrings.mockFailure,
    MockUploadMode.slow: AppStrings.mockSlow,
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MockModeCubit>();
    return SafeArea(
      child: BlocBuilder<MockModeCubit, MockUploadMode>(
        builder: (context, selected) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                AppStrings.menuMockMode,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final entry in _labels.entries)
              ListTile(
                key: ValueKey(entry.key),
                selected: entry.key == selected,
                leading: Icon(
                  entry.key == selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(entry.value),
                onTap: () => cubit.select(entry.key),
              ),
          ],
        ),
      ),
    );
  }
}
