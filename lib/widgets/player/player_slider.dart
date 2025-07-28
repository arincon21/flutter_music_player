import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../utils/formatters.dart';

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
  final Color accentColor = const Color(0xFF8F5AFF); // Morado de lujo
  final Color goldColor = const Color(0xFFFFD700); // Dorado para detalles
  final Color darkBgStart = const Color(0xFF181A20);
  final Color darkBgEnd = const Color(0xFF23272F);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkBgStart, darkBgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: StreamBuilder<Duration>(
        stream: widget.audioPlayer.positionStream,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final double sliderMax = widget.duration.inSeconds.toDouble();
          final double sliderValue = _isDragging
              ? (_dragValue ?? 0.0)
              : position.inSeconds.clamp(0, sliderMax.toInt()).toDouble();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      formatDuration(sliderValue.toInt()),
                      key: ValueKey(sliderValue.toInt()),
                      style: TextStyle(
                        color: goldColor.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  Text(
                    formatDuration(sliderMax.toInt()),
                    style: TextStyle(
                      color: accentColor.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      activeTrackColor: accentColor,
                      inactiveTrackColor: Colors.white.withOpacity(0.15),
                      thumbColor: goldColor,
                      overlayColor: accentColor.withOpacity(0.2),
                    ),
                    child: Slider(
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
                  ),
                  if (_isDragging && _dragValue != null)
                    Positioned(
                      left:
                          (_dragValue! / sliderMax) *
                          (MediaQuery.of(context).size.width - 80),
                      child: Material(
                        color: Colors.transparent,
                        child: AnimatedOpacity(
                          opacity: _isDragging ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              formatDuration(_dragValue!.toInt()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
