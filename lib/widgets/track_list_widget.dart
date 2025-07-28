import 'dart:io';
import 'package:flutter/material.dart';
import '../models/track_data.dart';
import '../utils/formatters.dart';

class TrackListWidget extends StatelessWidget {
  final List<TrackData> trackList;
  final int? currentPlayingIndex;
  final void Function(int) onTrackSelected;

  const TrackListWidget({
    super.key,
    required this.trackList,
    required this.currentPlayingIndex,
    required this.onTrackSelected,
  });

  Widget buildAlbumArt(TrackData track) {
    if (track.artwork != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.memory(
          track.artwork!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return buildDefaultAlbumArt(track);
          },
        ),
      );
    }
    return buildDefaultAlbumArt(track);
  }

  Widget buildDefaultAlbumArt(TrackData track) {
    final Color trackColor = getColorFromString(track.artist);
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            trackColor.withOpacity(0.8),
            trackColor.withOpacity(1.0),
            Colors.black.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Imagen de fondo para simular textura
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&h=400&fit=crop&crop=entropy&auto=format&fm=jpg&q=60',
                ),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
          ),
          // Overlay oscuro
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color getColorFromString(String text) {
    final int hash = text.hashCode;
    const List<Color> colors = [
      Color(0xFF2D2D2D), // Gris oscuro como en la imagen
      Color(0xFF1A4A3A), // Verde oscuro
      Color(0xFF3D2A1F), // Marrón oscuro
      Color(0xFF1F2937), // Azul gris oscuro
      Color(0xFF374151), // Otro gris
    ];
    return colors[hash.abs() % colors.length];
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void showTrackInfo(BuildContext context, TrackData track) async {
    final FileStat stat = await track.file.stat();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(track.title, style: const TextStyle(color: Colors.black87)),
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
              if (track.albumArtist != null &&
                  track.albumArtist != track.artist)
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
              buildInfoRow(
                'Modificado',
                stat.modified.toString().split('.')[0],
              ),
              const SizedBox(height: 8),
              Text(
                'Ruta: ${track.file.path}',
                style: const TextStyle(color: Colors.black87, fontSize: 12),
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

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
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
            const Icon(Icons.music_off, size: 64, color: Colors.white60),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron archivos MP3',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega archivos MP3 a tu dispositivo para verlos aquí',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: null,
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
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: trackList.length,
            itemBuilder: (context, index) {
              final track = trackList[index];
              return Align(
                alignment:
                    Alignment.centerRight, // Alinea cada item a la derecha
                child: Container(
                  width: 220,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Título de categoría (simulando RAIN, FOREST, etc.)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6B7AFF),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              track.genre.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tarjeta principal
                      GestureDetector(
                        onTap: () => onTrackSelected(index),
                        child: Container(
                          width: 200,
                          height: 185,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              // Sombra principal - más intensa y cercana
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                                spreadRadius: -2,
                              ),
                              // Sombra secundaria - más suave y extendida
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                                spreadRadius: -8,
                              ),
                              // Sombra sutil para profundidad adicional
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 48,
                                offset: const Offset(0, 16),
                                spreadRadius: -12,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Fondo de la tarjeta (imagen de portada o gradiente)
                              track.artwork != null
                                  ? Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: DecorationImage(
                                          image: MemoryImage(track.artwork!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            getColorFromString(track.artist),
                                            getColorFromString(
                                              track.artist,
                                            ).withOpacity(0.8),
                                            Colors.black.withOpacity(0.9),
                                          ],
                                        ),
                                      ),
                                    ),
                              // Imagen de fondo para textura (solo si no hay artwork)
                              if (track.artwork == null)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: const DecorationImage(
                                      image: NetworkImage(
                                        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&h=400&fit=crop&crop=entropy&auto=format&fm=jpg&q=60',
                                      ),
                                      fit: BoxFit.cover,
                                      opacity: 0.15,
                                    ),
                                  ),
                                ),
                              // Overlay gradiente
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                              // Contenido de la tarjeta
                              Padding(
                                padding: const EdgeInsets.all(25),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Número de la pista (grande)
                                    Text(
                                      '${formatDuration(track.duration)}',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white,
                                      ),
                                    ),
                                    // Información de la canción
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            track.title.length > 50
                                                ? '${track.title.substring(0, 20)}...'
                                                : track.title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white,
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Indicador de reproducción
                              if (currentPlayingIndex == index)
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF6B7AFF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Iconos y descripción (como en la imagen)
                      Padding(
                        padding: const EdgeInsets.only(left: 30, top: 20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.share_outlined,
                              size: 18,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.star_outline,
                              size: 18,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                      // Descripción
                      Padding(
                        padding: const EdgeInsets.only(left: 30, top: 10),
                        child: Row(
                          children: [
                            Text(
                              '${track.artist} • ${formatDuration(track.duration)}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
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
