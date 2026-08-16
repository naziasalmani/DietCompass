import 'package:flutter/material.dart';
import '../onboarding_theme.dart';

/// Purple wave + leaf + dot-pattern background matching the reference screens.
/// Swap the [CustomPaint] / [Icon] placeholders for your real illustration
/// assets (e.g. `assets/images/leaf.png`) if you have them.
class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: AppColors.pageBg)),
        // Bottom wave
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 140),
            painter: _WavePainter(),
          ),
        ),
        // Top-left leaf sprig
        const Positioned(
          top: -10,
          left: -10,
          child: _LeafSprig(size: 90, opacity: 0.35),
        ),
        // Bottom-left leaf sprig
        const Positioned(
          bottom: 40,
          left: -10,
          child: _LeafSprig(size: 110, opacity: 0.3),
        ),
        // Dot pattern corners
        const Positioned(top: 140, left: 8, child: _DotGrid()),
        const Positioned(bottom: 160, right: 8, child: _DotGrid()),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.waveBg.withOpacity(0.9);
    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
          size.width * 0.25, size.height * 0.15, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.85, size.width, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LeafSprig extends StatelessWidget {
  final double size;
  final double opacity;
  const _LeafSprig({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Icon(Icons.eco, size: size, color: AppColors.primaryPurple),
    );
  }
}

class _DotGrid extends StatelessWidget {
  const _DotGrid();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.25,
      child: SizedBox(
        width: 70,
        height: 70,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
          itemCount: 36,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(radius: 1.8, backgroundColor: AppColors.primaryPurple),
          ),
        ),
      ),
    );
  }
}

/// Segmented step-progress bar with an icon "badge" on the current step.
class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final IconData stepIcon;

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (i) {
        // Even indices = segments, odd indices = small dot separators.
        if (i.isOdd) {
          return const SizedBox(width: 6);
        }
        final step = (i ~/ 2) + 1;
        final isCurrent = step == currentStep;
        final isDone = step < currentStep;
        if (isCurrent) {
          return Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryPurple,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(stepIcon, size: 16, color: Colors.white),
          );
        }
        return Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDone ? AppColors.primaryPurple : AppColors.borderLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

/// Simple stylized robot mascot built from shapes (no external asset needed).
/// Replace with `Image.asset('assets/images/robot.png')` if you have the
/// real illustration.
class RobotMascot extends StatelessWidget {
  final double size;
  final IconData? badgeIcon;
  final Color badgeColor;

  const RobotMascot({
    super.key,
    this.size = 150,
    this.badgeIcon,
    this.badgeColor = AppColors.primaryPurple,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Halo circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryPurple.withOpacity(0.08),
            ),
          ),
          // Antenna
          Positioned(
            top: size * 0.02,
            child: Container(
              width: 4,
              height: size * 0.14,
              color: AppColors.primaryPurple,
            ),
          ),
          Positioned(
            top: 0,
            child: CircleAvatar(radius: 5, backgroundColor: AppColors.primaryPurple),
          ),
          // Head
          Positioned(
            top: size * 0.16,
            child: Container(
              width: size * 0.62,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * 0.18),
                border: Border.all(color: AppColors.primaryPurple.withOpacity(0.25), width: 2),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Center(
                child: Container(
                  width: size * 0.44,
                  height: size * 0.28,
                  decoration: BoxDecoration(
                    color: AppColors.textDark,
                    borderRadius: BorderRadius.circular(size * 0.1),
                  ),
                  child: CustomPaint(painter: _RobotFacePainter()),
                ),
              ),
            ),
          ),
          // Body
          Positioned(
            bottom: size * 0.02,
            child: Container(
              width: size * 0.5,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * 0.14),
                border: Border.all(color: AppColors.primaryPurple.withOpacity(0.25), width: 2),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: size * 0.08,
                  backgroundColor: AppColors.primaryPurple,
                  child: Icon(Icons.eco, color: Colors.white, size: size * 0.08),
                ),
              ),
            ),
          ),
          if (badgeIcon != null)
            Positioned(
              right: size * 0.02,
              bottom: size * 0.18,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(badgeIcon, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _RobotFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final eyePaint = Paint()..color = AppColors.primaryPurple;
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.4), 3, eyePaint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.4), 3, eyePaint);
    final smilePaint = Paint()
      ..color = AppColors.primaryPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.62)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.82, size.width * 0.72, size.height * 0.62);
    canvas.drawPath(path, smilePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Common scaffold: background + back/skip header + progress bar +
/// step label + scrollable [child] + optional bottom button.
class OnboardingScaffold extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final IconData stepIcon;
  final VoidCallback? onBack;
  final VoidCallback onSkip;
  final Widget child;
  final Widget? bottomButton;

  const OnboardingScaffold({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepIcon,
    required this.onSkip,
    required this.child,
    this.onBack,
    this.bottomButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Stack(
        children: [
          const Positioned.fill(child: OnboardingBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (onBack != null)
                        _RoundIconButton(icon: Icons.chevron_left, onTap: onBack!)
                      else
                        const SizedBox(width: 44, height: 44),
                      TextButton(
                        onPressed: onSkip,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: OnboardingProgressBar(
                    currentStep: currentStep,
                    totalSteps: totalSteps,
                    stepIcon: stepIcon,
                  ),
                ),
                const SizedBox(height: 10),
                Text('Step $currentStep of $totalSteps', style: AppText.stepLabel),
                const SizedBox(height: 8),
                Expanded(child: child),
                if (bottomButton != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                    child: bottomButton,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: AppColors.textDark)),
      ),
    );
  }
}

/// Full-width gradient CTA button used on every step ("Continue", "Get
/// Started", etc.).
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Gradient gradient;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient = AppColors.primaryButtonGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable card used for goals / diet type / activity level grids.
class OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool multiSelect;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.multiSelect = true,
    this.iconColor = AppColors.primaryPurple,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.chipSelectedBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primaryPurple : AppColors.borderLight),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(height: 8),
                Text(title, style: AppText.cardLabel),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppText.sectionSubtitle),
                ],
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                selected
                    ? Icons.check_circle
                    : (multiSelect ? Icons.circle_outlined : Icons.circle_outlined),
                color: selected ? AppColors.primaryPurple : AppColors.borderLight,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rounded white "section card" wrapper used to group form fields.
class SectionCard extends StatelessWidget {
  final Widget child;
  const SectionCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}

/// A simple toggle switch row (used for Product Alerts / AI Features).
class ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const ToggleRow({super.key, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body.copyWith(color: AppColors.textDark))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryPurple,
          ),
        ],
      ),
    );
  }
}

/// Fades + slides its child up on first build — used for the step
/// entrance animation seen in the reference screens.
class EntranceAnimator extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const EntranceAnimator({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<EntranceAnimator> createState() => _EntranceAnimatorState();
}

class _EntranceAnimatorState extends State<EntranceAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(_fade);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
