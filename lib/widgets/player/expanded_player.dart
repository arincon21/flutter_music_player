import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/track_data.dart';
import '../../utils/enums.dart';
import 'mini_player.dart';
import 'expanded_player_content.dart';

class ExpandedPlayer extends StatelessWidget {
  final TrackData? track;
  final bool isPanelExpanded;
  final VoidCallback onOpen;
  final VoidCallback onPlayPrevious;
  final VoidCallback onPlayNext;
  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleRepeat;
  final AudioPlayer audioPlayer;
  final RepeatMode repeatMode;
  final bool isShuffle;
  final int? currentTrackIndex;
  final int trackListLength;

  const ExpandedPlayer({
    super.key,
    required this.track,
    required this.isPanelExpanded,
    required this.onOpen,
    required this.onPlayPrevious,
    required this.onPlayNext,
    required this.onToggleShuffle,
    required this.onToggleRepeat,
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
        (currentTrackIndex! > 0 || repeatMode == RepeatMode.all || isShuffle);
    final bool canPlayNext =
        hasTrack &&
        (currentTrackIndex! < trackListLength - 1 ||
            repeatMode == RepeatMode.all ||
            isShuffle);
    return hasTrack
        ? Column(
            children: [
              MiniPlayer(
                track: track,
                isPanelExpanded: isPanelExpanded,
                onOpen: onOpen,
                onPlayPrevious: onPlayPrevious,
                onPlayNext: onPlayNext,
                audioPlayer: audioPlayer,
                repeatMode: repeatMode,
                isShuffle: isShuffle,
                currentTrackIndex: currentTrackIndex,
                trackListLength: trackListLength,
              ),
              Expanded(
                child: ExpandedPlayerContent(
                  track: track!,
                  canPlayPrev: canPlayPrev,
                  canPlayNext: canPlayNext,
                  audioPlayer: audioPlayer,
                  onPlayPrevious: onPlayPrevious,
                  onPlayNext: onPlayNext,
                  isShuffle: isShuffle,
                  repeatMode: repeatMode,
                  onToggleShuffle: onToggleShuffle,
                  onToggleRepeat: onToggleRepeat,
                ),
              ),
            ],
          )
        : const SizedBox.shrink();
  }
}
