enum HitType {
  mano,
  manoAcento,
  manoTapada,
  palo,
  paloAcento,
  paloApagado,
  madera,
  maderaAcento,
  silencio,
}

extension HitTypeExtension on HitType {
  String get code {
    switch (this) {
      case HitType.mano:
        return 'M';
      case HitType.manoAcento:
        return 'M*';
      case HitType.manoTapada:
        return 'MT';
      case HitType.palo:
        return 'P';
      case HitType.paloAcento:
        return 'P*';
      case HitType.paloApagado:
        return 'PA';
      case HitType.madera:
        return 'MD';
      case HitType.maderaAcento:
        return 'MD*';
      case HitType.silencio:
        return '-';
    }
  }

  String get label {
    switch (this) {
      case HitType.mano:
        return 'Mano';
      case HitType.manoAcento:
        return 'Mano Acentuada';
      case HitType.manoTapada:
        return 'Mano Tapada';
      case HitType.palo:
        return 'Palo';
      case HitType.paloAcento:
        return 'Palo Acentuado';
      case HitType.paloApagado:
        return 'Palo Apagado';
      case HitType.madera:
        return 'Madera';
      case HitType.maderaAcento:
        return 'Madera Acentuada';
      case HitType.silencio:
        return 'Silencio';
    }
  }

  bool get isAccented {
    return this == HitType.manoAcento ||
        this == HitType.paloAcento ||
        this == HitType.maderaAcento;
  }

  static HitType fromCode(String code) {
    switch (code.trim()) {
      case 'M':
        return HitType.mano;
      case 'M*':
        return HitType.manoAcento;
      case 'MT':
        return HitType.manoTapada;
      case 'P':
        return HitType.palo;
      case 'P*':
        return HitType.paloAcento;
      case 'PA':
        return HitType.paloApagado;
      case 'MD':
        return HitType.madera;
      case 'MD*':
        return HitType.maderaAcento;
      case '-':
      default:
        return HitType.silencio;
    }
  }
}

enum InstrumentType { madera, chico, repique, piano }

enum SoundKit {
  basic,   // Sintético Básico (Original)
  bright,  // Modelado Físico (Resonante)
  dry,     // Modelado Físico (Seco / "Pa-La-Ca")
}

extension SoundKitExtension on SoundKit {
  String get name {
    switch (this) {
      case SoundKit.basic:
        return 'Sintético Básico';
      case SoundKit.bright:
        return 'Modelado (Resonante)';
      case SoundKit.dry:
        return 'Modelado (Seco)';
    }
  }

  String get suffix {
    switch (this) {
      case SoundKit.basic:
        return '_basic';
      case SoundKit.bright:
        return '_bright';
      case SoundKit.dry:
        return '_dry';
    }
  }
}

extension InstrumentTypeExtension on InstrumentType {
  String get name {
    switch (this) {
      case InstrumentType.madera:
        return 'Madera (Clave)';
      case InstrumentType.chico:
        return 'Chico (Motor)';
      case InstrumentType.repique:
        return 'Repique (Diálogo)';
      case InstrumentType.piano:
        return 'Piano (Bajo)';
    }
  }

  String get key {
    switch (this) {
      case InstrumentType.madera:
        return 'madera';
      case InstrumentType.chico:
        return 'chico';
      case InstrumentType.repique:
        return 'repique';
      case InstrumentType.piano:
        return 'piano';
    }
  }

