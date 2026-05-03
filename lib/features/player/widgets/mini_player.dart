import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme.dart';
import '../../../services/audio_service.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    final track = audioService.currentTrack;

    if (track == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const FullPlayerSheet(),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: const Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            StreamBuilder<Duration?>(
              stream: audioService.player.positionStream,
              builder: (context, posSnap) {
                return StreamBuilder<Duration?>(
                  stream: audioService.player.durationStream,
                  builder: (context, durSnap) {
                    final position = posSnap.data ?? Duration.zero;
                    final duration = durSnap.data ?? Duration.zero;
                    final progress = duration.inMilliseconds > 0
                        ? position.inMilliseconds / duration.inMilliseconds
                        : 0.0;
                    return LinearProgressIndicator(
                      value: progress,
                      minHeight: 2.5,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    );
                  },
                );
              },
            ),
            // Controls
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Surah icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${track.id}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Consumer<AudioService>(
                          builder: (context, audio, child) {
                            return Text(
                              audio.currentReciterName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Previous
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 28),
                    color: AppColors.textSecondary,
                    onPressed: audioService.player.hasPrevious
                        ? () => audioService.skipToPrevious()
                        : null,
                  ),
                  // Play / Pause
                  StreamBuilder<PlayerState>(
                    stream: audioService.player.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final processing = playerState?.processingState;
                      final playing = playerState?.playing ?? false;

                      if (processing == ProcessingState.loading ||
                          processing == ProcessingState.buffering) {
                        return const SizedBox(
                          width: 40,
                          height: 40,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }

                      return Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: AppColors.white,
                            size: 26,
                          ),
                          onPressed: () {
                            if (playing) {
                              audioService.pause();
                            } else {
                              audioService.play();
                            }
                          },
                        ),
                      );
                    },
                  ),
                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 28),
                    color: AppColors.textSecondary,
                    onPressed: audioService.player.hasNext
                        ? () => audioService.skipToNext()
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
