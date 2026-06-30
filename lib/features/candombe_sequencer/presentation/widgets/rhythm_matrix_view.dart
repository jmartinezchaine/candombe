import 'package:flutter/material.dart';
import '../../../../core/services/sequencer_service.dart';
import '../../data/models/candombe_pattern.dart';

class RhythmMatrixView extends StatelessWidget {
  const RhythmMatrixView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SequencerService();

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final pattern = service.pattern;
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Marcador de Pulsos (1, 2, 3, 4) en la parte superior
                Padding(
                  padding: const EdgeInsets.only(left: 130.0, bottom: 8.0),
                  child: SizedBox(
                    width: 582,
                    child: Row(
                      children: List.generate(4, (pulseIndex) {
                        return Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              'PULSO ${pulseIndex + 1}',
                              style: TextStyle(
                                color: service.currentStep ~/ 4 == pulseIndex && service.isPlaying
                                    ? Colors.amber
                                    : Colors.white30,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                
                // Rejilla de instrumentos
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: InstrumentType.values.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final instrumentType = InstrumentType.values[index];
                    final instPattern = pattern.instrumentPatterns[instrumentType]!;
                    
                    return _InstrumentRow(
                      instrumentPattern: instPattern,
                      currentStep: service.isPlaying ? service.currentStep : -1,
                      activePlaybackMeasureIndex: service.isPlaying 
                          ? (service.playbackStates[instrumentType]?.currentMeasureIndex ?? 0)
                          : -1,
                      selectedEditMeasureIndex: service.getSelectedEditMeasureIndex(instrumentType),
                      onCellTap: (stepIndex) => service.cycleHit(instrumentType, stepIndex),
                      onMuteTap: () => service.toggleMute(instrumentType),
                      onSoloTap: () => service.toggleSolo(instrumentType),
                      onVolumeChanged: (volume) => service.setVolume(instrumentType, volume),
                      onSelectEditMeasure: (mIndex) => service.setSelectedEditMeasureIndex(instrumentType, mIndex),
                      onAddMeasure: () => service.addMeasure(instrumentType),
                      onRemoveMeasure: (mIndex) => service.removeMeasure(instrumentType, mIndex),
                      onSetMeasureRepetitions: (mIndex, repeats) => service.setMeasureRepetitions(instrumentType, mIndex, repeats),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InstrumentRow extends StatelessWidget {
  final InstrumentPattern instrumentPattern;
  final int currentStep;
  final int activePlaybackMeasureIndex;
  final int selectedEditMeasureIndex;
  final ValueChanged<int> onCellTap;
  final VoidCallback onMuteTap;
  final VoidCallback onSoloTap;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<int> onSelectEditMeasure;
  final VoidCallback onAddMeasure;
  final ValueChanged<int> onRemoveMeasure;
  final void Function(int, int) onSetMeasureRepetitions;

  const _InstrumentRow({
    required this.instrumentPattern,
    required this.currentStep,
    required this.activePlaybackMeasureIndex,
    required this.selectedEditMeasureIndex,
    required this.onCellTap,
    required this.onMuteTap,
    required this.onSoloTap,
    required this.onVolumeChanged,
    required this.onSelectEditMeasure,
    required this.onAddMeasure,
    required this.onRemoveMeasure,
    required this.onSetMeasureRepetitions,
  });

  Color _getInstrumentColor() {
    switch (instrumentPattern.type) {
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

  @override
  Widget build(BuildContext context) {
    final instrumentColor = _getInstrumentColor();
    final editIndex = selectedEditMeasureIndex < instrumentPattern.measures.length 
        ? selectedEditMeasureIndex 
        : 0;
    final activeEditMeasure = instrumentPattern.measures[editIndex];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna Izquierda: Encabezado del Instrumento
          SizedBox(
            width: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instrumentPattern.type.name.split(' ')[0], // Solo el nombre base
                  style: TextStyle(
                    color: instrumentPattern.isMuted 
                        ? Colors.white24 
                        : Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Botón Mute (M)
                    GestureDetector(
                      onTap: onMuteTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: instrumentPattern.isMuted
                              ? Colors.red.withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: instrumentPattern.isMuted
                                ? Colors.red.withOpacity(0.6)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          'MUTE',
                          style: TextStyle(
                            color: instrumentPattern.isMuted ? Colors.red : Colors.white54,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Botón Solo (S)
                    GestureDetector(
                      onTap: onSoloTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: instrumentPattern.isSoloed
                              ? Colors.amber.withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: instrumentPattern.isSoloed
                                ? Colors.amber.withOpacity(0.6)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          'SOLO',
                          style: TextStyle(
                            color: instrumentPattern.isSoloed ? Colors.amber : Colors.white54,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      size: 11,
                      color: instrumentPattern.isMuted ? Colors.white24 : Colors.white54,
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 16,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.0),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 8.0),
                            activeTrackColor: instrumentColor,
                            inactiveTrackColor: Colors.white.withOpacity(0.06),
                            thumbColor: instrumentColor,
                            overlayColor: instrumentColor.withOpacity(0.12),
                          ),
                          child: Slider(
                            value: instrumentPattern.volume,
                            min: 0.0,
                            max: 1.0,
                            onChanged: instrumentPattern.isMuted ? null : onVolumeChanged,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),

          // Columna Derecha: Selector de Compases y Rejilla de Celdas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de compases y repeticiones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tabs de compases
                    Row(
                      children: [
                        ...List.generate(instrumentPattern.measures.length, (mIndex) {
                          final isSelected = mIndex == editIndex;
                          final isPlayingThis = mIndex == activePlaybackMeasureIndex;
                          final measure = instrumentPattern.measures[mIndex];

                          return GestureDetector(
                            onTap: () => onSelectEditMeasure(mIndex),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? instrumentColor.withOpacity(0.2) 
                                    : Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected 
                                      ? instrumentColor.withOpacity(0.8) 
                                      : isPlayingThis 
                                          ? Colors.green.withOpacity(0.6)
                                          : Colors.white.withOpacity(0.08),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPlayingThis) ...[
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    'C${mIndex + 1}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white60,
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '(${measure.repeatCount}x)',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white54 : Colors.white30,
                                      fontSize: 8,
                                    ),
                                  ),
                                  if (instrumentPattern.measures.length > 1 && isSelected) ...[
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => onRemoveMeasure(mIndex),
                                      child: Icon(
                                        Icons.close,
                                        size: 10,
                                        color: Colors.red.shade300,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        }),
                        if (instrumentPattern.measures.length < 6)
                          GestureDetector(
                            onTap: onAddMeasure,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Selector de repeticiones del compás seleccionado
                    Row(
                      children: [
                        Text(
                          'Repeticiones C${editIndex + 1}: ',
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            final currentRep = activeEditMeasure.repeatCount;
                            if (currentRep > 1) {
                              onSetMeasureRepetitions(editIndex, currentRep - 1);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.remove, size: 10, color: Colors.white70),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '${activeEditMeasure.repeatCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final currentRep = activeEditMeasure.repeatCount;
                            if (currentRep < 8) {
                              onSetMeasureRepetitions(editIndex, currentRep + 1);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.add, size: 10, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Rejilla de celdas
                Row(
                  children: List.generate(16, (stepIndex) {
                    final isCurrent = currentStep == stepIndex && activePlaybackMeasureIndex == editIndex;
                    final hit = activeEditMeasure.steps[stepIndex];
                    
                    // Dividir visualmente cada pulso (cada 4 celdas)
                    final isPulseStart = stepIndex % 4 == 0;
                    
                    return Expanded(
                      child: Row(
                        children: [
                          if (isPulseStart && stepIndex > 0)
                            Container(
                              width: 2,
                              height: 32,
                              color: Colors.white10,
                            ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: _CellWidget(
                                hit: hit,
                                isCurrent: isCurrent,
                                instrumentColor: instrumentColor,
                                isMuted: instrumentPattern.isMuted,
                                onTap: () => onCellTap(stepIndex),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CellWidget extends StatelessWidget {
  final HitType hit;
  final bool isCurrent;
  final Color instrumentColor;
  final bool isMuted;
  final VoidCallback onTap;

  const _CellWidget({
    required this.hit,
    required this.isCurrent,
    required this.instrumentColor,
    required this.isMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = hit == HitType.silencio;
    final isAccented = hit.isAccented;

    // Colores basados en el golpe
    Color cellBgColor = Colors.transparent;
    Color borderCol = Colors.white.withOpacity(0.06);
    double borderWidth = 1.0;
    
    if (!isEmpty && !isMuted) {
      if (hit == HitType.paloApagado) {
        // Palo apagado: borde discontinuo o color atenuado
        cellBgColor = instrumentColor.withOpacity(0.15);
        borderCol = instrumentColor.withOpacity(0.7);
        borderWidth = 1.5;
      } else if (isAccented) {
        cellBgColor = instrumentColor;
        borderCol = Colors.white.withOpacity(0.8);
        borderWidth = 1.5;
      } else {
        cellBgColor = instrumentColor.withOpacity(0.4);
        borderCol = instrumentColor;
      }
    }

    if (isCurrent) {
      borderCol = Colors.white;
      borderWidth = 2.0;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 38,
        decoration: BoxDecoration(
          color: isCurrent && isEmpty 
              ? Colors.white.withOpacity(0.1) 
              : cellBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderCol,
            width: borderWidth,
          ),
          boxShadow: isCurrent && !isEmpty && !isMuted
              ? [
                  BoxShadow(
                    color: instrumentColor.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Center(
          child: isEmpty
              ? Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.white70 : Colors.white10,
                    shape: BoxShape.circle,
                  ),
                )
              : Text(
                  hit.code.replaceAll('*', ''), // Mostrar código de golpe sin el asterisco
                  style: TextStyle(
                    color: isAccented && !isMuted 
                        ? Colors.black 
                        : (isMuted ? Colors.white24 : Colors.white),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
