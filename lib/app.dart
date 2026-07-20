import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme.dart';
import 'data/progress_store.dart';
import 'state/progress_controller.dart';
import 'ui/screens/mode_select_screen.dart';

class DeadlockApp extends StatefulWidget {
  final ProgressStore store;
  const DeadlockApp({super.key, required this.store});

  @override
  State<DeadlockApp> createState() => _DeadlockAppState();
}

class _DeadlockAppState extends State<DeadlockApp> {
  late final ProgressController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = ProgressController(widget.store);
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _progressController,
      builder: (context, _) {
        Locale? appLocale;
        if (_progressController.language != 'system') {
          appLocale = Locale(_progressController.language);
        }

        return MaterialApp(
          title: 'Deadlock',
          debugShowCheckedModeBanner: false,
          theme: ThemeConfig.buildTheme(),
          locale: appLocale,
          // Support both Turkish and English based on device locale
          supportedLocales: const [
            Locale('tr'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            // If appLocale is set explicitly, use that.
            if (appLocale != null) return appLocale;
            // Otherwise fall back to device language. If Turkish, use Turkish. Otherwise English.
            if (locale?.languageCode == 'tr') return const Locale('tr');
            return const Locale('en');
          },
          home: ModeSelectScreen(progressController: _progressController),
        );
      },
    );
  }
}
