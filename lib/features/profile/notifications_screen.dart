import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Notification model representing an in-app alert or reminder.
class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isRead = false,
    this.actionLabel,
  });

  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String category;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  bool isRead;
  final String? actionLabel;

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes.clamp(1, 60)}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.initialTab = 0,
  });

  final int initialTab;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Settings State
  bool _masterNotifications = true;
  bool _mealReminders = true;
  bool _aiHealthAlerts = true;
  bool _recipeSuggestions = true;
  bool _weeklyReports = true;
  bool _quietHours = false;
  String _reminderTime = '08:00 AM, 01:00 PM, 07:30 PM';

  bool _isLoading = true;

  late List<AppNotification> _notifications;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _initializeNotifications();
    _loadSettings();
  }

  void _initializeNotifications() {
    _notifications = [
      AppNotification(
        id: 'notif_1',
        title: 'Daily Streak Milestone! 🔥',
        message:
            'You\'re on a 12-day healthy choices streak. Your current diet health score is 87/100.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        category: 'Milestone',
        icon: Icons.local_fire_department_rounded,
        iconColor: const Color(0xFFE0862E),
        iconBg: const Color(0xFFFCEEDD),
        isRead: false,
      ),
      AppNotification(
        id: 'notif_2',
        title: 'Personalized AI Insight 🤖',
        message:
            'Based on your low-sugar goal, we recommend checking ingredients on your afternoon snacks.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        category: 'AI Coach',
        icon: Icons.psychology_rounded,
        iconColor: const Color(0xFF6C4EF5),
        iconBg: const Color(0xFFEDE7FA),
        isRead: false,
      ),
      AppNotification(
        id: 'notif_3',
        title: 'New High-Protein Recipe Found 🍳',
        message:
            '3 delicious recipes were curated matching your pantry ingredients and vegetarian preferences.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        category: 'Recipes',
        icon: Icons.restaurant_menu_rounded,
        iconColor: const Color(0xFF1E8A4C),
        iconBg: const Color(0xFFE3F5EA),
        isRead: false,
      ),
      AppNotification(
        id: 'notif_4',
        title: 'Hydration & Lunch Reminder 🥗',
        message:
            'Don\'t forget to drink water and scan your lunch to keep your daily macro balance on target.',
        timestamp: DateTime.now().subtract(const Duration(hours: 22)),
        category: 'Reminder',
        icon: Icons.water_drop_rounded,
        iconColor: const Color(0xFF3B82F6),
        iconBg: const Color(0xFFE3EEFC),
        isRead: true,
      ),
      AppNotification(
        id: 'notif_5',
        title: 'Weekly Summary Ready 📊',
        message:
            'Your nutrition compatibility averaged 91% this past week. Great job avoiding hidden additives!',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        category: 'Report',
        icon: Icons.insights_rounded,
        iconColor: const Color(0xFF9B7BFA),
        iconBg: const Color(0xFFF3EFFF),
        isRead: true,
      ),
    ];
  }

  Future<void> _loadSettings() async {
    try {
      final master = await _storage.read(key: 'notif_master');
      final meal = await _storage.read(key: 'notif_meal');
      final ai = await _storage.read(key: 'notif_ai');
      final recipe = await _storage.read(key: 'notif_recipe');
      final weekly = await _storage.read(key: 'notif_weekly');
      final quiet = await _storage.read(key: 'notif_quiet');
      final time = await _storage.read(key: 'notif_time');

      if (mounted) {
        setState(() {
          if (master != null) _masterNotifications = master == 'true';
          if (meal != null) _mealReminders = meal == 'true';
          if (ai != null) _aiHealthAlerts = ai == 'true';
          if (recipe != null) _recipeSuggestions = recipe == 'true';
          if (weekly != null) _weeklyReports = weekly == 'true';
          if (quiet != null) _quietHours = quiet == 'true';
          if (time != null && time.isNotEmpty) _reminderTime = time;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearAllNotifications() {
    setState(() {
      _notifications.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications cleared.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background ambient decor
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220 * scale,
              height: 220 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -40,
            child: Container(
              width: 180 * scale,
              height: 180 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E8A4C).withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(scale),
                SizedBox(height: 8 * scale),
                _buildTabs(scale),
                SizedBox(height: 10 * scale),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotificationsFeed(scale),
                      _buildSettingsTab(scale),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 8 * scale),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42 * scale,
              height: 42 * scale,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14 * scale),
                border: Border.all(color: const Color(0xFFE5DEFF)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C4EF5).withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF1B1B2E),
              ),
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Notifications',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B1B2E),
                        ),
                      ),
                    ),
                    if (_unreadCount > 0) ...[
                      SizedBox(width: 6 * scale),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7 * scale,
                          vertical: 2 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C4EF5),
                          borderRadius: BorderRadius.circular(10 * scale),
                        ),
                        child: Text(
                          '$_unreadCount new',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10 * scale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Alerts, reminders & preferences',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: const Color(0xFF6B6B7B),
                  ),
                ),
              ],
            ),
          ),
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Container(
                width: 38 * scale,
                height: 38 * scale,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(color: const Color(0xFFE5DEFF)),
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF1B1B2E),
                  size: 20,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16 * scale),
              ),
              onSelected: (value) {
                if (value == 'read_all') _markAllAsRead();
                if (value == 'clear_all') _clearAllNotifications();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF6C4EF5)),
                      SizedBox(width: 10),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, size: 18, color: Color(0xFFE0475B)),
                      SizedBox(width: 10),
                      Text('Clear all'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTabs(double scale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.all(4 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: const Color(0xFFE5DEFF)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF6C4EF5),
          borderRadius: BorderRadius.circular(12 * scale),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C4EF5).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6B6B7B),
        labelStyle: TextStyle(
          fontSize: 13 * scale,
          fontWeight: FontWeight.w700,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_active_outlined, size: 15),
                SizedBox(width: 4),
                Flexible(
                  child: Text('Alerts', overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Tab(
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tune_rounded, size: 15),
                SizedBox(width: 4),
                Flexible(
                  child: Text('Preferences', overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsFeed(double scale) {
    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32 * scale),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80 * scale,
                height: 80 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEDE7FA),
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  size: 40,
                  color: Color(0xFF6C4EF5),
                ),
              ),
              SizedBox(height: 16 * scale),
              Text(
                'All caught up!',
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
              SizedBox(height: 6 * scale),
              Text(
                'You have no active alerts. We\'ll notify you when new health insights or recipe ideas are available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13 * scale,
                  color: const Color(0xFF6B6B7B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 10 * scale),
      physics: const BouncingScrollPhysics(),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => SizedBox(height: 10 * scale),
      itemBuilder: (context, index) {
        final item = _notifications[index];
        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            setState(() {
              _notifications.removeAt(index);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Removed "${item.title}"'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    setState(() {
                      _notifications.insert(index, item);
                    });
                  },
                ),
              ),
            );
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFFE0475B),
              borderRadius: BorderRadius.circular(18 * scale),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                item.isRead = true;
              });
            },
            child: Container(
              padding: EdgeInsets.all(14 * scale),
              decoration: BoxDecoration(
                color: item.isRead ? Colors.white.withValues(alpha: 0.85) : Colors.white,
                borderRadius: BorderRadius.circular(18 * scale),
                border: Border.all(
                  color: item.isRead
                      ? const Color(0xFFEBE7F5)
                      : const Color(0xFF6C4EF5).withValues(alpha: 0.35),
                  width: item.isRead ? 1.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.isRead
                        ? Colors.black.withValues(alpha: 0.02)
                        : const Color(0xFF6C4EF5).withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44 * scale,
                    height: 44 * scale,
                    decoration: BoxDecoration(
                      color: item.iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      color: item.iconColor,
                      size: 22 * scale,
                    ),
                  ),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6 * scale,
                                vertical: 2 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: item.iconBg,
                                borderRadius: BorderRadius.circular(6 * scale),
                              ),
                              child: Text(
                                item.category,
                                style: TextStyle(
                                  fontSize: 10 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: item.iconColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item.timeAgo,
                              style: TextStyle(
                                fontSize: 11 * scale,
                                color: const Color(0xFF9E9EB2),
                              ),
                            ),
                            if (!item.isRead) ...[
                              SizedBox(width: 6 * scale),
                              Container(
                                width: 8 * scale,
                                height: 8 * scale,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6C4EF5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 6 * scale),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14.5 * scale,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B1B2E),
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          item.message,
                          style: TextStyle(
                            fontSize: 12.5 * scale,
                            color: const Color(0xFF5A5A6E),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(double scale) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 10 * scale),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSettingsCard(
          scale: scale,
          title: 'General Notification Controls',
          subtitle: 'Enable or disable push notifications across DietCompass',
          children: [
            _buildSwitchTile(
              scale: scale,
              icon: Icons.notifications_active_rounded,
              iconColor: const Color(0xFF6C4EF5),
              iconBg: const Color(0xFFEDE7FA),
              title: 'Push Notifications',
              subtitle: 'Receive real-time diet and scan alerts',
              value: _masterNotifications,
              onChanged: (val) {
                setState(() => _masterNotifications = val);
                _saveSetting('notif_master', val.toString());
              },
            ),
          ],
        ),
        SizedBox(height: 14 * scale),
        _buildSettingsCard(
          scale: scale,
          title: 'Reminders & Schedules',
          subtitle: 'Set automated reminders for meals and hydration',
          children: [
            _buildSwitchTile(
              scale: scale,
              icon: Icons.restaurant_rounded,
              iconColor: const Color(0xFF1E8A4C),
              iconBg: const Color(0xFFE3F5EA),
              title: 'Meal & Hydration Reminders',
              subtitle: 'Daily alerts to log meals & maintain hydration',
              value: _mealReminders && _masterNotifications,
              enabled: _masterNotifications,
              onChanged: (val) {
                setState(() => _mealReminders = val);
                _saveSetting('notif_meal', val.toString());
              },
            ),
            const Divider(height: 1, color: Color(0xFFF0ECF8)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14 * scale,
                vertical: 12 * scale,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36 * scale,
                    height: 36 * scale,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3EFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFF6C4EF5),
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder Times',
                          style: TextStyle(
                            fontSize: 13.5 * scale,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B1B2E),
                          ),
                        ),
                        Text(
                          _reminderTime,
                          style: TextStyle(
                            fontSize: 11.5 * scale,
                            color: const Color(0xFF6C4EF5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _masterNotifications
                        ? () => _showTimePickerModal(scale)
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6C4EF5),
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 14 * scale),
        _buildSettingsCard(
          scale: scale,
          title: 'Intelligence & Content',
          subtitle: 'Choose what smart updates you receive',
          children: [
            _buildSwitchTile(
              scale: scale,
              icon: Icons.psychology_rounded,
              iconColor: const Color(0xFFE0862E),
              iconBg: const Color(0xFFFCEEDD),
              title: 'AI Health & Allergy Warnings',
              subtitle: 'Immediate alerts when scanned items conflict with your diet',
              value: _aiHealthAlerts && _masterNotifications,
              enabled: _masterNotifications,
              onChanged: (val) {
                setState(() => _aiHealthAlerts = val);
                _saveSetting('notif_ai', val.toString());
              },
            ),
            const Divider(height: 1, color: Color(0xFFF0ECF8)),
            _buildSwitchTile(
              scale: scale,
              icon: Icons.auto_awesome_rounded,
              iconColor: const Color(0xFF3B82F6),
              iconBg: const Color(0xFFE3EEFC),
              title: 'Smart Recipe Suggestions',
              subtitle: 'New recipes tailored to your pantry & macros',
              value: _recipeSuggestions && _masterNotifications,
              enabled: _masterNotifications,
              onChanged: (val) {
                setState(() => _recipeSuggestions = val);
                _saveSetting('notif_recipe', val.toString());
              },
            ),
            const Divider(height: 1, color: Color(0xFFF0ECF8)),
            _buildSwitchTile(
              scale: scale,
              icon: Icons.insights_rounded,
              iconColor: const Color(0xFF9B7BFA),
              iconBg: const Color(0xFFF3EFFF),
              title: 'Weekly Health & Streak Summary',
              subtitle: 'Weekly overview of diet scores & scan milestones',
              value: _weeklyReports && _masterNotifications,
              enabled: _masterNotifications,
              onChanged: (val) {
                setState(() => _weeklyReports = val);
                _saveSetting('notif_weekly', val.toString());
              },
            ),
          ],
        ),
        SizedBox(height: 14 * scale),
        _buildSettingsCard(
          scale: scale,
          title: 'Quiet Mode',
          subtitle: 'Silence alerts during rest hours',
          children: [
            _buildSwitchTile(
              scale: scale,
              icon: Icons.nightlight_round,
              iconColor: const Color(0xFF5A5A6E),
              iconBg: const Color(0xFFEDEAF4),
              title: 'Do Not Disturb (10:00 PM – 07:00 AM)',
              subtitle: 'Mute non-urgent notifications at night',
              value: _quietHours,
              onChanged: (val) {
                setState(() => _quietHours = val);
                _saveSetting('notif_quiet', val.toString());
              },
            ),
          ],
        ),
        SizedBox(height: 24 * scale),
      ],
    );
  }

  Widget _buildSettingsCard({
    required double scale,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: const Color(0xFFE5DEFF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C4EF5).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16 * scale, 14 * scale, 16 * scale, 8 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B1B2E),
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5 * scale,
                    color: const Color(0xFF6B6B7B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0ECF8)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required double scale,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 10 * scale),
      child: Row(
        children: [
          Container(
            width: 38 * scale,
            height: 38 * scale,
            decoration: BoxDecoration(
              color: enabled ? iconBg : const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: enabled ? iconColor : const Color(0xFF9E9E9E),
              size: 20 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5 * scale,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? const Color(0xFF1B1B2E)
                        : const Color(0xFF9E9E9E),
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: const Color(0xFF6B6B7B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: const Color(0xFF6C4EF5),
            activeTrackColor: const Color(0xFF6C4EF5).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  void _showTimePickerModal(double scale) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.all(20 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Reminder Schedule',
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                'Choose when you want daily hydration and meal log reminders.',
                style: TextStyle(fontSize: 13 * scale, color: const Color(0xFF6B6B7B)),
              ),
              SizedBox(height: 16 * scale),
              ...[
                'Breakfast & Morning Hydration (08:00 AM)',
                'Lunch & Afternoon Check-in (01:00 PM)',
                'Dinner & Daily Goal Wrap-up (07:30 PM)',
              ].map(
                (time) => ListTile(
                  leading: const Icon(Icons.check_circle_rounded, color: Color(0xFF6C4EF5)),
                  title: Text(time, style: TextStyle(fontSize: 13.5 * scale, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: 14 * scale),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C4EF5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14 * scale),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 13 * scale),
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
