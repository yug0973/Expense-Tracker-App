import 'package:flutter/material.dart';

class TColor {
  static bool isDark = true;

  // Primary colors — same in both themes
  static Color get primary => const Color(0xff5E00F5);
  static Color get primary500 => const Color(0xff7722FF);
  static Color get primary20 => const Color(0xff924EFF);
  static Color get primary10 => const Color(0xffAD7BFF);
  static Color get primary5 => const Color(0xffC9A7FF);
  static Color get primary0 => const Color(0xffE4D3FF);

  static Color get secondary => const Color(0xffFF7966);
  static Color get secondary50 => const Color(0xffFFA699);
  static Color get secondary0 => const Color(0xffFFD2CC);

  static Color get secondaryG => const Color(0xff00FAD9);
  static Color get secondaryG50 => const Color(0xff7DFFEE);

  // Theme-aware colors
  static Color get gray =>
      isDark ? const Color(0xff0E0E12) : const Color(0xffF2F2F7);

  static Color get gray80 =>
      isDark ? const Color(0xff1C1C23) : const Color(0xffE5E5EA);

  static Color get gray70 =>
      isDark ? const Color(0xff353542) : const Color(0xffD1D1D6);

  static Color get gray60 =>
      isDark ? const Color(0xff4E4E61) : const Color(0xffC7C7CC);

  static Color get gray50 =>
      isDark ? const Color(0xff666680) : const Color(0xffAEAEB2);

  static Color get gray40 =>
      isDark ? const Color(0xff83839C) : const Color(0xff8E8E93);

  static Color get gray30 =>
      isDark ? const Color(0xffA2A2B5) : const Color(0xff636366);

  static Color get gray20 =>
      isDark ? const Color(0xffC1C1CD) : const Color(0xff3A3A3C);

  static Color get gray10 =>
      isDark ? const Color(0xffE0E0E6) : const Color(0xff1C1C1E);

  static Color get border =>
      isDark ? const Color(0xffCFCFFC) : const Color(0xffC6C6C8);

  static Color get white =>
      isDark ? Colors.white : Colors.black;

  static Color get background =>
      isDark ? const Color(0xff0E0E12) : const Color(0xffF2F2F7);

  static Color get cardBg =>
      isDark ? const Color(0xff1C1C23) : Colors.white;

  static Color get primaryText =>
      isDark ? Colors.white : Colors.black;

  static Color get secondaryText =>
      isDark ? const Color(0xff4E4E61) : const Color(0xff8E8E93);
}