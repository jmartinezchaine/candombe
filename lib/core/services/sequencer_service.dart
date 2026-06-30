import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_service.dart';
import '../../features/candombe_sequencer/data/models/candombe_pattern.dart';

class SequencerService extends ChangeNotifier {
  static final SequencerService _instance = SequencerService._internal();
  factory SequencerService() => _instance;
  SequencerService._internal();

  final AudioService _audioService = AudioService();

  Timer? _timer;
  Stopwatch? _stopwatch;
  int _ticksCount = 0;
  int _lastTickElapsedUs = 0;

  int get stepDurationMicroseconds => (15000000 / _bpm).round();

  double get fractionalProgress {
    if (!_isPlaying || _stopwatch == null) return 0.0;
    final duration = stepDurationMicroseconds;
    final elapsedUs = _stopwatch!.elapsedMicroseconds;
    final elapsedSinceTick = elapsedUs - _lastTickElapsedUs;
    return (elapsedSinceTick / duration).clamp(0.0, 1.0);
  }
  
  // Estado de reproducción
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  int _bpm = 90;
  int get bpm => _bpm;

  int _currentStep = 0;
  int get currentStep => _currentStep;

  // Patrón rítmico actual
  late CandombePattern _pattern;
  CandombePattern get pattern => _pattern;

  // Lista de patrones guardados
  List<CandombePattern> _savedPatterns = [];
  List<CandombePattern> get savedPatterns => _savedPatterns;

  SoundKit _soundKit = SoundKit.dry;
  SoundKit get soundKit => _soundKit;

  // Seguimiento de repetición y compás de reproducción activo por instrumento
  final Map<InstrumentType, InstrumentPlaybackState> _playbackStates = {
    InstrumentType.madera: InstrumentPlaybackState(),
    InstrumentType.chico: InstrumentPlaybackState(),
    InstrumentType.repique: InstrumentPlaybackState(),
    InstrumentType.piano: InstrumentPlaybackState(),
  };
  Map<InstrumentType, InstrumentPlaybackState> get playbackStates => _playbackStates;

  // Índice del compás que se está editando en la UI por instrumento
  final Map<InstrumentType, int> _selectedEditMeasureIndices = {
    InstrumentType.madera: 0,
    InstrumentType.chico: 0,
    InstrumentType.repique: 0,
    InstrumentType.piano: 0,
  };

  int getSelectedEditMeasureIndex(InstrumentType type) => _selectedEditMeasureIndices[type] ?? 0;

  void setSelectedEditMeasureIndex(InstrumentType type, int index) {
    _selectedEditMeasureIndices[type] = index;
    notifyListeners();
  }

  // Inicialización
  Future<void> init() async {
    _pattern = CandombePattern.ansinaDefault();
    await loadSavedPatterns();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKitIndex = prefs.getInt('selected_sound_kit');
      if (savedKitIndex != null && savedKitIndex >= 0 && savedKitIndex < SoundKit.values.length) {
        _soundKit = SoundKit.values[savedKitIndex];
      }
    } catch (e) {
      debugPrint('Error al cargar el kit de sonido: $e');
    }

