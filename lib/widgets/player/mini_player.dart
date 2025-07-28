import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/track_data.dart';
import '../../utils/enums.dart';
import '../marquee.dart';
import 'player_slider.dart';

class MiniPlayer extends StatelessWidget {
  final TrackData? track;
  final bool isPanelExpanded;
  final VoidCallback onOpen;
  final VoidCallback onPlayPrevious;
  final VoidCallback onPlayNext;
  final AudioPlayer audioPlayer;
  final RepeatMode repeatMode;
  final bool isShuffle;
  final int? currentTrackIndex;
  final int trackListLength;

  const MiniPlayer({
    super.key,
    required this.track,
    required this.isPanelExpanded,
    required this.onOpen,
    required this.onPlayPrevious,
    required this.onPlayNext,
    required this.audioPlayer,
    required this.repeatMode,
    required this.isShuffle,
    required this.currentTrackIndex,
    required this.trackListLength,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasTrack = track != null;
    if (!hasTrack || isPanelExpanded) {
      return const SizedBox.shrink();
    }
    final duration = track?.duration != null
        ? Duration(seconds: track!.duration!)
        : Duration.zero;
    final bool isPlaying = audioPlayer.playing;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: onOpen,
          child: Container(
            height: 135,
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: const Color(0xFFFEFFFF),
              border: Border(
                top: BorderSide(color: Color(0x42000000), width: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: track?.artwork != null
                            ? Image.memory(
                                track!.artwork!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                color: const Color(0xFFFF6B6B),
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track?.title ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF172438),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              track?.artist ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF172438).withOpacity(0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: const Color(0xFF172438),
                          size: 32,
                        ),
                        onPressed: () {
                          if (isPlaying) {
                            audioPlayer.pause();
                          } else {
                            audioPlayer.play();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Barra de progreso debajo de la información de la canción
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: PlayerSlider(
                    audioPlayer: audioPlayer,
                    duration: duration,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
