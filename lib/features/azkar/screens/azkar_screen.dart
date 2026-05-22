import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/theme.dart';
import '../../../services/quran_api_service.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  final QuranApiService _api = QuranApiService();
  Map<String, dynamic> _azkarData = {};
  Map<String, dynamic> _duasData = {};
  bool _isLoading = true;
  String _error = '';

  static const List<_CategoryItem> _azkarCategories = [
    _CategoryItem('morning_azkar', 'Morning Azkar', 'أذكار الصباح', Icons.wb_sunny_rounded, Color(0xFFFFF8E1)),
    _CategoryItem('evening_azkar', 'Evening Azkar', 'أذكار المساء', Icons.nights_stay_rounded, Color(0xFFE8EAF6)),
    _CategoryItem('prayer_azkar', 'Prayer Azkar', 'أذكار الصلاة', Icons.mosque_rounded, Color(0xFFE8F5E9)),
    _CategoryItem('prayer_later_azkar', 'After Prayer', 'بعد الصلاة', Icons.auto_awesome_rounded, Color(0xFFF3E5F5)),
    _CategoryItem('sleep_azkar', 'Sleep Azkar', 'أذكار النوم', Icons.bedtime_rounded, Color(0xFFE0F2F1)),
    _CategoryItem('wake_up_azkar', 'Wake Up', 'أذكار الاستيقاظ', Icons.alarm_rounded, Color(0xFFFCE4EC)),
    _CategoryItem('adhan_azkar', 'Adhan', 'أذكار الأذان', Icons.volume_up_rounded, Color(0xFFE0F7FA)),
    _CategoryItem('wudu_azkar', 'Wudu', 'أذكار الوضوء', Icons.water_drop_rounded, Color(0xFFE3F2FD)),
    _CategoryItem('mosque_azkar', 'Mosque', 'أذكار المسجد', Icons.account_balance_rounded, Color(0xFFF1F8E9)),
    _CategoryItem('home_azkar', 'Home', 'أذكار المنزل', Icons.home_rounded, Color(0xFFFFF3E0)),
    _CategoryItem('food_azkar', 'Food & Drink', 'أذكار الطعام', Icons.restaurant_rounded, Color(0xFFEFEBE9)),
    _CategoryItem('miscellaneous_azkar', 'Other Azkar', 'أذكار متنوعة', Icons.menu_book_rounded, Color(0xFFF5F5F5)),
  ];

  static const List<_CategoryItem> _duaCategories = [
    _CategoryItem('prophetic_duas', 'Prophetic Duas', 'أدعية نبوية', Icons.volunteer_activism_rounded, Color(0xFFE8F5E9)),
    _CategoryItem('quran_duas', 'Quranic Duas', 'أدعية قرآنية', Icons.auto_stories_rounded, Color(0xFFFFF8E1)),
    _CategoryItem('prophets_duas', 'Prophets\' Duas', 'أدعية الأنبياء', Icons.star_rounded, Color(0xFFE8EAF6)),
    _CategoryItem('quran_completion_duas', 'Khatm Al-Quran', 'ختم القرآن', Icons.celebration_rounded, Color(0xFFFCE4EC)),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.fetchAzkar(),
        _api.fetchDuas(),
      ]);
      if (mounted) {
        setState(() {
          _azkarData = results[0];
          _duasData = results[1];
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() { _isLoading = true; _error = ''; });
                _loadData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCountAzkar = constraints.maxWidth > 800 ? 5 : (constraints.maxWidth > 500 ? 4 : 3);
        final crossAxisCountDuas = constraints.maxWidth > 600 ? 3 : 2;

        return AnimationLimiter(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // Azkar section header
              const _SectionHeader(title: 'Daily Azkar', subtitle: 'الأذكار اليومية'),
              const SizedBox(height: 16),
              // Azkar grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCountAzkar,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 165, // Increased from 150 to fix 6px overflow
                ),
                itemCount: _azkarCategories.length,
                itemBuilder: (context, index) {
                  final cat = _azkarCategories[index];
                  final items = _azkarData[cat.key] as List<dynamic>? ?? [];
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    columnCount: crossAxisCountAzkar,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: _CategoryCard(
                          category: cat,
                          itemCount: items.length,
                          onTap: () => _openCategory(cat.label, cat.arabicLabel, items),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Duas section
              const _SectionHeader(title: 'Duas', subtitle: 'الأدعية'),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCountDuas,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 140, // Increased from 120 to fix potential overflow
                ),
                itemCount: _duaCategories.length,
                itemBuilder: (context, index) {
                  final cat = _duaCategories[index];
                  final items = _duasData[cat.key] as List<dynamic>? ?? [];
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    columnCount: crossAxisCountDuas,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: _CategoryCard(
                          category: cat,
                          itemCount: items.length,
                          onTap: () => _openCategory(cat.label, cat.arabicLabel, items),
                          wide: true,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCategory(String title, String arabicTitle, List<dynamic> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AzkarDetailScreen(
          title: title,
          arabicTitle: arabicTitle,
          items: items,
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String key;
  final String label;
  final String arabicLabel;
  final IconData icon;
  final Color color;
  const _CategoryItem(this.key, this.label, this.arabicLabel, this.icon, this.color);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: AppTheme.arabicStyle(
                    fontSize: 18,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    height: 1.2)),
          ],
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _CategoryItem category;
  final int itemCount;
  final VoidCallback onTap;
  final bool wide;

  const _CategoryCard({
    required this.category,
    required this.itemCount,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: category.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: category.color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(wide ? 16 : 12),
        child: Column(
          mainAxisAlignment: wide ? MainAxisAlignment.center : MainAxisAlignment.start,
          crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (!wide) const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon,
                  size: wide ? 28 : 32,
                  color: AppColors.primary),
            ),
            SizedBox(height: wide ? 8 : 12),
            Text(
              category.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: wide ? TextAlign.start : TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!wide) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$itemCount items',
                  style: const TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── DETAIL SCREEN ──────────────────────────────────────────────

class _AzkarDetailScreen extends StatelessWidget {
  final String title;
  final String arabicTitle;
  final List<dynamic> items;

  const _AzkarDetailScreen({
    required this.title,
    required this.arabicTitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text(arabicTitle,
                style: AppTheme.arabicStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                    height: 1.2)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index] as Map<String, dynamic>;
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _AzkarItemCard(
                    text: item['text'] ?? '',
                    count: item['count'] ?? 1,
                    index: index + 1,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AzkarItemCard extends StatefulWidget {
  final String text;
  final int count;
  final int index;

  const _AzkarItemCard({
    required this.text,
    required this.count,
    required this.index,
  });

  @override
  State<_AzkarItemCard> createState() => _AzkarItemCardState();
}

class _AzkarItemCardState extends State<_AzkarItemCard>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _remaining = widget.count;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _remaining <= 0;

    return GestureDetector(
      onTapDown: (_) => _animController.forward(),
      onTapUp: (_) {
        _animController.reverse();
        if (_remaining > 0) {
          setState(() => _remaining--);
        }
      },
      onTapCancel: () => _animController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isComplete ? AppColors.primarySurface : AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isComplete ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isComplete ? AppColors.primary.withOpacity(0.1) : AppColors.shadow.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isComplete ? AppColors.primary.withOpacity(0.2) : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isComplete)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 26)
                  else if (widget.count > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.goldSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat_rounded, size: 14, color: AppColors.gold),
                          const SizedBox(width: 4),
                          Text(
                            '$_remaining',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Text
              Text(
                widget.text,
                style: AppTheme.arabicStyle(
                  fontSize: 24,
                  height: 2.2,
                  color: AppColors.textPrimary,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.justify,
              ),
              if (widget.count > 1 && !isComplete) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Tap anywhere on the card to count',
                    style: const TextStyle(
                        color: AppColors.textSecondary, 
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
