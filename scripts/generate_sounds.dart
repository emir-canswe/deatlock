// Synthesizes high-quality, rich click, slide, and win sound effects as standard 8-bit mono PCM WAV files.
// Run with: dart run scripts/generate_sounds.dart

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final outputDir = Directory('assets/sounds');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  generateClick(File('assets/sounds/click.wav'));
  generateSlide(File('assets/sounds/slide.wav'));
  generateWin(File('assets/sounds/win.wav'));

  print('High-quality sound assets generated successfully in assets/sounds/');
}

void writeWav(File file, List<int> samples, int sampleRate) {
  final byteData = ByteData(44 + samples.length);

  // RIFF Header
  byteData.setUint8(0, 0x52); // R
  byteData.setUint8(1, 0x49); // I
  byteData.setUint8(2, 0x46); // F
  byteData.setUint8(3, 0x46); // F

  // ChunkSize (file size minus 8 bytes)
  byteData.setUint32(4, 36 + samples.length, Endian.little);

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

  // Subchunk1Size (16 for PCM)
  byteData.setUint32(16, 16, Endian.little);

  // AudioFormat (1 for PCM)
  byteData.setUint16(20, 1, Endian.little);

  // NumChannels (1 for mono)
  byteData.setUint16(22, 1, Endian.little);

  // SampleRate
  byteData.setUint32(24, sampleRate, Endian.little);

  // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
  byteData.setUint32(28, sampleRate, Endian.little);

  // BlockAlign (NumChannels * BitsPerSample/8)
  byteData.setUint16(32, 1, Endian.little);

  // BitsPerSample (8 bits)
  byteData.setUint16(34, 8, Endian.little);

  // Subchunk2ID: "data"
  byteData.setUint8(36, 0x64); // d
  byteData.setUint8(37, 0x61); // a
  byteData.setUint8(38, 0x74); // t
  byteData.setUint8(39, 0x61); // a

  // Subchunk2Size (NumSamples * NumChannels * BitsPerSample/8)
  byteData.setUint32(40, samples.length, Endian.little);

  // Write raw samples (8-bit values are unsigned: 0 to 255, center is 128)
  for (int i = 0; i < samples.length; i++) {
    byteData.setUint8(44 + i, samples[i]);
  }

  file.writeAsBytesSync(byteData.buffer.asUint8List());
}

/// A short, warm, pleasant tap sound (pop)
void generateClick(File file) {
  const sampleRate = 11025;
  const duration = 0.05; // 50ms
  final numSamples = (sampleRate * duration).toInt();
  final samples = List<int>.filled(numSamples, 128);

  const freq = 523.25; // C5 note: warmer than raw 600Hz beep
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final envelope = math.exp(-35.0 * t); // slightly softer decay
    final wave = math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t); // add light warm harmonic
    samples[i] = (128 + 90 * wave * envelope).toInt().clamp(0, 255);
  }

  writeWav(file, samples, sampleRate);
}

/// Soft sliding sound: sweeps down smoothly with warm sine/cosine mix to make it less harsh
void generateSlide(File file) {
  const sampleRate = 11025;
  const duration = 0.18; // 180ms
  final numSamples = (sampleRate * duration).toInt();
  final samples = List<int>.filled(numSamples, 128);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    // Frequency sweeps from 180Hz down to 90Hz (softer range)
    final progress = t / duration;
    final freq = 180.0 - 90.0 * progress;
    
    // Envelope swells up quickly then dies down slowly
    final envelope = math.sin(progress * math.pi) * math.exp(-2.5 * progress);
    
    final phase = 2.0 * math.pi * (180.0 * t - 0.5 * 90.0 * t * t / duration);
    // Double oscillator mix (sine + subharmonic sine) for richer, deeper "slide" woosh
    final wave = math.sin(phase) + 0.4 * math.sin(phase * 0.5);
    
    samples[i] = (128 + 80 * wave * envelope).toInt().clamp(0, 255);
  }

  writeWav(file, samples, sampleRate);
}

/// Win chord: Luxury C-Major7 chord (C5, E5, G5, B5, C6) with rich spatial chorus,
/// clean chime decay, and soft fade-in pad to feel extremely satisfying.
void generateWin(File file) {
  const sampleRate = 11025;
  const duration = 1.3; // 1.3 seconds for a longer, richer decay
  final numSamples = (sampleRate * duration).toInt();
  final samples = List<int>.filled(numSamples, 128);

  // Notes: C5(523.25), E5(659.25), G5(783.99), B5(987.77), C6(1046.50), G6(1567.98)
  final freqs = [523.25, 659.25, 783.99, 987.77, 1046.50, 1567.98];
  // Smooth staggered entry to build a gorgeous upward chord swell
  final startTimes = [0.0, 0.06, 0.12, 0.18, 0.24, 0.30];

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    double mix = 0.0;

    for (int n = 0; n < 6; n++) {
      if (t >= startTimes[n]) {
        final tNote = t - startTimes[n];
        // Softer exponential decay for a lush pad chime feeling
        final envelope = math.exp(-2.0 * tNote);
        
        // Multi-oscillator harmonic mix per note (sine + soft triangle/cos blend for warm luxury texture)
        final sine = math.sin(2.0 * math.pi * freqs[n] * tNote);
        final overtone = 0.25 * math.sin(4.0 * math.pi * freqs[n] * tNote);
        final noteWave = sine + overtone;
        
        mix += noteWave * envelope * 0.18;
      }
    }

    // Smooth overall fade out to prevent clicking at the end of audio
    final overallEnvelope = math.exp(-0.6 * t) * (1.0 - math.exp(-12.0 * t));
    samples[i] = (128 + 110 * mix * overallEnvelope).toInt().clamp(0, 255);
  }

  writeWav(file, samples, sampleRate);
}
