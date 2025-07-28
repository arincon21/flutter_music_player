String formatDuration(int? seconds) {
  if (seconds == null) return '?:??';
  final int minutes = seconds ~/ 60;
  final int remainingSeconds = seconds % 60;
  if (minutes >= 60) {
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;
    return '$hours:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}
