
import 'dart:io';
import 'dart:typed_data';
import 'package:audiotags/audiotags.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/track_data.dart';

class TrackFinder {
  Future<List<TrackData>> findTracks() async {
    List<TrackData> trackList = [];
    Set<String> foundPaths = {};
    List<File> foundFiles = [];
    bool permissionGranted = false;
    if (Platform.isAndroid) {
      if (await Permission.audio.isDenied) {
        final status = await Permission.audio.request();
        permissionGranted = status.isGranted;
        debugPrint(
          'Permiso audio:  [32m [1m${permissionGranted ? 'concedido' : 'denegado'}\u001b[0m',
        );
      } else {
        permissionGranted = await Permission.audio.isGranted;
        debugPrint('Permiso audio ya concedido: $permissionGranted');
      }
      if (!permissionGranted) {
        if (await Permission.storage.isDenied) {
          final status = await Permission.storage.request();
          permissionGranted = status.isGranted;
          debugPrint(
            'Permiso storage: ${permissionGranted ? 'concedido' : 'denegado'}',
          );
        } else {
          permissionGranted = await Permission.storage.isGranted;
          debugPrint('Permiso storage ya concedido: $permissionGranted');
        }
      }
      if (!permissionGranted &&
          await Permission.manageExternalStorage.isDenied) {
        final status = await Permission.manageExternalStorage.request();
        permissionGranted = status.isGranted;
        debugPrint(
          'Permiso manageExternalStorage: ${permissionGranted ? 'concedido' : 'denegado'}',
        );
      }
    } else {
      permissionGranted = true;
    }
    debugPrint('Permiso final: $permissionGranted');
    if (!permissionGranted) return [];
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
      debugPrint('Directorio app agregado: ${appDir.path}');
    }
    for (Directory dir in searchDirectories) {
      debugPrint('Buscando en: ${dir.path}');
      try {
        await for (FileSystemEntity entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
            debugPrint('MP3 encontrado: ${entity.path}');
            try {
              final canonicalPath = await entity.resolveSymbolicLinks();
              if (foundPaths.add(canonicalPath)) {
                foundFiles.add(entity);
              }
            } catch (e) {
              final absolutePath = entity.absolute.path;
              if (foundPaths.add(absolutePath)) {
                foundFiles.add(entity);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error al buscar en directorio ${dir.path}: $e');
      }
    }
    for (int i = 0; i < foundFiles.length; i++) {
      File file = foundFiles[i];
      try {
        Tag? tag = await AudioTags.read(file.path);
        String title =
            tag?.title?.trim() ??
            file.path.split('/').last.replaceAll('.mp3', '');
        String artist = tag?.trackArtist?.trim() ?? 'Artista desconocido';
        String album = tag?.album?.trim() ?? 'Álbum desconocido';
        String genre = tag?.genre?.trim() ?? 'Género desconocido';
        String? albumArtist = tag?.albumArtist?.trim();
        int? duration = tag?.duration ?? 222;
        int? year = tag?.year;
        int? trackNumber = tag?.trackNumber;
        Uint8List? artwork = tag?.pictures.isNotEmpty == true
            ? tag!.pictures.first.bytes
            : null;
        if (title.isEmpty) {
          title = file.path.split('/').last.replaceAll('.mp3', '');
        }
        trackList.add(
          TrackData(
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
          ),
        );
      } catch (e) {
        debugPrint('Error al extraer metadatos de ${file.path}: $e');
        trackList.add(
          TrackData(
            file: file,
            title: file.path.split('/').last.replaceAll('.mp3', ''),
            artist: 'Artista desconocido',
            album: 'Álbum desconocido',
            genre: 'Género desconocido',
          ),
        );
      }
    }
    trackList.sort((a, b) {
      int artistComparison = a.artist.toLowerCase().compareTo(
        b.artist.toLowerCase(),
      );
      if (artistComparison != 0) return artistComparison;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return trackList;
  }
}
