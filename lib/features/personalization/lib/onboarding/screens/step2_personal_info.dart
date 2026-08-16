import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import '../onboarding_theme.dart';
import '../widgets/onboarding_widgets.dart';

class Step2PersonalInfo extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const Step2PersonalInfo({
    super.key,
    required this.data,
    required this.onContinue,
    required this.onBack,
    required this.onSkip,
  });

  @override
  State<Step2PersonalInfo> createState() => _Step2PersonalInfoState();
}

class _Step2PersonalInfoState extends State<Step2PersonalInfo> {
  static const goals = [
    ('Healthy Eating', Icons.eco, Color(0xFF34C77B)),
    ('Weight Loss', Icons.monitor_weight_outlined, AppColors.primaryPurple),
    ('Weight Gain', Icons.fitness_center, Colors.orange),
    ('Maintain Weight', Icons.savings_outlined, Color(0xFF34C77B)),
    ('High Protein Diet', Icons.local_drink_outlined, AppColors.primaryPurple),
    ('High Fibre Diet', Icons.grass, Color(0xFF34C77B)),
    ('Low Sugar Diet', Icons.category_outlined, Colors.redAccent),
    ('Low Sodium Diet', Icons.favorite_outline, Colors.blue),
    ('Heart Healthy Diet', Icons.favorite, Colors.redAccent),
    ('Diabetes Friendly Diet', Icons.water_drop_outlined, Colors.blue),
    (
      'Budget Friendly Meals',
      Icons.account_balance_wallet_outlined,
      Colors.amber,
    ),
    ('Family Nutrition', Icons.groups_outlined, AppColors.primaryPurple),
    ('Kids Nutrition', Icons.child_care, Colors.orange),
    ('Sports Nutrition', Icons.directions_run, AppColors.primaryPurple),
    ('Vegetarian', Icons.eco_outlined, Color(0xFF34C77B)),
    ('Vegan', Icons.spa_outlined, Color(0xFF34C77B)),
  ];

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return OnboardingScaffold(
      currentStep: 2,
      totalSteps: 7,
      stepIcon: Icons.eco,
      onBack: widget.onBack,
      onSkip: widget.onSkip,

      bottomButton: GradientButton(
        label: 'Continue',
        onTap: widget.onContinue,
      ),

      child: EntranceAnimator(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              RichText(
                text: const TextSpan(
                  style: AppText.title,
                  children: [
                    TextSpan(text: 'Tell us about\n'),
                    TextSpan(
                      text: 'yourself ',
                      style: AppText.titleAccent,
                    ),
                    TextSpan(
                      text: '\u{1F343}',
                      style: AppText.titleAccent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'This helps us personalize your nutrition, recipes and health recommendations.',
                style: AppText.body,
              ),

              const SizedBox(height: 20),

              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Full Name',
                      style: AppText.sectionTitle,
                    ),

                    const SizedBox(height: 8),

                    _TextField(
                      hint: 'Enter your full name',
                      icon: Icons.person_outline,
                      onChanged: (v) => d.fullName = v,
                    ),

                    const SizedBox(height: 16),

                    // AGE + GENDER
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Age',
                                style: AppText.sectionTitle,
                              ),
                              const SizedBox(height: 8),
                              _TextField(
                                hint: 'Enter your age',
                                icon: Icons.calendar_today_outlined,
                                keyboardType: TextInputType.number,
                                onChanged: (v) => d.age = v,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gender',
                                style: AppText.sectionTitle,
                              ),
                              const SizedBox(height: 8),
                              _Dropdown(
                                hint: 'Select gender',
                                icon: Icons.person_outline,
                                value: d.gender,
                                items: const [
                                  'Male',
                                  'Female',
                                  'Other',
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    d.gender = v;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // HEIGHT + WEIGHT
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Height',
                                style: AppText.sectionTitle,
                              ),
                              const SizedBox(height: 8),
                              _TextField(
                                hint: 'Enter height',
                                icon: Icons.height,
                                suffix: 'cm',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => d.height = v,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Weight',
                                style: AppText.sectionTitle,
                              ),
                              const SizedBox(height: 8),
                              _TextField(
                                hint: 'Enter weight',
                                icon: Icons.monitor_weight_outlined,
                                suffix: 'kg',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => d.weight = v,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Your Goals',
                      style: AppText.sectionTitle,
                    ),

                    const Text(
                      '(Select all that apply)',
                      style: AppText.sectionSubtitle,
                    ),

                    const SizedBox(height: 12),

                    // GOALS GRID
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: goals.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,

                        // Taller cards so long titles fit.
                        childAspectRatio: 1.15,
                      ),
                      itemBuilder: (_, i) {
                        final (title, icon, color) = goals[i];
                        final selected = d.goals.contains(title);

                        return _GoalCard(
                          icon: icon,
                          iconColor: color,
                          title: title,
                          selected: selected,
                          onTap: () {
                            setState(() {
                              if (selected) {
                                d.goals.remove(title);
                              } else {
                                d.goals.add(title);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.primaryPurple,
                  ),

                  SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      'The more details you provide, the smarter and more personalized your experience will be.',
                      style: AppText.sectionSubtitle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// GOAL CARD
// ============================================================

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primaryPurple
                  : AppColors.borderLight,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ICON + CHECKBOX
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: 30,
                  ),

                  const SizedBox(width: 8),

                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.primaryPurple
                          : Colors.white,
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryPurple
                            : AppColors.borderLight,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // GOAL TITLE
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// TEXT FIELD
// ============================================================

class _TextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final String? suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  const _TextField({
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,

        prefixIcon: Icon(
          icon,
          color: AppColors.primaryPurple,
          size: 20,
        ),

        suffixText: suffix,

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryPurple,
          ),
        ),
      ),
    );
  }
}


// ============================================================
// GENDER DROPDOWN
// ============================================================

class _Dropdown extends StatelessWidget {
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),

      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.borderLight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,

          hint: Row(
            children: [
              Icon(
                icon,
                color: AppColors.primaryPurple,
                size: 20,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGray,
                  ),
                ),
              ),
            ],
          ),

          items: items.map(
            (e) {
              return DropdownMenuItem<String>(
                value: e,
                child: Text(
                  e,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ).toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }
}