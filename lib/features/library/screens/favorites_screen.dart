import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/audio_service.dart';
import '../../../services/biometric_service.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<FirestoreService>();
    final audioService = context.read<AudioService>();
    final biometricService = context.read<BiometricService>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: StreamBuilder<List<int>>(
        stream: firestoreService.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const Center(child: Text('No favorites yet.'));
          }

          final favoriteTracks = audioService.tracks
              .where((track) => favorites.contains(track.id))
              .toList();

          return ListView.builder(
            itemCount: favoriteTracks.length,
            itemBuilder: (context, index) {
              final track = favoriteTracks[index];
              return ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: Text(track.title),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    // Biometric confirmation for sensitive action (delete)
                    final isSupported = await biometricService.isBiometricSupported();
                    bool canDelete = true;
                    
                    if (isSupported) {
                      canDelete = await biometricService.authenticate(
                        reason: 'Confirm deletion of favorite',
                      );
                    }

                    if (canDelete) {
                      await firestoreService.removeFavorite(track.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Removed from favorites')),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Authentication failed. Deletion cancelled.')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
