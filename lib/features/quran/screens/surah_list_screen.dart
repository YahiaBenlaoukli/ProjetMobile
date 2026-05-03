import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      // Pre-load audio tracks in background for default reciter
      if (mounted) {
        final audio = context.read<AudioService>();
        if (!audio.tracksLoaded) {
          // fetch default reciters list and select Alafasy if not selected
          await audio.fetchReciters();
          if (audio.currentReciterId.isEmpty && audio.reciters.isNotEmpty) {
            // Find Mishary Alafasy (id: 1) or take first
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: _filterSurahs,
            decoration: InputDecoration(
              hintText: 'Search surah...',
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppColors.textHint),
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
        // Count and Reciter Selection
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredSurahs.length} Surahs',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.record_voice_over_rounded, 
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Consumer<AudioService>(
                        builder: (context, audio, child) {
                          final name = audio.currentReciterName;
                          return Text(
                            name.isNotEmpty ? name : 'Mishary Alafasy',
                            style: const TextStyle(
                              fontSize: 12,
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
                          size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Surah list
        Expanded(
          child: ListView.builder(
            itemCount: _filteredSurahs.length,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            itemBuilder: (context, index) {
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
            },
          ),
        ),
      ],
    );
  }
}

class _SurahCard extends StatelessWidget {
  final Map<String, dynamic> surah;
  final bool isFavorite;
  final ValueChanged<int> onToggleFavorite;

  const _SurahCard({
    required this.surah,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final number = int.tryParse(surah['number'].toString()) ?? 0;
    final nameAr = surah['name_ar'] ?? '';
    final nameEn = surah['name_en'] ?? '';
    final type = surah['type'] ?? '';
    final ayatCount = surah['ayat_count'] ?? '';
    final isMeccan = type == 'Meccan';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SurahReaderScreen(
                surahNumber: number,
                surahNameEn: nameEn,
                surahNameAr: nameAr,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Number badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameEn,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isMeccan
                                ? AppColors.primarySurface
                                : const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isMeccan
                                  ? AppColors.meccan
                                  : AppColors.medinan,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$ayatCount verses',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            // Find the estimated start page for this surah and open the viewer
                            final audio = context.read<AudioService>();
                            // We can use a quick local mapping or an API method if available, 
                            // here using a simple fallback to page 1 for the viewer entry
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuranPageViewer(
                                  surahName: nameAr,
                                  initialPage: audio.getSurahStartPage(number),
                                ),
                              ),
                            );
                          },
                          child: const Icon(Icons.menu_book_rounded, 
                              size: 16, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arabic name
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    nameAr,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Favorite toggle
                      GestureDetector(
                        onTap: () {
                          onToggleFavorite(number);
                          context
                              .read<FirestoreService>()
                              .addFavorite(number);
                        },
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                          color: isFavorite
                              ? AppColors.gold
                              : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
