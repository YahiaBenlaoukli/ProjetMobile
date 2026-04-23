import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../../services/audio_service.dart';
import '../../../services/firestore_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final audioService = context.read<AudioService>();
      if (audioService.tracks.isEmpty) {
        audioService.fetchAndLoadPlaylist().then((_) {
          if (mounted) setState(() {});
        });
      }
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    final player = audioService.player;

    if (audioService.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quran Playlist')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: audioService.tracks.length,
              itemBuilder: (context, index) {
                final track = audioService.tracks[index];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(track.title),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      context.read<FirestoreService>().addFavorite(track.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to favorites')),
                      );
                    },
                  ),
                  onTap: () {
                    player.seek(Duration.zero, index: index);
                    player.play();
                    context.read<FirestoreService>().recordPlay();
                  },
                );
              },
            ),
          ),
          // Player Controls
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.deepPurple.shade900,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<SequenceState?>(
                  stream: player.sequenceStateStream,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    if (state?.sequence.isEmpty ?? true) {
                      return const Text('No track selected');
                    }
                    final metadata = state!.currentSource!.tag as MediaItem;
                    return Text(
                      metadata.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: player.hasPrevious ? player.seekToPrevious : null,
                    ),
                    StreamBuilder<PlayerState>(
                      stream: player.playerStateStream,
                      builder: (context, snapshot) {
                        final playerState = snapshot.data;
                        final processingState = playerState?.processingState;
                        final playing = playerState?.playing;

                        if (processingState == ProcessingState.loading ||
                            processingState == ProcessingState.buffering) {
                          return Container(
                            margin: const EdgeInsets.all(8.0),
                            width: 32.0,
                            height: 32.0,
                            child: const CircularProgressIndicator(),
                          );
                        } else if (playing != true) {
                          return IconButton(
                            icon: const Icon(Icons.play_arrow),
                            iconSize: 48.0,
                            onPressed: player.play,
                          );
                        } else if (processingState != ProcessingState.completed) {
                          return IconButton(
                            icon: const Icon(Icons.pause),
                            iconSize: 48.0,
                            onPressed: player.pause,
                          );
                        } else {
                          return IconButton(
                            icon: const Icon(Icons.replay),
                            iconSize: 48.0,
                            onPressed: () => player.seek(Duration.zero, index: player.effectiveIndices.first),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: player.hasNext ? player.seekToNext : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
