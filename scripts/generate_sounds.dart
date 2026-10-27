// Soft, calming sound effects for FataBlock.
//
// Design rules (the previous set was harsh):
//  - Gentle onsets: 5-10 ms raised-cosine attacks instead of ~1.5 ms spikes.
//  - Warm timbre: pure sine tones with at most one faint octave, run through a
//    low-pass so nothing bright survives. No sparkle above ~3 kHz.
//  - Low levels: peaks sit between -16 and -10 dBFS, not at -0.7 dBFS.
//  - One key: every pitched cue is C major, so the stars (C-E-G) sit on top of
//    the win chord instead of clashing with it.
//  - Percussive cues (click, slide, snap, bump) are round "taps" in four
//    clearly different registers. None goes below ~150 Hz: a phone speaker
//    barely reproduces that, so a deeper tap would simply vanish. Body comes
//    from a faint second harmonic instead.
//
// Usage:  dart run scripts/generate_sounds.dart [outputDir]
//         (default output directory: assets/sounds)

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sr = 44100;

void main(List<String> args) {
  final outDir = args.isNotEmpty ? args.first : 'assets/sounds';
  Directory(outDir).createSync(recursive: true);
  File f(String name) => File('$outDir/$name.wav');

  writeWav(f('click'), click(), peakDb: -12);
  writeWav(f('slide'), slide(), peakDb: -16);
  writeWav(f('snap'), snap(), peakDb: -12);
  writeWav(f('bump'), bump(), peakDb: -12);
  writeWav(f('hint'), hint(), peakDb: -13);
  writeWav(f('undo'), undo(), peakDb: -15);
  writeWav(f('star1'), star(1), peakDb: -12);
  writeWav(f('star2'), star(2), peakDb: -12);
  writeWav(f('star3'), star(3), peakDb: -11);
  writeWav(f('win'), win(), peakDb: -10);

  // ignore: avoid_print
  print('Soft sounds written to $outDir');
}

// ── DSP helpers ──────────────────────────────────────────────────────────────

/// Raised-cosine attack (no click) times an exponential decay.
double env(double t, double attack, double decay) {
  final a = t < attack ? 0.5 - 0.5 * math.cos(math.pi * t / attack) : 1.0;
  return a * math.exp(-t / decay);
}

List<double> blank(double seconds) =>
    List<double>.filled((sr * seconds).round(), 0.0);

/// Two cascaded one-pole low-pass filters (-12 dB/oct). Removes the bright
/// edge that makes small phone speakers sound harsh.
List<double> lowpass(List<double> x, double cutoffHz) {
  final a = 1 - math.exp(-2 * math.pi * cutoffHz / sr);
  final y = List<double>.filled(x.length, 0.0);
  double s1 = 0, s2 = 0;
  for (int i = 0; i < x.length; i++) {
    s1 += a * (x[i] - s1);
    s2 += a * (s1 - s2);
    y[i] = s2;
  }
  return y;
}

/// Fades the very start and end so there can never be an edge pop.
void fades(List<double> s, {double inMs = 1, double outMs = 20}) {
  final inN = (sr * inMs / 1000).round();
  final outN = (sr * outMs / 1000).round();
  for (int i = 0; i < inN && i < s.length; i++) {
    s[i] *= i / inN;
  }
  for (int i = 0; i < outN && i < s.length; i++) {
    s[s.length - 1 - i] *= i / outN;
  }
}

/// Sine whose pitch glides exponentially from [f0] to [f1] (time constant
/// [tau]), with a faint second harmonic [h2] for body.
List<double> glide(double seconds, double f0, double f1, double tau, double h2) {
  final out = blank(seconds);
  double ph = 0;
  for (int i = 0; i < out.length; i++) {
    final t = i / sr;
    final f = f1 + (f0 - f1) * math.exp(-t / tau);
    ph += 2 * math.pi * f / sr;
    out[i] = math.sin(ph) + h2 * math.sin(2 * ph);
  }
  return out;
}

/// Soft bell / marimba-like voice: fundamental plus a faint decaying octave.
/// Deliberately no inharmonic partials, which are what sound "metallic".
double bell(double f, double t, double decay, {double attack = 0.010}) {
  if (t < 0) return 0.0;
  final e = env(t, attack, decay);
  final body = math.sin(2 * math.pi * f * t) +
      0.10 * math.sin(2 * math.pi * f * 2 * t) * math.exp(-t / (decay * 0.5));
  return body * e;
}

/// Small, warm room: parallel combs + an all-pass smear.
List<double> reverb(List<double> dry, double wet) {
  final len = dry.length;
  const delays = <int>[1557, 1617, 1491, 1422];
  const fb = <double>[0.78, 0.76, 0.80, 0.74];
  final sum = List<double>.filled(len, 0.0);
  for (int c = 0; c < delays.length; c++) {
    final buf = List<double>.filled(len, 0.0);
    for (int i = 0; i < len; i++) {
      final d = i >= delays[c] ? buf[i - delays[c]] : 0.0;
      buf[i] = dry[i] + fb[c] * d;
      sum[i] += buf[i];
    }
  }
  final mixed = List<double>.filled(len, 0.0);
  for (int i = 0; i < len; i++) {
    mixed[i] = dry[i] + (sum[i] / delays.length) * wet;
  }
  const apD = 441;
  const apG = 0.6;
  final out = List<double>.filled(len, 0.0);
  for (int i = 0; i < len; i++) {
    final xD = i >= apD ? mixed[i - apD] : 0.0;
    final yD = i >= apD ? out[i - apD] : 0.0;
    out[i] = -apG * mixed[i] + xD + apG * yD;
  }
  return out;
}

