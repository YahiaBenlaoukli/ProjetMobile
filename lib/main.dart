import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/theme.dart';
import 'services/biometric_service.dart';
import 'services/auth_service.dart';
import 'services/audio_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/quran_api_service.dart';
import 'services/download_service.dart';
import 'features/auth/screens/biometric_screen.dart';
import 'features/auth/screens/auth_wrapper.dart';
import 'features/quran/screens/surah_list_screen.dart';
import 'features/azkar/screens/azkar_screen.dart';
import 'features/prayer/screens/prayer_times_screen.dart';
import 'features/player/widgets/mini_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.test1.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadService = DownloadService();

    return MultiProvider(
      providers: [
        Provider<BiometricService>(create: (_) => BiometricService()),
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<DownloadService>.value(value: downloadService),
        ChangeNotifierProvider<AudioService>(
          create: (_) => AudioService(downloadService),
        ),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<QuranApiService>(create: (_) => QuranApiService()),
      ],
      child: MaterialApp(
        title: 'Quran App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
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

  static const List<_Tab> _tabs = [
    _Tab(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: "Qur'an",
      title: 'القرآن الكريم',
    ),
    _Tab(
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories_rounded,
      label: 'Azkar',
      title: 'الأذكار والأدعية',
    ),
    _Tab(
      icon: Icons.access_time_outlined,
      activeIcon: Icons.access_time_filled_rounded,
      label: 'Prayer',
      title: 'مواقيت الصلاة',
    ),
  ];

  final List<Widget> _screens = const [
    SurahListScreen(),
    AzkarScreen(),
    PrayerTimesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final tab = _tabs[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tab.title,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textHint, size: 22),
            onPressed: () => authService.signOut(),
            tooltip: 'Sign out',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider,
            height: 1,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player
          const MiniPlayer(),
          // Bottom nav
          Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_tabs.length, (index) {
                    final t = _tabs[index];
                    final selected = index == _currentIndex;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _currentIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primarySurface
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selected ? t.activeIcon : t.icon,
                              size: 24,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textHint,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              t.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String title;

  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.title,
  });
}
