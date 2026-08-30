import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';

/// DietCompass — Active Sessions Screen
/// -----------------------------------------------------------------------
/// Displays logged-in devices, active token sessions, and provides remote
/// device logout capabilities matching the DietCompass visual language.
class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  bool _isLoading = true;
  bool _isLoggingOutAll = false;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      final response = await ApiService.instance.get(
        '/auth/sessions',
        requiresAuth: true,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null && response.data!['data'] is List) {
            _sessions = List<Map<String, dynamic>>.from(response.data!['data']);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogoutAll() async {
    setState(() => _isLoggingOutAll = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final response = await ApiService.instance.post(
        '/auth/logout-all',
        requiresAuth: true,
      );

      if (!mounted) return;
      setState(() => _isLoggingOutAll = false);

      if (response.success) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1B1B2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF1E8A4C), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Logged out from all other devices successfully.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
        _fetchSessions();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingOutAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final scale = (width / 390.0).clamp(0.85, 1.25);
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      body: Stack(
        children: [
          // Ambient blurred background orbs
          Positioned(
            top: -40,
            left: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.12),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onBack ?? () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40 * scale,
                          height: 40 * scale,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14 * scale),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20 * scale,
                            color: const Color(0xFF1B1B2E),
                          ),
                        ),
                      ),
                      SizedBox(width: 14 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Sessions',
                              style: TextStyle(
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B1B2E),
                              ),
                            ),
                            Text(
                              'Manage devices where your account is active',
                              style: TextStyle(
                                fontSize: 12 * scale,
                                color: const Color(0xFF6B6B7B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Device Card
                        Container(
                          padding: EdgeInsets.all(18 * scale),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20 * scale),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C4EF5).withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44 * scale,
                                    height: 44 * scale,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6C4EF5), Color(0xFF8467F8)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14 * scale),
                                    ),
                                    child: Icon(
                                      Icons.phone_android_rounded,
                                      color: Colors.white,
                                      size: 22 * scale,
                                    ),
                                  ),
                                  SizedBox(width: 12 * scale),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Device',
                                          style: TextStyle(
                                            fontSize: 14.5 * scale,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF1B1B2E),
                                          ),
                                        ),
                                        SizedBox(height: 2 * scale),
                                        Text(
                                          user?.email ?? 'Active Mobile Session',
                                          style: TextStyle(
                                            fontSize: 12 * scale,
                                            color: const Color(0xFF6B6B7B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F5EA),
                                      borderRadius: BorderRadius.circular(8 * scale),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF1E8A4C),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Active Now',
                                          style: TextStyle(
                                            fontSize: 10 * scale,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1E8A4C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 14 * scale),
                              Container(
                                padding: EdgeInsets.all(12 * scale),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F7FD),
                                  borderRadius: BorderRadius.circular(12 * scale),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lock_rounded,
                                      size: 16 * scale,
                                      color: const Color(0xFF6C4EF5),
                                    ),
                                    SizedBox(width: 8 * scale),
                                    Expanded(
                                      child: Text(
                                        'Session protected with encrypted JWT Bearer tokens in device storage.',
                                        style: TextStyle(
                                          fontSize: 11.5 * scale,
                                          color: const Color(0xFF6B6B7B),
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_isLoading) ...[
                          SizedBox(height: 16 * scale),
                          const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ] else if (_sessions.length > 1) ...[
                          SizedBox(height: 20 * scale),
                          Text(
                            'OTHER ACTIVE SESSIONS (${_sessions.length - 1})',
                            style: TextStyle(
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: const Color(0xFF6B6B7B),
                            ),
                          ),
                          SizedBox(height: 10 * scale),
                          ..._sessions.skip(1).map((s) => Container(
                            margin: EdgeInsets.only(bottom: 10 * scale),
                            padding: EdgeInsets.all(14 * scale),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16 * scale),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.devices_other_rounded, color: const Color(0xFF6C4EF5), size: 20 * scale),
                                SizedBox(width: 10 * scale),
                                Expanded(
                                  child: Text(
                                    s['deviceInfo'] ?? 'Remote Device',
                                    style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],

                        SizedBox(height: 24 * scale),

                        // Section Title
                        Text(
                          'SESSION CONTROLS',
                          style: TextStyle(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: const Color(0xFF6B6B7B),
                          ),
                        ),
                        SizedBox(height: 10 * scale),

                        // Logout All Devices Button
                        Container(
                          padding: EdgeInsets.all(16 * scale),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20 * scale),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C4EF5).withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign Out Other Sessions',
                                style: TextStyle(
                                  fontSize: 13.5 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B1B2E),
                                ),
                              ),
                              SizedBox(height: 4 * scale),
                              Text(
                                'If you notice unfamiliar activity, you can terminate all other active device sessions immediately.',
                                style: TextStyle(
                                  fontSize: 12 * scale,
                                  color: const Color(0xFF6B6B7B),
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 16 * scale),
                              SizedBox(
                                width: double.infinity,
                                height: 46 * scale,
                                child: OutlinedButton(
                                  onPressed: _isLoggingOutAll ? null : _handleLogoutAll,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE0525C),
                                    side: const BorderSide(color: Color(0xFFE0525C), width: 1.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12 * scale),
                                    ),
                                  ),
                                  child: _isLoggingOutAll
                                      ? SizedBox(
                                          width: 18 * scale,
                                          height: 18 * scale,
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(Color(0xFFE0525C)),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.logout_rounded, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Log Out From All Other Devices',
                                              style: TextStyle(
                                                fontSize: 13 * scale,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
