import 'dart:io';
import 'package:flutter/material.dart';
import '../models/track_data.dart';
import '../utils/formatters.dart';

class TrackListWidget extends StatefulWidget {
  final List<TrackData> trackList;
  final int? currentPlayingIndex;
  final void Function(int) onTrackSelected;

  const TrackListWidget({
    super.key,
    required this.trackList,
    required this.currentPlayingIndex,
    required this.onTrackSelected,
  });

  @override
  State<TrackListWidget> createState() => _TrackListWidgetState();
}

class _TrackListWidgetState extends State<TrackListWidget> {
  void _hapticFeedback() {
    // Feedback háptico simple
    try {
      Feedback.forTap(context);
    } catch (_) {}
  }
  final Set<int> _favorites = {};

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
    final trackList = widget.trackList;
    final currentPlayingIndex = widget.currentPlayingIndex;
    final onTrackSelected = widget.onTrackSelected;
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
                color: Colors.white,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega archivos MP3 a tu dispositivo para verlos aquí',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.refresh),
              label: const Text('Volver a buscar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8F5AFF),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      color: const Color(0xFF181A20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: trackList.length,
              itemBuilder: (context, index) {
                final track = trackList[index];
                final isCurrent = currentPlayingIndex == index;
                return Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    width: 220,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: isCurrent
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFD700),
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? const Color(0xFFFFD700)
                                      : const Color(0xFF8F5AFF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                track.genre.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                  letterSpacing: 1.2,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _hapticFeedback();
                            onTrackSelected(index);
                          },
                          child: Container(
                            width: 200,
                            height: 185,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                  spreadRadius: -2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                  spreadRadius: -8,
                                ),
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
                                track.artwork != null
                                    ? Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          image: DecorationImage(
                                            image: MemoryImage(track.artwork!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              getColorFromString(track.artist),
                                              getColorFromString(track.artist).withOpacity(0.8),
                                              Colors.black.withOpacity(0.9),
                                            ],
                                          ),
                                        ),
                                      ),
                                if (track.artwork == null)
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      image: const DecorationImage(
                                        image: NetworkImage(
                                          'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&h=400&fit=crop&crop=entropy&auto=format&fm=jpg&q=60',
                                        ),
                                        fit: BoxFit.cover,
                                        opacity: 0.15,
                                      ),
                                    ),
                                  ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
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
                                Padding(
                                  padding: const EdgeInsets.all(25),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formatDuration(track.duration),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              track.title.length > 50
                                                  ? '${track.title.substring(0, 20)}...'
                                                  : track.title,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                                height: 1.2,
                                                fontFamily: 'Montserrat',
                                              ),
                                              maxLines: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCurrent)
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Icon(
                                      Icons.equalizer,
                                      color: const Color(0xFFFFD700),
                                      size: 24,
                                    ),
                                  ),
                                // Icono de favorito interactivo
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: () {
                                      _hapticFeedback();
                                      setState(() {
                                        if (_favorites.contains(index)) {
                                          _favorites.remove(index);
                                        } else {
                                          _favorites.add(index);
                                        }
                                      });
                                    },
                                    child: Tooltip(
                                      message: _favorites.contains(index)
                                          ? 'Quitar de favoritos'
                                          : 'Agregar a favoritos',
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        child: _favorites.contains(index)
                                            ? Icon(
                                                Icons.star,
                                                key: const ValueKey('fav'),
                                                color: const Color(0xFFFFD700),
                                                size: 32,
                                              )
                                            : Icon(
                                                Icons.star_border,
                                                key: const ValueKey('notfav'),
                                                color: Colors.white70,
                                                size: 32,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 30, top: 20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.share_outlined,
                                size: 18,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 12),
                              // Reemplazado por el icono interactivo en la tarjeta
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 30, top: 10),
                          child: Row(
                            children: [
                              Text(
                                '${track.artist} • ${formatDuration(track.duration)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  height: 1.3,
                                  fontFamily: 'Montserrat',
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
      ),
    );
  }
}
