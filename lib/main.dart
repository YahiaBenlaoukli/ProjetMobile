import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/biometric_service.dart';
import 'services/auth_service.dart';
import 'services/audio_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'features/auth/screens/biometric_screen.dart';
import 'features/auth/screens/auth_wrapper.dart';
import 'features/player/screens/player_screen.dart';
import 'features/library/screens/favorites_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Just Audio Background
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.test1.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase initialization error (ignored for stub): $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BiometricService>(create: (_) => BiometricService()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<AudioService>(create: (_) => AudioService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<StorageService>(create: (_) => StorageService()),
      ],
      child: MaterialApp(
        title: 'Secure Audio App',
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          primaryColor: Colors.deepPurple,
          colorScheme: const ColorScheme.dark(
            primary: Colors.deepPurple,
            secondary: Colors.purpleAccent,
          ),
        ),
        home: const BiometricScreen(
          nextScreen: AuthWrapper(
            child: MainScreen(),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PlayerScreen(),
    const FavoritesScreen(),
    const DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Audio App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Player',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}



