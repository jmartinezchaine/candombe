import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final outDir = Directory('assets/audio');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  // ==========================================
  // 1. GENERAR KIT SINTÉTICO BÁSICO (ORIGINAL)
  // ==========================================
  final basicSuffix = '_basic';
  writeWav(File('${outDir.path}/madera$basicSuffix.wav'), generateSine(frequency: 900, durationMs: 100, volume: 0.6, decay: 45.0));
  writeWav(File('${outDir.path}/madera_accent$basicSuffix.wav'), generateSine(frequency: 1000, durationMs: 100, volume: 0.9, decay: 35.0));
  writeWav(File('${outDir.path}/chico_mano$basicSuffix.wav'), generatePercussion(startFreq: 480, endFreq: 440, durationMs: 40, volume: 0.65, noiseMix: 0.25));
  writeWav(File('${outDir.path}/chico_palo$basicSuffix.wav'), generatePercussion(startFreq: 340, endFreq: 240, durationMs: 150, volume: 0.95, noiseMix: 0.28));
  
  // Repique básico (no estaba en original, generado como sweeps coherentes)
  writeWav(File('${outDir.path}/repique_mano$basicSuffix.wav'), generatePercussion(startFreq: 180, endFreq: 140, durationMs: 160, volume: 0.7, noiseMix: 0.15));
  writeWav(File('${outDir.path}/repique_palo$basicSuffix.wav'), generatePercussion(startFreq: 280, endFreq: 200, durationMs: 150, volume: 0.85, noiseMix: 0.25));
  writeWav(File('${outDir.path}/repique_tapado$basicSuffix.wav'), generatePercussion(startFreq: 350, endFreq: 300, durationMs: 80, volume: 0.8, noiseMix: 0.35));

  writeWav(File('${outDir.path}/piano_mano$basicSuffix.wav'), generatePercussion(startFreq: 80, endFreq: 60, durationMs: 120, volume: 0.6, noiseMix: 0.03));
  writeWav(File('${outDir.path}/piano_palo$basicSuffix.wav'), generatePercussion(startFreq: 90, endFreq: 55, durationMs: 420, volume: 0.9, noiseMix: 0.10));
  writeWav(File('${outDir.path}/piano_palo_acento$basicSuffix.wav'), generatePercussion(startFreq: 95, endFreq: 50, durationMs: 480, volume: 0.98, noiseMix: 0.12));
  writeWav(File('${outDir.path}/piano_apagado$basicSuffix.wav'), generatePercussion(startFreq: 85, endFreq: 65, durationMs: 120, volume: 0.75, noiseMix: 0.10));

  // ==========================================
  // 2. GENERAR KIT MODELADO FÍSICO BRILLANTE
  // ==========================================
  final brightSuffix = '_bright';
  writeWav(File('${outDir.path}/madera$brightSuffix.wav'), generateMadera(accented: false, dry: false));
  writeWav(File('${outDir.path}/madera_accent$brightSuffix.wav'), generateMadera(accented: true, dry: false));
  writeWav(File('${outDir.path}/chico_mano$brightSuffix.wav'), generateChicoMano(dry: false));
  writeWav(File('${outDir.path}/chico_palo$brightSuffix.wav'), generateChicoPalo(dry: false));
  writeWav(File('${outDir.path}/repique_mano$brightSuffix.wav'), generateRepiqueMano(dry: false));
  writeWav(File('${outDir.path}/repique_palo$brightSuffix.wav'), generateRepiquePalo(dry: false));
  writeWav(File('${outDir.path}/repique_tapado$brightSuffix.wav'), generateRepiqueTapado(dry: false));
  writeWav(File('${outDir.path}/piano_mano$brightSuffix.wav'), generatePianoMano(dry: false));
  writeWav(File('${outDir.path}/piano_palo$brightSuffix.wav'), generatePianoPalo(accented: false, dry: false));
  writeWav(File('${outDir.path}/piano_palo_acento$brightSuffix.wav'), generatePianoPalo(accented: true, dry: false));
  writeWav(File('${outDir.path}/piano_apagado$brightSuffix.wav'), generatePianoApagado(dry: false));

  // ==========================================
  // 3. GENERAR KIT MODELADO FÍSICO SECO (ANSINA)
  // ==========================================
  final drySuffix = '_dry';
  writeWav(File('${outDir.path}/madera$drySuffix.wav'), generateMadera(accented: false, dry: true));
  writeWav(File('${outDir.path}/madera_accent$drySuffix.wav'), generateMadera(accented: true, dry: true));
  writeWav(File('${outDir.path}/chico_mano$drySuffix.wav'), generateChicoMano(dry: true));
  writeWav(File('${outDir.path}/chico_palo$drySuffix.wav'), generateChicoPalo(dry: true));
  writeWav(File('${outDir.path}/repique_mano$drySuffix.wav'), generateRepiqueMano(dry: true));
  writeWav(File('${outDir.path}/repique_palo$drySuffix.wav'), generateRepiquePalo(dry: true));
  writeWav(File('${outDir.path}/repique_tapado$drySuffix.wav'), generateRepiqueTapado(dry: true));
  writeWav(File('${outDir.path}/piano_mano$drySuffix.wav'), generatePianoMano(dry: true));
  writeWav(File('${outDir.path}/piano_palo$drySuffix.wav'), generatePianoPalo(accented: false, dry: true));
  writeWav(File('${outDir.path}/piano_palo_acento$drySuffix.wav'), generatePianoPalo(accented: true, dry: true));
  writeWav(File('${outDir.path}/piano_apagado$drySuffix.wav'), generatePianoApagado(dry: true));

  print('Todos los 33 archivos de audio de alta fidelidad se han generado en assets/audio/.');
}

