# DietCompass Onboarding Flow

A 7-step onboarding flow matching your reference screens: welcome, personal
info, lifestyle, health info, food preferences, personalize-AI, and the
final summary/"You're all set" screen.

## How it's wired

- `lib/onboarding/onboarding_flow.dart` — the controller. A `PageView` with
  `NeverScrollableScrollPhysics`, so navigation only happens through the
  **Continue** / back-arrow / **Skip** buttons, exactly like your reference.
  Tapping **Continue** animates to the next page; on the last step it calls
  `onComplete(data)`.
- `lib/onboarding/onboarding_data.dart` — one plain object that accumulates
  every answer across all 7 steps (name, age, goals, allergies, etc.) so the
  summary screen (step 7) can read it back.
- `lib/onboarding/screens/step1..step7_*.dart` — one file per screen, laid
  out to match your screenshots (progress bar, step label, title, robot
  mascot, form card(s), gradient Continue button).
- `lib/onboarding/widgets/onboarding_widgets.dart` — shared pieces: the
  wavy purple background, leaf/dot decorations, the segmented progress bar,
  the robot mascot, `OptionCard` (selectable tiles), `SectionCard`,
  `GradientButton`, `ToggleRow`, and `EntranceAnimator` (the fade/slide-in
  used on every step, matching the animation frames in your screenshots).

## Drop-in integration

1. Copy `lib/onboarding/` into your existing DietCompass project's `lib/`
   folder.
2. Wherever you currently launch first-time onboarding, replace it with:
   ```dart
   Navigator.of(context).push(
     MaterialPageRoute(
       builder: (_) => OnboardingFlow(
         onComplete: (OnboardingData data) {
           // persist `data` (SharedPreferences / your backend / provider)
           Navigator.of(context).pushReplacement(
             MaterialPageRoute(builder: (_) => const HomeScreen()),
           );
         },
       ),
     ),
   );
   ```
3. To preview it standalone first: `flutter run -t lib/main_demo.dart`.

## Matching your exact palette / assets

- All colors live in `lib/onboarding/onboarding_theme.dart`
  (`AppColors.primaryPurple`, `AppColors.accentGreen`, etc.) — update these
  to the exact hex values from your `home_screen.dart`.
- The robot mascot (`RobotMascot` in `onboarding_widgets.dart`) is built
  from shapes so the flow runs with zero extra assets. If you have the real
  3D robot illustration as PNGs, swap the widget body for
  `Image.asset('assets/images/robot_step_x.png')`.
- The background wave/leaves are a `CustomPainter` + `Icons.eco` — swap for
  your actual leaf/wave PNGs the same way if you have them.

## Notes

- `Skip` currently jumps straight to `onComplete` (or `onSkipAll` if you
  pass a separate callback) — change `_skip()` in `onboarding_flow.dart` if
  you want Skip to only jump to the last step instead.
- Step 7's **Edit** button jumps back to step 2 (`_goToPage(1)`) — adjust if
  you'd rather it opened a specific field.
- Validation (required fields, etc.) isn't wired up — `Continue` always
  advances. Add checks in each step's `onContinue` if needed.
