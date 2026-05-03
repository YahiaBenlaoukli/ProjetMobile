import 'package:flutter/material.dart';
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
    _CategoryItem('morning_azkar', 'Morning Azkar', 'أذكار الصباح', Icons.wb_sunny_outlined, Color(0xFFFFF8E1)),
    _CategoryItem('evening_azkar', 'Evening Azkar', 'أذكار المساء', Icons.nights_stay_outlined, Color(0xFFE8EAF6)),
    _CategoryItem('prayer_azkar', 'Prayer Azkar', 'أذكار الصلاة', Icons.mosque_outlined, Color(0xFFE8F5E9)),
    _CategoryItem('prayer_later_azkar', 'After Prayer', 'بعد الصلاة', Icons.auto_awesome_outlined, Color(0xFFF3E5F5)),
    _CategoryItem('sleep_azkar', 'Sleep Azkar', 'أذكار النوم', Icons.bedtime_outlined, Color(0xFFE0F2F1)),
    _CategoryItem('wake_up_azkar', 'Wake Up', 'أذكار الاستيقاظ', Icons.alarm_outlined, Color(0xFFFCE4EC)),
    _CategoryItem('adhan_azkar', 'Adhan', 'أذكار الأذان', Icons.volume_up_outlined, Color(0xFFE0F7FA)),
    _CategoryItem('wudu_azkar', 'Wudu', 'أذكار الوضوء', Icons.water_drop_outlined, Color(0xFFE3F2FD)),
    _CategoryItem('mosque_azkar', 'Mosque', 'أذكار المسجد', Icons.account_balance_outlined, Color(0xFFF1F8E9)),
    _CategoryItem('home_azkar', 'Home', 'أذكار المنزل', Icons.home_outlined, Color(0xFFFFF3E0)),
    _CategoryItem('food_azkar', 'Food & Drink', 'أذكار الطعام', Icons.restaurant_outlined, Color(0xFFEFEBE9)),
    _CategoryItem('miscellaneous_azkar', 'Other Azkar', 'أذكار متنوعة', Icons.menu_book_outlined, Color(0xFFF5F5F5)),
  ];

  static const List<_CategoryItem> _duaCategories = [
    _CategoryItem('prophetic_duas', 'Prophetic Duas', 'أدعية نبوية', Icons.volunteer_activism, Color(0xFFE8F5E9)),
    _CategoryItem('quran_duas', 'Quranic Duas', 'أدعية قرآنية', Icons.auto_stories, Color(0xFFFFF8E1)),
    _CategoryItem('prophets_duas', 'Prophets\' Duas', 'أدعية الأنبياء', Icons.star_outline_rounded, Color(0xFFE8EAF6)),
    _CategoryItem('quran_completion_duas', 'Khatm Al-Quran', 'ختم القرآن', Icons.celebration_outlined, Color(0xFFFCE4EC)),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Azkar section header
        const _SectionHeader(title: 'Daily Azkar', subtitle: 'الأذكار اليومية'),
        const SizedBox(height: 12),
        // Azkar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.88,
          ),
          itemCount: _azkarCategories.length,
          itemBuilder: (context, index) {
            final cat = _azkarCategories[index];
            final items = _azkarData[cat.key] as List<dynamic>? ?? [];
            return _CategoryCard(
              category: cat,
              itemCount: items.length,
              onTap: () => _openCategory(cat.label, cat.arabicLabel, items),
            );
          },
        ),
        const SizedBox(height: 28),
        // Duas section
        const _SectionHeader(title: 'Duas', subtitle: 'الأدعية'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemCount: _duaCategories.length,
          itemBuilder: (context, index) {
            final cat = _duaCategories[index];
            final items = _duasData[cat.key] as List<dynamic>? ?? [];
            return _CategoryCard(
              category: cat,
              itemCount: items.length,
              onTap: () => _openCategory(cat.label, cat.arabicLabel, items),
              wide: true,
            );
          },
        ),
      ],
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
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gold,
                    fontFamily: 'serif')),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        padding: EdgeInsets.all(wide ? 14 : 12),
        child: Column(
          mainAxisAlignment: wide ? MainAxisAlignment.center : MainAxisAlignment.start,
          crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (!wide) const SizedBox(height: 4),
            Icon(category.icon,
                size: wide ? 26 : 28,
                color: AppColors.primary),
            SizedBox(height: wide ? 6 : 8),
            Text(
              category.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: wide ? TextAlign.start : TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!wide) ...[
              const SizedBox(height: 2),
              Text(
                '$itemCount',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
            Text(arabicTitle,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gold,
                    fontFamily: 'serif')),
          ],
        ),
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index] as Map<String, dynamic>;
          return _AzkarItemCard(
            text: item['text'] ?? '',
            count: item['count'] ?? 1,
            index: index + 1,
          );
        },
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
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
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
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isComplete
                ? AppColors.primarySurface
                : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isComplete
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.divider,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isComplete)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 22)
                  else if (widget.count > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.goldSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_remaining',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // Text
              Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'serif',
                  color: AppColors.textPrimary,
                  height: 1.9,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              if (widget.count > 1 && !isComplete) ...[
                const SizedBox(height: 10),
                Text(
                  'Tap to count · Repeat ${widget.count} times',
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
