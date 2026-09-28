// Synthesizes studio-grade, 16-bit 44.1kHz mono PCM WAV sound effects:
// 1. click.wav: Crisp, tactile bubble/mechanical switch tap (Nintendo Switch / iOS style)
// 2. slide.wav: Deep, juicy tactile wooden/neon block "thock" glide with warm acoustic resonance
// 3. win.wav: Triumphant, uplifting, crystal glockenspiel / bell arpeggio fanfare with lush shimmer
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

  print('Synthesizing studio-grade 16-bit 44.1kHz audio assets...');
  generateClick(File('assets/sounds/click.wav'));
  generateSlide(File('assets/sounds/slide.wav'));
  generateWin(File('assets/sounds/win.wav'));

  print('All sound assets generated successfully in assets/sounds/ (16-bit, 44,100 Hz PCM)!');
}

/// Writes standard 16-bit signed PCM mono WAV file at 44.1kHz.
/// Normalizes peak amplitude to prevent digital clipping while maximizing loudness and punch.
void writeWav16(File file, List<double> floatSamples, int sampleRate) {
  // 1. Find peak for smart normalization
  double maxAmp = 0.0;
  for (final s in floatSamples) {
    final abs = s.abs();
    if (abs > maxAmp) maxAmp = abs;
  }

  final double gain = maxAmp > 0.0 ? (0.92 / maxAmp) : 1.0;

  final numSamples = floatSamples.length;
  final byteData = ByteData(44 + numSamples * 2);

  // RIFF Header
  byteData.setUint8(0, 0x52); // R
  byteData.setUint8(1, 0x49); // I
  byteData.setUint8(2, 0x46); // F
  byteData.setUint8(3, 0x46); // F

  // ChunkSize (file size minus 8 bytes: 36 + subchunk2size)
  byteData.setUint32(4, 36 + numSamples * 2, Endian.little);

  // WAVE Format
  byteData.setUint8(8, 0x57);  // W
  byteData.setUint8(9, 0x41);  // A
  byteData.setUint8(10, 0x56); // V
  byteData.setUint8(11, 0x45); // E

  // Subchunk1ID: "fmt "
  byteData.setUint8(12, 0x66); // f
  byteData.setUint8(13, 0x6D); // m
  byteData.setUint8(14, 0x74); // t
  byteData.setUint8(15, 0x20); // space

  // Subchunk1Size: 16 for PCM
  byteData.setUint32(16, 16, Endian.little);

  // AudioFormat: 1 (PCM)
  byteData.setUint16(20, 1, Endian.little);

  // NumChannels: 1 (Mono)
  byteData.setUint16(22, 1, Endian.little);

  // SampleRate (44100 Hz)
  byteData.setUint32(24, sampleRate, Endian.little);

  // ByteRate = SampleRate * NumChannels * BitsPerSample / 8 = 44100 * 1 * 16 / 8 = 88200
  byteData.setUint32(28, sampleRate * 2, Endian.little);

  // BlockAlign = NumChannels * BitsPerSample / 8 = 1 * 16 / 8 = 2
  byteData.setUint16(32, 2, Endian.little);

  // BitsPerSample = 16
  byteData.setUint16(34, 16, Endian.little);

  // Subchunk2ID: "data"
  byteData.setUint8(36, 0x64); // d
  byteData.setUint8(37, 0x61); // a
  byteData.setUint8(38, 0x74); // t
  byteData.setUint8(39, 0x61); // a

  // Subchunk2Size: numSamples * 2
  byteData.setUint32(40, numSamples * 2, Endian.little);

  // Write signed 16-bit PCM samples (-32768 to 32767) in Little Endian
  for (int i = 0; i < numSamples; i++) {
    final normalized = (floatSamples[i] * gain).clamp(-1.0, 1.0);
    final pcm16 = (normalized * 32767.0).round().clamp(-32768, 32767);
    byteData.setInt16(44 + i * 2, pcm16, Endian.little);
  }

  file.writeAsBytesSync(byteData.buffer.asUint8List());
}

