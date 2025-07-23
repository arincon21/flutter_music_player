import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track_data.dart';
import '../utils/enums.dart';
import 'marquee.dart';

class MiniPlayerPlayPause extends StatelessWidget {
  final AudioPlayer audioPlayer;
  const MiniPlayerPlayPause({super.key, required this.audioPlayer});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? PlayerState(false, ProcessingState.idle);
        return Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(0, 0, 0, 0.08), // color de fondo
            shape: BoxShape.circle, // forma circular
          ),
          child: IconButton(
            icon: Icon(
              state.playing ? Icons.pause : Icons.play_arrow,
              color: const Color(0xFF172438),
              size: 24,
            ),
            onPressed: () async {
              if (state.playing) {
                await audioPlayer.pause();
              } else {
                await audioPlayer.play();
              }
            },
          ),
        );
      },
    );
  }
}

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

class PlayerSlider extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final Duration duration;
  const PlayerSlider({
    super.key,
    required this.audioPlayer,
    required this.duration,
  });
  @override
  State<PlayerSlider> createState() => PlayerSliderState();
}

class PlayerSliderState extends State<PlayerSlider> {
  double? _dragValue;
  bool _isDragging = false;

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    if (minutes >= 60) {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return '$hours:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final double sliderMax = widget.duration.inSeconds.toDouble();
        final double sliderValue = _isDragging
            ? (_dragValue ?? 0.0)
            : position.inSeconds.clamp(0, sliderMax.toInt()).toDouble();
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(sliderValue.toInt()),
                  style: TextStyle(
                    color: const Color(0xFF172438).withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDuration(sliderMax.toInt()),
                  style: TextStyle(
                    color: const Color(0xFF172438).withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Slider(
              value: sliderValue,
              min: 0.0,
              max: sliderMax > 0 ? sliderMax : 1.0,
              onChanged: sliderMax > 0
                  ? (value) {
                      setState(() {
                        _isDragging = true;
                        _dragValue = value;
                      });
                    }
                  : null,
              onChangeEnd: sliderMax > 0
                  ? (value) async {
                      setState(() {
                        _isDragging = false;
                        _dragValue = null;
                      });
                      await widget.audioPlayer.seek(
                        Duration(seconds: value.toInt()),
                      );
                    }
                  : null,
            ),
          ],
        );
      },
    );
  }
}

class ExpandedPlayerPlayPause extends StatelessWidget {
  final AudioPlayer audioPlayer;
  const ExpandedPlayerPlayPause({super.key, required this.audioPlayer});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? PlayerState(false, ProcessingState.idle);
        return GestureDetector(
          onTap: () async {
            if (state.playing) {
              await audioPlayer.pause();
            } else {
              await audioPlayer.play();
            }
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFF172438),
              shape: BoxShape.circle,
            ),
            child: Icon(
              state.playing ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}
