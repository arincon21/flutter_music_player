// track_list_widget.dart
// Widget profesional y optimizado para mostrar la lista de canciones con carátula y metadatos.

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Modelo de datos para una pista de audio.
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

/// Widget que muestra la lista de canciones y permite seleccionar una para reproducir.
class TrackListWidget extends StatelessWidget {
  final List<TrackData> trackList;
  final int? currentPlayingIndex;
  final void Function(int) onTrackSelected;

  const TrackListWidget({
    Key? key,
    required this.trackList,
    required this.currentPlayingIndex,
    required this.onTrackSelected,
  }) : super(key: key);

  /// Construye la carátula del álbum o un ícono por defecto.
  Widget buildAlbumArt(TrackData track) {
    if (track.artwork != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.memory(
          track.artwork!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return buildDefaultAlbumArt(track);
          },
        ),
      );
    }
    return buildDefaultAlbumArt(track);
  }

  /// Carátula por defecto basada en el artista.
  Widget buildDefaultAlbumArt(TrackData track) {
    final Color trackColor = getColorFromString(track.artist);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note,
          color: Colors.white70,
          size: 24,
        ),
      ),
    );
  }

  /// Genera un color consistente a partir de un string.
  Color getColorFromString(String text) {
    final int hash = text.hashCode;
    const List<Color> colors = [
      Color(0xFFFF6B6B), Color(0xFF6B7AFF), Color(0xFF4ECDC4), Color(0xFFFFD93D),
      Color(0xFF6BCF7F), Color(0xFFFF8E53), Color(0xFF845EC2), Color(0xFF4E9FFF),
      Color(0xFFFF6B9D), Color(0xFF95E1D3),
    ];
    return colors[hash.abs() % colors.length];
  }

  /// Formatea la duración en mm:ss o hh:mm:ss.
  String formatDuration(int? seconds) {
    if (seconds == null) return '?:??';
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    if (minutes >= 60) {
      final int hours = minutes ~/ 60;
      final int remainingMinutes = minutes % 60;
      return '${hours}:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Formatea el tamaño del archivo en B, KB o MB.
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Muestra un diálogo con los metadatos completos de la pista.
  void showTrackInfo(BuildContext context, TrackData track) async {
    final FileStat stat = await track.file.stat();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          track.title,
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (track.artwork != null) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      track.artwork!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              buildInfoRow('Artista', track.artist),
              if (track.albumArtist != null && track.albumArtist != track.artist)
                buildInfoRow('Artista del álbum', track.albumArtist!),
              buildInfoRow('Álbum', track.album),
              buildInfoRow('Género', track.genre),
              if (track.year != null)
                buildInfoRow('Año', track.year.toString()),
              if (track.trackNumber != null)
                buildInfoRow('Pista', track.trackNumber.toString()),
              buildInfoRow('Duración', formatDuration(track.duration)),
              const SizedBox(height: 8),
              buildInfoRow('Tamaño', formatFileSize(stat.size)),
              buildInfoRow('Modificado', stat.modified.toString().split('.')[0]),
              const SizedBox(height: 8),
              Text(
                'Ruta: ${track.file.path}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFF6B7AFF)),
            ),
          ),
        ],
      ),
    );
  }

  /// Fila de información para el diálogo de metadatos.
  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white70),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (trackList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_off,
              size: 64,
              color: Colors.white60,
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron archivos MP3',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega archivos MP3 a tu dispositivo para verlos aquí',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: null, // Deshabilitado, la recarga la maneja el padre
              icon: const Icon(Icons.refresh),
              label: const Text('Volver a buscar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B7AFF),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Música (${trackList.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: null, // Deshabilitado, la recarga la maneja el padre
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white60,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: trackList.length,
            itemBuilder: (context, index) {
              final track = trackList[index];
              return GestureDetector(
                onTap: () => onTrackSelected(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: currentPlayingIndex == index
                        ? Border.all(color: const Color(0xFF6B7AFF), width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      buildAlbumArt(track),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              track.artist,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (track.album != 'Álbum desconocido')
                              Text(
                                track.album,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatDuration(track.duration),
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                          if (track.year != null)
                            Text(
                              track.year.toString(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => showTrackInfo(context, track),
                        child: const Icon(Icons.more_vert,
                            color: Colors.white60, size: 20),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
