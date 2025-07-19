import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audiotags/audiotags.dart';

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

class TrackListWidget extends StatefulWidget {
  const TrackListWidget({Key? key}) : super(key: key);

  @override
  State<TrackListWidget> createState() => _TrackListWidgetState();
}

class _TrackListWidgetState extends State<TrackListWidget> {
  List<TrackData> trackList = [];
  bool isLoading = false;
  bool hasPermission = false;
  String loadingMessage = 'Buscando archivos MP3...';

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadFiles();
  }

  Future<void> _checkPermissionsAndLoadFiles() async {
    setState(() {
      isLoading = true;
      loadingMessage = 'Verificando permisos...';
    });

    bool permissionGranted = false;

    if (Platform.isAndroid) {
      // Para Android 13+ (API 33+)
      if (await Permission.audio.isDenied) {
        final status = await Permission.audio.request();
        permissionGranted = status.isGranted;
      } else {
        permissionGranted = await Permission.audio.isGranted;
      }

      // Fallback para versiones anteriores
      if (!permissionGranted) {
        if (await Permission.storage.isDenied) {
          final status = await Permission.storage.request();
          permissionGranted = status.isGranted;
        } else {
          permissionGranted = await Permission.storage.isGranted;
        }
      }

      // Para Android 11+ también necesitamos MANAGE_EXTERNAL_STORAGE en algunos casos
      if (!permissionGranted &&
          await Permission.manageExternalStorage.isDenied) {
        final status = await Permission.manageExternalStorage.request();
        permissionGranted = status.isGranted;
      }
    } else {
      permissionGranted = true; // Para iOS o otras plataformas
    }

    setState(() {
      hasPermission = permissionGranted;
    });

    if (permissionGranted) {
      await _loadMp3Files();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadMp3Files() async {
    setState(() {
      isLoading = true;
      loadingMessage = 'Buscando archivos MP3...';
      trackList.clear();
    });

    Set<String> foundPaths = {};
    List<File> foundFiles = [];

    try {
      List<Directory> searchDirectories = [];

      if (Platform.isAndroid) {
        List<String> commonMusicPaths = [
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Documents',
          '/sdcard/Music',
          '/sdcard/Download',
        ];

        for (String path in commonMusicPaths) {
          Directory dir = Directory(path);
          if (await dir.exists()) {
            searchDirectories.add(dir);
          }
        }
      } else {
        Directory appDir = await getApplicationDocumentsDirectory();
        searchDirectories.add(appDir);
      }

      // Buscar archivos MP3
      for (Directory dir in searchDirectories) {
        await _searchMp3InDirectory(dir, foundFiles, foundPaths);
      }

      setState(() {
        loadingMessage =
            'Procesando metadatos (${foundFiles.length} archivos)...';
      });

      // Procesar metadatos de cada archivo
      List<TrackData> tracks = [];
      for (int i = 0; i < foundFiles.length; i++) {
        File file = foundFiles[i];

        setState(() {
          loadingMessage =
              'Procesando metadatos (${i + 1}/${foundFiles.length})...';
        });

        TrackData trackData = await _extractMetadata(file);
        tracks.add(trackData);
      }

      // Ordenar por artista y luego por título
      tracks.sort((a, b) {
        int artistComparison =
            a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
        if (artistComparison != 0) return artistComparison;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

      setState(() {
        trackList = tracks;
      });
    } catch (e) {
      print('Error al buscar archivos MP3: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _searchMp3InDirectory(
      Directory dir, List<File> foundFiles, Set<String> foundPaths) async {
    try {
      await for (FileSystemEntity entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          try {
            final canonicalPath = await entity.resolveSymbolicLinks();
            if (foundPaths.add(canonicalPath)) {
              foundFiles.add(entity);
            }
          } catch (e) {
            print('No se pudo resolver la ruta para ${entity.path}: $e');
            final absolutePath = entity.absolute.path;
            if (foundPaths.add(absolutePath)) {
              foundFiles.add(entity);
            }
          }
        }
      }
    } catch (e) {
      print('Error al buscar en directorio ${dir.path}: $e');
    }
  }

  Future<TrackData> _extractMetadata(File file) async {
    try {
      // Leer metadatos usando audiotags
      Tag? tag = await AudioTags.read(file.path);

      String title = tag?.title?.trim() ?? _getFileName(file.path);
      String artist = tag?.trackArtist?.trim() ?? 'Artista desconocido';
      String album = tag?.album?.trim() ?? 'Álbum desconocido';
      String genre = tag?.genre?.trim() ?? 'Género desconocido';
      String? albumArtist = tag?.albumArtist?.trim();
      int? duration = tag?.duration ?? 222;
      int? year = tag?.year;
      int? trackNumber = tag?.trackNumber;
      Uint8List? artwork =
          tag?.pictures?.isNotEmpty == true ? tag!.pictures.first.bytes : null;

      // DEBUG: Imprimir los metadatos extraídos
      print('Metadatos extraídos de: ${file.path}');
      print('  Título: ${title}');
      print('  Artista: ${artist}');
      print('  Álbum: ${album}');
      print('  Género: ${genre}');
      print('  Artista del álbum: ${albumArtist}');
      print('  Duración: ${duration}');
      print('  Año: ${year}');
      print('  Número de pista: ${trackNumber}');
      print('  Artwork: ${artwork != null ? 'Sí' : 'No'}');

      // Si el título está vacío, usar el nombre del archivo
      if (title.isEmpty) {
        title = _getFileName(file.path);
      }

      return TrackData(
        file: file,
        title: title,
        artist: artist,
        album: album,
        genre: genre,
        duration: duration,
        year: year,
        trackNumber: trackNumber,
        albumArtist: albumArtist,
        artwork: artwork,
      );
    } catch (e) {
      print('Error al extraer metadatos de ${file.path}: $e');

      // Fallback si no se pueden extraer los metadatos
      return TrackData(
        file: file,
        title: _getFileName(file.path),
        artist: 'Artista desconocido',
        album: 'Álbum desconocido',
        genre: 'Género desconocido',
      );
    }
  }

  String _getFileName(String path) {
    return path.split('/').last.replaceAll('.mp3', '');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color _getColorFromString(String text) {
    // Generar color consistente basado en el texto
    int hash = text.hashCode;
    List<Color> colors = [
      Color(0xFFFF6B6B), // Rojo
      Color(0xFF6B7AFF), // Azul
      Color(0xFF4ECDC4), // Verde azulado
      Color(0xFFFFD93D), // Amarillo
      Color(0xFF6BCF7F), // Verde
      Color(0xFFFF8E53), // Naranja
      Color(0xFF845EC2), // Púrpura
      Color(0xFF4E9FFF), // Azul claro
      Color(0xFFFF6B9D), // Rosa
      Color(0xFF95E1D3), // Verde menta
    ];
    return colors[hash.abs() % colors.length];
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '?:??';

    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;

    if (minutes >= 60) {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return '${hours}:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildAlbumArt(TrackData track) {
    if (track.artwork != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          track.artwork!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAlbumArt(track);
          },
        ),
      );
    }
    return _buildDefaultAlbumArt(track);
  }

  Widget _buildDefaultAlbumArt(TrackData track) {
    Color trackColor = _getColorFromString(track.artist);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          color: Colors.white.withOpacity(0.8),
          size: 24,
        ),
      ),
    );
  }

  Widget buildTrackList() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              loadingMessage,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_off,
              size: 64,
              color: Colors.white60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin permisos de almacenamiento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Se necesitan permisos para acceder a los archivos de audio',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkPermissionsAndLoadFiles,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6B7AFF),
              ),
              child: const Text('Solicitar permisos'),
            ),
          ],
        ),
      );
    }

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
              onPressed: _loadMp3Files,
              icon: Icon(Icons.refresh),
              label: Text('Volver a buscar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6B7AFF),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                onTap: _loadMp3Files,
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: Icon(
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
            padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: trackList.length,
            itemBuilder: (context, index) {
              TrackData track = trackList[index];

              return Container(
                margin: EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    _buildAlbumArt(track),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track.artist,
                            style: TextStyle(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDuration(track.duration),
                          style: TextStyle(color: Colors.white60, fontSize: 12),
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
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showTrackInfo(track),
                      child: Icon(Icons.more_vert,
                          color: Colors.white60, size: 20),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showTrackInfo(TrackData track) async {
    FileStat stat = await track.file.stat();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        title: Text(
          track.title,
          style: TextStyle(color: Colors.white),
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
              _buildInfoRow('Artista', track.artist),
              if (track.albumArtist != null &&
                  track.albumArtist != track.artist)
                _buildInfoRow('Artista del álbum', track.albumArtist!),
              _buildInfoRow('Álbum', track.album),
              _buildInfoRow('Género', track.genre),
              if (track.year != null)
                _buildInfoRow('Año', track.year.toString()),
              if (track.trackNumber != null)
                _buildInfoRow('Pista', track.trackNumber.toString()),
              _buildInfoRow('Duración', _formatDuration(track.duration)),
              const SizedBox(height: 8),
              _buildInfoRow('Tamaño', _formatFileSize(stat.size)),
              _buildInfoRow(
                  'Modificado', stat.modified.toString().split('.')[0]),
              const SizedBox(height: 8),
              Text(
                'Ruta: ${track.file.path}',
                style: TextStyle(color: Colors.white70, fontSize: 12),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.white70),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildTrackList();
  }
}
