import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../services/quran_api_service.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final QuranApiService _api = QuranApiService();
  Map<String, dynamic> _prayerData = {};
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      final data = await _api.fetchPrayerTimes();
      if (mounted) {
        setState(() {
          _prayerData = data;
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
            Text('Detecting location...',
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
              const Icon(Icons.location_off_rounded,
                  size: 48, color: AppColors.textHint),
              const SizedBox(height: 16),
              const Text('Unable to load prayer times',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_error,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() { _isLoading = true; _error = ''; });
                  _loadPrayerTimes();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final region = _prayerData['region'] ?? '';
    final country = _prayerData['country'] ?? '';
    final prayerTimes =
        _prayerData['prayer_times'] as Map<String, dynamic>? ?? {};
    final dateData = _prayerData['date'] as Map<String, dynamic>? ?? {};
    final dateEn = dateData['date_en'] ?? '';
    final hijriData =
        dateData['date_hijri'] as Map<String, dynamic>? ?? {};
    final hijriDate = hijriData['date'] ?? '';
    final hijriMonth =
        (hijriData['month'] as Map<String, dynamic>?)?['ar'] ?? '';
    final hijriYear = hijriData['year'] ?? '';
    final hijriWeekday =
        (hijriData['weekday'] as Map<String, dynamic>?)?['ar'] ?? '';

    final prayers = [
      _PrayerInfo('Fajr', 'الفجر', Icons.wb_twilight_rounded, const Color(0xFF3949AB)),
      _PrayerInfo('Sunrise', 'الشروق', Icons.wb_sunny_outlined, const Color(0xFFEF6C00)),
      _PrayerInfo('Dhuhr', 'الظهر', Icons.light_mode_rounded, const Color(0xFFF9A825)),
      _PrayerInfo('Asr', 'العصر', Icons.sunny_snowing, const Color(0xFFE65100)),
      _PrayerInfo('Maghrib', 'المغرب', Icons.nights_stay_outlined, const Color(0xFFC62828)),
      _PrayerInfo('Isha', 'العشاء', Icons.nightlight_round, const Color(0xFF4527A0)),
    ];

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        setState(() { _isLoading = true; _error = ''; });
        await _loadPrayerTimes();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Location & Date Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$region, $country',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: 60,
                  height: 1,
                  color: Colors.white24,
                ),
                const SizedBox(height: 14),
                Text(
                  dateEn,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  '$hijriWeekday · $hijriDate $hijriMonth $hijriYear هـ',
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 15,
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Section title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Prayer Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Prayer times
          ...prayers.asMap().entries.map((entry) {
            final index = entry.key;
            final prayer = entry.value;
            final time = prayerTimes[prayer.name] ?? '--:--';

            return AnimatedContainer(
              duration: Duration(milliseconds: 200 + index * 50),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: prayer.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(prayer.icon, color: prayer.color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prayer.arabicName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontFamily: 'serif',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: prayer.color,
                      letterSpacing: -0.5,
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

class _PrayerInfo {
  final String name;
  final String arabicName;
  final IconData icon;
  final Color color;
  const _PrayerInfo(this.name, this.arabicName, this.icon, this.color);
}