  // Obtiene el path del asset y volumen correspondiente para el tipo de golpe
  (String, double) getAssetForHit(HitType hit, SoundKit kit) {
    if (hit == HitType.silencio) return ('', 0.0);

    final suffix = kit.suffix;

    switch (this) {
      case InstrumentType.madera:
        if (hit == HitType.maderaAcento) {
          return ('assets/audio/madera_accent$suffix.wav', 1.0);
        }
        return ('assets/audio/madera$suffix.wav', 0.7);

      case InstrumentType.chico:
        if (hit == HitType.mano || hit == HitType.manoAcento) {
          final vol = (hit == HitType.manoAcento) ? 1.0 : 0.6;
          return ('assets/audio/chico_mano$suffix.wav', vol);
        } else if (hit == HitType.palo || hit == HitType.paloAcento) {
          final vol = (hit == HitType.paloAcento) ? 1.0 : 0.75;
          return ('assets/audio/chico_palo$suffix.wav', vol);
        }
        return ('assets/audio/chico_mano$suffix.wav', 0.5); // Fallback

      case InstrumentType.repique:
        if (hit == HitType.mano || hit == HitType.manoAcento) {
          final vol = (hit == HitType.manoAcento) ? 1.0 : 0.7;
          return ('assets/audio/repique_mano$suffix.wav', vol);
        } else if (hit == HitType.palo || hit == HitType.paloAcento) {
          final vol = (hit == HitType.paloAcento) ? 1.0 : 0.75;
          return ('assets/audio/repique_palo$suffix.wav', vol);
        } else if (hit == HitType.manoTapada) {
          return ('assets/audio/repique_tapado$suffix.wav', 0.8);
        }
        return ('assets/audio/repique_mano$suffix.wav', 0.5); // Fallback

      case InstrumentType.piano:
        if (hit == HitType.mano || hit == HitType.manoAcento) {
          final vol = (hit == HitType.manoAcento) ? 1.0 : 0.7;
          return ('assets/audio/piano_mano$suffix.wav', vol);
        } else if (hit == HitType.paloAcento) {
          return ('assets/audio/piano_palo_acento$suffix.wav', 1.0);
        } else if (hit == HitType.palo) {
          return ('assets/audio/piano_palo$suffix.wav', 0.85);
        } else if (hit == HitType.paloApagado) {
          return ('assets/audio/piano_apagado$suffix.wav', 0.9);
        }
        return ('assets/audio/piano_mano$suffix.wav', 0.5); // Fallback
    }
  }
}

class CandombeMeasure {
  final List<HitType> steps;
  int repeatCount;

  CandombeMeasure({
    required this.steps,
    this.repeatCount = 1,
  }) : assert(steps.length == 16);

  CandombeMeasure copyWith({
    List<HitType>? steps,
    int? repeatCount,
  }) {
    return CandombeMeasure(
      steps: steps ?? List.from(this.steps),
      repeatCount: repeatCount ?? this.repeatCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps.map((e) => e.code).toList(),
      'repeatCount': repeatCount,
    };
  }

  factory CandombeMeasure.fromJson(Map<String, dynamic> json) {
    final stepsList = json['steps'] as List;
    final steps = stepsList.map((e) => HitTypeExtension.fromCode(e.toString())).toList();
    final repeatCount = json['repeatCount'] as int? ?? 1;
    return CandombeMeasure(steps: steps, repeatCount: repeatCount);
  }
}

class InstrumentPattern {
  final InstrumentType type;
  final List<CandombeMeasure> measures;
  bool isMuted;
  bool isSoloed;
  double volume;

  InstrumentPattern({
    required this.type,
    List<CandombeMeasure>? measures,
    List<HitType>? steps,
    this.isMuted = false,
    this.isSoloed = false,
    this.volume = 1.0,
  })  : this.measures = measures ?? [CandombeMeasure(steps: steps ?? List.filled(16, HitType.silencio))],
        assert(measures != null || steps != null);

  // Getter de conveniencia para mantener compatibilidad
  List<HitType> get steps => measures.first.steps;

  InstrumentPattern copyWith({
    List<CandombeMeasure>? measures,
    List<HitType>? steps,
    bool? isMuted,
    bool? isSoloed,
    double? volume,
  }) {
    List<CandombeMeasure> newMeasures;
    if (measures != null) {
      newMeasures = measures;
    } else if (steps != null) {
      newMeasures = [CandombeMeasure(steps: steps, repeatCount: this.measures.first.repeatCount)];
    } else {
      newMeasures = this.measures.map((m) => m.copyWith()).toList();
    }
    return InstrumentPattern(
      type: type,
      measures: newMeasures,
      isMuted: isMuted ?? this.isMuted,
      isSoloed: isSoloed ?? this.isSoloed,
      volume: volume ?? this.volume,
    );
  }
}

class CandombePattern {
  final String name;
  final String proyecto;
  final String estilo;
  final String compas;
  final int subdivisiones;
  final Map<InstrumentType, InstrumentPattern> instrumentPatterns;

