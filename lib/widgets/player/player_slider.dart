import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../utils/formatters.dart';

class PlayerSlider extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final Duration duration;
  const PlayerSlider({required this.audioPlayer, required this.duration});
  @override
  State<PlayerSlider> createState() => PlayerSliderState();
}

class PlayerSliderState extends State<PlayerSlider> {
  double? _dragValue;
  bool _isDragging = false;

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
                  formatDuration(sliderValue.toInt()),
                  style: TextStyle(
                    color: const Color(0xFF172438).withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  formatDuration(sliderMax.toInt()),
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
