import 'package:flutter/widgets.dart';

/// Heights, widths and spacing used across the app.
class AppSizes {
  AppSizes._();

  // Spacing scale
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 24.0;
  static const s6 = 32.0;
  static const s7 = 48.0;

  /// Standard screen gutter in the design (390 wide frame, 342 wide content).
  static const gutter = 24.0;

  // Buttons
  static const buttonHeight = 56.0;
  static const buttonHeightMd = 48.0;
  static const buttonHeightSm = 44.0;
  static const iconButton = 44.0;
  static const iconButtonIcon = 22.0;

  // Discovery action row (Pass · Compliment · Like · Super Like)
  static const actionPass = 60.0;
  static const actionPassIcon = 26.0;
  static const actionSmall = 52.0;
  static const actionSmallIcon = 24.0;
  static const actionLike = 72.0;
  static const actionLikeIcon = 34.0;

  // Bars
  static const headerHeight = 44.0;
  static const navBarHeight = 72.0;

  // Avatars
  static const avatarSm = 44.0;
  static const avatarMd = 48.0;
  static const avatarLg = 56.0;
  static const avatarXl = 72.0;
}

/// Corner radii.
class AppRadius {
  AppRadius._();
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const full = 999.0;

  /// The signature arch: fully round top, softly rounded bottom.
  static BorderRadius arch(double width, {double bottom = 20}) => BorderRadius.only(
    topLeft: Radius.circular(width / 2),
    topRight: Radius.circular(width / 2),
    bottomLeft: Radius.circular(bottom),
    bottomRight: Radius.circular(bottom),
  );
}

/// Ready-made spacing boxes: `AppGaps.h16` instead of `SizedBox(height: 16)`.
class AppGaps {
  AppGaps._();

  // Vertical
  static const h2 = SizedBox(height: 2);
  static const h3 = SizedBox(height: 3);
  static const h4 = SizedBox(height: 4);
  static const h6 = SizedBox(height: 6);
  static const h7 = SizedBox(height: 7);
  static const h8 = SizedBox(height: 8);
  static const h10 = SizedBox(height: 10);
  static const h12 = SizedBox(height: 12);
  static const h14 = SizedBox(height: 14);
  static const h16 = SizedBox(height: 16);
  static const h18 = SizedBox(height: 18);
  static const h19 = SizedBox(height: 19);
  static const h20 = SizedBox(height: 20);
  static const h24 = SizedBox(height: 24);
  static const h38 = SizedBox(height: 38);
  static const h40 = SizedBox(height: 40);

  // Horizontal
  static const w4 = SizedBox(width: 4);
  static const w5 = SizedBox(width: 5);
  static const w6 = SizedBox(width: 6);
  static const w8 = SizedBox(width: 8);
  static const w10 = SizedBox(width: 10);
  static const w12 = SizedBox(width: 12);
  static const w14 = SizedBox(width: 14);
  static const w16 = SizedBox(width: 16);
  static const w44 = SizedBox(width: AppSizes.iconButton);
}
