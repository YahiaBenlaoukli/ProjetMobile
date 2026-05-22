import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../../../services/firestore_service.dart';
import '../../../services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _monthlyGoal = 0;
  bool _isLoadingGoal = true;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final storageService = context.read<StorageService>();
    final goal = await storageService.getMonthlyGoal();
    if (mounted) {
      setState(() {
        _monthlyGoal = goal;
        _isLoadingGoal = false;
      });
    }
  }

  Future<void> _updateGoal() async {
    int? newGoal = await showDialog<int>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _monthlyGoal.toString());
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Set Monthly Goal', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Number of plays'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newGoal != null && mounted) {
      final storageService = context.read<StorageService>();
      await storageService.setMonthlyGoal(newGoal);
      setState(() {
        _monthlyGoal = newGoal;
      });
    }
  }

  String _formatListeningTime(int seconds) {
    if (seconds <= 0) return '0s';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  String _formatMinutes(double minutes) {
    if (minutes >= 60) {
      final h = (minutes / 60).floor();
      final m = (minutes % 60).floor();
      return '${h}h${m > 0 ? ' ${m}m' : ''}';
    }
    return '${minutes.toStringAsFixed(0)}m';
  }

  Map<String, dynamic>? _getMostListenedSurah(Map<String, dynamic> surahPlays) {
    if (surahPlays.isEmpty) return null;
    String? topKey;
    int maxCount = -1;

    surahPlays.forEach((key, val) {
      if (val is Map) {
        final count = val['count'] ?? 0;
        if (count > maxCount) {
          maxCount = count;
          topKey = key;
        }
      }
    });

    if (topKey == null) return null;
    return Map<String, dynamic>.from(surahPlays[topKey]!);
  }

  List<MapEntry<String, Map<String, dynamic>>> _getSortedSurahPlays(Map<String, dynamic> surahPlays) {
    final list = <MapEntry<String, Map<String, dynamic>>>[];
    surahPlays.forEach((key, value) {
      if (value is Map) {
        list.add(MapEntry(key, Map<String, dynamic>.from(value)));
      }
    });
    list.sort((a, b) {
      final countA = a.value['count'] ?? 0;
      final countB = b.value['count'] ?? 0;
      return countB.compareTo(countA);
    });
    return list;
  }

  /// Build last 7 days of listening data for the chart
  List<_DayData> _getLast7DaysData(Map<String, dynamic> dailyListening) {
    final now = DateTime.now();
    final days = <_DayData>[];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final seconds = (dailyListening[dateKey] ?? 0) as int;
      final minutes = seconds / 60.0;
      final label = weekdays[date.weekday - 1];
      days.add(_DayData(label: label, minutes: minutes, isToday: i == 0));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity & Statistics'),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: firestoreService.getStatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final stats = snapshot.data ?? {};
          final totalPlays = stats['total_plays'] ?? 0;
          final totalSeconds = stats['total_listening_time_seconds'] ?? 0;
          final Map<String, dynamic> surahPlays = Map<String, dynamic>.from(stats['surah_plays'] ?? {});
          final Map<String, dynamic> dailyListening = Map<String, dynamic>.from(stats['daily_listening'] ?? {});

          final mostListened = _getMostListenedSurah(surahPlays);
          final sortedSurahs = _getSortedSurahPlays(surahPlays);
          final last7Days = _getLast7DaysData(dailyListening);

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section Title
                  const Text(
                    'Your Activity',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Side-by-Side Summary Cards
                  Row(
                    children: [
                      Expanded(child: _buildSummaryCard(
                        icon: Icons.play_circle_fill_rounded,
                        iconBgColor: AppColors.primarySurface,
                        iconColor: AppColors.primary,
                        label: 'Total Plays',
                        value: '$totalPlays',
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryCard(
                        icon: Icons.access_time_filled_rounded,
                        iconBgColor: AppColors.goldSurface,
                        iconColor: AppColors.gold,
                        label: 'Listening Time',
                        value: _formatListeningTime(totalSeconds),
                        iconBorderColor: AppColors.gold.withOpacity(0.15),
                      )),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Weekly Listening Chart ──
                  _buildWeeklyChart(last7Days),
                  const SizedBox(height: 20),

                  // Goal Progress Section
                  _buildGoalCard(totalPlays),
                  const SizedBox(height: 20),

                  // Most Listened Surah Section
                  if (mostListened != null) ...[
                    const Text(
                      'Most Listened Surah',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMostListenedCard(mostListened),
                    const SizedBox(height: 24),
                  ],

                  // Top Played Surahs List
                  if (sortedSurahs.isNotEmpty) ...[
                    const Text(
                      'Top Surahs Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTopSurahsList(sortedSurahs),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── WIDGET BUILDERS ─────────────────────────────────────────

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
    Color? iconBorderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
              border: iconBorderColor != null ? Border.all(color: iconBorderColor) : null,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<_DayData> days) {
    final maxMinutes = days.map((d) => d.minutes).reduce(max);
    final maxY = maxMinutes <= 0 ? 10.0 : (maxMinutes * 1.3).ceilToDouble();
    final totalWeekMinutes = days.fold<double>(0, (sum, d) => sum + d.minutes);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Daily Listening',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total: ${_formatMinutes(totalWeekMinutes)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Last 7 days',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = days[group.x.toInt()];
                      return BarTooltipItem(
                        '${day.label}\n${_formatMinutes(day.minutes)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) return const SizedBox.shrink();
                        final day = days[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            day.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w500,
                              color: day.isToday ? AppColors.primary : AppColors.textHint,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()}m',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textHint,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(days.length, (index) {
                  final day = days[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: day.minutes > 0 ? day.minutes : 0.15, // tiny bar for zero
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        gradient: day.isToday
                            ? const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [AppColors.primary, AppColors.primaryLight],
                              )
                            : LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.primaryMuted.withOpacity(0.6),
                                  AppColors.primaryMuted.withOpacity(0.9),
                                ],
                              ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: AppColors.background,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(int totalPlays) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.flag_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Monthly Goal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                onPressed: _updateGoal,
                tooltip: 'Edit goal',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoadingGoal
              ? const Center(child: LinearProgressIndicator(color: AppColors.primary))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_monthlyGoal > 0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (totalPlays / _monthlyGoal).clamp(0.0, 1.0),
                          backgroundColor: AppColors.primarySurface,
                          color: AppColors.primary,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${((totalPlays / _monthlyGoal) * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$totalPlays / $_monthlyGoal plays',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'No monthly goal set. Tap the edit icon to set one!',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildMostListenedCard(Map<String, dynamic> mostListened) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: AppColors.goldLight,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mostListened['name'] ?? 'Surah',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${mostListened['count'] ?? 0} plays',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        _formatListeningTime(mostListened['listening_time_seconds'] ?? 0),
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildTopSurahsList(List<MapEntry<String, Map<String, dynamic>>> sortedSurahs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedSurahs.length > 5 ? 5 : sortedSurahs.length,
      itemBuilder: (context, index) {
        final entry = sortedSurahs[index];
        final surahData = entry.value;
        final isTopOne = index == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isTopOne ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isTopOne ? AppColors.primarySurface : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isTopOne ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surahData['name'] ?? 'Surah',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${surahData['count'] ?? 0} plays',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatListeningTime(surahData['listening_time_seconds'] ?? 0),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayData {
  final String label;
  final double minutes;
  final bool isToday;

  const _DayData({
    required this.label,
    required this.minutes,
    this.isToday = false,
  });
}