// Función de Normalización para prevenir distorsión digital (Clipping)
List<double> normalize(List<double> samples, double targetVolume) {
  double peak = 0.0;
  for (final s in samples) {
    final absVal = s.abs();
    if (absVal > peak) peak = absVal;
  }
  if (peak == 0.0) return samples;
  final scale = targetVolume / peak;
  return List<double>.generate(samples.length, (i) => samples[i] * scale);
}

// Filtro de Paso Alto simple (RC filter equivalent)
List<double> highPass(List<double> input, double cutoffCoeff) {
  final output = List<double>.filled(input.length, 0.0);
  double prevInput = 0.0;
  double prevOutput = 0.0;
  for (int i = 0; i < input.length; i++) {
    output[i] = input[i] - prevInput + prevOutput * cutoffCoeff;
    prevInput = input[i];
    prevOutput = output[i];
  }
  return output;
}

// Filtro de Paso Bajo simple
List<double> lowPass(List<double> input, double alpha) {
  final output = List<double>.filled(input.length, 0.0);
  double prevOutput = 0.0;
  for (int i = 0; i < input.length; i++) {
    output[i] = input[i] * alpha + prevOutput * (1.0 - alpha);
    prevOutput = output[i];
  }
  return output;
}

// Genera ruido blanco
List<double> generateWhiteNoise(int length) {
  final rand = Random();
  return List<double>.generate(length, (_) => (rand.nextDouble() * 2.0) - 1.0);
}

// =========================================================================
// SINTETIZADORES BÁSICOS (Originales basados en barridos sinusoidales simples)
// =========================================================================

List<double> generateSine({
  required double frequency,
  required double durationMs,
  required double volume,
  required double decay,
}) {
  const sampleRate = 44100;
  final numSamples = (sampleRate * (durationMs / 1000.0)).round();
  final samples = List<double>.filled(numSamples, 0.0);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-decay * t);
    samples[i] = sin(2 * pi * frequency * t) * env * volume;
  }
  return normalize(samples, volume);
}

