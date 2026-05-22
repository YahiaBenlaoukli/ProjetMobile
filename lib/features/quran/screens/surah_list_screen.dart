import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/theme.dart';
import '../../../services/quran_api_service.dart';
import '../../../services/audio_service.dart';
import '../../../services/firestore_service.dart';
import 'surah_reader_screen.dart';
import 'quran_page_viewer.dart';
import 'reciter_selection_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final QuranApiService _api = QuranApiService();
  List<Map<String, dynamic>> _surahs = [];
  List<Map<String, dynamic>> _filteredSurahs = [];
  bool _isLoading = true;
  String _error = '';
  final TextEditingController _searchController = TextEditingController();
  Set<int> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final surahs = await _api.fetchSurahs();
      if (mounted) {
        final audio = context.read<AudioService>();
        if (!audio.tracksLoaded) {
          await audio.fetchReciters();
          if (audio.currentReciterId.isEmpty && audio.reciters.isNotEmpty) {
            final defaultReciter = audio.reciters.firstWhere(
              (r) => r['reciter_id'] == '1',
              orElse: () => audio.reciters.first,
            );
            await audio.selectReciter(defaultReciter);
          }
        }
      }
      if (mounted) {
        setState(() {
          _surahs = surahs;
          _filteredSurahs = surahs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterSurahs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSurahs = _surahs;
      } else {
        _filteredSurahs = _surahs.where((s) {
          final nameEn = (s['name_en'] ?? '').toString().toLowerCase();
          final nameAr = (s['name_ar'] ?? '').toString();
          final number = s['number'].toString();
          return nameEn.contains(query.toLowerCase()) ||
              nameAr.contains(query) ||
              number == query;
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading Surahs...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 56, color: AppColors.textHint),
              const SizedBox(height: 16),
              const Text('Unable to load surahs',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_error,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = '';
                  });
                  _loadData();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSurahs,
              decoration: InputDecoration(
                hintText: 'Search surah or number...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.textHint, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _filterSurahs('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredSurahs.length} Surahs',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReciterSelectionScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.record_voice_over_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Consumer<AudioService>(
                        builder: (context, audio, child) {
                          final name = audio.currentReciterName;
                          return Text(
                            name.isNotEmpty ? name : 'Mishary',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Surah list
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              return AnimationLimiter(
                child: isWide
                    ? GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 100, // Fixed height prevents bottom overflow
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredSurahs.length,
                        itemBuilder: (context, index) => AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          columnCount: 2,
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildSurahCard(index),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: _filteredSurahs.length,
                        itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildSurahCard(index),
                            ),
                          ),
                        ),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSurahCard(int index) {
    final surah = _filteredSurahs[index];
    return _SurahCard(
      surah: surah,
      isFavorite: _favorites.contains(
          int.tryParse(surah['number'].toString()) ?? 0),
      onToggleFavorite: (id) {
        setState(() {
          if (_favorites.contains(id)) {
            _favorites.remove(id);
          } else {
            _favorites.add(id);
          }
        });
      },
    );
  }
}

class _SurahCard extends StatefulWidget {
  final Map<String, dynamic> surah;
  final bool isFavorite;
  final ValueChanged<int> onToggleFavorite;

  const _SurahCard({
    required this.surah,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<_SurahCard> createState() => _SurahCardState();
}

class _SurahCardState extends State<_SurahCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final number = int.tryParse(widget.surah['number'].toString()) ?? 0;
    final nameAr = widget.surah['name_ar'] ?? '';
    final nameEn = widget.surah['name_en'] ?? '';
    final type = widget.surah['type'] ?? '';
    final ayatCount = widget.surah['ayat_count'] ?? '';
    final isMeccan = type == 'Meccan';

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SurahReaderScreen(
              surahNumber: number,
              surahNameEn: nameEn,
              surahNameAr: nameAr,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
                      .animate(animation),
                  child: child,
                ),
              );
            },
          ),
        );
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Number badge (Hexagon or rounded square)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryLight.withOpacity(0.2),
                        AppColors.primarySurface,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nameEn,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            isMeccan ? Icons.location_city_rounded : Icons.mosque_rounded,
                            size: 12,
                            color: isMeccan ? AppColors.meccan : AppColors.medinan,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isMeccan ? AppColors.meccan : AppColors.medinan,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.textHint,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '$ayatCount verses',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arabic name
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          nameAr,
                          style: AppTheme.arabicStyle(
                            fontSize: 20,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Favorite toggle
                          GestureDetector(
                            onTap: () {
                              widget.onToggleFavorite(number);
                              context.read<FirestoreService>().addFavorite(number);
                            },
                            child: Icon(
                              widget.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 20,
                              color: widget.isFavorite ? AppColors.error : AppColors.textHint,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Play button
                          GestureDetector(
                            onTap: () {
                              context.read<AudioService>().playSurahWithPlaylist(number);
                              context.read<FirestoreService>().recordPlay();
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
