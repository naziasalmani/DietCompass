import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/config/app_config.dart';
import 'help_guide_screen.dart';

/// DietCompass — Help & Support Screen
/// -----------------------------------------------------------------------
/// Matches the exact visual language of My Profile, Privacy & Security, and
/// Health Profile: lavender background (0xFFF3F0FB), frosted glass cards,
/// animated expandable FAQs, Quick Help guides, Contact Us, and Report a Problem.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  // Track expanded state for FAQ items
  final Set<int> _expandedFaqIndices = {};

  static final List<HelpGuideTopic> _quickHelpTopics = [
    const HelpGuideTopic(
      title: 'Getting Started',
      subtitle: 'Learn how to use DietCompass',
      icon: Icons.flag_rounded,
      iconColor: Color(0xFF6C4EF5),
      iconBg: Color(0xFFEDE7FA),
      sections: [
        HelpGuideSection(
          heading: '1. Welcome to DietCompass',
          body: 'DietCompass is your AI-powered nutrition and diet assistant. It is designed to help you make informed dietary choices by scanning food barcodes, analyzing ingredient labels, generating personalized recipes from your pantry, and creating weekly meal plans customized to your health goals.',
          tips: [
            'Set up your Dietary Preferences in My Profile to ensure all scan alerts and recipes are tailored to your needs.',
            'Maintain your daily scan streak to track your health progress and improve your nutrition habits.',
          ],
        ),
        HelpGuideSection(
          heading: '2. Navigating the App',
          body: 'Use the bottom navigation bar to switch between the Home Dashboard, Scan Scanner, AI Coach & Recipes, and your Personal Profile.',
        ),
      ],
    ),
    const HelpGuideTopic(
      title: 'Scanning Products',
      subtitle: 'Learn how to scan and analyze food products',
      icon: Icons.qr_code_scanner_rounded,
      iconColor: Color(0xFF1E8A4C),
      iconBg: Color(0xFFE3F5EA),
      sections: [
        HelpGuideSection(
          heading: 'Barcode Scanner Mode',
          body: 'Align the barcode within the camera viewfinder on the Scan tab. DietCompass automatically recognizes standard UPC-A, EAN-13, and GTIN codes and retrieves nutritional data instantly.',
          tips: [
            'Ensure good lighting and avoid reflections on glossy packaging.',
            'Hold the device 4 to 8 inches away from the barcode.',
          ],
        ),
        HelpGuideSection(
          heading: 'Ingredient OCR Photo Mode',
          body: 'If a barcode is unavailable or missing, switch to the OCR Camera mode to photograph the ingredient list. Optical character recognition extracts and evaluates the text automatically.',
        ),
        HelpGuideSection(
          heading: 'Manual Search',
          body: 'You can also type any food name or ingredient directly into the search bar on the Scan tab to look up its nutritional profile.',
        ),
      ],
    ),
    const HelpGuideTopic(
      title: 'Understanding Results',
      subtitle: 'Learn how DietCompass analyzes ingredients and nutrition',
      icon: Icons.analytics_outlined,
      iconColor: Color(0xFF3B82F6),
      iconBg: Color(0xFFE3EEFC),
      sections: [
        HelpGuideSection(
          heading: 'Health & Nutrition Score',
          body: 'Every scanned item receives an objective score from 0 to 100 based on positive factors (fiber, protein, vitamins) and risk factors (excess sugar, sodium, saturated fat, harmful additives).',
        ),
        HelpGuideSection(
          heading: 'Allergen & Preference Match',
          body: 'DietCompass checks all ingredients against your personalized allergies (such as Gluten, Peanuts, Dairy) and dietary preferences (such as Vegetarian, Vegan, Eggetarian). If an incompatible ingredient is detected, a high-visibility warning badge is displayed.',
        ),
        HelpGuideSection(
          heading: 'Healthier Alternatives',
          body: 'For lower-scoring products, DietCompass suggests compatible healthier alternatives available in the product database.',
        ),
      ],
    ),
    const HelpGuideTopic(
      title: 'Recipes & Recommendations',
      subtitle: 'Get help with recipes and personalized recommendations',
      icon: Icons.restaurant_menu_rounded,
      iconColor: Color(0xFFE0862E),
      iconBg: Color(0xFFFCEEDD),
      sections: [
        HelpGuideSection(
          heading: 'Pantry Recipe Generator',
          body: 'Input the ingredients you currently have at home into your Pantry. DietCompass generates safe, delicious recipes that prioritize what you have while respecting your diet and allergen restrictions.',
        ),
        HelpGuideSection(
          heading: 'Saving & Bookmarking Recipes',
          body: 'Tap the bookmark icon on any generated or viewed recipe card to save it. You can access all your saved favorites anytime under My Profile → Saved Recipes.',
        ),
        HelpGuideSection(
          heading: 'AI Weekly Meal Planner',
          body: 'Generate structured 3-day or 7-day meal plans customized by target calories, goal (Weight Loss, Muscle Gain, Balanced), and dietary preferences.',
        ),
      ],
    ),
  ];

  static const List<Map<String, String>> _faqs = [
    {
      'question': 'How does DietCompass analyze a food product?',
      'answer':
          'When you scan a product, DietCompass identifies its barcode or extracts ingredients using OCR text recognition. The ingredients and nutritional values (calories, protein, fats, sugars, sodium) are scored against nutritional guidelines and cross-referenced with your personal diet type, allergies, and health goals.',
    },
    {
      'question': 'How do I scan a product?',
      'answer':
          'Tap the Scan icon on the bottom navigation bar. Point your camera at the barcode on the package. You can also tap the camera icon to photograph the ingredients text directly, or type the product name in manual search.',
    },
    {
      'question': 'Where can I see my scan history?',
      'answer':
          'Your recent scans appear directly on the Home dashboard and the Scan screen. You can also view your complete historical scan list by tapping "Scan History" inside My Profile → Privacy & Security or on the Scan screen.',
    },
    {
      'question': 'How are my dietary preferences used?',
      'answer':
          'Your dietary preferences (Diet Type, Allergies, Foods You Dislike, and Health Goals) are used across the app to flag incompatible products with warning badges, tailor healthy recommendations, and filter recipes generated in the Recipe Generator and Weekly Meal Planner.',
    },
    {
      'question': 'How do I save a recipe?',
      'answer':
          'When viewing any recipe in the Recipe Generator or Recipe History, tap the bookmark icon on the recipe card or detail page. The recipe will instantly appear in My Profile → Saved Recipes for quick offline access.',
    },
    {
      'question': 'How do I change my profile information?',
      'answer':
          'Go to My Profile and select "Personal Information" to update your name, phone, date of birth, height, and weight. To modify your nutrition goals or lifestyle metrics, tap "Health Profile" or "Dietary Preferences".',
    },
    {
      'question': 'How do I protect my account?',
      'answer':
          'Go to My Profile → Privacy & Security. You can manage your password, review active Google OAuth sign-in status, inspect connected active sessions, or request a complete JSON copy of your personal data via "Download My Data".',
    },
  ];

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
    _animCtrl.dispose();
    super.dispose();
  }

  void _openGuideTopic(HelpGuideTopic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HelpGuideScreen(topic: topic),
      ),
    );
  }

  void _handleContactEmail() async {
    final email = AppConfig.supportEmail;
    await Clipboard.setData(ClipboardData(text: email));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1B1B2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.copy_rounded, color: Color(0xFF1E8A4C), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Support email ($email) copied to clipboard.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Hi DietCompass Support Team,\n\nI need assistance with: \n\nApp Version: 1.0.0 (Beta)',
          subject: '[DietCompass Support Request]',
        ),
      );
    } catch (_) {}
  }

  void _showReportProblemDialog() {
    final problemCtrl = TextEditingController();
    String selectedCategory = 'Scanning';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final mq = MediaQuery.of(context);
          final scale = (mq.size.width / 390.0).clamp(0.85, 1.25);

          return Padding(
            padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
            child: Container(
              padding: EdgeInsets.all(22 * scale),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36 * scale,
                          height: 36 * scale,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECEE),
                            borderRadius: BorderRadius.circular(10 * scale),
                          ),
                          child: Icon(Icons.bug_report_outlined, color: const Color(0xFFE0525C), size: 20 * scale),
                        ),
                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: Text(
                            'Report a Problem',
                            style: TextStyle(
                              fontSize: 16.5 * scale,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1B1B2E),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B6B7B)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    SizedBox(height: 14 * scale),
                    Text(
                      'Category',
                      style: TextStyle(fontSize: 12.5 * scale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E)),
                    ),
                    SizedBox(height: 6 * scale),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF9F7FD),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 10 * scale),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12 * scale),
                          borderSide: BorderSide(color: const Color(0xFF6C4EF5).withValues(alpha: 0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12 * scale),
                          borderSide: BorderSide(color: const Color(0xFF6C4EF5).withValues(alpha: 0.15)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Scanning', child: Text('Scanning & Barcodes')),
                        DropdownMenuItem(value: 'Recipes', child: Text('Recipe Generator')),
                        DropdownMenuItem(value: 'MealPlanner', child: Text('Meal Planner')),
                        DropdownMenuItem(value: 'Account', child: Text('Account & Login')),
                        DropdownMenuItem(value: 'Other', child: Text('Other Issue')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                    SizedBox(height: 14 * scale),
                    Text(
                      'Problem Description',
                      style: TextStyle(fontSize: 12.5 * scale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E)),
                    ),
                    SizedBox(height: 6 * scale),
                    TextField(
                      controller: problemCtrl,
                      maxLines: 4,
                      style: TextStyle(fontSize: 13.5 * scale, color: const Color(0xFF1B1B2E)),
                      decoration: InputDecoration(
                        hintText: 'Please describe what happened and how to reproduce the issue...',
                        hintStyle: TextStyle(color: const Color(0xFFA0A0B0), fontSize: 12.5 * scale),
                        filled: true,
                        fillColor: const Color(0xFFF9F7FD),
                        contentPadding: EdgeInsets.all(12 * scale),
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
                    SizedBox(height: 18 * scale),
                    SizedBox(
                      width: double.infinity,
                      height: 48 * scale,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (problemCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please describe the problem first.')),
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);
                                final text = problemCtrl.text.trim();
                                Navigator.pop(ctx);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF1B1B2E),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    content: const Row(
                                      children: [
                                        Icon(Icons.mark_email_read_rounded, color: Color(0xFF1E8A4C), size: 18),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Opening email dispatch to submit your report to support...',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                try {
                                  await SharePlus.instance.share(
                                    ShareParams(
                                      text: 'DietCompass Problem Report\nCategory: $selectedCategory\nDetails: $text\n\nApp Version: 1.0.0 (Beta)',
                                      subject: '[DietCompass Bug Report: $selectedCategory]',
                                    ),
                                  );
                                } catch (_) {}
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C4EF5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14 * scale)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Submit Report',
                          style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final scale = (width / 390.0).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FB),
      body: Stack(
        children: [
          // Ambient blurred background orbs
          Positioned(
            top: -50,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C4EF5).withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            top: 300,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E8A4C).withValues(alpha: 0.08),
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
                              'Help & Support',
                              style: TextStyle(
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B1B2E),
                              ),
                            ),
                            Text(
                              "We're here to help you",
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

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Section 1: Quick Help ───────────────────────────
                        _buildSectionHeader('How can we help?', scale),
                        SizedBox(height: 10 * scale),
                        _buildCard(
                          scale: scale,
                          child: Column(
                            children: [
                              for (int i = 0; i < _quickHelpTopics.length; i++) ...[
                                _buildMenuRow(
                                  topic: _quickHelpTopics[i],
                                  scale: scale,
                                  onTap: () => _openGuideTopic(_quickHelpTopics[i]),
                                ),
                                if (i < _quickHelpTopics.length - 1) _buildDivider(),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: 22 * scale),

                        // ── Section 2: FAQ ──────────────────────────────────
                        _buildSectionHeader('Frequently Asked Questions', scale),
                        SizedBox(height: 10 * scale),
                        _buildCard(
                          scale: scale,
                          child: Column(
                            children: [
                              for (int i = 0; i < _faqs.length; i++) ...[
                                _buildFaqTile(
                                  index: i,
                                  question: _faqs[i]['question']!,
                                  answer: _faqs[i]['answer']!,
                                  scale: scale,
                                ),
                                if (i < _faqs.length - 1) _buildDivider(),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: 22 * scale),

                        // ── Section 3: Contact Us ───────────────────────────
                        _buildSectionHeader('Contact Us', scale),
                        SizedBox(height: 10 * scale),
                        _buildCard(
                          scale: scale,
                          child: Column(
                            children: [
                              _buildActionRow(
                                icon: Icons.email_outlined,
                                iconColor: const Color(0xFF6C4EF5),
                                iconBg: const Color(0xFFEDE7FA),
                                title: 'Email Support',
                                subtitle: 'Get help from the DietCompass support team',
                                scale: scale,
                                onTap: _handleContactEmail,
                              ),
                              _buildDivider(),
                              _buildActionRow(
                                icon: Icons.bug_report_outlined,
                                iconColor: const Color(0xFFE0525C),
                                iconBg: const Color(0xFFFFECEE),
                                title: 'Report a Problem',
                                subtitle: "Tell us about an issue you're experiencing",
                                scale: scale,
                                onTap: _showReportProblemDialog,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 22 * scale),

                        // ── Section 4: App Information ──────────────────────
                        _buildSectionHeader('App Information', scale),
                        SizedBox(height: 10 * scale),
                        _buildCard(
                          scale: scale,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 14 * scale),
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
                                  child: Icon(Icons.explore_rounded, color: Colors.white, size: 22 * scale),
                                ),
                                SizedBox(width: 14 * scale),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'DietCompass',
                                        style: TextStyle(
                                          fontSize: 14.5 * scale,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1B1B2E),
                                        ),
                                      ),
                                      SizedBox(height: 2 * scale),
                                      Text(
                                        'AI-Powered Nutrition & Diet Assistant',
                                        style: TextStyle(
                                          fontSize: 11.5 * scale,
                                          color: const Color(0xFF6B6B7B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 9 * scale, vertical: 4 * scale),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE7FA),
                                    borderRadius: BorderRadius.circular(8 * scale),
                                  ),
                                  child: Text(
                                    '1.0.0 (Beta)',
                                    style: TextStyle(
                                      fontSize: 11 * scale,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF6C4EF5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 28 * scale),
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

  Widget _buildSectionHeader(String title, double scale) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15 * scale,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1B1B2E),
      ),
    );
  }

  Widget _buildCard({required double scale, required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFF3F0FB), indent: 16, endIndent: 16);
  }

  Widget _buildMenuRow({
    required HelpGuideTopic topic,
    required double scale,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20 * scale),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 14 * scale),
        child: Row(
          children: [
            Container(
              width: 38 * scale,
              height: 38 * scale,
              decoration: BoxDecoration(
                color: topic.iconBg,
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: Icon(topic.icon, color: topic.iconColor, size: 18 * scale),
            ),
            SizedBox(width: 14 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: TextStyle(
                      fontSize: 13.5 * scale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B2E),
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    topic.subtitle,
                    style: TextStyle(
                      fontSize: 11.5 * scale,
                      color: const Color(0xFF6B6B7B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20 * scale, color: const Color(0xFFA0A0B0)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required double scale,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20 * scale),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 14 * scale),
        child: Row(
          children: [
            Container(
              width: 38 * scale,
              height: 38 * scale,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: Icon(icon, color: iconColor, size: 18 * scale),
            ),
            SizedBox(width: 14 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5 * scale,
                      fontWeight: FontWeight.w700,
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
            Icon(Icons.chevron_right_rounded, size: 20 * scale, color: const Color(0xFFA0A0B0)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile({
    required int index,
    required String question,
    required String answer,
    required double scale,
  }) {
    final isExpanded = _expandedFaqIndices.contains(index);

    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedFaqIndices.remove(index);
          } else {
            _expandedFaqIndices.add(index);
          }
        });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 14 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 13.5 * scale,
                      fontWeight: FontWeight.w700,
                      color: isExpanded ? const Color(0xFF6C4EF5) : const Color(0xFF1B1B2E),
                    ),
                  ),
                ),
                SizedBox(width: 8 * scale),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20 * scale,
                    color: isExpanded ? const Color(0xFF6C4EF5) : const Color(0xFFA0A0B0),
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: EdgeInsets.only(top: 10 * scale),
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 12.5 * scale,
                    color: const Color(0xFF5A5A6A),
                    height: 1.45,
                  ),
                ),
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
