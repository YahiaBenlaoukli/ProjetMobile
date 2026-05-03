import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../services/quran_api_service.dart';

class QuranPageViewer extends StatefulWidget {
  final int initialPage;
  final String surahName;

  const QuranPageViewer({
    super.key,
    this.initialPage = 1,
    this.surahName = '',
  });

  @override
  State<QuranPageViewer> createState() => _QuranPageViewerState();
}

class _QuranPageViewerState extends State<QuranPageViewer> {
  late PageController _pageController;
  late int _currentPage;
  final QuranApiService _api = QuranApiService();
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 1 || page > 604) return;
    _pageController.animateToPage(
      page - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _showPagePicker() {
    final controller = TextEditingController(text: '$_currentPage');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Go to page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '1 – 604',
            labelText: 'Page number',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= 604) {
                Navigator.pop(context);
                _goToPage(page);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // Page viewer
            PageView.builder(
              controller: _pageController,
              reverse: true, // RTL page turning
              itemCount: 604,
              onPageChanged: (index) {
                setState(() => _currentPage = index + 1);
              },
              itemBuilder: (context, index) {
                final pageNum = index + 1;
                final imageUrl = _api.getPageImageUrl(pageNum);

                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          final value = progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null;
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: value,
                                  color: AppColors.primary,
                                  strokeWidth: 2.5,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Page $pageNum',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image_outlined,
                                    size: 48, color: AppColors.textHint),
                                const SizedBox(height: 12),
                                Text(
                                  'Failed to load page $pageNum',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => setState(() {}),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            // Top bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              top: _showControls ? 0 : -120,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              if (widget.surahName.isNotEmpty)
                                Text(
                                  widget.surahName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                'Page $_currentPage of 604',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.grid_view_rounded,
                              color: Colors.white, size: 20),
                          onPressed: _showPagePicker,
                          tooltip: 'Go to page',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom nav arrows
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              bottom: _showControls ? 0 : -80,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Next page (RTL: right arrow goes to next page which is lower number)
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded,
                              color: Colors.white, size: 32),
                          onPressed: _currentPage < 604
                              ? () => _goToPage(_currentPage + 1)
                              : null,
                        ),
                        // Page indicator
                        GestureDetector(
                          onTap: _showPagePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_currentPage',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        // Previous page
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded,
                              color: Colors.white, size: 32),
                          onPressed: _currentPage > 1
                              ? () => _goToPage(_currentPage - 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
