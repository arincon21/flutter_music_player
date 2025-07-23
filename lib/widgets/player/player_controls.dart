
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MiniPlayerPlayPause extends StatelessWidget {
  final AudioPlayer audioPlayer;
  const MiniPlayerPlayPause({required this.audioPlayer});
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

class ExpandedPlayerPlayPause extends StatelessWidget {
  final AudioPlayer audioPlayer;
  const ExpandedPlayerPlayPause({required this.audioPlayer});
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