/// Ultra-crisp, satisfying tactile bubble / mechanical switch tap (Nintendo Switch / iOS style)
/// Duration: ~38ms at 44.1kHz
void generateClick(File file) {
  const sampleRate = 44100;
  const duration = 0.038;
  final numSamples = (sampleRate * duration).toInt();
  final samples = List<double>.filled(numSamples, 0.0);

  final rand = math.Random(42);
  double phase = 0.0;

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;

    // 1. Initial micro-transient snap (first 2.5ms) - gives the physical "click" feeling
    final noiseTransient = (rand.nextDouble() * 2.0 - 1.0) * math.exp(-t / 0.002);

    // 2. Resonant tonal body: drops quickly from 1350Hz down to 520Hz (tactile pop)
    final freq = 520.0 + 830.0 * math.exp(-t / 0.006);
    phase += 2.0 * math.pi * freq / sampleRate;

    // Harmonic blend: pure sine + warm first overtone + gentle sub
    final tone = math.sin(phase) + 0.32 * math.sin(phase * 2.0) + 0.12 * math.sin(phase * 0.5);

    // 3. Ultra-fast snappy envelope (0.6ms attack, 12ms decay)
    final attack = 1.0 - math.exp(-t / 0.0006);
    final decay = math.exp(-t / 0.010);
    final envelope = attack * decay;

    samples[i] = (0.28 * noiseTransient + 0.85 * tone) * envelope;
  }

  writeWav16(file, samples, sampleRate);
}

/// Premium smooth block slide: silky plastic-on-surface glide with satisfying magnetic snap-lock
/// Inspired by high-end sliding puzzle sounds (Monument Valley / Alto's Odyssey style)
/// Duration: ~90ms — short enough to chain rapidly, rich enough to feel premium
void generateSlide(File file) {
  const sampleRate = 44100;
  const duration = 0.090;
  final numSamples = (sampleRate * duration).toInt();
  final samples = List<double>.filled(numSamples, 0.0);

  final rand = math.Random(9999);
  double lowPassNoise = 0.0;
  double highPassNoise = 0.0;
  double prevRaw = 0.0;

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final rawNoise = rand.nextDouble() * 2.0 - 1.0;

    // ── 1. Silky glide layer ─────────────────────────────────────────
    // Low-pass filtered white noise: simulates smooth surface friction (plastic/glass glide)
    lowPassNoise += (rawNoise - lowPassNoise) * 0.08;
    // High-pass filtered noise: adds a subtle bright "swoosh" presence
    highPassNoise = rawNoise - prevRaw + 0.92 * highPassNoise;
    prevRaw = rawNoise;

    // Glide envelope: fast 1ms ramp-up → sustain → gentle tail
    final glideEnv = (1.0 - math.exp(-t / 0.001)) * math.exp(-t / 0.028);
    final glide = (0.65 * lowPassNoise + 0.18 * highPassNoise) * glideEnv;

    // ── 2. Tonal body: deep resonant "thock" ──────────────────────────
    // Sweeps from 600Hz → 380Hz as block travels and settles
    // This range (D5-G5) cuts through tiny phone speakers beautifully
    final sweepFreq = 380.0 + 220.0 * math.exp(-t / 0.012);
    // Slightly detuned second layer for richness (chorus-like width)
    final sweepFreq2 = sweepFreq * 1.008;

    final phase1 = 2.0 * math.pi * sweepFreq * t;
    final phase2 = 2.0 * math.pi * sweepFreq2 * t;

    // Pure fundamental + warm octave + 5th harmonic sparkle
    final body = math.sin(phase1)
        + 0.38 * math.sin(phase1 * 2.0)   // octave warmth
        + 0.08 * math.sin(phase1 * 3.0)   // 5th harmonic sparkle
        + 0.15 * math.sin(phase2);         // slight detuned chorus

    // Body envelope: punchy 1ms attack, 22ms warm decay
    final bodyEnv = (1.0 - math.exp(-t / 0.001)) * math.exp(-t / 0.018);

    // ── 3. Magnetic snap-lock "click" at end of slide ────────────────
    // Fires at ~50ms — the satisfying "clunk" as block locks into grid slot
    double snapLock = 0.0;
    if (t > 0.046) {
      final ts = t - 0.046;
      // Quick pitch-drop snap (680Hz → 420Hz) simulating piece landing in slot
      final snapFreq = 420.0 + 260.0 * math.exp(-ts / 0.004);
      final snapPhase = 2.0 * math.pi * snapFreq * ts;
      final snap = math.sin(snapPhase) + 0.3 * math.sin(snapPhase * 2.1);
      snapLock = snap * math.exp(-ts / 0.010) * 0.60;
    }

    // ── 4. Mix with balanced levels ──────────────────────────────────
    samples[i] = (0.22 * glide)
               + (0.80 * body * bodyEnv)
               + snapLock;
  }

  writeWav16(file, samples, sampleRate);
}

