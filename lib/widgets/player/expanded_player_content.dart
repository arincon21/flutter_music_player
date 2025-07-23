
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/track_data.dart';
import '../../utils/enums.dart';
import '../marquee.dart';
import 'player_controls.dart';
import 'player_slider.dart';

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
    final duration = track.duration != null
        ? Duration(seconds: track.duration!)
        : Duration.zero;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: const Color(0xFFFF6B6B),
            ),
            child: track.artwork != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(track.artwork!, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 30,
            width: 300,
            child: MarqueeOrStaticText(
              text: track.title,
              style: const TextStyle(
                color: Color(0xFF172438),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            track.artist,
            style: TextStyle(
              color: Color(0xFF172438).withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          PlayerSlider(audioPlayer: audioPlayer, duration: duration),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  isShuffle ? Icons.shuffle_on : Icons.shuffle,
                  color: isShuffle ? Color(0xFF172438) : Colors.grey,
                  size: 28,
                ),
                onPressed: onToggleShuffle,
                tooltip: 'Aleatorio',
              ),
              IconButton(
                icon: Icon(
                  Icons.skip_previous,
                  color: canPlayPrev ? const Color(0xFF172438) : Colors.grey,
                  size: 32,
                ),
                onPressed: canPlayPrev ? onPlayPrevious : null,
              ),
              ExpandedPlayerPlayPause(audioPlayer: audioPlayer),
              IconButton(
                icon: Icon(
                  Icons.skip_next,
                  color: canPlayNext ? const Color(0xFF172438) : Colors.grey,
                  size: 32,
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
                      : Color(0xFF172438),
                  size: 28,
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
  }
}
