import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../services/audio_service.dart';

class ReciterSelectionScreen extends StatefulWidget {
  const ReciterSelectionScreen({super.key});

  @override
  State<ReciterSelectionScreen> createState() => _ReciterSelectionScreenState();
}

class _ReciterSelectionScreenState extends State<ReciterSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredReciters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReciters();
  }

  Future<void> _loadReciters() async {
    final audioService = context.read<AudioService>();
    await audioService.fetchReciters();
    if (mounted) {
      setState(() {
        _filteredReciters = audioService.reciters;
        _isLoading = false;
      });
    }
  }

  void _filterReciters(String query) {
    final audioService = context.read<AudioService>();
    setState(() {
      if (query.isEmpty) {
        _filteredReciters = audioService.reciters;
      } else {
        _filteredReciters = audioService.reciters.where((r) {
          final name = (r['reciter_name'] ?? '').toString();
          final shortName = (r['reciter_short_name'] ?? '').toString().toLowerCase();
          return name.contains(query) || shortName.contains(query.toLowerCase());
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
    final audioService = context.watch<AudioService>();
    final currentReciterId = audioService.currentReciterId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Reciter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            )),
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterReciters,
              decoration: InputDecoration(
                hintText: 'Search reciter...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.textHint),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.textHint, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _filterReciters('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filteredReciters.length} reciters',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // List
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _filteredReciters.length,
                itemBuilder: (context, index) {
                  final reciter = _filteredReciters[index];
                  final id = reciter['reciter_id']?.toString() ?? '';
                  final name = reciter['reciter_name'] ?? '';
                  final shortName = reciter['reciter_short_name'] ?? '';
                  final isSelected = id == currentReciterId;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    color: isSelected
                        ? AppColors.primarySurface
                        : AppColors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.record_voice_over_rounded,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.primary,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      subtitle: Text(
                        shortName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 24)
                          : const Icon(Icons.arrow_forward_ios_rounded,
                              color: AppColors.textHint, size: 16),
                      onTap: () async {
                        await audioService.selectReciter(reciter);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
