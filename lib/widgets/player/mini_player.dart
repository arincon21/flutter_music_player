
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/track_data.dart';
import '../../utils/enums.dart';
import '../marquee.dart';
import 'player_controls.dart';

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
    final bool canPlayPrev =
        hasTrack &&
        (currentTrackIndex! > 0 ||
            repeatMode == RepeatMode.all ||
            isShuffle);
    final bool canPlayNext =
        hasTrack &&
        (currentTrackIndex! < trackListLength - 1 ||
            repeatMode == RepeatMode.all ||
            isShuffle);
    if (!hasTrack || isPanelExpanded) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        height: 80,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFFFF),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                borderRadius: BorderRadius.circular(25),
              ),
              child: track!.artwork != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(track!.artwork!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Icon(Icons.music_note, color: Color(0xFF172438)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 20, // Altura fija para el Marquee
                      child: MarqueeOrStaticText(
                        text: track!.title,
                        style: const TextStyle(
                          color: Color(0xFF172438),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Text(
                      track!.artist,
                      style: TextStyle(
                        color: const Color(0xFF172438).withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(
                Icons.skip_previous,
                color: canPlayPrev ? const Color(0xFF172438) : Colors.grey,
                size: 24,
              ),
              onPressed: canPlayPrev ? onPlayPrevious : null,
            ),
            MiniPlayerPlayPause(audioPlayer: audioPlayer),
            IconButton(
              icon: Icon(
                Icons.skip_next,
                color: canPlayNext ? const Color(0xFF172438) : Colors.grey,
                size: 24,
              ),
              onPressed: canPlayNext ? onPlayNext : null,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
