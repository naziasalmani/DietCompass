import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/model/ai_analysis_model.dart';
import '../../../core/model/food_product.dart';
import '../../../core/services/ai_service.dart';

/// DietCompass — Product-Centric AI Coach Bottom Sheet
///
/// Provides a dedicated, product-grounded AI conversational experience
/// evaluating the currently scanned product against the authenticated user's profile.
class ProductAiCoachSheet extends StatefulWidget {
  const ProductAiCoachSheet({
    super.key,
    required this.product,
    this.compatibility,
    this.overallScore,
    this.goodPoints = const [],
    this.watchPoints = const [],
    this.alternatives = const [],
  });

  final FoodProduct product;
  final ProductCompatibility? compatibility;
  final int? overallScore;
  final List<String> goodPoints;
  final List<String> watchPoints;
  final List<dynamic> alternatives;

  static Future<void> show(
    BuildContext context, {
    required FoodProduct product,
    ProductCompatibility? compatibility,
    int? overallScore,
    List<String> goodPoints = const [],
    List<String> watchPoints = const [],
    List<dynamic> alternatives = const [],
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductAiCoachSheet(
        product: product,
        compatibility: compatibility,
        overallScore: overallScore,
        goodPoints: goodPoints,
        watchPoints: watchPoints,
        alternatives: alternatives,
      ),
    );
  }

  @override
  State<ProductAiCoachSheet> createState() => _ProductAiCoachSheetState();
}

