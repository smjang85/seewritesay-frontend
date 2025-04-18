import 'package:flutter/material.dart';
import 'package:see_write_say/core/helpers/format/format_helper.dart';

class AudioControlBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final ValueChanged<Duration> onSeek;
  final bool isPlaying;
  final bool isPaused;

  const AudioControlBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onStop,
    required this.onSeek,
    required this.isPlaying,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
          max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
          onChanged: (value) => onSeek(Duration(milliseconds: value.toInt())),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              FormatHelper.formatTime(position),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              FormatHelper.formatTime(duration),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                isPaused ? Icons.play_arrow :
                isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              onPressed: onPlayPause,
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: onStop,
            ),
          ],
        ),
      ],
    );
  }
}
