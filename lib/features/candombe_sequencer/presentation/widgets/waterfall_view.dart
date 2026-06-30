import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../../core/services/sequencer_service.dart';
import '../../data/models/candombe_pattern.dart';

class WaterfallView extends StatefulWidget {
  const WaterfallView({super.key});

  @override
  State<WaterfallView> createState() => _WaterfallViewState();
}

class _WaterfallViewState extends State<WaterfallView>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final SequencerService _service = SequencerService();

  @override
  void initState() {
    super.initState();
    // Ticker para re-dibujar la cascada en cada frame y lograr animación suave de 60fps
    _ticker = createTicker((elapsed) {
      if (_service.isPlaying) {
        setState(() {}); // Forzar repintado suave
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        return Container(
          height: 380,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Dibujo de la cascada
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WaterfallPainter(
                      pattern: _service.pattern,
                      currentStep: _service.currentStep,
                      fractionalProgress: _service.isPlaying ? _service.fractionalProgress : 0.0,
                      playbackStates: _service.playbackStates,
                    ),
                  ),
                ),
                
                // Etiquetas fijas de los instrumentos arriba de las pistas
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      _LaneHeader(label: 'MADERA', color: Colors.orange.shade400),
                      _LaneHeader(label: 'CHICO', color: Colors.red.shade400),
                      _LaneHeader(label: 'REPIQUE', color: Colors.teal.shade300),
                      _LaneHeader(label: 'PIANO', color: Colors.amber.shade300),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LaneHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _LaneHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterfallPainter extends CustomPainter {
  final CandombePattern pattern;
  final int currentStep;
  final double fractionalProgress;
  final Map<InstrumentType, InstrumentPlaybackState> playbackStates;

  _WaterfallPainter({
    required this.pattern,
    required this.currentStep,
    required this.fractionalProgress,
    required this.playbackStates,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double laneWidth = size.width / 4;
    final double targetY = size.height - 70; // Línea de impacto
    const double stepSpacing = 50.0; // Distancia en píxeles por subdivisión

    // 1. Dibujar líneas de carril (Lanes) y zona de impacto
    final laneDividerPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.5;
    
    // Separadores verticales
    canvas.drawLine(Offset(laneWidth, 0), Offset(laneWidth, size.height), laneDividerPaint);
    canvas.drawLine(Offset(laneWidth * 2, 0), Offset(laneWidth * 2, size.height), laneDividerPaint);
    canvas.drawLine(Offset(laneWidth * 3, 0), Offset(laneWidth * 3, size.height), laneDividerPaint);

    // Pintar línea horizontal de impacto
    final targetLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, targetY), Offset(size.width, targetY), targetLinePaint);

    // Pintar los botones/objetivos de impacto para cada carril
    final List<InstrumentType> instruments = [
      InstrumentType.madera,
      InstrumentType.chico,
      InstrumentType.repique,
      InstrumentType.piano
    ];

    for (int i = 0; i < instruments.length; i++) {
      final type = instruments[i];
      final isMuted = pattern.instrumentPatterns[type]?.isMuted ?? false;
      final instColor = _getInstrumentColor(type);
      final centerX = (i * laneWidth) + (laneWidth / 2);

      // Si el paso actual tiene golpe, destellar el objetivo
      final instPattern = pattern.instrumentPatterns[type];
      final measureIndex = playbackStates[type]?.currentMeasureIndex ?? 0;
      final activeMeasure = instPattern != null && measureIndex < instPattern.measures.length 
          ? instPattern.measures[measureIndex] 
          : null;
      final currentHit = activeMeasure?.steps[currentStep] ?? HitType.silencio;
      final isHittingNow = currentHit != HitType.silencio && !isMuted;

      final targetPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHittingNow ? 3.0 : 1.5
        ..color = isHittingNow 
            ? instColor 
            : (isMuted ? Colors.white10 : instColor.withOpacity(0.3));

      // Círculo objetivo
      canvas.drawCircle(Offset(centerX, targetY), 20.0, targetPaint);

      // Si está golpeando, dibujar destello brillante de fondo
      if (isHittingNow) {
        final glowPaint = Paint()
          ..color = instColor.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(Offset(centerX, targetY), 24.0, glowPaint);
      }
    }

    // 2. Dibujar las notas cayendo
    for (int i = 0; i < instruments.length; i++) {
      final type = instruments[i];
      final instPattern = pattern.instrumentPatterns[type];
      if (instPattern == null || instPattern.isMuted) continue;

      final instColor = _getInstrumentColor(type);
      final centerX = (i * laneWidth) + (laneWidth / 2);

      // Dibujar notas futuras y notas recientemente cruzadas
      for (int stepIndex = 0; stepIndex < 16; stepIndex++) {
        // Calcular la distancia relativa entre este paso y el paso de reproducción actual
        double stepDiff = stepIndex - (currentStep + fractionalProgress);
        
        // Ajustar para el bucle continuo del secuenciador
        while (stepDiff < -8) {
          stepDiff += 16;
        }
        while (stepDiff > 8) {
          stepDiff -= 16;
        }

        // Determinar a qué compás (actual, siguiente o anterior) corresponde este stepIndex
        // en base a la distancia de paso relativa en la rejilla circular de 16 pasos.
        int measureOffset = 0;
        final diff = stepIndex - currentStep;
        if (diff < -8) {
          measureOffset = 1;
        } else if (diff > 8) {
          measureOffset = -1;
        }

        final playbackState = playbackStates[type];
        final measures = instPattern.measures;
        int targetMeasureIndex = playbackState?.currentMeasureIndex ?? 0;

        if (measureOffset != 0 && measures.length > 1) {
          int targetRepeatCount = playbackState?.currentRepeatCount ?? 0;
          if (measureOffset == 1) {
            // Avanzar hacia el futuro
            final currentMeasure = measures[targetMeasureIndex % measures.length];
            targetRepeatCount++;
            if (targetRepeatCount >= currentMeasure.repeatCount) {
              targetMeasureIndex = (targetMeasureIndex + 1) % measures.length;
            }
          } else if (measureOffset == -1) {
            // Retroceder hacia el pasado
            targetRepeatCount--;
            if (targetRepeatCount < 0) {
              final prevMeasureIndex = (targetMeasureIndex - 1 + measures.length) % measures.length;
              targetMeasureIndex = prevMeasureIndex;
            }
          }
        }

        final activeMeasure = measures[targetMeasureIndex % measures.length];
        final hit = activeMeasure.steps[stepIndex];
        if (hit == HitType.silencio) continue;

        // Calcular la coordenada Y. Las notas caen desde arriba hacia targetY
        final double y = targetY - (stepDiff * stepSpacing);

        // Si se sale mucho de la pantalla, no renderizar
        if (y < -30 || y > size.height + 30) continue;

        // Dibujar el golpe
        _drawNote(canvas, Offset(centerX, y), hit, instColor);
      }
    }
  }

  void _drawNote(Canvas canvas, Offset position, HitType hit, Color baseColor) {
    final double radius = hit.isAccented ? 18.0 : 15.0;
    
    // 1. Efecto de resplandor exterior si es acentuada
    if (hit.isAccented) {
      final glowPaint = Paint()
        ..color = baseColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(position, radius + 4, glowPaint);
    }

    // 2. Relleno principal de la nota
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _getNoteFillColor(hit, baseColor);
    canvas.drawCircle(position, radius, fillPaint);

    // 3. Contorno de la nota
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hit.isAccented ? 2.5 : 1.5
      ..color = hit.isAccented ? Colors.white : baseColor;
    canvas.drawCircle(position, radius, borderPaint);

    // 4. Detalle visual para Palo Apagado (PA)
    if (hit == HitType.paloApagado) {
      final crossPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.white60;
      // Dibujar una X en el centro
      canvas.drawLine(
        Offset(position.dx - 6, position.dy - 6),
        Offset(position.dx + 6, position.dy + 6),
        crossPaint,
      );
      canvas.drawLine(
        Offset(position.dx + 6, position.dy - 6),
        Offset(position.dx - 6, position.dy + 6),
        crossPaint,
      );
    } else {
      // Dibujar texto identificador en el centro (M, P, MD)
      final textSpan = TextSpan(
        text: hit.code.replaceAll('*', ''),
        style: TextStyle(
          color: _getNoteTextColor(hit, baseColor),
          fontSize: hit.isAccented ? 10.0 : 9.0,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2,
        ),
      );
    }
  }

  Color _getInstrumentColor(InstrumentType type) {
    switch (type) {
      case InstrumentType.madera:
        return Colors.orange.shade400;
      case InstrumentType.chico:
        return Colors.red.shade400;
      case InstrumentType.repique:
        return Colors.teal.shade300;
      case InstrumentType.piano:
        return Colors.amber.shade300;
    }
  }

  Color _getNoteFillColor(HitType hit, Color baseColor) {
    if (hit.isAccented) {
      return baseColor; // Relleno sólido brillante
    }
    if (hit == HitType.paloApagado) {
      return Colors.grey.shade900.withOpacity(0.9); // Fondo oscuro
    }
    // Golpes normales tienen color translúcido
    return baseColor.withOpacity(0.35);
  }

  Color _getNoteTextColor(HitType hit, Color baseColor) {
    if (hit.isAccented) {
      return Colors.black; // Contraste contra el fondo brillante
    }
    return Colors.white;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Re-dibujar siempre ya que la posición cambia constantemente
  }
}
