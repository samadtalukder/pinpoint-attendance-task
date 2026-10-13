import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import 'upload_queue_cubit.dart';
import 'upload_queue_state.dart';
import 'widgets/connection_chip.dart';
import 'widgets/sync_progress_header.dart';
import 'widgets/upload_tile.dart';

/// Pending uploads with live status. Expects an [UploadQueueCubit] above it.
class UploadManagerScreen extends StatelessWidget {
  const UploadManagerScreen({super.key, required this.onStartNewBatch});

  final VoidCallback onStartNewBatch;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UploadQueueCubit, UploadQueueState>(
      listenWhen: (previous, current) =>
          current.feedback != UploadQueueFeedback.none &&
          previous.feedback != current.feedback,
      listener: _showFeedback,
      builder: (context, state) {
        final cubit = context.read<UploadQueueCubit>();
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: Text(
              AppStrings.uploadsTitle,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ConnectionChip(online: state.isOnline),
              ),
              PopupMenuButton<_MenuAction>(
                tooltip: AppStrings.moreOptions,
                onSelected: (action) => switch (action) {
                  _MenuAction.retryNow => cubit.retryNow(),
                  _MenuAction.addSample => cubit.addSampleBatch(),
                  _MenuAction.clearSynced => cubit.clearSynced(),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _MenuAction.retryNow,
                    enabled: state.pendingCount > 0 && !state.isUploading,
                    child: const Text(AppStrings.retryNow),
                  ),
                  const PopupMenuItem(
                    value: _MenuAction.addSample,
                    child: Text(AppStrings.addSampleBatch),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.clearSynced,
                    enabled: state.hasSynced,
                    child: const Text(AppStrings.clearSynced),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(child: _Body(state: state)),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: onStartNewBatch,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text(AppStrings.startNewBatch),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFeedback(BuildContext context, UploadQueueState state) {
    final message = switch (state.feedback) {
      UploadQueueFeedback.retrying => AppStrings.feedbackRetrying,
      UploadQueueFeedback.cleared => AppStrings.feedbackCleared,
      UploadQueueFeedback.sampleAdded => AppStrings.feedbackSampleAdded,
      UploadQueueFeedback.actionFailed => AppStrings.feedbackActionFailed,
      UploadQueueFeedback.none => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
    context.read<UploadQueueCubit>().feedbackShown();
  }
}

enum _MenuAction { retryNow, addSample, clearSynced }

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final UploadQueueState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_done_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(AppStrings.emptyTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                AppStrings.emptyBody,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final cubit = context.read<UploadQueueCubit>();
    final pending = state.pending;
    final synced = state.synced;
    return ListView(
      children: [
        SyncProgressHeader(
          state: state,
          onPause: cubit.pauseAll,
          onResume: cubit.resume,
        ),
        if (pending.isNotEmpty) ...[
          _SectionHeader(
            '${AppStrings.pendingUploadsHeader} (${pending.length})',
          ),
          for (final item in pending)
            UploadTile(
              key: ValueKey(item.id),
              upload: item,
              online: state.isOnline,
              paused: state.isPaused,
            ),
        ],
        if (synced.isNotEmpty) ...[
          _SectionHeader('${AppStrings.syncedHeader} (${synced.length})'),
          for (final item in synced)
            UploadTile(
              key: ValueKey(item.id),
              upload: item,
              online: state.isOnline,
              paused: state.isPaused,
            ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: AppTheme.label(
            context,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
