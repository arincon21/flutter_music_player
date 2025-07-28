import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VerticalPlayerControls extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback? onShuffle;
  final VoidCallback? onRepeat;
  final double? volume;
  final ValueChanged<double>? onVolumeChanged;

  const VerticalPlayerControls({
    super.key,
    required this.audioPlayer,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    this.onShuffle,
    this.onRepeat,
    this.volume,
    this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF8F5AFF);
    final goldColor = const Color(0xFFFFD700);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF181A20), Color(0xFF23272F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.skip_previous_rounded, color: goldColor, size: 32),
            onPressed: onPrevious,
            tooltip: 'Anterior',
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isPlaying
                ? IconButton(
                    key: const ValueKey('pause'),
                    icon: Icon(Icons.pause_rounded, color: accentColor, size: 40),
                    onPressed: onPlayPause,
                    tooltip: 'Pausar',
                  )
                : IconButton(
                    key: const ValueKey('play'),
                    icon: Icon(Icons.play_arrow_rounded, color: accentColor, size: 40),
                    onPressed: onPlayPause,
                    tooltip: 'Reproducir',
                  ),
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: Icon(Icons.skip_next_rounded, color: goldColor, size: 32),
            onPressed: onNext,
            tooltip: 'Siguiente',
          ),
          const SizedBox(height: 24),
          if (onShuffle != null)
            IconButton(
              icon: Icon(Icons.shuffle_rounded, color: accentColor.withOpacity(0.7), size: 28),
              onPressed: onShuffle,
              tooltip: 'Aleatorio',
            ),
          if (onRepeat != null)
            IconButton(
              icon: Icon(Icons.repeat_rounded, color: accentColor.withOpacity(0.7), size: 28),
              onPressed: onRepeat,
              tooltip: 'Repetir',
            ),
          const SizedBox(height: 24),
          if (volume != null && onVolumeChanged != null)
            Column(
              children: [
                Icon(Icons.volume_up_rounded, color: goldColor, size: 24),
                Slider(
                  value: volume!,
                  min: 0.0,
                  max: 1.0,
                  activeColor: accentColor,
                  inactiveColor: Colors.white.withOpacity(0.15),
                  onChanged: onVolumeChanged,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
