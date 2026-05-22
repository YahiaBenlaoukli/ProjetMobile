import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../services/quran_api_service.dart';

class SurahReaderScreen extends StatefulWidget {
  final int surahNumber;
  final String surahNameEn;
  final String surahNameAr;

  const SurahReaderScreen({
    super.key,
    required this.surahNumber,
    required this.surahNameEn,
    required this.surahNameAr,
  });

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  final QuranApiService _api = QuranApiService();
  List<Map<String, dynamic>> _ayahs = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadSurahAyahs();
  }

  Future<void> _loadSurahAyahs() async {
    try {
      List<Map<String, dynamic>> allAyahs = [];
      bool foundSurah = false;
      bool finishedSurah = false;

      int startPage = _estimateStartPage(widget.surahNumber);

      for (int page = startPage; page <= 604 && !finishedSurah; page++) {
        final response = await _api.fetchPageText(page);
        if (response['code'] == 200) {
          final data = response['data'];
          final ayahs = (data['ayahs'] as List).cast<Map<String, dynamic>>();

          for (var ayah in ayahs) {
            final surahNum = int.parse(ayah['surah']['number'].toString());
            if (surahNum == widget.surahNumber) {
              foundSurah = true;
              allAyahs.add(ayah);
            } else if (foundSurah) {
              finishedSurah = true;
              break;
            }
          }
          if (!foundSurah && page > startPage + 15) break;
        }
      }

      if (mounted) {
        setState(() {
          _ayahs = allAyahs;
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

  int _estimateStartPage(int surahNumber) {
    const Map<int, int> startPages = {
      1: 1, 2: 2, 3: 50, 4: 77, 5: 106, 6: 128, 7: 151, 8: 177,
      9: 187, 10: 208, 11: 221, 12: 235, 13: 249, 14: 255, 15: 262,
      16: 267, 17: 282, 18: 293, 19: 305, 20: 312, 21: 322, 22: 332,
      23: 342, 24: 350, 25: 359, 26: 367, 27: 377, 28: 385, 29: 396,
      30: 404, 31: 411, 32: 415, 33: 418, 34: 428, 35: 434, 36: 440,
      37: 446, 38: 453, 39: 458, 40: 467, 41: 477, 42: 483, 43: 489,
      44: 496, 45: 499, 46: 502, 47: 507, 48: 511, 49: 515, 50: 518,
      51: 520, 52: 523, 53: 526, 54: 528, 55: 531, 56: 534, 57: 537,
      58: 542, 59: 545, 60: 549, 61: 551, 62: 553, 63: 554, 64: 556,
      65: 558, 66: 560, 67: 562, 68: 564, 69: 566, 70: 568, 71: 570,
      72: 572, 73: 574, 74: 575, 75: 577, 76: 578, 77: 580, 78: 582,
      79: 583, 80: 585, 81: 586, 82: 587, 83: 587, 84: 589, 85: 590,
      86: 591, 87: 591, 88: 592, 89: 593, 90: 594, 91: 595, 92: 595,
      93: 596, 94: 596, 95: 597, 96: 597, 97: 598, 98: 598, 99: 599,
      100: 599, 101: 600, 102: 600, 103: 601, 104: 601, 105: 601,
      106: 602, 107: 602, 108: 602, 109: 603, 110: 603, 111: 603,
      112: 604, 113: 604, 114: 604,
    };
    return startPages[surahNumber] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.surahNameEn,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.surahNameAr,
                    style: AppTheme.arabicStyle(
                      color: AppColors.goldLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                  ),
                ),
                // Could add subtle Islamic pattern image here with opacity
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Loading verses...',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() { _isLoading = true; _error = ''; });
                _loadSurahAyahs();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_ayahs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 100),
        child: Center(
          child: Text('No verses found',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        children: [
          // Bismillah header (except At-Tawba)
          if (widget.surahNumber != 9)
            Container(
              margin: const EdgeInsets.only(bottom: 30),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  style: AppTheme.arabicStyle(
                    fontSize: 28,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          // Ayahs
          ..._ayahs.map((ayah) {
            final numberInSurah = ayah['numberInSurah'].toString();
            final text = ayah['text'] ?? '';
            final juz = ayah['juz'] ?? '';
            final page = ayah['page'] ?? '';
            final sajda = ayah['sajda'].toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sajda == '1'
                            ? AppColors.gold.withOpacity(0.5)
                            : Colors.transparent,
                        width: sajda == '1' ? 1.5 : 0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  numberInSurah,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Juz $juz · Page $page',
                                style: const TextStyle(
                                    color: AppColors.textSecondary, 
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (sajda == '1') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.goldSurface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Sajda',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          text,
                          style: AppTheme.arabicStyle(
                            fontSize: 26,
                            height: 2.2,
                            color: AppColors.textPrimary,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