class _ProductAiCoachSheetState extends State<ProductAiCoachSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<AiCoachChatMessage> _messages = [];
  bool _isThinking = false;

  late final AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _initWelcomeMessage();
  }

  void _initWelcomeMessage() {
    final score = widget.compatibility?.score ?? widget.overallScore;
    final scoreText = score != null ? ' (Score: $score%)' : '';
    final welcome =
        "Hi! I'm your AI Coach. I've analyzed **${widget.product.name}**$scoreText for your dietary profile.\n\n"
        "Ask me anything about its ingredients, sugar, portion size, or why it fits your diet!";

    _messages.add(
      AiCoachChatMessage(
        text: welcome,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _dotsCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<String> get _suggestedQuestions {
    final score = widget.compatibility?.score ?? widget.overallScore;
    final scoreQuestion = score != null
        ? 'Why is my compatibility score $score%?'
        : 'Why is my compatibility score this high/low?';

    return [
      'Is this product good for me?',
      scoreQuestion,
      'What ingredients should I be concerned about?',
      'Is the sugar content actually high?',
      'Is this suitable for my diet?',
      'Can I eat this regularly?',
      'What portion would be reasonable?',
      'What are healthier alternatives?',
    ];
  }

  Future<void> _sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isThinking) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(
        AiCoachChatMessage(
          text: clean,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isThinking = true;
    });

    _scrollToBottom();

    try {
      final reply = await AiService.instance.chatWithCoach(
        clean,
        history: _messages,
        product: widget.product,
        compatibility: widget.compatibility,
        concerns: widget.watchPoints,
        positiveFactors: widget.goodPoints,
        alternatives: widget.alternatives,
      );

      if (mounted) {
        setState(() {
          _messages.add(
            AiCoachChatMessage(
              text: reply,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isThinking = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            AiCoachChatMessage(
              text: "I'm having trouble connecting to AI services right now. Based on the product data, **${widget.product.name}** has ${widget.product.calories ?? 'standard'} calories and ${widget.product.sugar ?? 'moderate'}g sugar.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isThinking = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final height = size.height * 0.85;
    final colors = context.dcColors;

    final score = widget.compatibility?.score ?? widget.overallScore;
    Color scoreColor = colors.iconGreen;
    if (score != null) {
      if (score < 50) {
        scoreColor = colors.iconRed;
      } else if (score < 70) {
        scoreColor = colors.iconOrange;
      }
    } else {
      scoreColor = colors.iconPurple;
    }

    return Container(
      height: height + (bottomInset > 0 ? bottomInset : 0),
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: colors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          children: [
            // Drag handle & Header
            Container(
              padding: EdgeInsets.fromLTRB(18 * scale, 12 * scale, 18 * scale, 10 * scale),
              color: colors.surface,
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40 * scale,
                      height: 4.5 * scale,
                      decoration: BoxDecoration(
                        color: colors.divider,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  Row(
                    children: [
                      Container(
                        width: 36 * scale,
                        height: 36 * scale,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C4EF5), Color(0xFF8E72F8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 20 * scale,
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ask AI About This Product',
                              style: TextStyle(
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2 * scale),
                            Text(
                              'Get personalized answers about this product',
                              style: TextStyle(
                                fontSize: 11.5 * scale,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, size: 22 * scale, color: colors.textSecondary),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Product Context Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
              padding: EdgeInsets.all(10 * scale),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 44 * scale,
                      height: 44 * scale,
                      child: _buildProductThumbnail(scale),
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (widget.product.brand.isNotEmpty) ...[
                          SizedBox(height: 2 * scale),
                          Text(
                            widget.product.brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11 * scale,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 5 * scale),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 13 * scale, color: scoreColor),
                        SizedBox(width: 4 * scale),
                        Text(
                          score != null ? '$score%' : 'Calculating...',
                          style: TextStyle(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Suggested Question Chips
            SizedBox(
              height: 36 * scale,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _suggestedQuestions.length,
                separatorBuilder: (_, __) => SizedBox(width: 8 * scale),
                itemBuilder: (context, idx) {
                  final q = _suggestedQuestions[idx];
                  return ActionChip(
                    label: Text(
                      q,
                      style: TextStyle(
                        fontSize: 11.5 * scale,
                        fontWeight: FontWeight.w600,
                        color: colors.iconPurple,
                      ),
                    ),
                    backgroundColor: colors.surface,
                    side: BorderSide(color: colors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                    onPressed: () => _sendMessage(q),
                  );
                },
              ),
            ),
            SizedBox(height: 6 * scale),

            // Chat Messages Area
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: EdgeInsets.fromLTRB(16 * scale, 8 * scale, 16 * scale, 12 * scale),
                physics: const BouncingScrollPhysics(),
                itemCount: _messages.length + (_isThinking ? 1 : 0),
                itemBuilder: (context, idx) {
                  if (idx == _messages.length && _isThinking) {
                    return _buildThinkingBubble(scale);
                  }
                  final msg = _messages[idx];
                  return _buildChatBubble(msg, scale);
                },
              ),
            ),

            // Input Bar
            Container(
              padding: EdgeInsets.fromLTRB(
                14 * scale,
                8 * scale,
                14 * scale,
                (MediaQuery.of(context).padding.bottom + 8) * scale,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.cardBorder),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 14 * scale),
                      child: TextField(
                        controller: _inputCtrl,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        style: TextStyle(
                          fontSize: 13.5 * scale,
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask about ingredients, sugar, safety...',
                          hintStyle: TextStyle(
                            fontSize: 12.5 * scale,
                            color: colors.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10 * scale),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  GestureDetector(
                    onTap: () => _sendMessage(_inputCtrl.text),
                    child: Container(
                      width: 40 * scale,
                      height: 40 * scale,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C4EF5), Color(0xFF8E72F8)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C4EF5).withValues(alpha: 0.32),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18 * scale,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductThumbnail(double uiScale) {
    final imgUrl = widget.product.imageUrl;
    if (imgUrl.isNotEmpty) {
      if (imgUrl.startsWith('http://') || imgUrl.startsWith('https://')) {
        return Image.network(
          imgUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumbnailFallback(uiScale),
        );
      } else if (imgUrl.startsWith('assets/')) {
        return Image.asset(
          imgUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumbnailFallback(uiScale),
        );
      }
    }
    return _thumbnailFallback(uiScale);
  }

  Widget _thumbnailFallback(double uiScale) {
    final colors = context.dcColors;
    return Container(
      color: colors.surfaceSecondary,
      alignment: Alignment.center,
      child: Icon(
        Icons.fastfood_rounded,
        size: 22 * uiScale,
        color: colors.iconPurple,
      ),
    );
  }

  Widget _buildChatBubble(AiCoachChatMessage msg, double uiScale) {
    final colors = context.dcColors;
    final isUser = msg.isUser;

    return Padding(
      padding: EdgeInsets.only(bottom: 10 * uiScale),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28 * uiScale,
              height: 28 * uiScale,
              margin: EdgeInsets.only(right: 8 * uiScale, top: 2 * uiScale),
              decoration: BoxDecoration(
                color: colors.iconPurple,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16 * uiScale),
            ),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14 * uiScale, vertical: 10 * uiScale),
              decoration: BoxDecoration(
                color: isUser ? colors.iconPurple : colors.surface,
                gradient: isUser
                    ? const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF8467F8)])
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                border: isUser ? null : Border.all(color: colors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 13 * uiScale,
                  height: 1.45,
                  color: isUser ? Colors.white : colors.textPrimary,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 4 * uiScale),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingBubble(double uiScale) {
    final colors = context.dcColors;
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * uiScale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28 * uiScale,
            height: 28 * uiScale,
            margin: EdgeInsets.only(right: 8 * uiScale, top: 2 * uiScale),
            decoration: BoxDecoration(
              color: colors.iconPurple,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16 * uiScale),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14 * uiScale, vertical: 12 * uiScale),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Coach is thinking',
                  style: TextStyle(
                    fontSize: 12 * uiScale,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 6 * uiScale),
                AnimatedBuilder(
                  animation: _dotsCtrl,
                  builder: (context, _) {
                    final v = (_dotsCtrl.value * 3).floor() + 1;
                    return Text(
                      '.' * v,
                      style: TextStyle(
                        fontSize: 14 * uiScale,
                        fontWeight: FontWeight.w900,
                        color: colors.iconPurple,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
