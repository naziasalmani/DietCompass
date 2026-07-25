# DietCompass

Premium AI-powered nutrition assistant with an animated splash screen.

## Quick start

1. **Generate platform folders** (if this repo was scaffolded without Flutter CLI):

   ```bash
   cd C:\Users\A\Projects\diet_compass
   flutter create . --project-name diet_compass
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Add your design assets** to `assets/images/`:

   | File | Description |
   |------|-------------|
   | `logo.png` | Compass logo |
   | `robot.png` | AI robot hero |
   | `food_avocado.png` | Orbiting food icon |
   | `food_broccoli.png` | Orbiting food icon |
   | `food_strawberry.png` | Orbiting food icon |
   | `food_milk.png` | Orbiting food icon |
   | `food_salad.png` | Orbiting food icon |

   Custom-painted fallbacks render automatically when assets are missing.

4. **Run the app:**

   ```bash
   flutter run
   ```

## Splash screen features

- Logo scale + rotation entrance
- App name fade & slide-up
- Staggered tagline reveal
- Continuous robot float animation
- Food icons orbiting the robot
- Random glowing background particles
- Shimmer loading bar (purple → green gradient)
- Smooth fade/slide transition to onboarding

## Project structure

```
lib/
├── main.dart
├── core/theme/          # Colors & theme
├── features/
│   ├── splash/          # Splash screen + widgets
│   └── onboarding/      # Post-splash destination
assets/images/           # Logo, robot, food icons
```