    notifyListeners();
  }

  void setSoundKit(SoundKit kit) async {
    _soundKit = kit;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_sound_kit', kit.index);
    } catch (e) {
      debugPrint('Error al guardar el kit de sonido: $e');
    }
  }

  // Activa / Desactiva la reproducción
  void togglePlay() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    if (_isPlaying) return;
    _isPlaying = true;
    _playbackStates.forEach((_, state) => state.reset());
    _currentStep = 0;
    _ticksCount = 0;
    _stopwatch = Stopwatch()..start();
    _lastTickElapsedUs = 0;
    _playCurrentStep();
    _scheduleNextTick();
    notifyListeners();
  }

  void pause() {
    if (!_isPlaying) return;
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
    _stopwatch?.stop();
    notifyListeners();
  }

  void stop() {
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
    _stopwatch?.stop();
    _stopwatch = null;
    _currentStep = 0;
    _playbackStates.forEach((_, state) => state.reset());
    notifyListeners();
  }

  // Cambia los BPM
  void setBpm(int newBpm) {
    if (newBpm < 40 || newBpm > 200) return;
    _bpm = newBpm;
    notifyListeners();

    // Si está reproduciendo, reiniciar el timer con el nuevo intervalo
    if (_isPlaying) {
      _timer?.cancel();
      _ticksCount = 0;
      _stopwatch?.reset();
      _stopwatch?.start();
      _scheduleNextTick();
    }
  }

  // Reinicia al patrón base Ansina
  void resetToDefault() {
    final wasPlaying = _isPlaying;
    stop();
    _pattern = CandombePattern.ansinaDefault();
    _currentStep = 0;
    _selectedEditMeasureIndices.updateAll((key, value) => 0);
    notifyListeners();
    if (wasPlaying) {
      play();
    }
  }

  // Alterna el Mute de un instrumento
  void toggleMute(InstrumentType type) {
    final instPattern = _pattern.instrumentPatterns[type];
    if (instPattern != null) {
      instPattern.isMuted = !instPattern.isMuted;
      
      // Si se mutea, desactivar solo si estaba activo
      if (instPattern.isMuted) {
        instPattern.isSoloed = false;
      }
      notifyListeners();
    }
  }

  // Alterna el Solo de un instrumento
  void toggleSolo(InstrumentType type) {
    final instPattern = _pattern.instrumentPatterns[type];
    if (instPattern != null) {
      instPattern.isSoloed = !instPattern.isSoloed;
      
      // Si se activa Solo, quitar Mute
      if (instPattern.isSoloed) {
        instPattern.isMuted = false;
      }

      // Si hay al menos un instrumento en Solo, debemos asegurarnos de que la lógica lo respete
      notifyListeners();
    }
  }

  // Establece el volumen de un instrumento (pista)
  void setVolume(InstrumentType type, double value) {
    final instPattern = _pattern.instrumentPatterns[type];
    if (instPattern != null) {
      instPattern.volume = value.clamp(0.0, 1.0);
      notifyListeners();
    }
  }

  // Cambia cíclicamente el tipo de golpe en una celda
  void cycleHit(InstrumentType instrument, int stepIndex) {
    final instPattern = _pattern.instrumentPatterns[instrument];
    if (instPattern == null) return;

    final editIndex = getSelectedEditMeasureIndex(instrument);
    if (editIndex >= instPattern.measures.length) return;

    final activeMeasure = instPattern.measures[editIndex];
    final currentHit = activeMeasure.steps[stepIndex];
    final nextHit = _getNextHitType(instrument, currentHit);
    
    activeMeasure.steps[stepIndex] = nextHit;
    notifyListeners();
  }

  // Define el ciclo lógico de golpes por instrumento
  HitType _getNextHitType(InstrumentType instrument, HitType current) {
    switch (instrument) {
      case InstrumentType.madera:
        // Ciclo: Madera -> Madera Acentuada -> Silencio
        switch (current) {
          case HitType.silencio:
            return HitType.madera;
          case HitType.madera:
            return HitType.maderaAcento;
          default:
            return HitType.silencio;
        }

      case InstrumentType.chico:
        // Ciclo: Mano Acentuada -> Palo -> Silencio
        switch (current) {
          case HitType.silencio:
            return HitType.manoAcento;
          case HitType.manoAcento:
            return HitType.palo;
          default:
            return HitType.silencio;
        }

      case InstrumentType.repique:
        // Ciclo: Mano -> Mano Tapada -> Palo -> Silencio
        switch (current) {
          case HitType.silencio:
            return HitType.mano;
          case HitType.mano:
            return HitType.manoTapada;
          case HitType.manoTapada:
            return HitType.palo;
          default:
            return HitType.silencio;
        }

      case InstrumentType.piano:
        // Ciclo: Mano -> Mano Acentuada -> Palo -> Palo Acentuado -> Palo Apagado -> Silencio
        switch (current) {
          case HitType.silencio:
            return HitType.mano;
          case HitType.mano:
            return HitType.manoAcento;
          case HitType.manoAcento:
            return HitType.palo;
          case HitType.palo:
            return HitType.paloAcento;
          case HitType.paloAcento:
            return HitType.paloApagado;
          default:
            return HitType.silencio;
        }
    }
  }

  // Gestión de Compases (Measures) por Tambor
  void addMeasure(InstrumentType type) {
    final instPattern = _pattern.instrumentPatterns[type];
    if (instPattern == null) return;
    if (instPattern.measures.length >= 6) return; // Máximo 6 compases

    final lastMeasure = instPattern.measures.last;
    final newMeasure = CandombeMeasure(
      steps: List.from(lastMeasure.steps),
      repeatCount: 1,
    );

    instPattern.measures.add(newMeasure);
    _selectedEditMeasureIndices[type] = instPattern.measures.length - 1;
    notifyListeners();
  }

  void removeMeasure(InstrumentType type, int index) {
    final instPattern = _pattern.instrumentPatterns[type];
    if (instPattern == null) return;
    if (instPattern.measures.length <= 1) return;
    if (index >= instPattern.measures.length) return;

    instPattern.measures.removeAt(index);
    
    final currentEditIndex = getSelectedEditMeasureIndex(type);
    if (currentEditIndex >= instPattern.measures.length) {
      _selectedEditMeasureIndices[type] = instPattern.measures.length - 1;
    }

    final playbackState = _playbackStates[type];
    if (playbackState != null && playbackState.currentMeasureIndex >= instPattern.measures.length) {
      playbackState.reset();
    }

    notifyListeners();
  }

  void setMeasureRepetitions(InstrumentType type, int index, int repeats) {
    final instPattern = _pattern.instrumentPatterns[type];
    if (instPattern == null) return;
    if (index >= instPattern.measures.length) return;

    instPattern.measures[index].repeatCount = repeats.clamp(1, 8);
    notifyListeners();
  }

  // Planificador auto-corrector drift-free
  void _scheduleNextTick() {
    if (!_isPlaying) return;

    final stepDuration = stepDurationMicroseconds;
    _ticksCount++;

    final nextTheoreticalTimeUs = _ticksCount * stepDuration;
    final elapsedUs = _stopwatch!.elapsedMicroseconds;

    int delayUs = nextTheoreticalTimeUs - elapsedUs;
    if (delayUs < 0) {
      delayUs = 0;
    }

    _timer = Timer(Duration(microseconds: delayUs), _onTickCallback);
  }

  void _onTickCallback() {
    if (!_isPlaying) return;
    _tick();
    _scheduleNextTick();
  }

  // Dispara los golpes correspondientes al paso actual
  void _playCurrentStep() {
    final hasSolo = _pattern.instrumentPatterns.values.any((p) => p.isSoloed);

    _pattern.instrumentPatterns.forEach((type, instPattern) {
      if (instPattern.isMuted) return;
      if (hasSolo && !instPattern.isSoloed) return;

      final playbackState = _playbackStates[type];
      final measureIndex = playbackState?.currentMeasureIndex ?? 0;
      final activeMeasure = instPattern.measures[measureIndex < instPattern.measures.length ? measureIndex : 0];

      final hit = activeMeasure.steps[_currentStep];
      if (hit != HitType.silencio) {
        final (asset, volume) = type.getAssetForHit(hit, _soundKit);
        if (asset.isNotEmpty) {
          final finalVolume = volume * instPattern.volume;
          _audioService.playSample(asset, volume: finalVolume);
        }
      }
    });
  }

  // Ejecución en cada subdivisión (semicorchea)
  void _tick() {
    final nextStep = _currentStep + 1;
    if (nextStep >= 16) {
      // Fin del compás de 16 pasos: avanzar estados de reproducción individuales
      _pattern.instrumentPatterns.forEach((type, instPattern) {
        final playbackState = _playbackStates[type];
        if (playbackState != null) {
          final currentMeasure = instPattern.measures[playbackState.currentMeasureIndex < instPattern.measures.length 
              ? playbackState.currentMeasureIndex 
              : 0];
          playbackState.currentRepeatCount++;
          if (playbackState.currentRepeatCount >= currentMeasure.repeatCount) {
            playbackState.currentRepeatCount = 0;
            playbackState.currentMeasureIndex = (playbackState.currentMeasureIndex + 1) % instPattern.measures.length;
          }
        }
      });
      _currentStep = 0;
    } else {
      _currentStep = nextStep;
    }

    _lastTickElapsedUs = _stopwatch?.elapsedMicroseconds ?? 0;

    // Disparar audios del nuevo paso actual
    _playCurrentStep();

    // Notificar cambio de paso
    notifyListeners();
  }

  // --- MÉTODOS DE PERSISTENCIA Y GESTIÓN DE PATRONES ---

  Future<void> loadSavedPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? patternStrings = prefs.getStringList('saved_patterns');
      
      final defaultPatterns = [
        CandombePattern.ansinaDefault(),
        CandombePattern.jureRepicadoBasico(),
        CandombePattern.jureGularteRoll(),
        CandombePattern.jureGularteRepicado(),
        CandombePattern.jureMartirena332(),
        CandombePattern.jureMartirenaSignature(),
      ];

      if (patternStrings == null || patternStrings.isEmpty) {
        _savedPatterns = List.from(defaultPatterns);
        await _persistSavedPatterns();
      } else {
        _savedPatterns = patternStrings.map((str) {
          final Map<String, dynamic> json = jsonDecode(str);
          return CandombePattern.fromJson(json);
        }).toList();

        // Inyectar patrones por defecto faltantes
        for (final defPat in defaultPatterns) {
          if (!_savedPatterns.any((p) => p.name == defPat.name)) {
            _savedPatterns.add(defPat);
          }
        }
      }

      if (_savedPatterns.isNotEmpty) {
        final ansinaIndex = _savedPatterns.indexWhere((p) => p.name == 'Ansina Básico');
        final indexToLoad = ansinaIndex != -1 ? ansinaIndex : 0;
        _pattern = CandombePattern.fromJson(_savedPatterns[indexToLoad].toJson());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cargando patrones guardados: $e');
      }
      _savedPatterns = [
        CandombePattern.ansinaDefault(),
        CandombePattern.jureRepicadoBasico(),
        CandombePattern.jureGularteRoll(),
        CandombePattern.jureGularteRepicado(),
        CandombePattern.jureMartirena332(),
        CandombePattern.jureMartirenaSignature(),
      ];
      _pattern = CandombePattern.fromJson(_savedPatterns.first.toJson());
    }
  }

  Future<void> _persistSavedPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> patternStrings = _savedPatterns.map((pat) {
        return jsonEncode(pat.toJson());
      }).toList();
      await prefs.setStringList('saved_patterns', patternStrings);
    } catch (e) {
      if (kDebugMode) {
        print('Error persistiendo patrones: $e');
      }
    }
  }

  // Carga un patrón específico (haciendo una copia profunda para trabajar en memoria)
  void loadPattern(CandombePattern selectedPattern) {
    final wasPlaying = _isPlaying;
    stop();
    
    _pattern = CandombePattern.fromJson(selectedPattern.toJson());
    _currentStep = 0;
    _selectedEditMeasureIndices.updateAll((key, value) => 0);
    notifyListeners();
    
    if (wasPlaying) {
      play();
    }
  }

  // Guarda los cambios en el patrón activo
  Future<void> saveCurrentPattern() async {
    final index = _savedPatterns.indexWhere((pat) => pat.name == _pattern.name);
    if (index != -1) {
      _savedPatterns[index] = CandombePattern.fromJson(_pattern.toJson());
    } else {
      _savedPatterns.add(CandombePattern.fromJson(_pattern.toJson()));
    }
    await _persistSavedPatterns();
    notifyListeners();
  }

  // Guarda el patrón actual con un nuevo nombre
  Future<void> saveCurrentPatternAs(String newName) async {
    if (newName.trim().isEmpty) return;
    
    final newPattern = CandombePattern.fromJson(_pattern.toJson()).copyWith(
      name: newName.trim(),
    );
    
    final index = _savedPatterns.indexWhere((pat) => pat.name == newPattern.name);
    if (index != -1) {
      _savedPatterns[index] = newPattern;
    } else {
      _savedPatterns.add(newPattern);
    }
    
    _pattern = newPattern;
    await _persistSavedPatterns();
    notifyListeners();
  }

  // Elimina un patrón por nombre
  Future<void> deletePattern(String name) async {
    final readOnlyNames = [
      'Ansina Básico',
      'Jure Repicado Básico',
      'Jure Gularte Roll',
      'Jure Gularte Repicado',
      'Jure Martirena 3-3-2',
      'Jure Martirena Signature'
    ];
    if (readOnlyNames.contains(name)) return; // No permitir eliminar los por defecto
    
    _savedPatterns.removeWhere((pat) => pat.name == name);
    await _persistSavedPatterns();
    
    if (_pattern.name == name) {
      loadPattern(_savedPatterns.first);
    } else {
      notifyListeners();
    }
  }

  // Crea un nuevo patrón en blanco y lo activa
  Future<void> createNewPattern(String name) async {
    if (name.trim().isEmpty) return;
    
    final newPattern = CandombePattern.blank(name.trim());
    
    final index = _savedPatterns.indexWhere((pat) => pat.name == newPattern.name);
    if (index != -1) {
      _savedPatterns[index] = newPattern;
    } else {
      _savedPatterns.add(newPattern);
    }
    
    loadPattern(newPattern);
    await _persistSavedPatterns();
  }

  @visibleForTesting
  void tickForTesting() {
    _tick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class InstrumentPlaybackState {
  int currentMeasureIndex = 0;
  int currentRepeatCount = 0;

  void reset() {
    currentMeasureIndex = 0;
    currentRepeatCount = 0;
  }
}
