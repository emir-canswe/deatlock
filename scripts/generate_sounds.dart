// Synthesizes polished, 16-bit 44.1kHz mono PCM WAV sound effects:
// 1. click.wav : soft, warm marimba-style UI tick (gentle, non-fatiguing)
// 2. slide.wav : smooth airy woosh with a soft wooden landing "tok"
// 3. win.wav   : cheerful music-box arpeggio + major chord with a lush reverb tail
//
// Design notes for a pleasant result:
//  - raised-cosine attacks + short edge fades remove digital clicks at start/end
//  - mostly sine-based partials with tasteful, fast-decaying overtones (no harshness)
//  - a simple Schroeder reverb (comb + allpass) gives the win a rich, musical tail
//
// Run with: dart run scripts/generate_sounds.dart

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final outputDir = Directory('assets/sounds');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  print('Synthesizing polished 16-bit 44.1kHz audio assets...');
  generateClick(File('assets/sounds/click.wav'));
  generateSlide(File('assets/sounds/slide.wav'));
  generateWin(File('assets/sounds/win.wav'));
  print('Done — assets/sounds/{click,slide,win}.wav regenerated.');
}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Raised-cosine attack (click-free) multiplied by exponential decay.
double env(double t, double attack, double decay) {
  final a = t < attack ? 0.5 - 0.5 * math.cos(math.pi * (t / attack)) : 1.0;
  return a * math.exp(-t / decay);
}

/// Fades the first/last few milliseconds to guarantee no edge pops.
void applyEdgeFades(List<double> s, int sr, {double inMs = 1, double outMs = 8}) {
  final inN = (sr * inMs / 1000).round();
  final outN = (sr * outMs / 1000).round();
  for (int i = 0; i < inN && i < s.length; i++) {
    s[i] *= i / inN;
  }
  for (int i = 0; i < outN && i < s.length; i++) {
    s[s.length - 1 - i] *= i / outN;
  }
}

