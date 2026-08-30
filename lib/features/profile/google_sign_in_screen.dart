import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

/// DietCompass — Google Sign-In Management Screen
/// -----------------------------------------------------------------------
/// Displays Google OAuth 2.0 connection details, status, and allows account
/// switching/re-authentication matching the DietCompass visual language.
class GoogleSignInManagementScreen extends StatefulWidget {
  const GoogleSignInManagementScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<GoogleSignInManagementScreen> createState() =>
      _GoogleSignInManagementScreenState();
}

class _GoogleSignInManagementScreenState
    extends State<GoogleSignInManagementScreen> {
  bool _isConnecting = false;

  Future<void> _handleGoogleReconnect() async {
    setState(() => _isConnecting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final user = await AuthService.instance.loginWithGoogle();
      if (!mounted) return;
      setState(() => _isConnecting = false);

      if (user != null) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1B1B2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF1E8A4C), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connected to Google account ${user.email}.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConnecting = false);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B1B2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Color(0xFFE0525C), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Google Sign-In canceled or encountered an issue.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final scale = (width / 390.0).clamp(0.85, 1.25);
    final user = AuthService.instance.currentUser;
    final isGoogleConnected = user != null && user.email.contains('@gmail.com');

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      body: Stack(
        children: [
          // Ambient blurred background orbs
          Positioned(
            top: -50,
            right: -40,
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
                              'Google Sign-In',
                              style: TextStyle(
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B1B2E),
                              ),
                            ),
                            Text(
                              'Connected account & authentication',
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
                        // Main Connection Card
                        Container(
                          padding: EdgeInsets.all(20 * scale),
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
                                    width: 48 * scale,
                                    height: 48 * scale,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F0FB),
                                      borderRadius: BorderRadius.circular(16 * scale),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'G',
                                        style: TextStyle(
                                          fontSize: 24 * scale,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF4285F4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 14 * scale),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isGoogleConnected ? 'Google Account Connected' : 'Google Sign-In Available',
                                          style: TextStyle(
                                            fontSize: 15 * scale,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF1B1B2E),
                                          ),
                                        ),
                                        SizedBox(height: 2 * scale),
                                        Text(
                                          user?.email ?? 'No email linked',
                                          style: TextStyle(
                                            fontSize: 12.5 * scale,
                                            color: const Color(0xFF6B6B7B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                                    decoration: BoxDecoration(
                                      color: isGoogleConnected ? const Color(0xFFE3F5EA) : const Color(0xFFEDE7FA),
                                      borderRadius: BorderRadius.circular(8 * scale),
                                    ),
                                    child: Text(
                                      isGoogleConnected ? 'Connected' : 'Available',
                                      style: TextStyle(
                                        fontSize: 10.5 * scale,
                                        fontWeight: FontWeight.w700,
                                        color: isGoogleConnected ? const Color(0xFF1E8A4C) : const Color(0xFF6C4EF5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 18 * scale),
                              const Divider(height: 1, color: Color(0xFFF0EDF7)),
                              SizedBox(height: 16 * scale),

                              // Security Bullet Points
                              _buildFeatureRow(
                                icon: Icons.lock_outline_rounded,
                                title: 'Direct Google Cloud OAuth',
                                subtitle: 'Secure tokens verified cryptographically by the backend',
                                scale: scale,
                              ),
                              SizedBox(height: 12 * scale),
                              _buildFeatureRow(
                                icon: Icons.sync_rounded,
                                title: 'Synchronized Profile Data',
                                subtitle: 'Name, email, and avatar stay seamlessly linked',
                                scale: scale,
                              ),
                              SizedBox(height: 12 * scale),
                              _buildFeatureRow(
                                icon: Icons.shield_outlined,
                                title: 'No Passwords Stored',
                                subtitle: 'Google handles two-factor authentication and security checks',
                                scale: scale,
                              ),

                              SizedBox(height: 22 * scale),

                              // Action Button
                              SizedBox(
                                width: double.infinity,
                                height: 48 * scale,
                                child: ElevatedButton(
                                  onPressed: _isConnecting ? null : _handleGoogleReconnect,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C4EF5),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14 * scale),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isConnecting
                                      ? SizedBox(
                                          width: 20 * scale,
                                          height: 20 * scale,
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.account_circle_outlined, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              isGoogleConnected ? 'Switch / Reconnect Account' : 'Connect Google Account',
                                              style: TextStyle(
                                                fontSize: 13.5 * scale,
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

                        SizedBox(height: 24 * scale),
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

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required double scale,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32 * scale,
          height: 32 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE7FA),
            borderRadius: BorderRadius.circular(10 * scale),
          ),
          child: Icon(icon, color: const Color(0xFF6C4EF5), size: 16 * scale),
        ),
        SizedBox(width: 12 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1B2E),
                ),
              ),
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
      ],
    );
  }
}
