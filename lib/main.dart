import 'package:flutter/material.dart';
import 'features/candombe_sequencer/presentation/pages/sequencer_page.dart';

void main() {
  // Garantizar inicialización de bindings
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Candombe Play',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent, // Manejado por el gradiente de SequencerPage
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SequencerPage(),
    );
  }
}
