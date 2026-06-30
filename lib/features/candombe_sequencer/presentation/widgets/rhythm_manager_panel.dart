import 'package:flutter/material.dart';
import '../../../../core/services/sequencer_service.dart';
import '../../data/models/candombe_pattern.dart';

class RhythmManagerPanel extends StatefulWidget {
  const RhythmManagerPanel({super.key});

  @override
  State<RhythmManagerPanel> createState() => _RhythmManagerPanelState();
}

class _RhythmManagerPanelState extends State<RhythmManagerPanel> {
  final _sequencerService = SequencerService();

  void _showSaveAsDialog() {
    final controller = TextEditingController(text: '${_sequencerService.pattern.name} Copia');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1512),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          title: const Text(
            'Guardar Ritmo Como...',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nombre del Ritmo',
              labelStyle: const TextStyle(color: Colors.white60),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.deepOrange),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await _sequencerService.saveCurrentPatternAs(name);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showNewPatternDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1512),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          title: const Text(
            'Nuevo Ritmo Personalizado',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nombre del nuevo ritmo',
              labelStyle: const TextStyle(color: Colors.white60),
              hintText: 'Ej. Mi Base Lenta',
              hintStyle: const TextStyle(color: Colors.white24),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.deepOrange),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await _sequencerService.createNewPattern(name);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog() {
    final name = _sequencerService.pattern.name;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1512),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          title: const Text(
            'Eliminar Ritmo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar "$name"? Esta acción no se puede deshacer.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                await _sequencerService.deletePattern(name);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sequencerService,
      builder: (context, child) {
        final currentPattern = _sequencerService.pattern;
        final savedPatterns = _sequencerService.savedPatterns;
        final readOnlyNames = [
          'Ansina Básico',
          'Jure Repicado Básico',
          'Jure Gularte Roll',
          'Jure Gularte Repicado',
          'Jure Martirena 3-3-2',
          'Jure Martirena Signature'
        ];
        final isReadOnly = readOnlyNames.contains(currentPattern.name);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.04),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.library_music_rounded, size: 16, color: Colors.orange.shade400),
                  const SizedBox(width: 8),
                  const Text(
                    'Gestor de Ritmos',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 550;
                  
                  final dropdown = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: savedPatterns.any((p) => p.name == currentPattern.name) 
                            ? currentPattern.name 
                            : null,
                        dropdownColor: const Color(0xFF1E1916),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white60),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        hint: const Text('Seleccionar ritmo...', style: TextStyle(color: Colors.white38)),
                        items: savedPatterns.map((pat) {
                          return DropdownMenuItem<String>(
                            value: pat.name,
                            child: Text(pat.name),
                          );
                        }).toList(),
                        onChanged: (name) {
                          if (name != null) {
                            final target = savedPatterns.firstWhere((p) => p.name == name);
                            _sequencerService.loadPattern(target);
                          }
                        },
                      ),
                    ),
                  );

                  final buttons = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      // Botón Guardar Cambios
                      IconButton(
                        tooltip: isReadOnly ? 'Guardar copia personalizada' : 'Guardar Cambios',
                        icon: Icon(Icons.save_rounded, color: isReadOnly ? Colors.orangeAccent : Colors.greenAccent),
                        style: IconButton.styleFrom(
                          backgroundColor: (isReadOnly ? Colors.orangeAccent : Colors.greenAccent).withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (isReadOnly) {
                            _showSaveAsDialog();
                          } else {
                            await _sequencerService.saveCurrentPattern();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ritmo guardado correctamente'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      // Botón Guardar Como
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.08),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
                        ),
                        onPressed: _showSaveAsDialog,
                        label: const Text('Copia', style: TextStyle(fontSize: 12)),
                        icon: const Icon(Icons.copy_rounded, size: 14),
                      ),
                      // Botón Nuevo
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange.withOpacity(0.15),
                          foregroundColor: Colors.deepOrange.shade300,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.deepOrange.withOpacity(0.2)),
                          ),
                        ),
                        onPressed: _showNewPatternDialog,
                        label: const Text('Nuevo', style: TextStyle(fontSize: 12)),
                        icon: const Icon(Icons.add_rounded, size: 14),
                      ),
                      // Botón Eliminar
                      if (!isReadOnly)
                        IconButton(
                          tooltip: 'Eliminar Ritmo',
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _showDeleteConfirmDialog,
                        ),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: dropdown),
                        const SizedBox(width: 16),
                        buttons,
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        dropdown,
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: buttons,
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