/// Lush, musical reverb tail (parallel feedback combs + one allpass smear).
List<double> applyReverb(List<double> dry, int sr, {double wet = 0.26}) {
  final len = dry.length;
  final combDelays = <int>[1557, 1617, 1491, 1422];
  final combFb = <double>[0.80, 0.78, 0.82, 0.76];

  final wetBuf = List<double>.filled(len, 0.0);
  for (int c = 0; c < combDelays.length; c++) {
    final d = combDelays[c];
    final fb = combFb[c];
    final buf = List<double>.filled(len, 0.0);
    for (int i = 0; i < len; i++) {
      final delayed = i >= d ? buf[i - d] : 0.0;
      buf[i] = dry[i] + fb * delayed;
      wetBuf[i] += buf[i];
    }
  }

  final mixed = List<double>.filled(len, 0.0);
  for (int i = 0; i < len; i++) {
    mixed[i] = dry[i] + (wetBuf[i] / combDelays.length) * wet;
  }

  // Allpass diffusion for a smoother, less metallic tail.
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

// ── Click: soft warm marimba tick ───────────────────────────────────────────
void generateClick(File file) {
  const sampleRate = 44100;
  const duration = 0.06;
  final n = (sampleRate * duration).toInt();
  final s = List<double>.filled(n, 0.0);
  final rand = math.Random(7);

  const freq = 680.0; // ~E5, warm and friendly
  for (int i = 0; i < n; i++) {
    final t = i / sampleRate;
    final tone = math.sin(2 * math.pi * freq * t) +
        0.30 * math.sin(2 * math.pi * freq * 2.0 * t) * math.exp(-t / 0.012) +
        0.10 * math.sin(2 * math.pi * freq * 3.01 * t) * math.exp(-t / 0.007);
    // A whisper of texture for a tactile edge (very low, fast-gone).
    final texture = (rand.nextDouble() * 2 - 1) * math.exp(-t / 0.0012) * 0.08;
    s[i] = (0.82 * tone + texture) * env(t, 0.003, 0.026);
  }

  applyEdgeFades(s, sampleRate, inMs: 1, outMs: 6);
  writeWav16(file, s, sampleRate);
}

// ── Slide: clean warm wooden block tap (no noise) ───────────────────────────
// A soft, rounded "bloop" with a slight downward pitch glide that suggests the
// block settling into place. No hissy noise — pleasant on tiny phone speakers.
void generateSlide(File file) {
  const sampleRate = 44100;
  const duration = 0.12;
  final n = (sampleRate * duration).toInt();
  final s = List<double>.filled(n, 0.0);

  for (int i = 0; i < n; i++) {
    final t = i / sampleRate;

    // Pitch glides downward (≈450Hz → 270Hz) = the feel of motion settling.
    final f = 270.0 + 180.0 * math.exp(-t / 0.035);
    final tone = math.sin(2 * math.pi * f * t) +
        0.35 * math.sin(2 * math.pi * f * 2.0 * t) * math.exp(-t / 0.030) +
        0.12 * math.sin(2 * math.pi * f * 3.0 * t) * math.exp(-t / 0.014);

    // Soft tactile onset "pick" so it feels physical, not beepy.
    final pick = math.sin(2 * math.pi * 900.0 * t) * math.exp(-t / 0.004) * 0.14;

    s[i] = (0.9 * tone + pick) * env(t, 0.004, 0.045);
  }

  applyEdgeFades(s, sampleRate, inMs: 1, outMs: 8);
  writeWav16(file, s, sampleRate);
}

// ── Win: cheerful music-box arpeggio + chord with reverb ────────────────────
void generateWin(File file) {
  const sampleRate = 44100;
  const duration = 1.8;
  final n = (sampleRate * duration).toInt();
  final dry = List<double>.filled(n, 0.0);

  // Bright, friendly music-box voice (sine + quick overtone + light inharmonic).
  double voice(double freq, double tn, double decay) {
    if (tn < 0) return 0.0;
    final a = tn < 0.002 ? tn / 0.002 : 1.0;
    final f0 = math.sin(2 * math.pi * freq * tn) * math.exp(-tn / decay);
    final o1 = 0.25 *
        math.sin(2 * math.pi * freq * 2.0 * tn) *
        math.exp(-tn / (decay * 0.6));
    final o2 = 0.10 *
        math.sin(2 * math.pi * freq * 4.2 * tn) *
        math.exp(-tn / (decay * 0.35));
    return (f0 + o1 + o2) * a;
  }

  // Ascending C-major arpeggio → it just sounds "happy".
  const arpFreqs = <double>[523.25, 659.25, 783.99, 1046.50, 1318.51];
  const arpTimes = <double>[0.00, 0.075, 0.150, 0.225, 0.300];
  // Final sustained chord (C major, rings out).
  const chordFreqs = <double>[523.25, 659.25, 783.99, 1046.50];
  const chordTime = 0.40;
  // High sparkle on the chord hit.
  const sparkleFreqs = <double>[2093.00, 2637.02];

  for (int i = 0; i < n; i++) {
    final t = i / sampleRate;
    double mix = 0.0;

    for (int k = 0; k < arpFreqs.length; k++) {
      mix += voice(arpFreqs[k], t - arpTimes[k], 0.55) * 0.22;
    }
    if (t >= chordTime) {
      final tc = t - chordTime;
      for (final f in chordFreqs) {
        mix += voice(f, tc, 1.1) * 0.20;
      }
      for (final f in sparkleFreqs) {
        mix += voice(f, tc, 0.5) * 0.06;
      }
      // Warm sustaining pad for body underneath the chimes.
      final padEnv = math.sin(math.min(math.pi / 2, tc / 0.25)) * math.exp(-tc / 0.9);
      final pad = (math.sin(2 * math.pi * 130.81 * tc) * 0.4 +
              math.sin(2 * math.pi * 196.00 * tc) * 0.32 +
              math.sin(2 * math.pi * 261.63 * tc) * 0.28) *
          padEnv *
          0.16;
      mix += pad;
    }

    dry[i] = mix;
  }

  final wetSamples = applyReverb(dry, sampleRate, wet: 0.26);
  applyEdgeFades(wetSamples, sampleRate, inMs: 1, outMs: 40);
  writeWav16(file, wetSamples, sampleRate);
}

// ── WAV writer (16-bit signed PCM, mono, peak-normalized) ───────────────────
void writeWav16(File file, List<double> floatSamples, int sampleRate) {
  double maxAmp = 0.0;
  for (final s in floatSamples) {
    final abs = s.abs();
    if (abs > maxAmp) maxAmp = abs;
  }
  final gain = maxAmp > 0.0 ? (0.92 / maxAmp) : 1.0;

  final numSamples = floatSamples.length;
  final byteData = ByteData(44 + numSamples * 2);

  byteData.setUint8(0, 0x52);
  byteData.setUint8(1, 0x49);
  byteData.setUint8(2, 0x46);
  byteData.setUint8(3, 0x46);
  byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
  byteData.setUint8(8, 0x57);
  byteData.setUint8(9, 0x41);
  byteData.setUint8(10, 0x56);
  byteData.setUint8(11, 0x45);
  byteData.setUint8(12, 0x66);
  byteData.setUint8(13, 0x6D);
  byteData.setUint8(14, 0x74);
  byteData.setUint8(15, 0x20);
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little);
  byteData.setUint16(22, 1, Endian.little);
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * 2, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);
  byteData.setUint8(36, 0x64);
  byteData.setUint8(37, 0x61);
  byteData.setUint8(38, 0x74);
  byteData.setUint8(39, 0x61);
  byteData.setUint32(40, numSamples * 2, Endian.little);

  for (int i = 0; i < numSamples; i++) {
    final normalized = (floatSamples[i] * gain).clamp(-1.0, 1.0);
    final pcm16 = (normalized * 32767.0).round().clamp(-32768, 32767);
    byteData.setInt16(44 + i * 2, pcm16, Endian.little);
  }

  file.writeAsBytesSync(byteData.buffer.asUint8List());
}
