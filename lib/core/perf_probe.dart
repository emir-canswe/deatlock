import 'dart:async';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'audio.dart';
import '../domain/generator.dart';
import '../domain/hint.dart';

/// Measurement probe, compiled in only for `--dart-define=PERF=true` builds.
/// Normal builds contain none of it.
///
/// Every 2 seconds it prints one `[PERF]` line with
///  - frame build / raster / total times (Flutter's own FrameTiming), and
///  - UI-thread stalls, from a 5 ms heartbeat timer: if the UI thread is busy
///    (a long event handler, GC, a synchronous solve) the heartbeat arrives
///    late. This also catches blocking that happens outside the frame phases,
///    which FrameTiming cannot see.
const bool kPerfProbe = bool.fromEnvironment('PERF');

class PerfProbe {
  static final List<ui.FrameTiming> _frames = [];
  static final List<double> _gaps = [];
  static final Stopwatch _clock = Stopwatch()..start();
  static int _lastBeat = 0;

  static void start() {
    if (!kPerfProbe) return;
    // Native audioplayers lifecycle logs (load / prepared / play) for diagnosis.
    AudioLogger.logLevel = AudioLogLevel.info;
    SchedulerBinding.instance.addTimingsCallback(_frames.addAll);
    _lastBeat = _clock.elapsedMicroseconds;
    Timer.periodic(const Duration(milliseconds: 5), (_) {
      final now = _clock.elapsedMicroseconds;
      _gaps.add((now - _lastBeat) / 1000.0);
      _lastBeat = now;
    });
    Timer.periodic(const Duration(seconds: 2), (_) => _flush());
    Future<void>.delayed(const Duration(seconds: 7), _bench);
    Future<void>.delayed(const Duration(seconds: 12), _audioSelfTest);
  }

  static double _q(List<double> sorted, double q) =>
      sorted[((sorted.length - 1) * q).round()];

  static String _pct(List<double> v) {
    final s = [...v]..sort();
    return '${_q(s, .5).toStringAsFixed(1)}/${_q(s, .9).toStringAsFixed(1)}/'
        '${_q(s, .99).toStringAsFixed(1)}/${s.last.toStringAsFixed(1)}';
  }

  static void _flush() {
    final frames = List<ui.FrameTiming>.of(_frames);
    final gaps = List<double>.of(_gaps);
    _frames.clear();
    _gaps.clear();

    final stall25 = gaps.where((g) => g > 25).length;
    final stall50 = gaps.where((g) => g > 50).length;
    final stall100 = gaps.where((g) => g > 100).length;
    final maxGap = gaps.isEmpty ? 0.0 : gaps.reduce((a, b) => a > b ? a : b);

    if (frames.isEmpty) {
      debugPrint('[PERF] frames=0 stalls(>25/50/100ms)=$stall25/$stall50/$stall100 '
          'maxStall=${maxGap.toStringAsFixed(0)}ms');
      return;
    }
    final build = frames.map((f) => f.buildDuration.inMicroseconds / 1000.0).toList();
    final raster = frames.map((f) => f.rasterDuration.inMicroseconds / 1000.0).toList();
    final total = frames.map((f) => f.totalSpan.inMicroseconds / 1000.0).toList();
    final over17 = total.where((t) => t > 16.7).length;
    final over33 = total.where((t) => t > 33.4).length;
    debugPrint('[PERF] frames=${frames.length} '
        'build(p50/p90/p99/max)=${_pct(build)} '
        'raster=${_pct(raster)} total=${_pct(total)} '
        'over16.7ms=$over17 over33.4ms=$over33 '
        'stalls(>25/50/100ms)=$stall25/$stall50/$stall100 '
        'maxStall=${maxGap.toStringAsFixed(0)}ms');
  }

  /// One-off timing of the functions that run on the UI thread, measured on
  /// the real device (the host numbers are several times faster).
  static void _bench() {
    debugPrint('[BENCH] start (frames are blocked while this runs)');
    for (final l in const [1, 100, 208, 388, 448, 500]) {
      final g = generate(level: l);
      final sw = Stopwatch()..start();
      nextBestMove(g.meta, g.initialPositions);
      debugPrint('[BENCH] hint solve level $l: '
          '${(sw.elapsedMicroseconds / 1000).toStringAsFixed(1)}ms '
          '(optimal ${g.optimalMoves} moves)');
    }
    for (final entry in const {
      'level 113': 113,
      'level 288': 288,
      'sprint score 10': 10009,
      'sprint score 22': 10021,
      'daily': 20261027,
    }.entries) {
      final sw = Stopwatch()..start();
      generate(level: entry.value);
      debugPrint('[BENCH] generate ${entry.key}: '
          '${(sw.elapsedMicroseconds / 1000).toStringAsFixed(1)}ms');
    }
    debugPrint('[BENCH] done');
  }

  /// Plays the 2.4 s win sound back to back for ~10 s so that the system's audio
  /// service can be inspected while something is definitely sounding.
  static Future<void> _audioSelfTest() async {
    debugPrint('[AUDIOTEST] start enabled=${Audio.enabled}');
    for (int i = 0; i < 4; i++) {
      Audio.playWin();
      debugPrint('[AUDIOTEST] playWin #$i');
      await Future<void>.delayed(const Duration(milliseconds: 2500));
    }
    debugPrint('[AUDIOTEST] end');
  }
}