/// Triumphant, uplifting, crystal glockenspiel / bell arpeggio fanfare with lush shimmer
/// Duration: 2.3 seconds at 44.1kHz
void generateWin(File file) {
  const sampleRate = 44100;
  const duration = 2.3;
  final numSamples = (sampleRate * duration).toInt();
  final samples = List<double>.filled(numSamples, 0.0);

  // Cascading ascending crystal chime notes:
  // C5 (523.25), E5 (659.25), G5 (783.99), B5 (987.77), D6 (1174.66), E6 (1318.51), G6 (1567.98)
  // Followed by celebratory sustained chord: C6 (1046.50), E6 (1318.51), G6 (1567.98), C7 (2093.00)
  final arpeggioFreqs = [523.25, 659.25, 783.99, 987.77, 1174.66, 1318.51, 1567.98];
  final arpeggioTimes = [0.00,   0.065,  0.130,  0.195,  0.260,   0.325,   0.390];

  final chordFreqs = [1046.50, 1318.51, 1567.98, 2093.00];
  const chordTime = 0.48;

  // Single crystalline bell voice generator with realistic physical bell overtones
  double bellVoice(double freq, double tNote, double decayRate) {
    if (tNote < 0.0) return 0.0;
    // Bell attack: instantaneous smooth 1.5ms ramp-up
    final attack = math.min(1.0, tNote / 0.0015);
    
    // Fundamental tone
    final f0 = math.sin(2.0 * math.pi * freq * tNote) * math.exp(-decayRate * tNote);
    // Crystalline inharmonic bell overtones (2.76x and 5.40x decay much faster than fundamental)
    final overtone1 = 0.32 * math.sin(2.0 * math.pi * freq * 2.76 * tNote) * math.exp(-(decayRate * 2.8) * tNote);
    final overtone2 = 0.14 * math.sin(2.0 * math.pi * freq * 5.40 * tNote) * math.exp(-(decayRate * 4.5) * tNote);
    // Warm octave overtone
    final octave = 0.18 * math.sin(2.0 * math.pi * freq * 2.0 * tNote) * math.exp(-(decayRate * 1.5) * tNote);

    return (f0 + overtone1 + overtone2 + octave) * attack;
  }

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    double mix = 0.0;

    // 1. Arpeggio notes
    for (int n = 0; n < arpeggioFreqs.length; n++) {
      final tNote = t - arpeggioTimes[n];
      if (tNote >= 0.0) {
        mix += bellVoice(arpeggioFreqs[n], tNote, 3.2) * 0.22;
      }
    }

    // 2. Final triumphant chord strike (longer ring-out)
    if (t >= chordTime) {
      final tChord = t - chordTime;
      for (final freq in chordFreqs) {
        mix += bellVoice(freq, tChord, 1.6) * 0.24;
      }
    }

    // 3. Warm celestial acoustic pad underneath (fades in gently, supporting the chime arpeggio)
    if (t >= 0.12) {
      final tPad = t - 0.12;
      // Pad envelope: swell up over 0.4s, then gentle warm decay
      final padEnv = math.sin(math.min(math.pi * 0.5, tPad / 0.4)) * math.exp(-1.1 * tPad);
      // C major triad in octave 3 & 4 (C3, G3, C4, E4) with subtle chorus detune
      final chorus = math.sin(2.0 * math.pi * 2.0 * tPad) * 0.8;
      final padWave = math.sin(2.0 * math.pi * (130.81 + chorus) * tPad) * 0.4 +
                      math.sin(2.0 * math.pi * 196.00 * tPad) * 0.35 +
                      math.sin(2.0 * math.pi * 261.63 * tPad) * 0.3 +
                      math.sin(2.0 * math.pi * 329.63 * tPad) * 0.25;
      mix += padWave * padEnv * 0.18;
    }

    // Smooth master decay at the very end to avoid any abrupt edge
    final masterFade = t < 2.0 ? 1.0 : (2.3 - t) / 0.3;
    samples[i] = mix * math.max(0.0, masterFade);
  }

  writeWav16(file, samples, sampleRate);
}
