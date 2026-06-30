import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  final Map<String, AudioSource> _sources = {};

  // Listado de assets que necesitamos cargar
  static const List<String> audioAssets = [
    // Kit Básico (Original)
    'assets/audio/madera_basic.wav',
    'assets/audio/madera_accent_basic.wav',
    'assets/audio/chico_mano_basic.wav',
    'assets/audio/chico_palo_basic.wav',
    'assets/audio/repique_mano_basic.wav',
    'assets/audio/repique_palo_basic.wav',
    'assets/audio/repique_tapado_basic.wav',
    'assets/audio/piano_mano_basic.wav',
    'assets/audio/piano_palo_basic.wav',
    'assets/audio/piano_palo_acento_basic.wav',
    'assets/audio/piano_apagado_basic.wav',

    // Kit Modelado Resonante (Bright)
    'assets/audio/madera_bright.wav',
    'assets/audio/madera_accent_bright.wav',
    'assets/audio/chico_mano_bright.wav',
    'assets/audio/chico_palo_bright.wav',
    'assets/audio/repique_mano_bright.wav',
    'assets/audio/repique_palo_bright.wav',
    'assets/audio/repique_tapado_bright.wav',
    'assets/audio/piano_mano_bright.wav',
    'assets/audio/piano_palo_bright.wav',
    'assets/audio/piano_palo_acento_bright.wav',
    'assets/audio/piano_apagado_bright.wav',

    // Kit Modelado Seco (Dry)
    'assets/audio/madera_dry.wav',
    'assets/audio/madera_accent_dry.wav',
    'assets/audio/chico_mano_dry.wav',
    'assets/audio/chico_palo_dry.wav',
    'assets/audio/repique_mano_dry.wav',
    'assets/audio/repique_palo_dry.wav',
    'assets/audio/repique_tapado_dry.wav',
    'assets/audio/piano_mano_dry.wav',
    'assets/audio/piano_palo_dry.wav',
    'assets/audio/piano_palo_acento_dry.wav',
    'assets/audio/piano_apagado_dry.wav',
  ];

  Future<void> init() async {
    if (_initialized) return;

    try {
      debugPrint('Inicializando motor de audio SoLoud...');
      await SoLoud.instance.init();
      _initialized = true;
      debugPrint('SoLoud inicializado correctamente.');

      // Precargar todos los assets
      await _preloadAssets();
    } catch (e, stack) {
      _initialized = false;
      debugPrint('Error crítico al inicializar SoLoud: $e');
      debugPrint(stack.toString());
      // No lanzamos excepción para que la interfaz siga funcionando en simuladores sin audio
    }
  }

  Future<void> _preloadAssets() async {
    if (!_initialized) return;

    for (final asset in audioAssets) {
      try {
        debugPrint('Precargando asset de audio: $asset');
        final source = await SoLoud.instance.loadAsset(
          asset,
          mode: kIsWeb ? LoadMode.disk : LoadMode.memory,
        );
        _sources[asset] = source;
      } catch (e) {
        debugPrint('Error al precargar $asset: $e');
      }
    }
    debugPrint('Carga de assets de audio finalizada. Total precargados: ${_sources.length}');
  }

  // Reproduce un golpe
  void playSample(String assetPath, {double volume = 1.0}) {
    if (!_initialized) {
      debugPrint('Intento de reproducir $assetPath pero SoLoud no está inicializado.');
      return;
    }

    final source = _sources[assetPath];
    if (source != null) {
      try {
        SoLoud.instance.play(source, volume: volume);
      } catch (e) {
        debugPrint('Error al reproducir $assetPath: $e');
      }
    } else {
      debugPrint('Advertencia: El asset $assetPath no estaba precargado.');
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    try {
      SoLoud.instance.deinit();
      _sources.clear();
      _initialized = false;
      debugPrint('Motor de audio SoLoud liberado.');
    } catch (e) {
      debugPrint('Error al liberar SoLoud: $e');
    }
  }
}
