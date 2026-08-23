import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/model/scan_history_item.dart';
import '../../core/services/scan_history_service.dart';
import 'camera_scan_screen.dart';
import 'result_screen.dart';

/// DietCompass — Full Scan History Screen
/// Displays the complete persisted scan history for the authenticated user.
class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  bool _isLoading = false;
  List<ScanHistoryItem> _allScans = [];
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (ScanHistoryService.instance.currentHistory.isNotEmpty) {
      _allScans = ScanHistoryService.instance.currentHistory;
    } else {
      _isLoading = true;
    }
    ScanHistoryService.instance.addListener(_onScanHistoryChanged);
    _loadHistory();
  }

  void _onScanHistoryChanged() {
    if (!mounted) return;
    setState(() {
      _allScans = ScanHistoryService.instance.currentHistory;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    ScanHistoryService.instance.removeListener(_onScanHistoryChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool forceRefresh = false}) async {
    if (_allScans.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final scans = await ScanHistoryService.instance.getScanHistory(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _allScans = scans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ScanHistoryItem> get _filteredScans {
    if (_searchQuery.trim().isEmpty) return _allScans;
    final q = _searchQuery.trim().toLowerCase();
    return _allScans.where((item) {
      final name = item.productName.toLowerCase();
      final brand = item.brand.toLowerCase();
      return name.contains(q) || brand.contains(q);
    }).toList();
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF1E8A4C);
    if (score >= 60) return const Color(0xFFE0862E);
    return const Color(0xFFE0525C);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B1B2E), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'All Scans',
          style: TextStyle(
            color: const Color(0xFF1B1B2E),
            fontWeight: FontWeight.w800,
            fontSize: 18 * scale,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E8A4C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history_rounded, size: 14, color: Color(0xFF1E8A4C)),
                const SizedBox(width: 4),
                Text(
                  '${_allScans.length}',
                  style: const TextStyle(
                    color: Color(0xFF1E8A4C),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1E8A4C),
        onRefresh: () => _loadHistory(forceRefresh: true),
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    icon: const Icon(Icons.search_rounded, color: Color(0xFF8C8CA1), size: 20),
                    hintText: 'Search scanned products…',
                    hintStyle: TextStyle(
                      color: const Color(0xFFA0A0B2),
                      fontSize: 14 * scale,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Color(0xFF8C8CA1)),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // Content area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E8A4C)),
                      ),
                    )
                  : _filteredScans.isEmpty
                      ? _buildEmptyState(scale)
                      : ListView.separated(
                          padding: EdgeInsets.all(16 * scale),
                          itemCount: _filteredScans.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12 * scale),
                          itemBuilder: (context, index) {
                            final item = _filteredScans[index];
                            return _buildScanCard(item, scale);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double scale) {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64 * scale, color: const Color(0xFFB0B0C4)),
              SizedBox(height: 16 * scale),
              Text(
                'No matching scans found',
                style: TextStyle(
                  fontSize: 17 * scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                'Try searching for another product name or brand.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5 * scale,
                  color: const Color(0xFF8C8CA1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90 * scale,
              height: 90 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF1E8A4C).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 44 * scale,
                color: const Color(0xFF1E8A4C),
              ),
            ),
            SizedBox(height: 20 * scale),
            Text(
              'No scans yet',
              style: TextStyle(
                fontSize: 20 * scale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B1B2E),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              'Scan a product to see your scan history here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14 * scale,
                color: const Color(0xFF7A7A90),
                height: 1.4,
              ),
            ),
            SizedBox(height: 24 * scale),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CameraScanScreen(
                      source: CameraSource.scan,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Scan Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E8A4C),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 14 * scale),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: TextStyle(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanCard(ScanHistoryItem item, double scale) {
    final scoreColor = _getScoreColor(item.score);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultScreen(product: item.toFoodProduct()),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64 * scale,
                height: 64 * scale,
                color: const Color(0xFFF3F5FA),
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildFallbackIcon(scale),
                      )
                    : _buildFallbackIcon(scale),
              ),
            ),
            SizedBox(width: 14 * scale),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B2E),
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 3 * scale),
                  Text(
                    item.brand.isNotEmpty ? item.brand : 'Food Product',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5 * scale,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8C8CA1),
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12 * scale, color: const Color(0xFFA0A0B2)),
                      SizedBox(width: 4 * scale),
                      Text(
                        item.formattedTime,
                        style: TextStyle(
                          fontSize: 11.5 * scale,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFA0A0B2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Score Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${item.score}',
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    'Score',
                    style: TextStyle(
                      fontSize: 9.5 * scale,
                      fontWeight: FontWeight.w600,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6 * scale),
            Icon(Icons.chevron_right_rounded, size: 20 * scale, color: const Color(0xFFB0B0C4)),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(double scale) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 28 * scale,
        color: const Color(0xFFB0B0C4),
      ),
    );
  }
}