  CandombePattern({
    required this.name,
    required this.proyecto,
    required this.estilo,
    required this.compas,
    required this.subdivisiones,
    required this.instrumentPatterns,
  });

  // Genera el patrón base de Ansina
  factory CandombePattern.ansinaDefault() {
    final maderaSteps = [
      'MD*', '-', '-', 'MD', '-', '-', 'MD*', '-', '-', '-', 'MD*', '-', 'MD*', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final chicoSteps = [
      '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P'
    ].map(HitTypeExtension.fromCode).toList();

    final repiqueSteps = [
      'P', 'M', 'MT', 'P', '-', 'M', 'P', '-', 'P', 'M', 'MT', 'P', '-', 'M', 'P', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final pianoSteps = [
      'M', '-', '-', 'P', 'PA', '-', '-', '-', 'P', 'M*', 'P*', '-', 'PA', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    return CandombePattern(
      name: 'Ansina Básico',
      proyecto: 'Candombe Play',
      estilo: 'Ansina',
      compas: '4/4',
      subdivisiones: 16,
      instrumentPatterns: {
        InstrumentType.madera: InstrumentPattern(type: InstrumentType.madera, steps: maderaSteps),
        InstrumentType.chico: InstrumentPattern(type: InstrumentType.chico, steps: chicoSteps),
        InstrumentType.repique: InstrumentPattern(type: InstrumentType.repique, steps: repiqueSteps),
        InstrumentType.piano: InstrumentPattern(type: InstrumentType.piano, steps: pianoSteps),
      },
    );
  }

  factory CandombePattern.jureRepicadoBasico() {
    final maderaSteps = [
      'MD*', '-', '-', 'MD', '-', '-', 'MD*', '-', '-', '-', 'MD*', '-', 'MD*', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final chicoSteps = [
      '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P'
    ].map(HitTypeExtension.fromCode).toList();

    final repiqueSteps = [
      'P', 'P', 'P', '-', 'P', 'P', 'P', '-', 'P', 'P', 'P', '-', 'P', 'P', 'P', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final pianoSteps = [
      'M', '-', '-', 'P', 'PA', '-', '-', '-', 'P', 'M*', 'P*', '-', 'PA', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    return CandombePattern(
      name: 'Jure Repicado Básico',
      proyecto: 'Candombe Play',
      estilo: 'Jure/General',
      compas: '4/4',
      subdivisiones: 16,
      instrumentPatterns: {
        InstrumentType.madera: InstrumentPattern(type: InstrumentType.madera, steps: maderaSteps),
        InstrumentType.chico: InstrumentPattern(type: InstrumentType.chico, steps: chicoSteps),
        InstrumentType.repique: InstrumentPattern(type: InstrumentType.repique, steps: repiqueSteps),
        InstrumentType.piano: InstrumentPattern(type: InstrumentType.piano, steps: pianoSteps),
      },
    );
  }

  factory CandombePattern.jureGularteRoll() {
    final maderaSteps = [
      'MD*', '-', '-', 'MD', '-', '-', 'MD*', '-', '-', '-', 'MD*', '-', 'MD*', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final chicoSteps = [
      '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P'
    ].map(HitTypeExtension.fromCode).toList();

    final repiqueSteps = [
      'M', 'P', 'P', 'P', 'M', 'P', 'P', 'P', 'M', 'P', 'P', 'P', 'M', 'P', 'P', 'P'
    ].map(HitTypeExtension.fromCode).toList();

    final pianoSteps = [
      'M', '-', '-', 'P', 'PA', '-', '-', '-', 'P', 'M*', 'P*', '-', 'PA', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    return CandombePattern(
      name: 'Jure Gularte Roll',
      proyecto: 'Candombe Play',
      estilo: 'Ansina',
      compas: '4/4',
      subdivisiones: 16,
      instrumentPatterns: {
        InstrumentType.madera: InstrumentPattern(type: InstrumentType.madera, steps: maderaSteps),
        InstrumentType.chico: InstrumentPattern(type: InstrumentType.chico, steps: chicoSteps),
        InstrumentType.repique: InstrumentPattern(type: InstrumentType.repique, steps: repiqueSteps),
        InstrumentType.piano: InstrumentPattern(type: InstrumentType.piano, steps: pianoSteps),
      },
    );
  }

  factory CandombePattern.jureGularteRepicado() {
    final maderaSteps = [
      'MD*', '-', '-', 'MD', '-', '-', 'MD*', '-', '-', '-', 'MD*', '-', 'MD*', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final chicoSteps = [
      '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P'
    ].map(HitTypeExtension.fromCode).toList();

    final repiqueSteps = [
      'M', '-', 'P', 'P', 'M', '-', 'P', 'P', 'M', '-', 'P', 'P', 'M', '-', 'P', 'P'
    ].map(HitTypeExtension.fromCode).toList();

    final pianoSteps = [
      'M', '-', '-', 'P', 'PA', '-', '-', '-', 'P', 'M*', 'P*', '-', 'PA', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    return CandombePattern(
      name: 'Jure Gularte Repicado',
      proyecto: 'Candombe Play',
      estilo: 'Ansina',
      compas: '4/4',
      subdivisiones: 16,
      instrumentPatterns: {
        InstrumentType.madera: InstrumentPattern(type: InstrumentType.madera, steps: maderaSteps),
        InstrumentType.chico: InstrumentPattern(type: InstrumentType.chico, steps: chicoSteps),
        InstrumentType.repique: InstrumentPattern(type: InstrumentType.repique, steps: repiqueSteps),
        InstrumentType.piano: InstrumentPattern(type: InstrumentType.piano, steps: pianoSteps),
      },
    );
  }

  factory CandombePattern.jureMartirena332() {
    final maderaSteps = [
      'MD*', '-', '-', 'MD', '-', '-', 'MD*', '-', '-', '-', 'MD*', '-', 'MD*', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final chicoSteps = [
      '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P'
    ].map(HitTypeExtension.fromCode).toList();

    final repiqueSteps = [
      '-', 'M', 'P', 'P', 'M', 'P', 'P', '-', '-', 'M', 'P', 'P', 'M', 'P', 'P', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final pianoSteps = [
      'M', '-', '-', 'P', 'PA', '-', '-', '-', 'P', 'M*', 'P*', '-', 'PA', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    return CandombePattern(
      name: 'Jure Martirena 3-3-2',
      proyecto: 'Candombe Play',
      estilo: 'Cuareim',
      compas: '4/4',
      subdivisiones: 16,
      instrumentPatterns: {
        InstrumentType.madera: InstrumentPattern(type: InstrumentType.madera, steps: maderaSteps),
        InstrumentType.chico: InstrumentPattern(type: InstrumentType.chico, steps: chicoSteps),
        InstrumentType.repique: InstrumentPattern(type: InstrumentType.repique, steps: repiqueSteps),
        InstrumentType.piano: InstrumentPattern(type: InstrumentType.piano, steps: pianoSteps),
      },
    );
  }

  factory CandombePattern.jureMartirenaSignature() {
    final maderaSteps = [
      'MD*', '-', '-', 'MD', '-', '-', 'MD*', '-', '-', '-', 'MD*', '-', 'MD*', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final chicoSteps = [
      '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P'
    ].map(HitTypeExtension.fromCode).toList();

    final repiqueSteps = [
      '-', 'M', 'M', 'M', '-', 'M', 'M', 'M', '-', 'M', 'M', 'M', '-', 'M', 'M', 'M'
    ].map(HitTypeExtension.fromCode).toList();

    final pianoSteps = [
      'M', '-', '-', 'P', 'PA', '-', '-', '-', 'P', 'M*', 'P*', '-', 'PA', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    return CandombePattern(
      name: 'Jure Martirena Signature',
      proyecto: 'Candombe Play',
      estilo: 'Cuareim',
      compas: '4/4',
      subdivisiones: 16,
      instrumentPatterns: {
        InstrumentType.madera: InstrumentPattern(type: InstrumentType.madera, steps: maderaSteps),
        InstrumentType.chico: InstrumentPattern(type: InstrumentType.chico, steps: chicoSteps),
        InstrumentType.repique: InstrumentPattern(type: InstrumentType.repique, steps: repiqueSteps),
        InstrumentType.piano: InstrumentPattern(type: InstrumentType.piano, steps: pianoSteps),
      },
    );
  }

  factory CandombePattern.cachilaSilvaCuareim() {
    final maderaSteps = [
      'MD*', '-', '-', 'MD', '-', '-', 'MD*', '-', '-', '-', 'MD*', '-', '-', 'MD*', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final chicoSteps = [
      '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P'
    ].map(HitTypeExtension.fromCode).toList();

    final repiqueSteps = [
      'P', 'M', 'MT', 'P', 'P', 'M', 'MT', 'P', 'P', 'M', 'MT', 'P', '-', 'M', 'P', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final pianoSteps = [
      'M', '-', '-', 'P', 'PA', '-', '-', '-', 'P', 'M*', 'P*', '-', 'PA', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    return CandombePattern(
      name: 'Cachila Silva (Cuareim)',
      proyecto: 'Candombe Play',
      estilo: 'Cuareim',
      compas: '4/4',
      subdivisiones: 16,
      instrumentPatterns: {
        InstrumentType.madera: InstrumentPattern(type: InstrumentType.madera, steps: maderaSteps),
        InstrumentType.chico: InstrumentPattern(type: InstrumentType.chico, steps: chicoSteps),
        InstrumentType.repique: InstrumentPattern(type: InstrumentType.repique, steps: repiqueSteps),
        InstrumentType.piano: InstrumentPattern(type: InstrumentType.piano, steps: pianoSteps),
      },
    );
  }

  factory CandombePattern.wilsonMartirenaCuareim() {
    final maderaSteps = [
      'MD*', '-', '-', 'MD', '-', '-', 'MD*', '-', '-', '-', 'MD*', '-', '-', 'MD*', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final chicoSteps = [
      '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P'
    ].map(HitTypeExtension.fromCode).toList();

    final repiqueSteps = [
      'P', 'M', 'MT', 'P', '-', '-', '-', '-', '-', '-', '-', '-', '-', 'M', 'P', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final pianoSteps = [
      'M', '-', '-', 'P', 'PA', '-', '-', '-', 'P', 'M*', 'P*', '-', 'PA', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    return CandombePattern(
      name: 'Wilson Martirena (Cuareim)',
      proyecto: 'Candombe Play',
      estilo: 'Cuareim',
      compas: '4/4',
      subdivisiones: 16,
      instrumentPatterns: {
        InstrumentType.madera: InstrumentPattern(type: InstrumentType.madera, steps: maderaSteps),
        InstrumentType.chico: InstrumentPattern(type: InstrumentType.chico, steps: chicoSteps),
        InstrumentType.repique: InstrumentPattern(type: InstrumentType.repique, steps: repiqueSteps),
        InstrumentType.piano: InstrumentPattern(type: InstrumentType.piano, steps: pianoSteps),
      },
    );
  }

  factory CandombePattern.sergioOrtunoAnsina() {
    final maderaSteps = [
      'MD*', '-', '-', 'MD', '-', '-', 'MD*', '-', '-', '-', 'MD*', '-', 'MD*', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final chicoSteps = [
      '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P'
    ].map(HitTypeExtension.fromCode).toList();

    final repiqueSteps = [
      'P', 'M', 'MT', 'P', 'M', 'P', 'P', 'M', 'P', 'P', 'M', 'P', '-', 'M', 'P', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final pianoSteps = [
      'M', '-', '-', 'P', 'PA', '-', '-', '-', 'P', 'M*', 'P*', '-', 'PA', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    return CandombePattern(
      name: 'Sergio Ortuño (Ansina)',
      proyecto: 'Candombe Play',
      estilo: 'Ansina',
      compas: '4/4',
      subdivisiones: 16,
      instrumentPatterns: {
        InstrumentType.madera: InstrumentPattern(type: InstrumentType.madera, steps: maderaSteps),
        InstrumentType.chico: InstrumentPattern(type: InstrumentType.chico, steps: chicoSteps),
        InstrumentType.repique: InstrumentPattern(type: InstrumentType.repique, steps: repiqueSteps),
        InstrumentType.piano: InstrumentPattern(type: InstrumentType.piano, steps: pianoSteps),
      },
    );
  }

  factory CandombePattern.pericoGularteDesplazado() {
    final maderaSteps = [
      'MD*', '-', '-', 'MD', '-', '-', 'MD*', '-', '-', '-', 'MD*', '-', 'MD*', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    final chicoSteps = [
      '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P', '-', 'M*', 'P', 'P'
    ].map(HitTypeExtension.fromCode).toList();

    final repiqueSteps = [
      'P', 'M', 'MT', 'P', '-', 'M', 'P', '-', 'P', 'M', 'MT', 'P', 'P', 'M', 'MT', 'P'
    ].map(HitTypeExtension.fromCode).toList();

    final pianoSteps = [
      'M', '-', '-', 'P', 'PA', '-', '-', '-', 'P', 'M*', 'P*', '-', 'PA', '-', '-', '-'
    ].map(HitTypeExtension.fromCode).toList();

    return CandombePattern(
      name: 'Perico Gularte Desplazado (Ansina)',
      proyecto: 'Candombe Play',
      estilo: 'Ansina',
      compas: '4/4',
      subdivisiones: 16,
      instrumentPatterns: {
        InstrumentType.madera: InstrumentPattern(type: InstrumentType.madera, steps: maderaSteps),
        InstrumentType.chico: InstrumentPattern(type: InstrumentType.chico, steps: chicoSteps),
        InstrumentType.repique: InstrumentPattern(type: InstrumentType.repique, steps: repiqueSteps),
        InstrumentType.piano: InstrumentPattern(type: InstrumentType.piano, steps: pianoSteps),
      },
    );
  }

  // Genera un patrón en blanco
  factory CandombePattern.blank(String name) {
    return CandombePattern(
      name: name,
      proyecto: 'Candombe Play',
      estilo: 'Personalizado',
      compas: '4/4',
      subdivisiones: 16,
      instrumentPatterns: {
        InstrumentType.madera: InstrumentPattern(
          type: InstrumentType.madera,
          steps: List.filled(16, HitType.silencio),
        ),
        InstrumentType.chico: InstrumentPattern(
          type: InstrumentType.chico,
          steps: List.filled(16, HitType.silencio),
        ),
        InstrumentType.repique: InstrumentPattern(
          type: InstrumentType.repique,
          steps: List.filled(16, HitType.silencio),
        ),
        InstrumentType.piano: InstrumentPattern(
          type: InstrumentType.piano,
          steps: List.filled(16, HitType.silencio),
        ),
      },
    );
  }

  // Serialización a JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'proyecto': proyecto,
      'estilo': estilo,
      'compas': compas,
      'subdivisiones': subdivisiones,
      'patron_base': {
        'madera': instrumentPatterns[InstrumentType.madera]!.steps.map((e) => e.code).toList(),
        'chico': instrumentPatterns[InstrumentType.chico]!.steps.map((e) => e.code).toList(),
        'repique': instrumentPatterns[InstrumentType.repique]!.steps.map((e) => e.code).toList(),
        'piano': instrumentPatterns[InstrumentType.piano]!.steps.map((e) => e.code).toList(),
      },
      'compases_instrumentos': {
        'madera': instrumentPatterns[InstrumentType.madera]!.measures.map((m) => m.toJson()).toList(),
        'chico': instrumentPatterns[InstrumentType.chico]!.measures.map((m) => m.toJson()).toList(),
        'repique': instrumentPatterns[InstrumentType.repique]!.measures.map((m) => m.toJson()).toList(),
        'piano': instrumentPatterns[InstrumentType.piano]!.measures.map((m) => m.toJson()).toList(),
      },
      'tracks': {
        'madera': {
          'volume': instrumentPatterns[InstrumentType.madera]!.volume,
          'isMuted': instrumentPatterns[InstrumentType.madera]!.isMuted,
          'isSoloed': instrumentPatterns[InstrumentType.madera]!.isSoloed,
        },
        'chico': {
          'volume': instrumentPatterns[InstrumentType.chico]!.volume,
          'isMuted': instrumentPatterns[InstrumentType.chico]!.isMuted,
          'isSoloed': instrumentPatterns[InstrumentType.chico]!.isSoloed,
        },
        'repique': {
          'volume': instrumentPatterns[InstrumentType.repique]!.volume,
          'isMuted': instrumentPatterns[InstrumentType.repique]!.isMuted,
          'isSoloed': instrumentPatterns[InstrumentType.repique]!.isSoloed,
        },
        'piano': {
          'volume': instrumentPatterns[InstrumentType.piano]!.volume,
          'isMuted': instrumentPatterns[InstrumentType.piano]!.isMuted,
          'isSoloed': instrumentPatterns[InstrumentType.piano]!.isSoloed,
        },
      }
    };
  }

  // Deserialización de JSON
  factory CandombePattern.fromJson(Map<String, dynamic> json) {
    final pat = json['patron_base'] as Map<String, dynamic>;
    final tracks = json['tracks'] as Map<String, dynamic>?;
    final compases = json['compases_instrumentos'] as Map<String, dynamic>?;

    List<CandombeMeasure> parseMeasures(String key, List<HitType> fallbackSteps) {
      if (compases != null && compases[key] != null) {
        final list = compases[key] as List;
        return list.map((e) => CandombeMeasure.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [CandombeMeasure(steps: fallbackSteps, repeatCount: 1)];
    }

    final maderaSteps = (pat['madera'] as List).map((e) => HitTypeExtension.fromCode(e.toString())).toList();
    final chicoSteps = (pat['chico'] as List).map((e) => HitTypeExtension.fromCode(e.toString())).toList();
    final repiqueSteps = pat['repique'] != null
        ? (pat['repique'] as List).map((e) => HitTypeExtension.fromCode(e.toString())).toList()
        : List.filled(16, HitType.silencio);
    final pianoSteps = (pat['piano'] as List).map((e) => HitTypeExtension.fromCode(e.toString())).toList();

    final maderaMeasures = parseMeasures('madera', maderaSteps);
    final chicoMeasures = parseMeasures('chico', chicoSteps);
    final repiqueMeasures = parseMeasures('repique', repiqueSteps);
    final pianoMeasures = parseMeasures('piano', pianoSteps);

    final maderaTrack = tracks?['madera'] as Map<String, dynamic>?;
    final chicoTrack = tracks?['chico'] as Map<String, dynamic>?;
    final repiqueTrack = tracks?['repique'] as Map<String, dynamic>?;
    final pianoTrack = tracks?['piano'] as Map<String, dynamic>?;

    return CandombePattern(
      name: json['name'] ?? json['estilo'] ?? 'Ansina Básico',
      proyecto: json['proyecto'] ?? 'Candombe Play',
      estilo: json['estilo'] ?? 'Ansina',
      compas: json['compas'] ?? '4/4',
      subdivisiones: json['subdivisiones'] ?? 16,
      instrumentPatterns: {
        InstrumentType.madera: InstrumentPattern(
          type: InstrumentType.madera,
          measures: maderaMeasures,
          volume: maderaTrack?['volume']?.toDouble() ?? 1.0,
          isMuted: maderaTrack?['isMuted'] ?? false,
          isSoloed: maderaTrack?['isSoloed'] ?? false,
        ),
        InstrumentType.chico: InstrumentPattern(
          type: InstrumentType.chico,
          measures: chicoMeasures,
          volume: chicoTrack?['volume']?.toDouble() ?? 1.0,
          isMuted: chicoTrack?['isMuted'] ?? false,
          isSoloed: chicoTrack?['isSoloed'] ?? false,
        ),
        InstrumentType.repique: InstrumentPattern(
          type: InstrumentType.repique,
          measures: repiqueMeasures,
          volume: repiqueTrack?['volume']?.toDouble() ?? 1.0,
          isMuted: repiqueTrack?['isMuted'] ?? false,
          isSoloed: repiqueTrack?['isSoloed'] ?? false,
        ),
        InstrumentType.piano: InstrumentPattern(
          type: InstrumentType.piano,
          measures: pianoMeasures,
          volume: pianoTrack?['volume']?.toDouble() ?? 1.0,
          isMuted: pianoTrack?['isMuted'] ?? false,
          isSoloed: pianoTrack?['isSoloed'] ?? false,
        ),
      },
    );
  }

  CandombePattern copyWith({
    String? name,
    String? estilo,
    Map<InstrumentType, InstrumentPattern>? instrumentPatterns,
  }) {
    return CandombePattern(
      name: name ?? this.name,
      proyecto: proyecto,
      estilo: estilo ?? this.estilo,
      compas: compas,
      subdivisiones: subdivisiones,
      instrumentPatterns: instrumentPatterns ?? this.instrumentPatterns,
    );
  }
}
