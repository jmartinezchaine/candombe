import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:candombe/core/services/sequencer_service.dart';
import 'package:candombe/features/candombe_sequencer/data/models/candombe_pattern.dart';

void main() {
  group('SequencerService & CandombePattern Tests', () {
    late SequencerService sequencer;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sequencer = SequencerService();
      await sequencer.init();
    });

    test('Inicialización correcta del secuenciador y patrón base', () {
      expect(sequencer.isPlaying, isFalse);
      expect(sequencer.bpm, equals(90));
      expect(sequencer.currentStep, equals(0));
      expect(sequencer.pattern.estilo, equals('Ansina'));
      expect(sequencer.pattern.subdivisiones, equals(16));
    });

    test('Fórmula matemática del tempo (BPM a microsegundos por subdivision)', () {
      // 90 BPM: 15,000,000 / 90 = 166,666.66 -> 166667 microsegundos
      expect(sequencer.stepDurationMicroseconds, equals(166667));

      // Cambiar a 120 BPM: 15,000,000 / 120 = 125000 microsegundos
      sequencer.setBpm(120);
      expect(sequencer.stepDurationMicroseconds, equals(125000));

      // Cambiar a 60 BPM: 15,000,000 / 60 = 250000 microsegundos
      sequencer.setBpm(60);
      expect(sequencer.stepDurationMicroseconds, equals(250000));
    });

    test('Verificación del patrón base tradicional de Ansina (4/4)', () {
      final pattern = sequencer.pattern;

      // Madera: MD* en el paso 0
      expect(pattern.instrumentPatterns[InstrumentType.madera]!.steps[0], equals(HitType.maderaAcento));
      // Madera: - en el paso 1
      expect(pattern.instrumentPatterns[InstrumentType.madera]!.steps[1], equals(HitType.silencio));

      // Chico: - en paso 0, M* en paso 1, P en paso 2
      expect(pattern.instrumentPatterns[InstrumentType.chico]!.steps[0], equals(HitType.silencio));
      expect(pattern.instrumentPatterns[InstrumentType.chico]!.steps[1], equals(HitType.manoAcento));
      expect(pattern.instrumentPatterns[InstrumentType.chico]!.steps[2], equals(HitType.palo));

      // Repique: P en paso 0, M en paso 1, MT en paso 2
      expect(pattern.instrumentPatterns[InstrumentType.repique]!.steps[0], equals(HitType.palo));
      expect(pattern.instrumentPatterns[InstrumentType.repique]!.steps[1], equals(HitType.mano));
      expect(pattern.instrumentPatterns[InstrumentType.repique]!.steps[2], equals(HitType.manoTapada));

      // Piano: M en paso 0, - en paso 1, PA en paso 4
      expect(pattern.instrumentPatterns[InstrumentType.piano]!.steps[0], equals(HitType.mano));
      expect(pattern.instrumentPatterns[InstrumentType.piano]!.steps[1], equals(HitType.silencio));
      expect(pattern.instrumentPatterns[InstrumentType.piano]!.steps[4], equals(HitType.paloApagado));
    });

    test('Lógica de alternancia cíclica de golpes', () {
      // Madera ciclo: Silencio -> Madera -> Madera Acentuada -> Silencio
      final initialHit = sequencer.pattern.instrumentPatterns[InstrumentType.madera]!.steps[1]; // Silencio (-)
      expect(initialHit, equals(HitType.silencio));

      sequencer.cycleHit(InstrumentType.madera, 1);
      expect(sequencer.pattern.instrumentPatterns[InstrumentType.madera]!.steps[1], equals(HitType.madera));

      sequencer.cycleHit(InstrumentType.madera, 1);
      expect(sequencer.pattern.instrumentPatterns[InstrumentType.madera]!.steps[1], equals(HitType.maderaAcento));

      sequencer.cycleHit(InstrumentType.madera, 1);
      expect(sequencer.pattern.instrumentPatterns[InstrumentType.madera]!.steps[1], equals(HitType.silencio));

      // Repique ciclo: Silencio -> Mano -> Mano Tapada -> Palo -> Silencio
      final initialRepiqueHit = sequencer.pattern.instrumentPatterns[InstrumentType.repique]!.steps[4]; // Silencio (-)
      expect(initialRepiqueHit, equals(HitType.silencio));

      sequencer.cycleHit(InstrumentType.repique, 4);
      expect(sequencer.pattern.instrumentPatterns[InstrumentType.repique]!.steps[4], equals(HitType.mano));

      sequencer.cycleHit(InstrumentType.repique, 4);
      expect(sequencer.pattern.instrumentPatterns[InstrumentType.repique]!.steps[4], equals(HitType.manoTapada));

      sequencer.cycleHit(InstrumentType.repique, 4);
      expect(sequencer.pattern.instrumentPatterns[InstrumentType.repique]!.steps[4], equals(HitType.palo));

      sequencer.cycleHit(InstrumentType.repique, 4);
      expect(sequencer.pattern.instrumentPatterns[InstrumentType.repique]!.steps[4], equals(HitType.silencio));
    });

    test('Persistencia: Guardar, Crear, Cargar y Eliminar patrones', () async {
      expect(sequencer.savedPatterns.length, equals(6));
      expect(sequencer.savedPatterns.first.name, equals('Ansina Básico'));

      // Crear nuevo patrón
      await sequencer.createNewPattern('Mi Candombe');
      expect(sequencer.savedPatterns.length, equals(7));
      expect(sequencer.pattern.name, equals('Mi Candombe'));
      expect(sequencer.pattern.instrumentPatterns[InstrumentType.madera]!.steps[0], equals(HitType.silencio));

      // Modificar paso y guardar
      sequencer.cycleHit(InstrumentType.madera, 0); // Madera
      await sequencer.saveCurrentPattern();

      // Recargar desde SharedPreferences
      final anotherSequencer = SequencerService();
      await anotherSequencer.init();
      expect(anotherSequencer.savedPatterns.length, equals(7));
      
      // Buscar el patrón guardado
      final loadedPattern = anotherSequencer.savedPatterns.firstWhere((p) => p.name == 'Mi Candombe');
      expect(loadedPattern.instrumentPatterns[InstrumentType.madera]!.steps[0], equals(HitType.madera));

      // Duplicar/Guardar como
      await sequencer.saveCurrentPatternAs('Mi Candombe Copia');
      expect(sequencer.savedPatterns.length, equals(8));
      expect(sequencer.pattern.name, equals('Mi Candombe Copia'));

      // Eliminar
      await sequencer.deletePattern('Mi Candombe Copia');
      expect(sequencer.savedPatterns.length, equals(7));
      expect(sequencer.pattern.name, equals('Ansina Básico')); // Retorna al primero (Ansina Básico)
    });

    test('Verificación de patrones por defecto de Luis Jure y protección de eliminación', () async {
      final jurePatterns = [
        'Jure Repicado Básico',
        'Jure Gularte Roll',
        'Jure Gularte Repicado',
        'Jure Martirena 3-3-2',
        'Jure Martirena Signature'
      ];

      for (final name in jurePatterns) {
        expect(sequencer.savedPatterns.any((p) => p.name == name), isTrue);
        
        // Intentar eliminarlo
        await sequencer.deletePattern(name);
        expect(sequencer.savedPatterns.any((p) => p.name == name), isTrue); // Sigue existiendo
      }
    });

    test('Multi-compás: creación, edición, avance de reproducción y persistencia', () async {
      // 1. Inicializar Chico y Piano con 1 compás, Repique con 2 compases
      final repiquePattern = sequencer.pattern.instrumentPatterns[InstrumentType.repique]!;
      expect(repiquePattern.measures.length, equals(1));

      // Agregar un segundo compás al repique
      sequencer.addMeasure(InstrumentType.repique);
      expect(repiquePattern.measures.length, equals(2));
      expect(sequencer.getSelectedEditMeasureIndex(InstrumentType.repique), equals(1));

      // Configurar repeticiones: C1 se repite 2 veces, C2 se repite 1 vez
      sequencer.setMeasureRepetitions(InstrumentType.repique, 0, 2);
      sequencer.setMeasureRepetitions(InstrumentType.repique, 1, 1);
      
      expect(repiquePattern.measures[0].repeatCount, equals(2));
      expect(repiquePattern.measures[1].repeatCount, equals(1));

      // 2. Editar paso en C2 (medida activa para edición en index 1)
      sequencer.cycleHit(InstrumentType.repique, 4); // De silencio a Mano
      expect(repiquePattern.measures[1].steps[4], equals(HitType.mano));
      // Verificar que C1 (index 0) no se altere
      expect(repiquePattern.measures[0].steps[4], equals(HitType.silencio));

      // 3. Simular ciclo de reproducción tick a tick
      sequencer.play();
      final playbackState = sequencer.playbackStates[InstrumentType.repique]!;
      
      // Al dar play se dispara el paso 0 de C1
      expect(playbackState.currentMeasureIndex, equals(0));
      expect(playbackState.currentRepeatCount, equals(0));

      // Tiquear 15 pasos para completar el primer ciclo de C1
      for (int i = 0; i < 15; i++) {
        sequencer.tickForTesting();
      }
      expect(sequencer.currentStep, equals(15));
      expect(playbackState.currentMeasureIndex, equals(0));
      expect(playbackState.currentRepeatCount, equals(0));

      // El tick 16 avanza al segundo ciclo de C1
      sequencer.tickForTesting();
      expect(sequencer.currentStep, equals(0));
      expect(playbackState.currentMeasureIndex, equals(0));
      expect(playbackState.currentRepeatCount, equals(1));

      // Tiquear 15 pasos más (llegamos al final del segundo ciclo de C1)
      for (int i = 0; i < 15; i++) {
        sequencer.tickForTesting();
      }
      expect(sequencer.currentStep, equals(15));
      expect(playbackState.currentMeasureIndex, equals(0));
      expect(playbackState.currentRepeatCount, equals(1));

      // El tick 32 avanza a C2 (primer ciclo de C2)
      sequencer.tickForTesting();
      expect(sequencer.currentStep, equals(0));
      expect(playbackState.currentMeasureIndex, equals(1));
      expect(playbackState.currentRepeatCount, equals(0));

      // Tiquear 15 pasos más (llegamos al final de C2)
      for (int i = 0; i < 15; i++) {
        sequencer.tickForTesting();
      }
      expect(sequencer.currentStep, equals(15));
      expect(playbackState.currentMeasureIndex, equals(1));
      expect(playbackState.currentRepeatCount, equals(0));

      // El tick 48 avanza y vuelve a C1 (primer ciclo de C1 de nuevo)
      sequencer.tickForTesting();
      expect(sequencer.currentStep, equals(0));
      expect(playbackState.currentMeasureIndex, equals(0));
      expect(playbackState.currentRepeatCount, equals(0));

      // 4. Persistencia: Guardar y Recargar para comprobar que se mantenga la estructura multi-compás
      await sequencer.createNewPattern('Mi Candombe MultiCompas');
      sequencer.addMeasure(InstrumentType.piano);
      sequencer.setMeasureRepetitions(InstrumentType.piano, 0, 3);
      sequencer.cycleHit(InstrumentType.piano, 5); // Mano
      await sequencer.saveCurrentPattern();

      final anotherSequencer = SequencerService();
      await anotherSequencer.init();
      
      final loadedPattern = anotherSequencer.savedPatterns.firstWhere((p) => p.name == 'Mi Candombe MultiCompas');
      final loadedPianoPattern = loadedPattern.instrumentPatterns[InstrumentType.piano]!;
      expect(loadedPianoPattern.measures.length, equals(2));
      expect(loadedPianoPattern.measures[0].repeatCount, equals(3));
      expect(loadedPianoPattern.measures[1].steps[5], equals(HitType.mano));
    });
  });
}
