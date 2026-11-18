import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_colors.dart';

/// The 50 Lumé icons exported from the design file (assets/icons/*.svg).
class LumeIcons {
  LumeIcons._();
  static const heart = 'heart', close = 'close', star = 'star', discover = 'discover', chat = 'chat';
  static const compliment = 'compliment', user = 'user', matches = 'matches', mic = 'mic', image = 'image';
  static const send = 'send', plus = 'plus', back = 'back', next = 'next', down = 'down', more = 'more';
  static const shield = 'shield', verified = 'verified', check = 'check', lock = 'lock', pin = 'pin';
  static const play = 'play', pause = 'pause', bell = 'bell', camera = 'camera', sliders = 'sliders';
  static const flag = 'flag', ban = 'ban', eye = 'eye', eyeoff = 'eyeoff', smile = 'smile', globe = 'globe';
  static const music = 'music', book = 'book', wine = 'wine', moon = 'moon', leaf = 'leaf', mail = 'mail';
  static const phone = 'phone', trash = 'trash', edit = 'edit', info = 'info', refresh = 'refresh';
  static const wifiOff = 'wifioff', key = 'key', logout = 'logout', help = 'help', undo = 'undo', run = 'run';
  static const people = 'people';
}

class LumeIcon extends StatelessWidget {
  const LumeIcon(this.name, {super.key, this.size = 24, this.color = AppColors.plum});

  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
