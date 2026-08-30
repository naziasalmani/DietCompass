import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';

/// DietCompass — Password & Login Management Screen
/// -----------------------------------------------------------------------
/// Provides full password modification, password reset requests, and security
/// credential management matching the DietCompass visual language.
class PasswordLoginScreen extends StatefulWidget {
  const PasswordLoginScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<PasswordLoginScreen> createState() => _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends State<PasswordLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  bool _isSendingReset = false;

  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordChange() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final response = await ApiService.instance.post(
        '/auth/change-password',
        body: {
          'currentPassword': _currentPasswordCtrl.text.trim(),
          'newPassword': _newPasswordCtrl.text.trim(),
        },
        requiresAuth: true,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.success) {
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();

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
                    'Password updated successfully.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        final errorMsg = response.message != null && response.message!.isNotEmpty
            ? response.message!
            : 'Failed to update password. Please check your current password.';
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1B1B2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFE0525C), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMsg,
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
      setState(() => _isSaving = false);
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
                  'Connection error. Please try again.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleSendResetLink() async {
    final user = AuthService.instance.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B1B2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('No email address associated with this account.', style: TextStyle(fontSize: 12)),
        ),
      );
      return;
    }

    setState(() => _isSendingReset = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await AuthService.instance.forgotPassword(email);
      if (!mounted) return;
      setState(() => _isSendingReset = false);

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B1B2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: Color(0xFF1E8A4C), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Password reset email sent to $email.',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSendingReset = false);
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
                  'Could not send reset link. Please try again later.',
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
    final isGoogleUser = user != null && user.email.contains('@gmail.com');

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      body: Stack(
        children: [
          // Ambient blurred background orbs
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E8A4C).withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar Header
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
                              'Password & Security',
                              style: TextStyle(
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B1B2E),
                              ),
                            ),
                            Text(
                              'Manage your account credentials',
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

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Card
                          Container(
                            padding: EdgeInsets.all(16 * scale),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20 * scale),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C4EF5).withValues(alpha: 0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
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
                                    isGoogleUser ? Icons.g_mobiledata_rounded : Icons.lock_outline_rounded,
                                    color: Colors.white,
                                    size: 24 * scale,
                                  ),
                                ),
                                SizedBox(width: 12 * scale),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isGoogleUser ? 'Google OAuth Account' : 'Password Protected',
                                        style: TextStyle(
                                          fontSize: 14 * scale,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1B1B2E),
                                        ),
                                      ),
                                      SizedBox(height: 2 * scale),
                                      Text(
                                        user?.email ?? 'Logged in user',
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
                                  child: Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 10 * scale,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E8A4C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20 * scale),

                          // Change Password Section
                          Text(
                            'CHANGE PASSWORD',
                            style: TextStyle(
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: const Color(0xFF6B6B7B),
                            ),
                          ),
                          SizedBox(height: 10 * scale),

                          Container(
                            padding: EdgeInsets.all(16 * scale),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20 * scale),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
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
                                if (!isGoogleUser) ...[
                                  _buildPasswordField(
                                    label: 'Current Password',
                                    controller: _currentPasswordCtrl,
                                    obscure: _obscureCurrent,
                                    onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Please enter your current password.';
                                      }
                                      return null;
                                    },
                                    scale: scale,
                                  ),
                                  SizedBox(height: 14 * scale),
                                ],

                                _buildPasswordField(
                                  label: 'New Password',
                                  controller: _newPasswordCtrl,
                                  obscure: _obscureNew,
                                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Please enter a new password.';
                                    }
                                    if (val.length < 8) {
                                      return 'Password must be at least 8 characters.';
                                    }
                                    return null;
                                  },
                                  scale: scale,
                                ),
                                SizedBox(height: 14 * scale),

                                _buildPasswordField(
                                  label: 'Confirm New Password',
                                  controller: _confirmPasswordCtrl,
                                  obscure: _obscureConfirm,
                                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Please confirm your new password.';
                                    }
                                    if (val != _newPasswordCtrl.text) {
                                      return 'Passwords do not match.';
                                    }
                                    return null;
                                  },
                                  scale: scale,
                                ),
                                SizedBox(height: 20 * scale),

                                // Update Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48 * scale,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _handlePasswordChange,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6C4EF5),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14 * scale),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isSaving
                                        ? SizedBox(
                                            width: 20 * scale,
                                            height: 20 * scale,
                                            child: const CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Update Password',
                                            style: TextStyle(
                                              fontSize: 14 * scale,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20 * scale),

                          // Forgot Password Helper Card
                          Container(
                            padding: EdgeInsets.all(16 * scale),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20 * scale),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C4EF5).withValues(alpha: 0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38 * scale,
                                  height: 38 * scale,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE7FA),
                                    borderRadius: BorderRadius.circular(12 * scale),
                                  ),
                                  child: Icon(
                                    Icons.help_outline_rounded,
                                    color: const Color(0xFF6C4EF5),
                                    size: 20 * scale,
                                  ),
                                ),
                                SizedBox(width: 12 * scale),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Forgot your current password?',
                                        style: TextStyle(
                                          fontSize: 13 * scale,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1B1B2E),
                                        ),
                                      ),
                                      Text(
                                        'We can send a secure reset link to your email.',
                                        style: TextStyle(
                                          fontSize: 11.5 * scale,
                                          color: const Color(0xFF6B6B7B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isSendingReset ? null : _handleSendResetLink,
                                  child: _isSendingReset
                                      ? SizedBox(
                                          width: 14 * scale,
                                          height: 14 * scale,
                                          child: const CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(
                                          'Send Link',
                                          style: TextStyle(
                                            fontSize: 12 * scale,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF6C4EF5),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30 * scale),
                        ],
                      ),
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    required double scale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5 * scale,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B1B2E),
          ),
        ),
        SizedBox(height: 6 * scale),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: TextStyle(fontSize: 14 * scale, color: const Color(0xFF1B1B2E)),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: const Color(0xFFA0A0B0), fontSize: 14 * scale),
            filled: true,
            fillColor: const Color(0xFFF9F7FD),
            contentPadding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF6B6B7B),
                size: 20 * scale,
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: BorderSide(color: const Color(0xFF6C4EF5).withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: BorderSide(color: const Color(0xFF6C4EF5).withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: const BorderSide(color: Color(0xFF6C4EF5), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
