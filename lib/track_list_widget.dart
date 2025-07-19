import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class TrackListWidget extends StatefulWidget {
  const TrackListWidget({Key? key}) : super(key: key);

  @override
  State<TrackListWidget> createState() => _TrackListWidgetState();
}

class _TrackListWidgetState extends State<TrackListWidget> {
  List<File> mp3Files = [];
  bool isLoading = false;
  bool hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadFiles();
  }

  Future<void> _checkPermissionsAndLoadFiles() async {
    setState(() {
      isLoading = true;
    });

    // Para Android 13+ (API 33+) usar permisos específicos de audio
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
      mp3Files.clear(); // Limpiar la lista antes de empezar
    });

    // Usar un Set para evitar rutas duplicadas.
    Set<String> foundPaths = {};

    try {
      // Obtener directorios comunes donde se almacenan archivos de audio
      List<Directory> searchDirectories = [];

      if (Platform.isAndroid) {
        // Buscar solo en directorios específicos para evitar redundancia.
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
        // Para iOS
        Directory appDir = await getApplicationDocumentsDirectory();
        searchDirectories.add(appDir);
      }

      List<File> foundFiles = [];

      // Buscar archivos MP3 en todos los directorios
      for (Directory dir in searchDirectories) {
        // Pasamos el Set a la función de búsqueda
        await _searchMp3InDirectory(dir, foundFiles, foundPaths);
      }

      // Ordenar por nombre
      foundFiles.sort((a, b) => a.path
          .split('/')
          .last
          .toLowerCase()
          .compareTo(b.path.split('/').last.toLowerCase()));

      setState(() {
        mp3Files = foundFiles;
      });
    } catch (e) {
      print('Error al buscar archivos MP3: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Modificamos la función para que acepte el Set de rutas.
  Future<void> _searchMp3InDirectory(
      Directory dir, List<File> foundFiles, Set<String> foundPaths) async {
    try {
      await for (FileSystemEntity entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          try {
            // SOLUCIÓN DEFINITIVA: Usar la ruta canónica para resolver 'apodos' como /sdcard/ y /storage/emulated/0/
            final canonicalPath = await entity.resolveSymbolicLinks();
            if (foundPaths.add(canonicalPath)) {
              // .add() en un Set devuelve true si el elemento no existía.
              foundFiles.add(entity);
            }
          } catch (e) {
            print('No se pudo resolver la ruta para ${entity.path}: $e');
            // Como fallback, usar la ruta absoluta si la canónica falla.
            final absolutePath = entity.absolute.path;
            if (foundPaths.add(absolutePath)) {
              foundFiles.add(entity);
            }
          }
        }
      }
    } catch (e) {
      // Ignoramos errores de permisos en directorios específicos
      print('Error al buscar en directorio ${dir.path}: $e');
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

  Color _getRandomColor() {
    List<Color> colors = [
      Color(0xFFFF6B6B),
      Color(0xFF6B7AFF),
      Color(0xFF4ECDC4),
      Color(0xFFE8E8E8),
      Color(0xFF2C2C2C),
      Color(0xFFFFD93D),
      Color(0xFF6BCF7F),
      Color(0xFFFF8E53),
      Color(0xFF845EC2),
      Color(0xFF4E9FFF),
    ];
    return colors[DateTime.now().millisecond % colors.length];
  }

  String _getFileCategory(String fileName) {
    // Puedes implementar lógica para categorizar por nombre o metadatos
    List<String> categories = [
      'Hiphop Rap',
      'Alternative',
      'Pop',
      'Rock',
      'Electronic'
    ];
    return categories[fileName.hashCode.abs() % categories.length];
  }

  String _getFileDuration(File file) {
    // Simulamos duración basada en el tamaño del archivo
    // En una implementación real, usarías un package como flutter_ffmpeg o similar
    try {
      int sizeInMB = file.lengthSync() ~/ (1024 * 1024);
      int estimatedMinutes = (sizeInMB * 0.8).round(); // Estimación aproximada
      if (estimatedMinutes < 60) {
        return '${estimatedMinutes}m';
      } else {
        int hours = estimatedMinutes ~/ 60;
        int minutes = estimatedMinutes % 60;
        return '${hours}h ${minutes}m';
      }
    } catch (e) {
      return '3m'; // Valor por defecto
    }
  }

  Widget buildTrackList() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Buscando archivos MP3...',
              style: TextStyle(color: Colors.white),
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

    if (mp3Files.isEmpty) {
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
                'Archivos MP3 (${mp3Files.length})',
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
            itemCount: mp3Files.length,
            itemBuilder: (context, index) {
              File file = mp3Files[index];
              String fileName = _getFileName(file.path);
              String category = _getFileCategory(fileName);
              String duration = _getFileDuration(file);
              Color trackColor = _getRandomColor();

              return Container(
                margin: EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: trackColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: index == 0
                          ? Center(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Color(0xFF172438),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.music_note,
                                color: Colors.white.withOpacity(0.8),
                                size: 24,
                              ),
                            ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Artista desconocido',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          duration,
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        Text(
                          category,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showFileInfo(file),
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

  void _showFileInfo(File file) async {
    FileStat stat = await file.stat();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        title: Text(
          _getFileName(file.path),
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ruta: ${file.path}',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Tamaño: ${_formatFileSize(stat.size)}',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Modificado: ${stat.modified.toString().split('.')[0]}',
              style: TextStyle(color: Colors.white70),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    return buildTrackList();
  }
}
