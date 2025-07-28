import 'dart:io';
import 'package:audiotags/audiotags.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/track_data.dart';

class TrackFinder {
  Future<List<TrackData>> findTracks() async {
    final List<TrackData> trackList = [];
    final Set<String> foundPaths = {};
    final List<File> foundFiles = [];
    bool permissionGranted = false;

    // --- Permisos optimizados y logging ---
    // Aquí se puede integrar la lógica para mostrar notificaciones de permisos
    if (Platform.isAndroid) {
      final permissions = [
        Permission.audio,
        Permission.storage,
        Permission.manageExternalStorage,
      ];
      for (final perm in permissions) {
        if (await perm.isDenied) {
          final status = await perm.request();
          permissionGranted = status.isGranted;
          debugPrint('Permiso ${perm.value}: ${permissionGranted ? 'concedido' : 'denegado'}');
          // Aquí se puede disparar una notificación si el permiso es denegado
          if (!permissionGranted) break;
        } else {
          permissionGranted = await perm.isGranted;
          debugPrint('Permiso ${perm.value} ya concedido: $permissionGranted');
        }
      }
    } else {
      permissionGranted = true;
    }
    debugPrint('Permiso final: $permissionGranted');
    if (!permissionGranted) {
      // Aquí se puede disparar una notificación de error de permisos
      return [];
    }

    // --- Directorios a buscar ---
    // Aquí se puede agregar lógica para carpetas personalizadas o más formatos
    final List<Directory> searchDirectories = [];
    if (Platform.isAndroid) {
      final List<String> commonMusicPaths = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
        '/sdcard/Music',
        '/sdcard/Download',
      ];
      for (final path in commonMusicPaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          searchDirectories.add(dir);
        }
      }
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      searchDirectories.add(appDir);
      debugPrint('Directorio app agregado: ${appDir.path}');
    }

    // --- Búsqueda de archivos mp3 ---
    // Aquí se puede agregar soporte para más formatos
    for (final dir in searchDirectories) {
      debugPrint('Buscando en: ${dir.path}');
      try {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
            try {
              final canonicalPath = await entity.resolveSymbolicLinks();
              if (foundPaths.add(canonicalPath)) foundFiles.add(entity);
            } catch (e) {
              final absolutePath = entity.absolute.path;
              if (foundPaths.add(absolutePath)) foundFiles.add(entity);
            }
          }
        }
      } catch (e) {
        debugPrint('Error al buscar en directorio ${dir.path}: $e');
        // Aquí se puede disparar una notificación de error de búsqueda
      }
    }

    // --- Extracción de metadatos y creación de TrackData ---
    // Aquí se puede agregar lógica para notificaciones de canción encontrada
    for (final file in foundFiles) {
      try {
        final tag = await AudioTags.read(file.path);
        final title = tag?.title?.trim().isNotEmpty == true
            ? tag!.title!.trim()
            : file.path.split('/').last.replaceAll('.mp3', '');
        final artist = tag?.trackArtist?.trim().isNotEmpty == true
            ? tag!.trackArtist!.trim()
            : 'Artista desconocido';
        final album = tag?.album?.trim().isNotEmpty == true
            ? tag!.album!.trim()
            : 'Álbum desconocido';
        final genre = tag?.genre?.trim().isNotEmpty == true
            ? tag!.genre!.trim()
            : 'Género desconocido';
        final albumArtist = tag?.albumArtist?.trim();
        final duration = tag?.duration ?? 222;
        final year = tag?.year;
        final trackNumber = tag?.trackNumber;
        final artwork = tag?.pictures.isNotEmpty == true ? tag!.pictures.first.bytes : null;

        trackList.add(TrackData(
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
        ));
        // Aquí se puede disparar una notificación de nueva canción agregada
      } catch (e) {
        debugPrint('Error al extraer metadatos de ${file.path}: $e');
        // Aquí se puede disparar una notificación de error de metadatos
        trackList.add(TrackData(
          file: file,
          title: file.path.split('/').last.replaceAll('.mp3', ''),
          artist: 'Artista desconocido',
          album: 'Álbum desconocido',
          genre: 'Género desconocido',
        ));
      }
    }

    // Ordena por artista y título
    trackList.sort((a, b) {
      final artistComparison = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
      if (artistComparison != 0) return artistComparison;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return trackList;
  }
}
