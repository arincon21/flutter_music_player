import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioVisualizer extends StatefulWidget {
  final AudioPlayer audioPlayer;
  const AudioVisualizer({super.key, required this.audioPlayer});

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> {
  // Simulación visual simple, listo para integrar paquetes avanzados
  double _level = 0.0;

  @override
  void initState() {
    super.initState();
    widget.audioPlayer.positionStream.listen((_) {
      setState(() {
        _level = (0.5 + 0.5 * (DateTime.now().millisecond % 100) / 100);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 180,
          height: 40 + 40 * _level,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Color(0xFF8F5AFF), Color(0xFFFFD700)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
