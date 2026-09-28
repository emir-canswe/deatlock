import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Central localization for Deadlock.
/// Supports Turkish (tr) and English (en).
/// Auto-detects from device locale.
class S {
  final bool isTr;
  const S._(this.isTr);

  /// Resolve from BuildContext (uses Flutter's Localizations).
  static S of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return S._(code == 'tr');
  }

  /// Resolve without context (uses platform dispatcher directly).
  static S get system {
    final code = ui.PlatformDispatcher.instance.locale.languageCode;
    return S._(code == 'tr');
  }

  // ── Main Menu ─────────────────────────────────────────────────────────
  String get play => isTr ? 'OYNA' : 'PLAY';
  String get gameModes => isTr ? 'OYUN MODLARI' : 'GAME MODES';
  String get bestLevel => isTr ? 'En yüksek: Bölüm' : 'Best: Level';
  String get selected => isTr ? 'Seçili' : 'Selected';
  String get dailyMission => isTr ? 'GÜNLÜK GÖREV' : 'DAILY MISSION';
  String get dailyMissionDesc => isTr ? 'Günlük bulmacayı çöz' : 'Solve the daily puzzle';

  // ── Mode Names ────────────────────────────────────────────────────────
  String get modeLevels => isTr ? 'Bölümler' : 'Levels';
  String get modeDaily => isTr ? 'Günlük' : 'Daily';
  String get modeSprint => isTr ? 'Koşu' : 'Sprint';
  String get modeZen => isTr ? 'Serbest' : 'Zen';
  String get modeZenSub => isTr ? 'Zen Mod' : 'Zen Mode';

  // ── Level subtitles ───────────────────────────────────────────────────
  String levelSubtitle(int n) => isTr ? 'Bölüm $n' : 'Level $n';
  String sprintBestSub(int n) => isTr ? 'En iyi: $n ⏱️' : 'Best: $n ⏱️';

  // ── Daily ─────────────────────────────────────────────────────────────
  String get dailyReady => isTr ? 'Bulmaca hazır 📅' : 'Puzzle ready 📅';
  String get dailySolved => isTr ? 'Çözüldü ✓' : 'Solved ✓';
  String dailyStreak(int n) => isTr ? '$n gün 🔥' : '$n days 🔥';

  // ── Top Bar ───────────────────────────────────────────────────────────
  String levelTitle(int n) => isTr ? 'BÖLÜM $n' : 'LEVEL $n';
  String get dailyTitle => isTr ? 'GÜNLÜK' : 'DAILY';
  String get sprintTitle => isTr ? 'KOŞU' : 'SPRINT';
  String get zenTitle => isTr ? 'ZEN' : 'ZEN';
  String moveStat(int n) => isTr ? 'HAMLE: $n' : 'MOVES: $n';
  String scoreStat(int n) => isTr ? 'SKOR: $n' : 'SCORE: $n';

  // ── Bottom Bar ────────────────────────────────────────────────────────
  String get undo => isTr ? 'GERİ AL' : 'UNDO';
  String get hint => isTr ? 'İPUCU' : 'HINT';
  String hintN(int n) => isTr ? 'İPUCU $n' : 'HINT $n';
  String get retry => isTr ? 'TEKRAR' : 'RETRY';

  // ── Win Sheet ─────────────────────────────────────────────────────────
  String get perfect => isTr ? 'MÜKEMMEL' : 'PERFECT';
  String get completed => isTr ? 'TAMAMLANDI' : 'COMPLETED';
  String get hintUsed => isTr ? 'İpucu kullanıldı' : 'Hint used';
  String get yourMoves => isTr ? 'HAMLENİZ' : 'YOUR MOVES';
  String get optimal => isTr ? 'OPTİMAL' : 'OPTIMAL';
  String get movesLabel => isTr ? 'HAMLE' : 'MOVES';
  String get streakLabel => isTr ? 'SERİ' : 'STREAK';
  String streakDays(int n) => isTr ? '$n Gün' : '$n Days';
  String get last30Days => isTr ? 'SON 30 GÜN' : 'LAST 30 DAYS';
  String get solved => isTr ? 'ÇÖZÜLEN' : 'SOLVED';
  String get bestLabel => isTr ? 'EN İYİ' : 'BEST';
  String get playAgain => isTr ? 'YENİDEN' : 'AGAIN';
  String get okBtn => isTr ? 'TAMAM' : 'OK';
  String get nextBtn => isTr ? 'SONRAKİ' : 'NEXT';

  // ── Levels Screen ─────────────────────────────────────────────────────
  String get levelsTitle => isTr ? 'BÖLÜMLER' : 'LEVELS';

  // ── Settings ─────────────────────────────────────────────────────────
  String get settingsTitle => isTr ? 'AYARLAR' : 'SETTINGS';
  String get haptics => isTr ? 'TİTREŞİM' : 'HAPTICS';
  String get sound => isTr ? 'SES' : 'SOUND';
  String get themeLabel => isTr ? 'TEMA' : 'THEME';
  String get themeSystem => isTr ? 'SİSTEM' : 'SYSTEM';
  String get themeLight => isTr ? 'AÇIK' : 'LIGHT';
  String get themeDark => isTr ? 'KOYU' : 'DARK';
  String get languageLabel => isTr ? 'UYGULAMA DİLİ' : 'APP LANGUAGE';
  String get langSystem => isTr ? 'SİSTEM' : 'SYSTEM';
  String get langTr => isTr ? 'TÜRKÇE' : 'TURKISH';
  String get langEn => isTr ? 'İNGİLİZCE' : 'ENGLISH';
  String get version => isTr ? 'SÜRÜM' : 'VERSION';
  String get resetProgress => isTr ? 'İLERLEMEYİ SIFIRLA' : 'RESET PROGRESS';
  String get resetProgressTitle => isTr ? 'İLERLEMEYİ SIFIRLA' : 'RESET PROGRESS';
  String get resetProgressBody => isTr
      ? 'Tüm ilerlemeniz silinecek. Emin misiniz?'
      : 'All your progress will be deleted. Are you sure?';
  String get cancelBtn => isTr ? 'İPTAL' : 'CANCEL';
  String get resetBtn => isTr ? 'SIFIRLA' : 'RESET';

  // ── Game Dialogs ──────────────────────────────────────────────────────
  String get warningTitle => isTr ? 'UYARI' : 'WARNING';
  String get dailyResetWarning => isTr
      ? 'Yeniden başlatırsanız bugün başarısız sayılacak ve seriniz bozulacaktır. Emin misiniz?'
      : 'Restarting will count as a failure today and break your streak. Are you sure?';

  // ── Hint overlay ──────────────────────────────────────────────────────
  String get slide => isTr ? 'Kaydır!' : 'Slide!';

  // ── Installation Banner ───────────────────────────────────────────────
  String get installCta => isTr ? 'Ana ekrana ekle' : 'Add to home screen';
  String get installSafariDesc => isTr ? 'Safari tarayıcısında eklemek için:' : 'To add in Safari browser:';
  String get installSafariStep1 => isTr
      ? '1. Alt menüdeki Paylaş (Share) simgesine dokunun.'
      : '1. Tap the Share icon at the bottom.';
  String get installSafariStep2 => isTr
      ? '2. Listeden "Ana Ekrana Ekle" (Add to Home Screen) seçeneğini seçin.'
      : '2. Select "Add to Home Screen" from the list.';

  // ── Daily History Screen ──────────────────────────────────────────────
  String get dailyHistoryTitle => isTr ? 'GÜNLÜK GEÇMİŞ' : 'DAILY HISTORY';
  String get activeStreakLabel => isTr ? 'AKTİF SERİ' : 'ACTIVE STREAK';
  String get notPlayed => isTr ? 'Oynanmadı' : 'Not Played';
  String get failed => isTr ? 'Başarısız' : 'Failed';
  String movesText(int n) => isTr ? '$n Hamle' : '$n Moves';
  String get timeLabel => isTr ? 'SÜRE' : 'TIME';
  String get copiedFeedback => isTr ? 'Panoya kopyalandı!' : 'Copied to clipboard!';
  String get copiedLabel => isTr ? 'KOPYALANDI' : 'COPIED';
  String get shareResultLabel => isTr ? 'SONUCU PAYLAŞ' : 'SHARE RESULT';
  String get timeUp => isTr ? 'SÜRE BİTTİ' : 'TIME UP';
  
  List<String> get monthsList => isTr
      ? ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık']
      : ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  // ── Star Gate (Yıldız Kapısı) ──────────────────────────────────────────
  String get starGateTitle => isTr ? 'YILDIZ KAPISI' : 'STAR GATE';
  String get starGateLocked => isTr ? 'KİLİTLİ' : 'LOCKED';
  String starGateRequired(int req, int cur) => isTr
      ? 'Bu bölüme geçmek için $req ⭐ gerekli. (Şu an: $cur ⭐)'
      : 'Requires $req ⭐ to unlock this level. (Current: $cur ⭐)';
  String get starGateTip => isTr
      ? 'Önceki bölümleri daha az hamleyle tekrar oynayarak 3 yıldız toplayabilirsin!'
      : 'Replay previous levels with fewer moves to collect 3 stars!';
  String starGateBlockedSheetDesc(int req, int cur) => isTr
      ? '51. ve sonraki bölümlere geçmek için en az $req ⭐ toplamalısın! (Şu an: $cur ⭐)'
      : 'Collect at least $req ⭐ to unlock level 51 and beyond! (Current: $cur ⭐)';
  String get toLevels => isTr ? 'BÖLÜMLERE DÖN' : 'LEVELS LIST';
  String get stars => isTr ? 'Yıldız' : 'Stars';

  // ── Tutorial & Optimal Route Guide (İlk 5 Seviye Yol Tarifi) ─────────
  String get tutorialGotIt => isTr ? 'ANLADIM' : 'GOT IT';
  String get tutorialTapToDismiss => isTr ? 'Başlamak için kaydır veya dokun' : 'Swipe or tap to begin';
  String get yolTarifi => isTr ? 'YOL TARİFİ' : 'ROUTE GUIDE';
  String get rehberGizle => isTr ? 'Gizle' : 'Hide';
  String get rehberGoster => isTr ? 'Yol Tarifi' : 'Guide';
  String get optimalRouteReady => isTr ? 'En optimal rota hazır' : 'Optimal route ready';
  String stepFormat(int current, int total) => isTr ? 'Adım $current / $total' : 'Step $current / $total';

  String get tutorialTitle1 => isTr ? '1. AŞAMA: ÇIKIŞA ULAŞ' : 'STAGE 1: REACH THE EXIT';
  String get tutorialDesc1 => isTr
      ? 'Kırmızı bloğu sağdaki çıkış kapısına doğru kaydır.'
      : 'Slide the red block rightward to the exit gate.';

  String get tutorialTitle2 => isTr ? '2. AŞAMA: ENGELLERİ KALDIR' : 'STAGE 2: CLEAR OBSTACLES';
  String get tutorialDesc2 => isTr
      ? 'Kırmızı bloğun önünü açmak için önce engel blokları kaydır.'
      : 'Slide other blocks to clear a path for the red block.';

  String get tutorialTitle3 => isTr ? '3. AŞAMA: HAREKET EKSENLERİ' : 'STAGE 3: MOVEMENT AXIS';
  String get tutorialDesc3 => isTr
      ? 'Yatay bloklar yalnızca sağa-sola, dikey bloklar ise yukarı-aşağı kayar.'
      : 'Horizontal blocks slide left/right, vertical blocks slide up/down.';

  String get tutorialTitle4 => isTr ? '4. AŞAMA: ZİNCİRLEME HAMLE' : 'STAGE 4: CHAIN MOVES';
  String get tutorialDesc4 => isTr
      ? 'Bir bloğu kaydırmak için bazen diğerlerini kenara çekmek gerekir.'
      : 'Sometimes you must slide other blocks aside to unlock the way.';

  String get tutorialTitle5 => isTr ? '5. AŞAMA: OPTİMAL ROTA & 3 YILDIZ' : 'STAGE 5: OPTIMAL ROUTE';
  String get tutorialDesc5 => isTr
      ? 'En kısa rotayı izleyerek 3 yıldızı kap! Hamle sayısını optimalde tut.'
      : 'Follow the shortest path for 3 stars! Keep moves at optimal.';

  // Dynamic turn-by-turn move guides
  String slideRedRight(int n) => isTr ? 'Kırmızı bloğu $n birim sağa kaydır ➔ Çıkışa!' : 'Slide red block $n cells right ➔ To exit!';
  String slideRedLeft(int n) => isTr ? 'Kırmızı bloğu $n birim sola kaydır' : 'Slide red block $n cells left';
  String slideHorizRight(int n) => isTr ? 'Yatay bloğu $n birim sağa kaydır' : 'Slide horizontal block $n cells right';
  String slideHorizLeft(int n) => isTr ? 'Yatay bloğu $n birim sola kaydır' : 'Slide horizontal block $n cells left';
  String slideVertDown(int n) => isTr ? 'Dikey bloğu $n birim aşağı kaydır' : 'Slide vertical block $n cells down';
  String slideVertUp(int n) => isTr ? 'Dikey bloğu $n birim yukarı kaydır' : 'Slide vertical block $n cells up';

  // ── Hint Action Banner & Feedback ─────────────────────────────────────
  String get hintTitle => isTr ? 'İPUCU' : 'HINT';
  String get hintApply => isTr ? 'HAMLEYİ YAP' : 'PLAY MOVE';
  String get hintClose => isTr ? 'KAPAT' : 'CLOSE';
  String get noHintsLeft => isTr ? 'İpucu kalmadı!' : 'No hints left!';
  String get hintActiveNotice => isTr ? 'İpucu zaten aktif' : 'Hint is already active';

  // ── Levels Screen Tier & Progress ─────────────────────────────────────
  String solvedCount(int cur, int total) => isTr ? '$cur / $total Çözüldü' : '$cur / $total Solved';
  String tierProgressTitle(int tier, int start, int end) =>
      isTr ? 'Aşama $tier • Bölüm $start-$end' : 'Tier $tier • Levels $start-$end';
  String get currentLevelBadge => isTr ? 'ŞU AN' : 'PLAY';
}
