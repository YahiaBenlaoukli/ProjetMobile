import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme.dart';
import '../../../services/audio_service.dart';
import '../../../services/download_service.dart';

class FullPlayerSheet extends StatelessWidget {
  const FullPlayerSheet({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    final downloadService = context.watch<DownloadService>();
    final track = audioService.currentTrack;
    final height = MediaQuery.of(context).size.height;

    if (track == null) return const SizedBox.shrink();

    return Container(
      height: height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          // Close & Download
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
                _DownloadButton(
                  surahId: track.id,
                  audioUrl: track.url,
                  downloadService: downloadService,
                ),
              ],
            ),
          ),
          const Spacer(flex: 1),
          // Surah Art
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Decorative pattern
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CustomPaint(painter: _IslamicPatternPainter()),
                  ),
                ),
                // Surah number
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${track.id}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: Colors.white70,
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 1,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'سورة',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white54,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Surah name
          Text(
            track.titleAr.isNotEmpty ? track.titleAr : track.title,
            style: const TextStyle(
              fontSize: 24,
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Consumer<AudioService>(
            builder: (context, audio, child) {
              return Text(
                audio.currentReciterName,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Verses
          Expanded(
            flex: 3,
            child: Consumer<AudioService>(
              builder: (context, audio, child) {
                if (audio.versesLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (audio.currentVerses.isEmpty) {
                  return const Center(
                    child: Text('No verses available', 
                        style: TextStyle(color: AppColors.textHint)),
                  );
                }

                return ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.1, 0.9, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    itemCount: audio.currentVerses.length,
                    itemBuilder: (context, index) {
                      final verse = audio.currentVerses[index];
                      final text = verse['text'] ?? '';
                      final number = verse['numberInSurah']?.toString() ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: text,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'serif',
                                  color: AppColors.textPrimary,
                                  height: 1.8,
                                ),
                              ),
                              const TextSpan(text: '  '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    number,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Seek bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: StreamBuilder<Duration?>(
              stream: audioService.player.positionStream,
              builder: (context, posSnap) {
                return StreamBuilder<Duration?>(
                  stream: audioService.player.durationStream,
                  builder: (context, durSnap) {
                    final position = posSnap.data ?? Duration.zero;
                    final duration = durSnap.data ?? Duration.zero;
                    final max =
                        duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.divider,
                            thumbColor: AppColors.primary,
                            overlayColor:
                                AppColors.primary.withValues(alpha: 0.15),
                          ),
                          child: Slider(
                            value: position.inMilliseconds
                                .toDouble()
                                .clamp(0, max),
                            max: max,
                            onChanged: (v) {
                              audioService
                                  .seek(Duration(milliseconds: v.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 40,
                color: AppColors.textPrimary,
                onPressed: audioService.player.hasPrevious
                    ? () => audioService.skipToPrevious()
                    : null,
              ),
              const SizedBox(width: 16),
              StreamBuilder<PlayerState>(
                stream: audioService.player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processing = playerState?.processingState;
                  final playing = playerState?.playing ?? false;

                  if (processing == ProcessingState.loading ||
                      processing == ProcessingState.buffering) {
                    return Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      if (playing) {
                        audioService.pause();
                      } else {
                        audioService.play();
                      }
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: AppColors.white,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 40,
                color: AppColors.textPrimary,
                onPressed: audioService.player.hasNext
                    ? () => audioService.skipToNext()
                    : null,
              ),
            ],
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final int surahId;
  final String audioUrl;
  final DownloadService downloadService;

  const _DownloadButton({
    required this.surahId,
    required this.audioUrl,
    required this.downloadService,
  });

  @override
  Widget build(BuildContext context) {
    final status = downloadService.getStatus(surahId);

    switch (status.state) {
      case DownloadState.none:
        return IconButton(
          icon: const Icon(Icons.download_rounded),
          color: AppColors.textSecondary,
          onPressed: () => downloadService.downloadSurah(surahId, audioUrl),
          tooltip: 'Download for offline',
        );
      case DownloadState.downloading:
        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: status.progress,
                strokeWidth: 2.5,
                color: AppColors.primary,
                backgroundColor: AppColors.divider,
              ),
              Text(
                '${(status.progress * 100).toInt()}',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      case DownloadState.completed:
        return IconButton(
          icon: const Icon(Icons.download_done_rounded),
          color: AppColors.success,
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Remove Download'),
                content: const Text('Delete the offline copy of this surah?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      downloadService.deleteSurah(surahId);
                      Navigator.pop(context);
                    },
                    child: const Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
          },
          tooltip: 'Downloaded',
        );
      case DownloadState.failed:
        return IconButton(
          icon: const Icon(Icons.error_outline_rounded),
          color: AppColors.error,
          onPressed: () => downloadService.downloadSurah(surahId, audioUrl),
          tooltip: 'Retry download',
        );
    }
  }
}

class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 30.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 12, paint);
      }
    }

    final diamondPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        final path = Path()
          ..moveTo(x, y - 8)
          ..lineTo(x + 8, y)
          ..lineTo(x, y + 8)
          ..lineTo(x - 8, y)
          ..close();
        canvas.drawPath(path, diamondPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
