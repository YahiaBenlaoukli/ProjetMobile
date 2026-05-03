import 'package:flutter/material.dart';
import '../../../services/quran_api_service.dart';

class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen>
    with SingleTickerProviderStateMixin {
  final QuranApiService _api = QuranApiService();
  Map<String, dynamic> _duasData = {};
  bool _isLoading = true;
  String _error = '';
  late TabController _tabController;

  static const List<Map<String, String>> _categories = [
    {'key': 'prophetic_duas', 'label': 'Prophetic', 'icon': '🤲'},
    {'key': 'quran_duas', 'label': 'Quranic', 'icon': '📖'},
    {'key': 'prophets_duas', 'label': 'Prophets', 'icon': '✨'},
    {'key': 'quran_completion_duas', 'label': 'Khatm', 'icon': '🎉'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadDuas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDuas() async {
    try {
      final data = await _api.fetchDuas();
      if (mounted) {
        setState(() {
          _duasData = data;
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
            CircularProgressIndicator(color: Colors.tealAccent),
            SizedBox(height: 16),
            Text('Loading Duas...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = '';
                });
                _loadDuas();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white54,
          tabAlignment: TabAlignment.start,
          tabs: _categories.map((cat) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat['icon']!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(cat['label']!),
                ],
              ),
            );
          }).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories.map((cat) {
              final key = cat['key']!;
              final items = _duasData[key] as List<dynamic>? ?? [];
              return _buildDuasList(items);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDuasList(List<dynamic> items) {
    if (items.isEmpty) {
      return const Center(
        child:
            Text('No duas available', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        final text = item['text'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.06),
                Colors.deepPurple.withOpacity(0.06),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade700, Colors.orange.shade600],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'serif',
                  color: Colors.white,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        );
      },
    );
  }
}
