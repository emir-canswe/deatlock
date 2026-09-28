import 'package:flutter/material.dart';
import '../../core/audio.dart';
import '../../core/haptics.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/progress_controller.dart';
import '../widgets/chunky_button.dart';

/// Modern, studio-quality Settings screen for DEADLOCK.
class SettingsScreen extends StatefulWidget {
  final ProgressController progressController;

  const SettingsScreen({
    super.key,
    required this.progressController,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticsEnabled = Haptics.enabled;
  bool _soundEnabled = false;

  @override
  void initState() {
    super.initState();
    _soundEnabled = widget.progressController.soundEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.bgStart, Palette.bgEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Bar: Back button + Title Capsule
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    ChunkyButton(
                      color: Palette.buttonWhiteBg,
                      shadowColor: Palette.buttonWhiteShadow,
                      borderRadius: 22,
                      width: 44,
                      height: 44,
                      depth: 3,
                      onPressed: () {
                        Haptics.selectionClick();
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: Palette.textHigh,
                        size: 26,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Palette.boardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Palette.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Palette.shadowColor,
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tune_rounded, size: 18, color: Palette.primary),
                                const SizedBox(width: 8),
                                Text(
                                  s.settingsTitle,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Palette.textHigh,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 44), // balance back button
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 2. Settings Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Gameplay Audio & Haptics
                      _buildSectionLabel(s.isTr ? 'OYUN DENEYİMİ' : 'GAMEPLAY & AUDIO'),
                      _buildCardGroup([
                        _buildToggleTile(
                          icon: Icons.vibration_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          title: s.haptics,
                          subtitle: s.isTr ? 'Dokunma ve zafer titreşimi' : 'Touch and win vibrations',
                          value: _hapticsEnabled,
                          onChanged: (val) async {
                            await Haptics.setEnabled(val);
                            if (val) Haptics.lightImpact();
                            setState(() => _hapticsEnabled = val);
                          },
                        ),
                        _buildDivider(),
                        _buildToggleTile(
                          icon: Icons.volume_up_rounded,
                          iconColor: Palette.coinGold,
                          title: s.sound,
                          subtitle: s.isTr ? 'Blok kaydırma ve zafer sesleri' : 'Slide & victory sound effects',
                          value: _soundEnabled,
                          onChanged: (val) async {
                            await widget.progressController.setSoundEnabled(val);
                            if (val) Audio.playClick();
                            setState(() => _soundEnabled = val);
                          },
                        ),
                      ]),

                      const SizedBox(height: 22),

                      // Section 2: Appearance & Language
                      _buildSectionLabel(s.isTr ? 'GÖRÜNÜM & DİL' : 'APPEARANCE & LANGUAGE'),
                      _buildCardGroup([
                        _buildThemeTile(s),
                        _buildDivider(),
                        _buildLanguageTile(s),
                      ]),

                      const SizedBox(height: 22),

                      // Section 3: Data Management
                      _buildSectionLabel(s.isTr ? 'VERİ YÖNETİMİ' : 'DATA MANAGEMENT'),
                      _buildCardGroup([
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                    width: 1.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.restart_alt_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.resetProgress,
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                        color: Palette.textHigh,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      s.isTr
                                          ? 'Tüm seviyeler ve yıldızlar sıfırlanır'
                                          : 'Clears all level scores & stars',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Palette.textLow,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              ChunkyButton(
                                color: const Color(0xFFEF4444),
                                shadowColor: const Color(0xFF991B1B),
                                borderRadius: 12,
                                depth: 3,
                                height: 38,
                                width: 90,
                                onPressed: () => _showResetDialog(context),
                                child: Text(
                                  s.resetBtn,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),

                      const SizedBox(height: 22),

                      // Section 4: About / Game Info
                      _buildSectionLabel(s.isTr ? 'BİLGİ' : 'ABOUT'),
                      _buildCardGroup([
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                                    width: 1.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFF0EA5E9),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DEADLOCK',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                        color: Palette.textHigh,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      s.isTr
                                          ? 'Gelişmiş Zeka & Bulmaca Motoru'
                                          : 'Advanced Puzzle Logic Engine',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Palette.textLow,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Palette.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Palette.primary.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'v3.0.0',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: Palette.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),

                      const SizedBox(height: 32),

                      // Footer Studio Branding
                      Column(
                        children: [
                          Text(
                            'DEADLOCK PUZZLE STUDIO',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                              color: Palette.textLow.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.isTr ? 'Oyuncular için özenle tasarlandı ❤️' : 'Crafted with care for players ❤️',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Palette.textLow.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          color: Palette.textLow,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Palette.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Palette.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Palette.cardBorder.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Palette.textHigh,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Palette.textLow,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildTactileSwitch(
            value: value,
            onTap: () => onChanged(!value),
          ),
        ],
      ),
    );
  }

  Widget _buildTactileSwitch({required bool value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        Haptics.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value ? Palette.primary : Palette.segmentTrack,
          border: Border.all(
            color: value ? Palette.primaryDark : Palette.segmentTrackBorder,
            width: 1.4,
          ),
          boxShadow: [
            if (value)
              BoxShadow(
                color: Palette.primary.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTile(S s) {
    final currentTheme = widget.progressController.themeMode;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.themeLabel,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Palette.textHigh,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.isTr ? 'Uygulama görünüm modu' : 'Application visual mode',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Palette.textLow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Palette.segmentTrack,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Palette.segmentTrackBorder, width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentButton(
                    icon: Icons.brightness_auto_rounded,
                    label: s.themeSystem,
                    isSelected: currentTheme == 'system',
                    onTap: () async {
                      Haptics.selectionClick();
                      await widget.progressController.setThemeMode('system');
                      setState(() {});
                    },
                  ),
                ),
                Expanded(
                  child: _buildSegmentButton(
                    icon: Icons.light_mode_rounded,
                    label: s.themeLight,
                    isSelected: currentTheme == 'light',
                    onTap: () async {
                      Haptics.selectionClick();
                      await widget.progressController.setThemeMode('light');
                      setState(() {});
                    },
                  ),
                ),
                Expanded(
                  child: _buildSegmentButton(
                    icon: Icons.dark_mode_rounded,
                    label: s.themeDark,
                    isSelected: currentTheme == 'dark',
                    onTap: () async {
                      Haptics.selectionClick();
                      await widget.progressController.setThemeMode('dark');
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(S s) {
    final currentLang = widget.progressController.language;
    final isTrSelected = currentLang == 'tr' || (currentLang == 'system' && s.isTr);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: Color(0xFF0284C7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.languageLabel,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Palette.textHigh,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.isTr ? 'Türkçe veya İngilizce' : 'Turkish or English',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Palette.textLow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Palette.segmentTrack,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Palette.segmentTrackBorder, width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentButton(
                    emoji: '🇹🇷',
                    label: s.langTr,
                    isSelected: isTrSelected,
                    onTap: () async {
                      Haptics.selectionClick();
                      await widget.progressController.setLanguage('tr');
                      setState(() {});
                    },
                  ),
                ),
                Expanded(
                  child: _buildSegmentButton(
                    emoji: '🇬🇧',
                    label: s.langEn,
                    isSelected: !isTrSelected,
                    onTap: () async {
                      Haptics.selectionClick();
                      await widget.progressController.setLanguage('en');
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    IconData? icon,
    String? emoji,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return isSelected
        ? ChunkyButton(
            color: Palette.primary,
            shadowColor: Palette.primaryDark,
            borderRadius: 12,
            depth: 2,
            onPressed: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (emoji != null) ...[
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                ] else if (icon != null) ...[
                  Icon(icon, size: 15, color: Colors.white),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
        : GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (emoji != null) ...[
                    Text(emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 15, color: Palette.textLow),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Palette.textLow,
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  void _showResetDialog(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.resetProgressTitle,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Palette.isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          s.resetProgressBody,
          style: ThemeConfig.bodyStyle.copyWith(
            fontSize: 13.5,
            color: Palette.textHigh,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: ChunkyButton(
                  color: Palette.buttonWhiteBg,
                  shadowColor: Palette.buttonWhiteShadow,
                  borderRadius: 14,
                  depth: 3,
                  height: 46,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    s.cancelBtn,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: Palette.textHigh,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChunkyButton(
                  color: const Color(0xFFEF4444),
                  shadowColor: const Color(0xFF991B1B),
                  borderRadius: 14,
                  depth: 3,
                  height: 46,
                  onPressed: () async {
                    Haptics.heavyImpact();
                    await widget.progressController.resetProgress();
                    if (mounted) {
                      setState(() {
                        _hapticsEnabled = Haptics.enabled;
                        _soundEnabled = widget.progressController.soundEnabled;
                      });
                    }
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(
                    s.resetBtn,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
