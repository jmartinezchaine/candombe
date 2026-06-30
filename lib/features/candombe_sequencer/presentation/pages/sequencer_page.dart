import 'package:flutter/material.dart';
import '../../../../core/services/sequencer_service.dart';
import '../../../../core/services/audio_service.dart';
import '../widgets/controls_panel.dart';
import '../widgets/rhythm_matrix_view.dart';
import '../widgets/waterfall_view.dart';
import '../widgets/rhythm_manager_panel.dart';

class SequencerPage extends StatefulWidget {
  const SequencerPage({super.key});

  @override
  State<SequencerPage> createState() => _SequencerPageState();
}

class _SequencerPageState extends State<SequencerPage> {
  SequencerViewMode _viewMode = SequencerViewMode.matrix;
  bool _audioLoading = true;
  String _loadingMessage = 'Preparando tambores...';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Inicializar el motor de audio y precargar samples
    await AudioService().init();
    
    // Inicializar el secuenciador
    await SequencerService().init();

    if (mounted) {
      setState(() {
        _audioLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cuerda1.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(0xE60A0909), // Negro puro con 90% de opacidad para garantizar excelente contraste
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: _audioLoading
              ? _buildLoadingState()
              : _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: Colors.deepOrange,
              strokeWidth: 3.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _loadingMessage,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // AppBar Personalizado Premium
        _buildCustomAppBar(),
        
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const RhythmManagerPanel(),
                const SizedBox(height: 16),
                
                // Switcher animado entre Matriz y Cascada
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: _viewMode == SequencerViewMode.matrix
                      ? const RhythmMatrixView(key: ValueKey('matrix'))
                      : const WaterfallView(key: ValueKey('waterfall')),
                ),
                
                const SizedBox(height: 20),
                
                // Panel de Controles
                ControlsPanel(
                  currentMode: _viewMode,
                  onViewModeChanged: (mode) {
                    setState(() {
                      _viewMode = mode;
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Tarjeta de Simbología de Golpes (Leyenda)
                _buildLegendCard(),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Candombe Play',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedBuilder(
                animation: SequencerService(),
                builder: (context, _) {
                  final pattern = SequencerService().pattern;
                  return Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AudioService().isInitialized ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: AudioService().isInitialized 
                              ? [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 4)]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${pattern.estilo} - ${pattern.name}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          
          // Metrónomo Visual (reemplaza el 4/4 estático)
          AnimatedBuilder(
            animation: SequencerService(),
            builder: (context, _) {
              final service = SequencerService();
              final isPlaying = service.isPlaying;
              final currentBeat = isPlaying ? (service.currentStep ~/ 4) : -1;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '4/4',
                      style: TextStyle(
                        color: isPlaying ? Colors.white30 : Colors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(4, (index) {
                        final isActive = isPlaying && currentBeat == index;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive 
                                ? Colors.amber 
                                : Colors.white.withOpacity(0.15),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.6),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange.shade400),
              const SizedBox(width: 8),
              const Text(
                'Simbología de Golpes',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendItem(code: 'M', label: 'Mano'),
              _LegendItem(code: 'P', label: 'Palo'),
              _LegendItem(code: 'PA', label: 'Palo Apagado'),
              _LegendItem(code: 'MD', label: 'Madera (Clave)'),
              _LegendItem(code: '*', label: 'Acentuado', color: Colors.amber),
              _LegendItem(code: '-', label: 'Silencio'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String code;
  final String label;
  final Color? color;

  const _LegendItem({
    required this.code,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: color ?? Colors.white.withOpacity(0.1),
            ),
          ),
          child: Text(
            code,
            style: TextStyle(
              color: color ?? Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60, // Usar white60
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