List<double> generatePercussion({
  required double startFreq,
  required double endFreq,
  required double durationMs,
  required double volume,
  required double noiseMix,
}) {
  const sampleRate = 44100;
  final numSamples = (sampleRate * (durationMs / 1000.0)).round();
  final samples = List<double>.filled(numSamples, 0.0);
  final rand = Random();

  // Caída exponencial de amplitud
  final decay = 5.0 / (durationMs / 1000.0);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = i / numSamples;
    
    // Barrido de frecuencia lineal
    final freq = startFreq + (endFreq - startFreq) * progress;
    final phase = 2 * pi * freq * t;
    
    final sineVal = sin(phase);
    final noiseVal = (rand.nextDouble() * 2.0) - 1.0;
    
    final env = exp(-decay * t);
    final mixedVal = sineVal * (1.0 - noiseMix) + noiseVal * noiseMix;
    
    samples[i] = mixedVal * env * volume;
  }
  return normalize(samples, volume);
}

// =========================================================================
// SINTETIZADORES DE MODELADO FÍSICO (BRILLANTE / SECO)
// =========================================================================

// 1. Madera (Clave): Sonido seco y leñoso
List<double> generateMadera({required bool accented, required bool dry}) {
  const sampleRate = 44100;
  final durationMs = accented ? (dry ? 80 : 90) : (dry ? 70 : 80);
  final numSamples = (sampleRate * (durationMs / 1000.0)).round();
  final samples = List<double>.filled(numSamples, 0.0);

  final freq0 = accented ? 1050.0 : 950.0;
  final freq1 = freq0 * 1.5;
  final freq2 = freq0 * 2.2;
  
  final decay = dry
      ? (accented ? 85.0 : 100.0)
      : (accented ? 75.0 : 90.0);
  final volume = accented ? 0.95 : 0.7;

  final noiseSamples = generateWhiteNoise(numSamples);
  final filteredNoise = highPass(noiseSamples, 0.85);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-decay * t);
    
    final osc = sin(2 * pi * freq0 * t) * 0.6 +
                sin(2 * pi * freq1 * t) * 0.3 +
                sin(2 * pi * freq2 * t) * 0.1;
                
    final noiseEnv = exp(-350.0 * t);
    final noiseComponent = filteredNoise[i] * noiseEnv * 0.45;
    
    samples[i] = (osc * env + noiseComponent) * volume;
  }
  return normalize(samples, volume);
}

// 2. Chico Mano (Toque sordo / tapado)
List<double> generateChicoMano({required bool dry}) {
  const sampleRate = 44100;
  final durationMs = dry ? 35 : 55; // Muy corto para que no resuene
  final numSamples = (sampleRate * (durationMs / 1000.0)).round();
  final samples = List<double>.filled(numSamples, 0.0);

  final freq0 = 480.0; // Afinación muy alta de chico (tambor agudo y tenso)
  final freq1 = freq0 * 1.6;
  final freq2 = freq0 * 2.5;
  
  final decay = dry ? 160.0 : 110.0; // Decay ultra rápido
  final volume = dry ? 0.65 : 0.75;

  final noiseSamples = generateWhiteNoise(numSamples);
  // Dejar pasar más brillo del golpe de mano (slap / tapado)
  final filteredNoise = lowPass(noiseSamples, dry ? 0.28 : 0.35); 

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-decay * t);
    
    // Mix armónico con presencia en agudos para evitar sonido sordo grave (sub-bass)
    final osc = dry
        ? (sin(2 * pi * freq0 * t) * 0.65 + sin(2 * pi * freq1 * t) * 0.25 + sin(2 * pi * freq2 * t) * 0.1)
        : (sin(2 * pi * freq0 * t) * 0.5 + sin(2 * pi * freq1 * t) * 0.35 + sin(2 * pi * freq2 * t) * 0.15);
                
    final noiseEnv = exp(dry ? -240.0 * t : -180.0 * t);
    final noiseComponent = filteredNoise[i] * noiseEnv * (dry ? 0.25 : 0.18);
    
    samples[i] = (osc * env + noiseComponent) * volume;
  }
  return normalize(samples, volume);
}

