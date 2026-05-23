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
import 'services/secure_storage_service.dart';
import 'features/auth/screens/biometric_screen.dart';
import 'features/auth/screens/auth_wrapper.dart';
import 'features/quran/screens/surah_list_screen.dart';
import 'features/azkar/screens/azkar_screen.dart';
import 'features/prayer/screens/prayer_times_screen.dart';
import 'features/player/widgets/mini_player.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

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
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider<AudioService>(
          create: (context) => AudioService(
            downloadService,
            context.read<FirestoreService>(),
          ),
        ),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<QuranApiService>(create: (_) => QuranApiService()),
        Provider<SecureStorageService>(create: (_) => SecureStorageService()),
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
    _Tab(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Stats',
      title: 'الإحصائيات والنشاط',
    ),
  ];

  final List<Widget> _screens = const [
    SurahListScreen(),
    AzkarScreen(),
    PrayerTimesScreen(),
    DashboardScreen(),
  ];

  String _getInitials(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) return 'U';
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _getFirstName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) return 'User';
    return displayName.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final tab = _tabs[_currentIndex];
    final displayName = authService.currentUser?.displayName;
    final initials = _getInitials(displayName);
    final firstName = _getFirstName(displayName);

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 0,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Avatar with initials
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Greeting & Arabic title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ' weclome ,$firstName ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tab.title,
                      style: AppTheme.arabicStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.textHint, size: 20),
              onPressed: () => authService.signOut(),
              tooltip: 'Sign out',
              splashRadius: 20,
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_tabs.length, (index) {
                  final t = _tabs[index];
                  final selected = index == _currentIndex;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_currentIndex != index) {
                        setState(() => _currentIndex = index);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primarySurface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              selected ? t.activeIcon : t.icon,
                              key: ValueKey<bool>(selected),
                              size: 24,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textHint,
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 8),
                            Text(
                              t.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
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
