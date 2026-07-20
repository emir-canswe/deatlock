import 'package:flutter/material.dart';
import '../../core/haptics.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/progress_controller.dart';
import '../widgets/chunky_button.dart';

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
        decoration: const BoxDecoration(
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
              // Header Row: Back button (Chunky) + Title pill (3D style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    ChunkyButton(
                      color: Colors.white,
                      shadowColor: const Color(0xFFCBD5E1),
                      borderRadius: 24,
                      width: 46,
                      height: 46,
                      depth: 3,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Palette.textHigh,
                        size: 26,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s.settingsTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Palette.textHigh,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 46), // balance
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. Haptics Card
              _buildSettingsCard(
                label: s.haptics,
                trailing: _buildToggle(
                  value: _hapticsEnabled,
                  onTap: () async {
                    final newValue = !_hapticsEnabled;
                    await Haptics.setEnabled(newValue);
                    setState(() => _hapticsEnabled = newValue);
                  },
                ),
              ),

              // 2. Sound Card
              _buildSettingsCard(
                label: s.sound,
                trailing: _buildToggle(
                  value: _soundEnabled,
                  onTap: () async {
                    final newValue = !_soundEnabled;
                    await widget.progressController.setSoundEnabled(newValue);
                    setState(() => _soundEnabled = newValue);
                  },
                ),
              ),

              // 3. Language Card
              _buildLanguageCard(s),

              // 4. Version Card
              _buildSettingsCard(
                label: s.version,
                trailing: const Text(
                  '3.0.0',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: Palette.textLow,
                  ),
                ),
              ),

              const Spacer(),

              // 4. Reset Progress ChunkyButton (3D Danger Red Button at bottom!)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ChunkyButton(
                  color: const Color(0xFFE24B4A), // danger red
                  shadowColor: const Color(0xFF991B1B), // dark red border
                  borderRadius: 18,
                  depth: 5,
                  height: 58,
                  onPressed: () => _showResetDialog(context),
                  child: Text(
                    s.resetProgress,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required String label, required Widget trailing}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Palette.textHigh,
              letterSpacing: 0.2,
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildToggle({required bool value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? const Color(0xFF19BFA0) : const Color(0xFFF1F5F9),
          border: Border.all(
            color: value ? const Color(0xFF109E83) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(S s) {
    final currentLang = widget.progressController.language;
    // Default to Turkish if language is system and system locale is Turkish
    final isTrSelected = currentLang == 'tr' || (currentLang == 'system' && s.isTr);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.languageLabel,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Palette.textHigh,
                  letterSpacing: 0.2,
                ),
              ),
              const Icon(Icons.translate_rounded, color: Palette.textLow, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentButton(
                    label: s.langTr,
                    isSelected: isTrSelected,
                    onTap: () async {
                      await widget.progressController.setLanguage('tr');
                      setState(() {});
                    },
                  ),
                ),
                Expanded(
                  child: _buildSegmentButton(
                    label: s.langEn,
                    isSelected: !isTrSelected,
                    onTap: () async {
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
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return isSelected
        ? ChunkyButton(
            color: Palette.primary,
            shadowColor: Palette.primaryDark,
            borderRadius: 10,
            depth: 2,
            onPressed: onTap,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          )
        : GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Palette.textLow,
                ),
              ),
            ),
          );
  }

  void _showResetDialog(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.boardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.resetProgressTitle,
          style: ThemeConfig.titleStyle.copyWith(color: const Color(0xFF991B1B)),
        ),
        content: Text(
          s.resetProgressBody,
          style: ThemeConfig.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancelBtn, style: ThemeConfig.labelStyle.copyWith(color: Palette.textLow)),
          ),
          TextButton(
            onPressed: () async {
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
            child: Text(s.resetBtn, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, color: Color(0xFFE24B4A))),
          ),
        ],
      ),
    );
  }
}
