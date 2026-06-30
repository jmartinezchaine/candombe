import 'package:flutter/material.dart';
import '../../../../core/services/sequencer_service.dart';
import '../../data/models/candombe_pattern.dart';

enum SequencerViewMode { matrix, waterfall }

class ControlsPanel extends StatelessWidget {
  final SequencerViewMode currentMode;
  final ValueChanged<SequencerViewMode> onViewModeChanged;

  const ControlsPanel({
    super.key,
    required this.currentMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final service = SequencerService();

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            children: [
              // Fila superior: Reproducción y Modos (Adaptable para móviles)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 380;

                  final playbackButtons = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Play/Pause con efecto de resplandor
                      GestureDetector(
                        onTap: service.togglePlay,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: service.isPlaying
                                  ? [Colors.amber.shade700, Colors.orange.shade600]
                                  : [Colors.deepOrange.shade600, Colors.red.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (service.isPlaying
                                        ? Colors.orange
                                        : Colors.red)
                                    .withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Icon(
                            service.isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Stop
                      IconButton.filledTonal(
                        onPressed: service.stop,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          backgroundColor: Colors.white.withOpacity(0.06),
                          foregroundColor: Colors.white70,
                        ),
                        icon: const Icon(Icons.stop_rounded),
                      ),
                      const SizedBox(width: 12),
                      // Reset
                      IconButton.filledTonal(
                        onPressed: service.resetToDefault,
                        tooltip: 'Restablecer ritmo Ansina',
                        style: IconButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          backgroundColor: Colors.white.withOpacity(0.06),
                          foregroundColor: Colors.amber.shade300,
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  );

                  final viewSelector = Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ViewTab(
                          label: 'Matriz',
                          icon: Icons.grid_on_rounded,
                          isSelected: currentMode == SequencerViewMode.matrix,
                          onTap: () => onViewModeChanged(SequencerViewMode.matrix),
                        ),
                        _ViewTab(
                          label: 'Cascada',
                          icon: Icons.waterfall_chart_rounded,
                          isSelected: currentMode == SequencerViewMode.waterfall,
                          onTap: () => onViewModeChanged(SequencerViewMode.waterfall),
                        ),
                      ],
                    ),
                  );

                  if (isWide) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        playbackButtons,
                        viewSelector,
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [playbackButtons],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [viewSelector],
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              
              // Fila inferior: Control de Tempo (BPM)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tempo de Calle',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${service.bpm}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'BPM',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Botón -
                      _TempoButton(
                        icon: Icons.remove,
                        onTap: () => service.setBpm(service.bpm - 1),
                        onLongPress: () => service.setBpm(service.bpm - 5),
                      ),
                      // Slider con color dinámico
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: Colors.amber.shade600,
                            inactiveTrackColor: Colors.white.withOpacity(0.1),
                            thumbColor: Colors.white,
                            overlayColor: Colors.amber.withOpacity(0.2),
                            trackHeight: 6.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                          ),
                          child: Slider(
                            value: service.bpm.toDouble(),
                            min: 40.0,
                            max: 160.0,
                            divisions: 120,
                            onChanged: (value) {
                              service.setBpm(value.toInt());
                            },
                          ),
                        ),
                      ),
                      // Botón +
                      _TempoButton(
                        icon: Icons.add,
                        onTap: () => service.setBpm(service.bpm + 1),
                        onLongPress: () => service.setBpm(service.bpm + 5),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),
              
              // Selector de Colección de Sonidos
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.library_music_rounded, size: 16, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Colección de Sonidos',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        _KitTab(
                          label: 'Básico (Original)',
                          isSelected: service.soundKit == SoundKit.basic,
                          onTap: () => service.setSoundKit(SoundKit.basic),
                        ),
                        _KitTab(
                          label: 'Modelado Resonante',
                          isSelected: service.soundKit == SoundKit.bright,
                          onTap: () => service.setSoundKit(SoundKit.bright),
                        ),
                        _KitTab(
                          label: 'Modelado Seco (Ansina)',
                          isSelected: service.soundKit == SoundKit.dry,
                          onTap: () => service.setSoundKit(SoundKit.dry),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ViewTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.amber.shade400 : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TempoButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TempoButton({
    required this.icon,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
      ),
    );
  }
}

class _KitTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _KitTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