// Chico Palo (Golpe de palo con rimshot brillante y seco)
List<double> generateChicoPalo({required bool dry}) {
  const sampleRate = 44100;
  final durationMs = dry ? 75 : 90;
  final numSamples = (sampleRate * (durationMs / 1000.0)).round();
  final samples = List<double>.filled(numSamples, 0.0);

  final freq0 = 360.0;
  final freq1 = freq0 * 1.55;
  final freq2 = freq0 * 2.55;
  
  final decay = dry ? 70.0 : 55.0;
  final volume = 0.95;

  final noiseSamples = generateWhiteNoise(numSamples);
  final filteredNoise = highPass(noiseSamples, 0.9);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-decay * t);
    
    final osc = sin(2 * pi * freq0 * t) * 0.5 +
                sin(2 * pi * freq1 * t) * 0.35 +
                sin(2 * pi * freq2 * t) * 0.15;
                
    final clickEnv = exp(-400.0 * t);
    final click = sin(2 * pi * 1400.0 * t) * clickEnv * 0.45;
    final noiseComponent = filteredNoise[i] * clickEnv * 0.35;
    
    samples[i] = (osc * env + click + noiseComponent) * volume;
  }
  return normalize(samples, volume);
}

// 3. Repique Mano (Abierto medio con cuerpo)
List<double> generateRepiqueMano({required bool dry}) {
  const sampleRate = 44100;
  final durationMs = dry ? 110 : 150;
  final numSamples = (sampleRate * (durationMs / 1000.0)).round();
  final samples = List<double>.filled(numSamples, 0.0);

  final freq0 = 165.0;
  final freq1 = freq0 * 1.55;
  final freq2 = freq0 * 2.3;
  
  final decay = dry ? 40.0 : 28.0;
  final volume = 0.8;

  final noiseSamples = generateWhiteNoise(numSamples);
  final filteredNoise = lowPass(noiseSamples, 0.2);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-decay * t);
    
    final osc = sin(2 * pi * freq0 * t) * 0.75 +
                sin(2 * pi * freq1 * t) * 0.2 +
                sin(2 * pi * freq2 * t) * 0.05;
                
    final noiseEnv = exp(-100.0 * t);
    final noiseComponent = filteredNoise[i] * noiseEnv * 0.12;
    
    samples[i] = (osc * env + noiseComponent) * volume;
  }
  return normalize(samples, volume);
}

// Repique Palo (Golpe de palo medio, brillante y resonante)
List<double> generateRepiquePalo({required bool dry}) {
  const sampleRate = 44100;
  final durationMs = dry ? 95 : 120;
  final numSamples = (sampleRate * (durationMs / 1000.0)).round();
  final samples = List<double>.filled(numSamples, 0.0);

  final freq0 = 270.0;
  final freq1 = freq0 * 1.5;
  final freq2 = freq0 * 2.5;
  
  final decay = dry ? 60.0 : 40.0;
  final volume = 0.9;

  final noiseSamples = generateWhiteNoise(numSamples);
  final filteredNoise = highPass(noiseSamples, 0.88);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-decay * t);
    
    final osc = sin(2 * pi * freq0 * t) * 0.65 +
                sin(2 * pi * freq1 * t) * 0.25 +
                sin(2 * pi * freq2 * t) * 0.1;
                
    final clickEnv = exp(-300.0 * t);
    final click = sin(2 * pi * 1050.0 * t) * clickEnv * 0.35;
    final noiseComponent = filteredNoise[i] * clickEnv * 0.3;
    
    samples[i] = (osc * env + click + noiseComponent) * volume;
  }
  return normalize(samples, volume);
}

// Repique Tapado (Slap seco y agudo amortiguado con la mano)
List<double> generateRepiqueTapado({required bool dry}) {
  const sampleRate = 44100;
  final durationMs = dry ? 40 : 50;
  final numSamples = (sampleRate * (durationMs / 1000.0)).round();
  final samples = List<double>.filled(numSamples, 0.0);

  final freq0 = 420.0;
  final freq1 = freq0 * 1.52;
  final freq2 = freq0 * 2.38;
  
  final decay = dry ? 130.0 : 110.0;
  final volume = 0.95;

  final noiseSamples = generateWhiteNoise(numSamples);
  final highPassedNoise = highPass(noiseSamples, 0.85);
  final filteredNoise = lowPass(highPassedNoise, 0.6);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-decay * t);
    
    final osc = sin(2 * pi * freq0 * t) * 0.4 +
                sin(2 * pi * freq1 * t) * 0.35 +
                sin(2 * pi * freq2 * t) * 0.25;
                
    final noiseEnv = exp(-180.0 * t);
    final noiseComponent = filteredNoise[i] * noiseEnv * 0.55;
    
    samples[i] = (osc * env + noiseComponent) * volume;
  }
  return normalize(samples, volume);
}

