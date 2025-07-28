import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/track_data.dart';
import '../../utils/enums.dart';
import '../marquee.dart';
import 'player_controls.dart';

class ExpandedPlayerContent extends StatelessWidget {
  final TrackData track;
  final bool canPlayPrev;
  final bool canPlayNext;
  final AudioPlayer audioPlayer;
  final VoidCallback onPlayPrevious;
  final VoidCallback onPlayNext;
  final bool isShuffle;
  final RepeatMode repeatMode;
  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleRepeat;
  const ExpandedPlayerContent({
    super.key,
    required this.track,
    required this.canPlayPrev,
    required this.canPlayNext,
    required this.audioPlayer,
    required this.onPlayPrevious,
    required this.onPlayNext,
    required this.isShuffle,
    required this.repeatMode,
    required this.onToggleShuffle,
    required this.onToggleRepeat,
  });

  @override
  Widget build(BuildContext context) {
    // Visual premium: gradiente, sombra, bordes dorados, animación sutil
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                width: constraints.maxWidth < 260 ? constraints.maxWidth : 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(
                    colors: [Color(0xFF23272F), Color(0xFF181A20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Color(0xFFFFD700),
                    width: 2.5,
                  ),
                ),
                child: track.artwork != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Image.memory(track.artwork!, fit: BoxFit.cover),
                      )
                    : const Center(
                        child: Icon(
                          Icons.music_note,
                          color: Color(0xFF8F5AFF),
                          size: 90,
                        ),
                      ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 34,
                width: constraints.maxWidth < 320 ? constraints.maxWidth : 320,
                child: MarqueeOrStaticText(
                  text: track.title,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                track.artist,
                style: const TextStyle(
                  color: Color(0xFF8F5AFF),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      isShuffle ? Icons.shuffle_on : Icons.shuffle,
                      color: isShuffle ? Color(0xFF8F5AFF) : Colors.grey,
                      size: 30,
                    ),
                    onPressed: onToggleShuffle,
                    tooltip: 'Aleatorio',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.skip_previous,
                      color: canPlayPrev ? Color(0xFFFFD700) : Colors.grey,
                      size: 36,
                    ),
                    onPressed: canPlayPrev ? onPlayPrevious : null,
                  ),
                  ExpandedPlayerPlayPause(audioPlayer: audioPlayer),
                  IconButton(
                    icon: Icon(
                      Icons.skip_next,
                      color: canPlayNext ? Color(0xFFFFD700) : Colors.grey,
                      size: 36,
                    ),
                    onPressed: canPlayNext ? onPlayNext : null,
                  ),
                  IconButton(
                    icon: Icon(
                      repeatMode == RepeatMode.off
                          ? Icons.repeat
                          : repeatMode == RepeatMode.all
                          ? Icons.repeat
                          : Icons.repeat_one,
                      color: repeatMode == RepeatMode.off
                          ? Colors.grey
                          : Color(0xFF8F5AFF),
                      size: 30,
                    ),
                    onPressed: onToggleRepeat,
                    tooltip: repeatMode == RepeatMode.off
                        ? 'Repetir desactivado'
                        : repeatMode == RepeatMode.all
                        ? 'Repetir todo'
                        : 'Repetir una sola',
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
