import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

/// DietCompass — Personal Information Screen
/// -----------------------------------------------------------------------
/// A fully editable profile form matching the reference layout exactly.
/// No bundled avatar asset was provided — pass [avatarImage] with your
/// own (e.g. `FileImage(File(path))` after the user picks one via the
/// camera button); until then it falls back to an initials avatar so
/// nothing crashes.
///
/// Text fields (Full Name, Username, Email, Phone, Address) are real,
/// editable `TextFormField`s. Fields the reference shows with a chevron
/// (Date of Birth, Gender, Country, City, Occupation, Diet Type, Height,
/// Weight) are tap-to-pick rows — wire [onFieldTap] to open your own
/// date picker / bottom sheet / dropdown for each, then update the
/// corresponding value via setState from the parent or by passing a new
/// widget instance.
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({
    super.key,
    this.avatarImage,
    this.fullName = 'Nazia Shaikh',
    this.badgeLabel = 'Healthy Explorer',
    this.email = 'nazia.shaikh@example.com',
    this.phone = ' 9876543210',
    this.username = 'nazia_healthy',
    this.countryCode = '+91',
    this.countryFlag = '🇮🇳',
    this.dateOfBirth = '15 May 2005',
    this.gender = 'Female',
    this.country = 'India',
    this.city = 'Mumbai',
    this.address = 'Bandra West, Mumbai, Maharashtra',
    this.occupation = 'Student',
    this.dietType = 'Vegetarian',
    this.height = '165 cm',
    this.weight = '58 kg',
    this.onBack,
    this.onSave,
    this.onAvatarTap,
    this.onFieldTap,
    this.onLearnMoreTap,
  });

  final ImageProvider? avatarImage;
  final String fullName;
  final String badgeLabel;
  final String email;
  final String phone;
  final String username;
  final String countryCode;
  final String countryFlag;
  final String dateOfBirth;
  final String gender;
  final String country;
  final String city;
  final String address;
  final String occupation;
  final String dietType;
  final String height;
  final String weight;

  final VoidCallback? onBack;

  /// Called with a map of the current field values when Save is tapped.
  final ValueChanged<Map<String, String>>? onSave;
  final VoidCallback? onAvatarTap;

  /// Called with the field id (e.g. 'dateOfBirth', 'gender', 'country',
  /// 'city', 'occupation', 'dietType', 'height', 'weight') when a
  /// tap-to-pick row is tapped.
  final ValueChanged<String>? onFieldTap;
  final VoidCallback? onLearnMoreTap;

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;

  Country _selectedCountry = Country.parse('IN');

late String _countryCode;
late String _countryFlag;
late String _countryName;

late String _selectedState;
late String _selectedCity;

List<String> _states = [];
List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();
    _fullNameCtrl = TextEditingController(text: widget.fullName);
    _usernameCtrl = TextEditingController(text: widget.username);
    _emailCtrl = TextEditingController(text: widget.email);
    _phoneCtrl = TextEditingController(text: widget.phone);
    _addressCtrl = TextEditingController(text: widget.address);
    _countryCode = widget.countryCode;
    _countryFlag = widget.countryFlag;
    _countryName = widget.country;
    _selectedState = "";