// 4. Piano Mano (Sonido de graves profundos y cálidos - sutil y apagado)
List<double> generatePianoMano({required bool dry}) {
  const sampleRate = 44100;
  final durationMs = dry ? 180 : 220; // Más corto para apagar la longa
  final numSamples = (sampleRate * (durationMs / 1000.0)).round();
  final samples = List<double>.filled(numSamples, 0.0);

  final freq0 = dry ? 50.0 : 60.0; // Un toque más grave y profundo
  final freq1 = freq0 * 1.5;
  final freq2 = freq0 * 2.0;
  
  final decay = dry ? 25.0 : 20.0; // Caída rápida para apagar la resonancia
  final volume = 0.65; // Más sutil comparado al palo

  final noiseSamples = generateWhiteNoise(numSamples);
  final filteredNoise = lowPass(noiseSamples, 0.04); // Más suave / cálido

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-decay * t);
    
    final osc = sin(2 * pi * freq0 * t) * 0.85 +
                sin(2 * pi * freq1 * t) * 0.1 +
                sin(2 * pi * freq2 * t) * 0.05;
                
    final noiseEnv = exp(-60.0 * t);
    final noiseComponent = filteredNoise[i] * noiseEnv * 0.04;
    
    samples[i] = (osc * env + noiseComponent) * volume;
  }
  return normalize(samples, volume);
}

// Piano Palo (Golpe de palo abierto - resonancia larga y grave)
List<double> generatePianoPalo({required bool accented, required bool dry}) {
  const sampleRate = 44100;
  final durationMs = accented ? (dry ? 500 : 650) : (dry ? 450 : 550); // Más largo para sostener la resonancia
  final numSamples = (sampleRate * (durationMs / 1000.0)).round();
  final samples = List<double>.filled(numSamples, 0.0);

  final freq0 = dry ? 50.0 : 58.0; // Frecuencias más graves y llenas
  final freq1 = freq0 * 1.5;
  final freq2 = freq0 * 2.1;
  
  final decay = dry 
      ? (accented ? 8.0 : 10.0) // Sostenido pero controlado para el kit seco
      : (accented ? 4.5 : 5.5); // Sostenido largo y resonante para el kit brillante
  final volume = accented ? 0.98 : 0.78;

  final noiseSamples = generateWhiteNoise(numSamples);
  final filteredNoise = lowPass(noiseSamples, accented ? 0.18 : 0.12);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-decay * t);
    
    // Implementar pitch sweep (desplazamiento de frecuencia) para simular el estiramiento del parche al golpear fuerte
    final slideAmt = accented ? 22.0 : 10.0;
    final slideDecay = 45.0;
    final phase0 = 2 * pi * (freq0 * t - (slideAmt / slideDecay) * (exp(-slideDecay * t) - 1.0));
    final phase1 = 2 * pi * (freq1 * t - ((slideAmt * 1.5) / slideDecay) * (exp(-slideDecay * t) - 1.0));
    final phase2 = 2 * pi * (freq2 * t - ((slideAmt * 2.1) / slideDecay) * (exp(-slideDecay * t) - 1.0));

    final osc = sin(phase0) * 0.75 +
                sin(phase1) * 0.15 +
                sin(phase2) * 0.1;
                
    final clickDecay = accented ? 280.0 : 220.0; // Caída más rápida en el acento para evitar sonido agudo sostenido
    final clickEnv = exp(-clickDecay * t);
    final clickFreq = accented ? 420.0 : 480.0; // Click más grave y gordo en el acento (420Hz vs 480Hz)
    final click = sin(2 * pi * clickFreq * t) * clickEnv * (accented ? 0.45 : 0.22);
    final noiseComponent = filteredNoise[i] * clickEnv * (accented ? 0.15 : 0.10);
    
    samples[i] = (osc * env + click + noiseComponent) * volume;
  }
  return normalize(samples, volume);
}

