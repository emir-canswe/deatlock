import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/audio.dart';
import 'core/haptics.dart';
import 'core/palette.dart';
import 'data/progress_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final progressStore = ProgressStore(prefs);
  
  // Load settings for haptics and audio
  await Haptics.load();
  Audio.init(progressStore);

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // System UI: Transparent status bar, light icons, light navigation bar
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Palette.bgEnd,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(DeadlockApp(store: progressStore));
}
