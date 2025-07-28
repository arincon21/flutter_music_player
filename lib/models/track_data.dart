import 'dart:io';
import 'dart:typed_data';

class TrackData {
  final File file;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final int? duration; // en segundos
  final int? year;
  final int? trackNumber;
  final String? albumArtist;
  final Uint8List? artwork;

  TrackData({
    required this.file,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    this.duration,
    this.year,
    this.trackNumber,
    this.albumArtist,
    this.artwork,
  });
}