// Piano Apagado (PA - Palo Apagado: sordo apagado pero con fuerza y corte rápido)
List<double> generatePianoApagado({required bool dry}) {
  const sampleRate = 44100;
  final durationMs = dry ? 110 : 130; // Un poco más largo para que la onda grave complete ciclos
  final numSamples = (sampleRate * (durationMs / 1000.0)).round();
  final samples = List<double>.filled(numSamples, 0.0);

  final freq0 = dry ? 52.0 : 65.0; // Más bajo/grave para evitar que suene agudo
  final freq1 = freq0 * 1.5;
  
  final decay = dry ? 35.0 : 30.0; // Caída rápida pero no instantánea para mantener el golpe grave (thump)
  final volume = 0.90;

  final noiseSamples = generateWhiteNoise(numSamples);
  final filteredNoise = lowPass(noiseSamples, 0.08); // Filtrar más los agudos del ruido

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = exp(-decay * t);
    
    final osc = sin(2 * pi * freq0 * t) * 0.8 +
                sin(2 * pi * freq1 * t) * 0.2;
                
    final noiseEnv = exp(-120.0 * t);
    final noiseComponent = filteredNoise[i] * noiseEnv * 0.15;
    
    final clickEnv = exp(-250.0 * t);
    final click = sin(2 * pi * 220.0 * t) * clickEnv * 0.20; // Click de palo más grave y sutil
    
    samples[i] = (osc * env + click + noiseComponent) * volume;
  }
  return normalize(samples, volume);
}

// Escribe los bytes estructurados en un archivo WAV PCM Mono de 16 bits y 44100 Hz
void writeWav(File file, List<double> samples) {
  const sampleRate = 44100;
  final byteData = ByteData(44 + samples.length * 2);

  // RIFF
  byteData.setUint8(0, 0x52); // R
  byteData.setUint8(1, 0x49); // I
  byteData.setUint8(2, 0x46); // F
  byteData.setUint8(3, 0x46); // F

  final fileSize = 36 + samples.length * 2;
  byteData.setUint32(4, fileSize, Endian.little);

  // WAVE
  byteData.setUint8(8, 0x57); // W
  byteData.setUint8(9, 0x41); // A
  byteData.setUint8(10, 0x56); // V
  byteData.setUint8(11, 0x45); // E

  // fmt 
  byteData.setUint8(12, 0x66); // f
  byteData.setUint8(13, 0x6d); // m
  byteData.setUint8(14, 0x74); // t
  byteData.setUint8(15, 0x20); // ' '

  byteData.setUint32(16, 16, Endian.little); // Tamaño subchunk
  byteData.setUint16(20, 1, Endian.little); // PCM
  byteData.setUint16(22, 1, Endian.little); // Canales: Mono
  byteData.setUint32(24, sampleRate, Endian.little); // Frecuencia de muestreo
  byteData.setUint32(28, sampleRate * 2, Endian.little); // Byte rate
  byteData.setUint16(32, 2, Endian.little); // Block align
  byteData.setUint16(34, 16, Endian.little); // 16 bits

  // data
  byteData.setUint8(36, 0x64); // d
  byteData.setUint8(37, 0x61); // a
  byteData.setUint8(38, 0x74); // t
  byteData.setUint8(39, 0x61); // a

  final subchunk2Size = samples.length * 2;
  byteData.setUint32(40, subchunk2Size, Endian.little);

  // Escribir muestras en formato PCM
  int offset = 44;
  for (final sample in samples) {
    final clamped = sample.clamp(-1.0, 1.0);
    final pcmVal = (clamped * 32767.0).round();
    byteData.setInt16(offset, pcmVal, Endian.little);
    offset += 2;
  }

  file.writeAsBytesSync(byteData.buffer.asUint8List());
}
