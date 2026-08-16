import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;

  Widget _tabItem(
  IconData icon,
  String title,
  bool active,
) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: active ? const Color(0xffF6F1FF) : Colors.transparent,
    ),
    child: Column(
      children: [
        Icon(
          icon,
          color: active
              ? const Color(0xff7B4DFF)
              : Colors.grey.shade700,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            color: active
                ? const Color(0xff7B4DFF)
                : Colors.grey.shade700,
            fontWeight:
                active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

Widget _inputField({
  required String label,
  required String hint,
  required IconData icon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xff241A63),
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: const Color(0xff7B4DFF),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xffE8E2FA),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xffE8E2FA),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _unitButton(
  String text,
  bool active,
) {
  return Container(
    width: 56,
    margin: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: active
          ? const LinearGradient(
              colors: [
                Color(0xff8E5BFF),
                Color(0xff6E3CF8),
              ],
            )
          : null,
      color: active ? null : Colors.transparent,
    ),
    alignment: Alignment.center,
    child: Text(
      text,
      style: TextStyle(
        color: active
            ? Colors.white
            : const Color(0xff5D567A),
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }
  

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final uiScale = size.width / 390;

    return Scaffold(
      backgroundColor: const Color(0xffF7F5FF),
      body: Stack(
        children: [

          Positioned(
            top: -80,
            left: -80,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) {
                return Transform.scale(
                  scale: 1 + (_bgController.value * .15),
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xffE8DEFF),
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            top: 60,
            right: -50,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) {
                return Transform.translate(
                  offset: Offset(0, 20 * _bgController.value),
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xffEFE7FF),
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: 22 * uiScale,
                vertical: 18 * uiScale,
              ),
              child: Column(
                children: [

                  Row(
                    children: [

                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 52 * uiScale,
                          height: 52 * uiScale,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.05),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xff7B4DFF),
                            size: 18,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14 * uiScale,
                          vertical: 8 * uiScale,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: const Color(0xffE5D8FF),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.help_outline,
                              size: 16,
                              color: Color(0xff7B4DFF),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Need Help?",
                              style: TextStyle(
                                color: Color(0xff7B4DFF),
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          ],
                        ),
                      )

                    ],
                  ),

                  SizedBox(height: 24 * uiScale),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Manual Nutrition Entry",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff19124F),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.auto_awesome,
                        color: Color(0xffA56BFF),
                        size: 20,
                      )
                    ],
                  ),

                  SizedBox(height: 10 * uiScale),

                  Text(
                    "Enter nutrition facts from any food package",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),

                  SizedBox(height: 28 * uiScale),

                  //==============================================================
// TOP TAB BAR
//==============================================================

Container(
  padding: EdgeInsets.all(6 * uiScale),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.05),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  ),
  child: Row(
    children: [
      Expanded(
        child: _tabItem(
          Icons.qr_code_scanner_rounded,
          "Scan Label",
          false,
        ),
      ),
      Expanded(
        child: _tabItem(
          Icons.image_outlined,
          "Upload Image",
          false,
        ),
      ),
      Expanded(
        child: _tabItem(
          Icons.edit_note_rounded,
          "Manual Entry",
          true,
        ),
      ),
    ],
  ),
),

SizedBox(height: 26 * uiScale),

//==============================================================
// PRODUCT INFORMATION CARD
//==============================================================

Container(
  padding: EdgeInsets.all(22 * uiScale),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.04),
        blurRadius: 18,
        offset: const Offset(0, 10),
      )
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      Row(
        children: [

          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xff8F5BFF),
                  Color(0xff6A39F7),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              "1",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          const Text(
            "Product Information",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xff22195E),
            ),
          ),
        ],
      ),

      SizedBox(height: 26 * uiScale),

      Row(
        children: [

          Expanded(
            child: _inputField(
              label: "Product Name *",
              hint: "Enter product name",
              icon: Icons.inventory_2_outlined,
            ),
          ),

          SizedBox(width: 16 * uiScale),

          Expanded(
            child: _inputField(
              label: "Brand (Optional)",
              hint: "Enter brand name",
              icon: Icons.business_outlined,
            ),
          ),
        ],
      ),

      SizedBox(height: 22 * uiScale),

      Text(
        "Serving Size *",
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: const Color(0xff241A63),
          fontSize: 15 * uiScale,
        ),
      ),

      SizedBox(height: 10 * uiScale),

      Row(
        children: [

          Expanded(
            flex: 3,
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xffE8E2FA),
                ),
              ),
              child: Row(
                children: [

                  const Icon(
                    Icons.restaurant_menu,
                    color: Color(0xff7C4DFF),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      "e.g. 40 g / 1 cup / 100 ml",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                  )
                ],
              ),
            ),
          ),

          SizedBox(width: 12 * uiScale),

          Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xffF4F1FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [

                _unitButton("g", true),

                _unitButton("ml", false),

                _unitButton("cup", false),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
),

SizedBox(height: 24 * uiScale),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}