// ── Percussive taps (four distinct, low registers) ──────────────────────────

/// UI tap: a soft wooden "tok".
List<double> click() {
  final x = glide(0.09, 420, 340, 0.018, 0.12);
  for (int i = 0; i < x.length; i++) {
    x[i] *= env(i / sr, 0.005, 0.024);
  }
  final y = lowpass(x, 1800);
  fades(y, outMs: 12);
  return y;
}

/// Block slide: the lightest, highest tap. It fires on every cell of a drag,
/// so it is also the quietest cue. Padded with silence so Android's player
/// renders such a short clip reliably.
List<double> slide() {
  final x = glide(0.11, 580, 480, 0.030, 0.10);
  for (int i = 0; i < x.length; i++) {
    x[i] *= env(i / sr, 0.006, 0.024);
  }
  final y = lowpass(x, 1600);
  fades(y, outMs: 14);
  return y;
}

/// Block settles into its slot: a round "thup".
List<double> snap() {
  final x = glide(0.14, 310, 235, 0.020, 0.30);
  for (int i = 0; i < x.length; i++) {
    x[i] *= env(i / sr, 0.005, 0.055);
  }
  final y = lowpass(x, 1500);
  fades(y, outMs: 16);
  return y;
}

/// Blocked move: a muted "dum". A gentle "not that one", never a buzz.
List<double> bump() {
  final x = glide(0.20, 205, 155, 0.045, 0.50);
  for (int i = 0; i < x.length; i++) {
    x[i] *= env(i / sr, 0.008, 0.085);
  }
  final y = lowpass(x, 1000);
  fades(y, outMs: 20);
  return y;
}

// ── Gentle musical cues (all C major) ───────────────────────────────────────

/// Hint: two soft bell notes, G5 then C6 — a calm "ting-ting", nothing sparkly.
List<double> hint() {
  final x = blank(1.0);
  for (int i = 0; i < x.length; i++) {
    final t = i / sr;
    x[i] = bell(783.99, t, 0.30) + 0.85 * bell(1046.50, t - 0.13, 0.32);
  }
  final y = reverb(lowpass(x, 3000), 0.22);
  fades(y, outMs: 80);
  return y;
}

/// Undo: a soft falling pair, G5 -> E5. Falling pitch reads as "going back".
List<double> undo() {
  final x = blank(0.4);
  for (int i = 0; i < x.length; i++) {
    final t = i / sr;
    x[i] = bell(783.99, t, 0.12, attack: 0.008) +
        0.9 * bell(659.25, t - 0.09, 0.14, attack: 0.008);
  }
  final y = lowpass(x, 2500);
  fades(y, outMs: 40);
  return y;
}

/// Star k lights up: C5, E5, G5 — together they are the C major arpeggio the
/// win chord is built on.
List<double> star(int k) {
  final f = <double>[523.25, 659.25, 783.99][k - 1];
  final x = blank(k == 3 ? 1.0 : 0.7);
  final decay = k == 3 ? 0.50 : 0.34;
  for (int i = 0; i < x.length; i++) {
    final t = i / sr;
    x[i] = bell(f, t, decay);
    if (k == 3) x[i] += 0.22 * bell(1046.50, t - 0.04, 0.45);
  }
  final y = reverb(lowpass(x, 3000), 0.18);
  fades(y, outMs: 60);
  return y;
}

/// Win: a warm C major chord that swells in slowly, with two quiet bells
/// floating on top. The stars supply the melody over it.
List<double> win() {
  final x = blank(2.4);
  const chord = <double>[261.63, 329.63, 392.00, 523.25];
  for (int i = 0; i < x.length; i++) {
    final t = i / sr;
    double pad = 0.0;
    for (final f in chord) {
      pad += 0.25 * math.sin(2 * math.pi * f * t) +
          0.045 * math.sin(2 * math.pi * f * 2 * t) * math.exp(-t / 0.6) +
          0.12 * math.sin(2 * math.pi * (f + 0.6) * t); // slight detune: warmth
    }
    x[i] = pad * env(t, 0.14, 1.15) +
        0.30 * bell(783.99, t - 0.35, 0.55) +
        0.22 * bell(1046.50, t - 0.52, 0.60);
  }
  final y = reverb(lowpass(x, 2600), 0.28);
  fades(y, outMs: 350);
  return y;
}

// ── WAV writer (16-bit mono PCM), normalised to a chosen peak ───────────────

void writeWav(File file, List<double> samples, {required double peakDb}) {
  double maxAmp = 0.0;
  for (final s in samples) {
    final a = s.abs();
    if (a > maxAmp) maxAmp = a;
  }
  final target = math.pow(10.0, peakDb / 20.0).toDouble();
  final gain = maxAmp > 0 ? target / maxAmp : 1.0;

  final n = samples.length;
  final b = ByteData(44 + n * 2);
  void tag(int off, String s) {
    for (int i = 0; i < s.length; i++) {
      b.setUint8(off + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  b.setUint32(4, 36 + n * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little); // PCM
  b.setUint16(22, 1, Endian.little); // mono
  b.setUint32(24, sr, Endian.little);
  b.setUint32(28, sr * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  b.setUint32(40, n * 2, Endian.little);
  for (int i = 0; i < n; i++) {
    final v = (samples[i] * gain).clamp(-1.0, 1.0);
    b.setInt16(44 + i * 2, (v * 32767.0).round(), Endian.little);
  }
  file.writeAsBytesSync(b.buffer.asUint8List());
}
