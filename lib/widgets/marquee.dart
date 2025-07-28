import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class MarqueeOrStaticText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  const MarqueeOrStaticText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: text, style: style);
        final painter = TextPainter(
          text: span,
          maxLines: 1,
          textDirection: TextDirection.ltr,
        );
        painter.layout();

        if (painter.width > constraints.maxWidth) {
          return Marquee(
            text: text,
            style: style,
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            blankSpace: 200.0,
            velocity: 80.0,
            pauseAfterRound: const Duration(seconds: 1),
            startPadding: 0,
            accelerationDuration: const Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          );
        } else {
          return Text(text, style: style, textAlign: textAlign);
        }
      },
    );
  }
}

class MiniPlayerTitle extends StatelessWidget {
  final String title;
  const MiniPlayerTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Color(0xFF172438),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Si el ancho no es válido, mostrar un Text normal
        if (constraints.maxWidth.isInfinite || constraints.maxWidth == 0) {
          return Text(
            title,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        final span = TextSpan(text: title, style: style);
        final painter = TextPainter(
          text: span,
          maxLines: 1,
          textDirection: TextDirection.ltr,
        );
        painter.layout(maxWidth: constraints.maxWidth);

        if (painter.width > constraints.maxWidth) {
          return SizedBox(
            height: 20,
            width: constraints.maxWidth,
            child: Marquee(
              text: title,
              style: style,
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              blankSpace: 50.0,
              velocity: 50.0,
              pauseAfterRound: const Duration(seconds: 1),
              startPadding: 10.0,
              accelerationDuration: const Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: const Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          );
        } else {
          return Text(
            title,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
      },
    );
  }
}