_selectedCity = widget.city;
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _selectCountry() {
  showCountryPicker(
    context: context,

    showPhoneCode: true,

    favorite: const [
      'IN',
      'US',
      'GB',
      'AE',
      'CA',
    ],

    onSelect: (Country country) {
      setState(() {
        _selectedCountry = country;
        _countryCode = "+${country.phoneCode}";
        _countryFlag = country.flagEmoji;
        _countryName = country.name;
      });
    },
  );
}

  Animation<double> _fade(double s, double e) =>
      CurvedAnimation(parent: _entranceCtrl, curve: Interval(s, e, curve: Curves.easeOut));

  Animation<Offset> _slide(double s, double e) => Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
      .animate(CurvedAnimation(parent: _entranceCtrl, curve: Interval(s, e, curve: Curves.easeOutCubic)));

  void _handleSave() {
    widget.onSave?.call({
      'fullName': _fullNameCtrl.text,
      'username': _usernameCtrl.text,
      'email': _emailCtrl.text,
      'phone': _phoneCtrl.text,
      'address': _addressCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FC),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(18 * scale, 8 * scale, 18 * scale, 28 * scale),
          physics: const BouncingScrollPhysics(),
          children: [
            FadeTransition(
              opacity: _fade(0.0, 0.3),
              child: _TopBar(uiScale: scale, onBack: () {
  Navigator.pop(context);
}, onSave: _handleSave),
            ),
            SizedBox(height: 16 * scale),

            FadeTransition(
              opacity: _fade(0.05, 0.4),
              child: SlideTransition(
                position: _slide(0.05, 0.42),
                child: _ProfileCard(
                  uiScale: scale,
                  avatarImage: widget.avatarImage,
                  fullName: widget.fullName,
                  badgeLabel: widget.badgeLabel,
                  email: widget.email,
                  phone: widget.phone,
                  onAvatarTap: widget.onAvatarTap,
                ),
              ),
            ),
            SizedBox(height: 22 * scale),

            FadeTransition(
              opacity: _fade(0.12, 0.46),
              child: SlideTransition(
                position: _slide(0.12, 0.48),
                child: _SectionHeader(uiScale: scale, icon: Icons.person_outline, title: 'Basic Information'),
              ),
            ),
            SizedBox(height: 10 * scale),
            FadeTransition(
              opacity: _fade(0.14, 0.5),
              child: SlideTransition(
                position: _slide(0.14, 0.52),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _TextField(uiScale: scale, controller: _fullNameCtrl, label: 'Full Name', icon: Icons.person_outline),
                        ),
                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: _TextField(uiScale: scale, controller: _usernameCtrl, label: 'Username', icon: Icons.alternate_email),
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * scale),
                    _TextField(uiScale: scale, controller: _emailCtrl, label: 'Email Address', icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
                    SizedBox(height: 10 * scale),
                    Row(
                      children: [
                        Expanded(
                          child: _TextField(uiScale: scale, controller: _phoneCtrl, label: 'Phone Number', icon: Icons.call_outlined, keyboardType: TextInputType.phone),
                        ),
                        SizedBox(width: 10 * scale),
                        _CountryCodeChip(
  uiScale: scale,
  flag: _countryFlag,
  code: _countryCode,
  onTap: _selectCountry,
),
                      ],
                    ),
                    SizedBox(height: 10 * scale),
                    Row(
                      children: [
                        Expanded(
                          child: _DropdownField(
                            uiScale: scale,
                            label: 'Date of Birth',
                            value: widget.dateOfBirth,
                            icon: Icons.calendar_today_outlined,
                            onTap: () => widget.onFieldTap?.call('dateOfBirth'),
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: _DropdownField(
                            uiScale: scale,
                            label: 'Gender',
                            value: widget.gender,
                            icon: Icons.person_outline,
                            onTap: () => widget.onFieldTap?.call('gender'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 22 * scale),

            FadeTransition(
              opacity: _fade(0.22, 0.56),
              child: SlideTransition(
                position: _slide(0.22, 0.58),
                child: _SectionHeader(uiScale: scale, icon: Icons.location_on_outlined, title: 'Location'),
              ),
            ),
            SizedBox(height: 10 * scale),
            FadeTransition(
              opacity: _fade(0.24, 0.6),
              child: SlideTransition(
                position: _slide(0.24, 0.62),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _DropdownField(
                            uiScale: scale,
                            label: 'Country',
                            value: _countryName,
                            icon: Icons.public,
                            onTap: _selectCountry,
                          ),
                        ),
                        
                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: _DropdownField(
                            uiScale: scale,
                            label: 'State',
                            value: _selectedState,
                            onTap: () {},
                            icon: Icons.map_outlined,
                          ),
                        ),

                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: _DropdownField(
                            uiScale: scale,
                            label: 'City',
                            value: _selectedCity,
                            onTap: () {},
                            icon: Icons.location_city_outlined,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * scale),
                    _TextField(uiScale: scale, controller: _addressCtrl, label: 'Address (Optional)', icon: Icons.home_outlined),
                  ],
                ),
              ),
            ),
            SizedBox(height: 22 * scale),

            FadeTransition(
              opacity: _fade(0.32, 0.66),
              child: SlideTransition(
                position: _slide(0.32, 0.68),
                child: _SectionHeader(uiScale: scale, icon: Icons.favorite_border, title: 'About You'),
              ),
            ),
            SizedBox(height: 10 * scale),
            FadeTransition(
              opacity: _fade(0.34, 0.7),
              child: SlideTransition(
                position: _slide(0.34, 0.72),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _DropdownField(
                            uiScale: scale,
                            label: 'Occupation',
                            value: widget.occupation,
                            icon: Icons.work_outline,
                            onTap: () => widget.onFieldTap?.call('occupation'),
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: _DropdownField(
                            uiScale: scale,
                            label: 'Diet Type',
                            value: widget.dietType,
                            icon: Icons.restaurant_outlined,
                            onTap: () => widget.onFieldTap?.call('dietType'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * scale),
                    Row(
                      children: [
                        Expanded(
                          child: _DropdownField(
                            uiScale: scale,
                            label: 'Height',
                            value: widget.height,
                            icon: Icons.straighten,
                            onTap: () => widget.onFieldTap?.call('height'),
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: _DropdownField(
                            uiScale: scale,
                            label: 'Weight',
                            value: widget.weight,
                            icon: Icons.monitor_weight_outlined,
                            onTap: () => widget.onFieldTap?.call('weight'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 22 * scale),

            FadeTransition(
              opacity: _fade(0.45, 0.85),
              child: SlideTransition(
                position: _slide(0.45, 0.88),
                child: _TrustFooter(uiScale: scale, onLearnMoreTap: widget.onLearnMoreTap),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar({required this.uiScale, this.onBack, this.onSave});
  final double uiScale;
  final VoidCallback? onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoundButton(uiScale: uiScale, icon: Icons.arrow_back, onTap: onBack),
        SizedBox(width: 12 * uiScale),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4 * uiScale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personal Information', style: TextStyle(fontSize: 20 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                SizedBox(height: 2 * uiScale),
                Text('Update your personal details', style: TextStyle(fontSize: 11.5 * uiScale, color: const Color(0xFF6B6B7B))),
              ],
            ),
          ),
        ),
        _SaveButton(uiScale: uiScale, onTap: onSave),
      ],
    );
  }
}

class _RoundButton extends StatefulWidget {
  const _RoundButton({required this.uiScale, required this.icon, this.onTap});
  final double uiScale;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 42 * widget.uiScale,
          height: 42 * widget.uiScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(widget.icon, size: 19 * widget.uiScale, color: const Color(0xFF1B1B2E)),
        ),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.94),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16 * widget.uiScale, vertical: 12 * widget.uiScale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF8A6CF5)]),
            boxShadow: [BoxShadow(color: const Color(0xFF6C4EF5).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_box_outlined, size: 15 * widget.uiScale, color: Colors.white),
              SizedBox(width: 6 * widget.uiScale),
              Text('Save', style: TextStyle(color: Colors.white, fontSize: 13.5 * widget.uiScale, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile card
// ---------------------------------------------------------------------------
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.uiScale,
    required this.avatarImage,
    required this.fullName,
    required this.badgeLabel,
    required this.email,
    required this.phone,
    this.onAvatarTap,
  });

  final double uiScale;
  final ImageProvider? avatarImage;
  final String fullName;
  final String badgeLabel;
  final String email;
  final String phone;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * uiScale),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECFB),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            bottom: -10,
            child: Opacity(
              opacity: 0.35,
              child: Icon(Icons.eco_rounded, size: 110 * uiScale, color: const Color(0xFFB9A6F2)),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 76 * uiScale,
                    height: 76 * uiScale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF6C4EF5), Color(0xFF1E8A4C)]),
                      image: avatarImage != null ? DecorationImage(image: avatarImage!, fit: BoxFit.cover) : null,
                    ),
                    child: avatarImage == null
                        ? Center(
                            child: Text(
                              fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26 * uiScale),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: _CameraButton(uiScale: uiScale, onTap: onAvatarTap),
                  ),
                ],
              ),
              SizedBox(width: 14 * uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8 * uiScale,
                      runSpacing: 4 * uiScale,
                      children: [
                        Text(fullName, style: TextStyle(fontSize: 18 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8 * uiScale, vertical: 3 * uiScale),
                          decoration: BoxDecoration(color: const Color(0xFFE4F5E9), borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.eco, size: 11 * uiScale, color: const Color(0xFF1E8A4C)),
                              SizedBox(width: 4 * uiScale),
                              Text(badgeLabel, style: TextStyle(fontSize: 10 * uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1E8A4C))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * uiScale),
                    Row(
                      children: [
                        Icon(Icons.mail_outline, size: 14 * uiScale, color: const Color(0xFF6C4EF5)),
                        SizedBox(width: 6 * uiScale),
                        Expanded(child: Text(email, style: TextStyle(fontSize: 12 * uiScale, color: const Color(0xFF3B3B4F)))),
                      ],
                    ),
                    SizedBox(height: 6 * uiScale),
                    Row(
                      children: [
                        Icon(Icons.call_outlined, size: 14 * uiScale, color: const Color(0xFF6C4EF5)),
                        SizedBox(width: 6 * uiScale),
                        Text(phone, style: TextStyle(fontSize: 12 * uiScale, color: const Color(0xFF3B3B4F))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CameraButton extends StatefulWidget {
  const _CameraButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_CameraButton> createState() => _CameraButtonState();
}

class _CameraButtonState extends State<_CameraButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 28 * widget.uiScale,
          height: 28 * widget.uiScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFF1ECFB), width: 2.4),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Icon(Icons.camera_alt, size: 13 * widget.uiScale, color: const Color(0xFF6C4EF5)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.uiScale, required this.icon, required this.title});
  final double uiScale;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34 * uiScale,
          height: 34 * uiScale,
          decoration: const BoxDecoration(color: Color(0xFFEDE7FA), shape: BoxShape.circle),
          child: Icon(icon, size: 16 * uiScale, color: const Color(0xFF6C4EF5)),
        ),
        SizedBox(width: 10 * uiScale),
        Text(title, style: TextStyle(fontSize: 15 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B2E))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Editable text field
// ---------------------------------------------------------------------------
class _TextField extends StatefulWidget {
  const _TextField({
    required this.uiScale,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final double uiScale;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(horizontal: 14 * widget.uiScale, vertical: 6 * widget.uiScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _focused ? const Color(0xFF6C4EF5) : const Color(0xFFE4E0F2), width: _focused ? 1.6 : 1.2),
        boxShadow: _focused ? [BoxShadow(color: const Color(0xFF6C4EF5).withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))] : [],
      ),
      child: Row(
        children: [
          Icon(widget.icon, size: 17 * widget.uiScale, color: const Color(0xFF6C4EF5)),
          SizedBox(width: 10 * widget.uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: TextStyle(fontSize: 10 * widget.uiScale, color: const Color(0xFF9A96A8))),
                TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  style: TextStyle(fontSize: 13.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E)),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tap-to-pick dropdown-style field
// ---------------------------------------------------------------------------
class _DropdownField extends StatefulWidget {
  const _DropdownField({
    required this.uiScale,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final double uiScale;
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_DropdownField> createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<_DropdownField> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14 * widget.uiScale, vertical: 12 * widget.uiScale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E0F2), width: 1.2),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 17 * widget.uiScale, color: const Color(0xFF6C4EF5)),
              SizedBox(width: 10 * widget.uiScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label, style: TextStyle(fontSize: 10 * widget.uiScale, color: const Color(0xFF9A96A8))),
                    Text(widget.value, style: TextStyle(fontSize: 13.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E))),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_down, size: 18 * widget.uiScale, color: const Color(0xFF9A96A8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryCodeChip extends StatefulWidget {
  const _CountryCodeChip({required this.uiScale, required this.flag, required this.code, this.onTap});
  final double uiScale;
  final String flag;
  final String code;
  final VoidCallback? onTap;

  @override
  State<_CountryCodeChip> createState() => _CountryCodeChipState();
}

class _CountryCodeChipState extends State<_CountryCodeChip> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 54 * widget.uiScale,
          padding: EdgeInsets.symmetric(horizontal: 10 * widget.uiScale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E0F2), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.flag, style: TextStyle(fontSize: 16 * widget.uiScale)),
              SizedBox(width: 4 * widget.uiScale),
              Text(widget.code, style: TextStyle(fontSize: 13.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B2E))),
              Icon(Icons.keyboard_arrow_down, size: 16 * widget.uiScale, color: const Color(0xFF9A96A8)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trust footer
// ---------------------------------------------------------------------------
class _TrustFooter extends StatelessWidget {
  const _TrustFooter({required this.uiScale, this.onLearnMoreTap});
  final double uiScale;
  final VoidCallback? onLearnMoreTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * uiScale),
      decoration: BoxDecoration(color: const Color(0xFFE9F7EE), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 34 * uiScale,
            height: 34 * uiScale,
            decoration: const BoxDecoration(color: Color(0xFF1E8A4C), shape: BoxShape.circle),
            child: Icon(Icons.verified_user, size: 16 * uiScale, color: Colors.white),
          ),
          SizedBox(width: 10 * uiScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your information is safe with us.', style: TextStyle(fontSize: 12 * uiScale, fontWeight: FontWeight.w800, color: const Color(0xFF1E8A4C))),
                Text('We never share your personal details with anyone.', style: TextStyle(fontSize: 10 * uiScale, color: const Color(0xFF3B3B4F))),
              ],
            ),
          ),
          SizedBox(width: 8 * uiScale),
          _LearnMoreButton(uiScale: uiScale, onTap: onLearnMoreTap),
        ],
      ),
    );
  }
}

class _LearnMoreButton extends StatefulWidget {
  const _LearnMoreButton({required this.uiScale, this.onTap});
  final double uiScale;
  final VoidCallback? onTap;

  @override
  State<_LearnMoreButton> createState() => _LearnMoreButtonState();
}

class _LearnMoreButtonState extends State<_LearnMoreButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * widget.uiScale, vertical: 9 * widget.uiScale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E8A4C).withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 12 * widget.uiScale, color: const Color(0xFF1E8A4C)),
              SizedBox(width: 5 * widget.uiScale),
              Text('Learn More', style: TextStyle(fontSize: 10.5 * widget.uiScale, fontWeight: FontWeight.w700, color: const Color(0xFF1E8A4C))),
            ],
          ),
        ),
      ),
    );
  }
}
