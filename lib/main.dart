import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/di/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts are fetched once and cached; bundle them under assets/fonts to ship offline.
  GoogleFonts.config.allowRuntimeFetching = true;
  await configureDependencies();
  runApp(LumeApp.create());
}
