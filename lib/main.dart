// main.dart
// Pantalla principal del reproductor de música con integración just_audio y UI profesional.

import 'package:flutter/material.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audiotags/audiotags.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'dart:typed_data';
import 'track_list_widget.dart';

void main() {
  runApp(const MyApp());
}

/// Widget principal de la aplicación.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MusicPlayerScreen(),
    );
  }
}

/// Pantalla principal con reproductor, lista y panel deslizante.
class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});
  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final PanelController _panelController = PanelController();
  late final AudioPlayer _audioPlayer;
  List<TrackData> _trackList = [];
  int? _currentTrackIndex;
  bool _isLoading = true;
  String _loadingMessage = 'Buscando archivos MP3...';
  bool _isPanelExpanded = false;

  // Streams para sincronización UI/estado
  Stream<Duration> get _positionStream => _audioPlayer.positionStream;
  Stream<PlayerState> get _playerStateStream => _audioPlayer.playerStateStream;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadTracks();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Busca archivos MP3 y extrae metadatos.
  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Buscando archivos MP3...';
    });
    List<TrackData> tracks = await _findTracks();
    setState(() {
      _trackList = tracks;
      _isLoading = false;
    });
  }

  /// Busca archivos MP3 en el dispositivo y extrae metadatos.
  Future<List<TrackData>> _findTracks() async {
    List<TrackData> trackList = [];
    Set<String> foundPaths = {};
    List<File> foundFiles = [];
    // Permisos
    bool permissionGranted = false;
    if (Platform.isAndroid) {
      if (await Permission.audio.isDenied) {
        final status = await Permission.audio.request();
        permissionGranted = status.isGranted;
        debugPrint('Permiso audio:  [32m [1m${permissionGranted ? 'concedido' : 'denegado'}\u001b[0m');
      } else {
        permissionGranted = await Permission.audio.isGranted;
        debugPrint('Permiso audio ya concedido: $permissionGranted');
      }
      if (!permissionGranted) {
        if (await Permission.storage.isDenied) {
          final status = await Permission.storage.request();
          permissionGranted = status.isGranted;
          debugPrint('Permiso storage: ${permissionGranted ? 'concedido' : 'denegado'}');
        } else {
          permissionGranted = await Permission.storage.isGranted;
          debugPrint('Permiso storage ya concedido: $permissionGranted');
        }
      }
      if (!permissionGranted && await Permission.manageExternalStorage.isDenied) {
        final status = await Permission.manageExternalStorage.request();
        permissionGranted = status.isGranted;
        debugPrint('Permiso manageExternalStorage: ${permissionGranted ? 'concedido' : 'denegado'}');
      }
    } else {
      permissionGranted = true;
    }
    debugPrint('Permiso final: $permissionGranted');
    if (!permissionGranted) return [];
    // Buscar directorios
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
    // Buscar archivos MP3
    for (Directory dir in searchDirectories) {
      debugPrint('Buscando en: ${dir.path}');
      try {
        await for (FileSystemEntity entity in dir.list(recursive: true, followLinks: false)) {
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
    // Extraer metadatos
    for (int i = 0; i < foundFiles.length; i++) {
      File file = foundFiles[i];
      try {
        Tag? tag = await AudioTags.read(file.path);
        String title = tag?.title?.trim() ?? file.path.split('/').last.replaceAll('.mp3', '');
        String artist = tag?.trackArtist?.trim() ?? 'Artista desconocido';
        String album = tag?.album?.trim() ?? 'Álbum desconocido';
        String genre = tag?.genre?.trim() ?? 'Género desconocido';
        String? albumArtist = tag?.albumArtist?.trim();
        int? duration = tag?.duration ?? 222;
        int? year = tag?.year;
        int? trackNumber = tag?.trackNumber;
        Uint8List? artwork = tag?.pictures?.isNotEmpty == true ? tag!.pictures.first.bytes : null;
        if (title.isEmpty) title = file.path.split('/').last.replaceAll('.mp3', '');
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
      } catch (e) {
        debugPrint('Error al extraer metadatos de ${file.path}: $e');
        trackList.add(TrackData(
          file: file,
          title: file.path.split('/').last.replaceAll('.mp3', ''),
          artist: 'Artista desconocido',
          album: 'Álbum desconocido',
          genre: 'Género desconocido',
        ));
      }
    }
    // Ordenar por artista y luego por título
    trackList.sort((a, b) {
      int artistComparison = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
      if (artistComparison != 0) return artistComparison;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return trackList;
  }

  /// Maneja la selección de un track desde la lista.
  /// Si es el mismo track, alterna play/pause. Si es otro, lo carga y reproduce.
  void _onTrackSelected(int index) async {
    if (_currentTrackIndex == index) {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } else {
      setState(() {
        _currentTrackIndex = index;
      });
      try {
        await _audioPlayer.setFilePath(_trackList[index].file.path);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint('Error al reproducir: $e');
      }
    }
  }

  /// Alterna play/pause desde los controles.
  void _playPause(PlayerState state) async {
    if (state.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  /// Reproduce el siguiente track si existe.
  void _playNext() {
    if (_currentTrackIndex != null && _currentTrackIndex! < _trackList.length - 1) {
      _onTrackSelected(_currentTrackIndex! + 1);
    }
  }

  /// Reproduce el track anterior si existe.
  void _playPrevious() {
    if (_currentTrackIndex != null && _currentTrackIndex! > 0) {
      _onTrackSelected(_currentTrackIndex! - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF172438),
        body: Stack(
          children: [
            _isLoading
                ? Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(_loadingMessage, style: const TextStyle(color: Colors.white)),
                    ],
                  ))
                : _buildTrackListScreen(),
            SlidingUpPanel(
              controller: _panelController,
              minHeight: _currentTrackIndex != null ? 120 : 0,
              maxHeight: MediaQuery.of(context).size.height - 100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              color: const Color(0xFFFEFFFF),
              backdropEnabled: false,
              onPanelSlide: (double pos) {
                setState(() {
                  _isPanelExpanded = pos > 0.5;
                });
              },
              panelBuilder: () => _buildExpandedPlayer(),
              body: Container(),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la pantalla de la lista de tracks.
  Widget _buildTrackListScreen() {
    return Container(
      color: const Color(0xFF172438),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TrackListWidget(
                trackList: _trackList,
                currentPlayingIndex: _currentTrackIndex,
                onTrackSelected: _onTrackSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header animado según el estado del panel.
  Widget _buildHeader() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isPanelExpanded ? _buildExpandedHeader() : _buildNormalHeader(),
    );
  }

  Widget _buildNormalHeader() {
    return Container(
      key: const ValueKey('normal_header'),
      height: 80,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          Text(
            'Poli. Top Tracks this Week',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Icon(Icons.more_horiz, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildExpandedHeader() {
    return Container(
      key: const ValueKey('expanded_header'),
      height: 80,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.more_horiz, color: Colors.white, size: 20),
          Column(
            children: [
              Text(
                'Playing from',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const Row(
                children: [
                  Text(
                    'Poli. Top Tracks this Week. All Genres',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  /// Mini reproductor sincronizado con el estado del player.
  Widget _buildMiniPlayer() {
    final track = _currentTrackIndex != null ? _trackList[_currentTrackIndex!] : null;
    final bool hasTrack = track != null;
    final bool canPlayPrev = hasTrack && _currentTrackIndex! > 0;
    final bool canPlayNext = hasTrack && _currentTrackIndex! < _trackList.length - 1;
    if (!hasTrack || _isPanelExpanded) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 80,
      margin: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Color(0xFFFEFFFF)),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: track!.artwork != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(track.artwork!, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(Icons.music_note, color: Color(0xFF172438)),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.title, style: const TextStyle(color: Color(0xFF172438), fontSize: 14, fontWeight: FontWeight.w600)),
                Text(track.artist, style: TextStyle(color: const Color(0xFF172438).withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.skip_previous, color: canPlayPrev ? const Color(0xFF172438) : Colors.grey, size: 24),
            onPressed: canPlayPrev ? _playPrevious : null,
          ),
          _MiniPlayerPlayPause(audioPlayer: _audioPlayer),
          IconButton(
            icon: Icon(Icons.skip_next, color: canPlayNext ? const Color(0xFF172438) : Colors.grey, size: 24),
            onPressed: canPlayNext ? _playNext : null,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  // Panel expandido sincronizado con el estado del player.
  Widget _buildExpandedPlayer() {
    final track = _currentTrackIndex != null ? _trackList[_currentTrackIndex!] : null;
    final bool hasTrack = track != null;
    final bool canPlayPrev = hasTrack && _currentTrackIndex! > 0;
    final bool canPlayNext = hasTrack && _currentTrackIndex! < _trackList.length - 1;
    return hasTrack
        ? Column(
            children: [
              _buildMiniPlayer(),
              Expanded(child: _ExpandedPlayerContent(
                track: track!,
                canPlayPrev: canPlayPrev,
                canPlayNext: canPlayNext,
                audioPlayer: _audioPlayer,
                onPlayPrevious: _playPrevious,
                onPlayNext: _playNext,
              )),
            ],
          )
        : const SizedBox.shrink();
  }
}

// --- Clases auxiliares al nivel superior ---

/// Botón play/pause optimizado para el minireproductor.
class _MiniPlayerPlayPause extends StatelessWidget {
  final AudioPlayer audioPlayer;
  const _MiniPlayerPlayPause({required this.audioPlayer});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? PlayerState(false, ProcessingState.idle);
        return IconButton(
          icon: Icon(state.playing ? Icons.pause : Icons.play_arrow, color: const Color(0xFF172438), size: 24),
          onPressed: () async {
            if (state.playing) {
              await audioPlayer.pause();
            } else {
              await audioPlayer.play();
            }
          },
        );
      },
    );
  }
}

/// Contenido del panel expandido optimizado.
class _ExpandedPlayerContent extends StatelessWidget {
  final TrackData track;
  final bool canPlayPrev;
  final bool canPlayNext;
  final AudioPlayer audioPlayer;
  final VoidCallback onPlayPrevious;
  final VoidCallback onPlayNext;
  const _ExpandedPlayerContent({
    required this.track,
    required this.canPlayPrev,
    required this.canPlayNext,
    required this.audioPlayer,
    required this.onPlayPrevious,
    required this.onPlayNext,
  });
  @override
  Widget build(BuildContext context) {
    final duration = track.duration != null ? Duration(seconds: track.duration!) : Duration.zero;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFFFF6B6B),
            ),
            child: track.artwork != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(track.artwork!, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(Icons.music_note, color: Colors.white, size: 80),
                  ),
          ),
          const SizedBox(height: 30),
          Text(track.title, style: const TextStyle(color: Color(0xFF172438), fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(track.artist, style: TextStyle(color: Color(0xFF172438).withOpacity(0.6), fontSize: 16)),
          const SizedBox(height: 30),
          _PlayerSlider(audioPlayer: audioPlayer, duration: duration),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous, color: canPlayPrev ? const Color(0xFF172438) : Colors.grey, size: 32),
                onPressed: canPlayPrev ? onPlayPrevious : null,
              ),
              _ExpandedPlayerPlayPause(audioPlayer: audioPlayer),
              IconButton(
                icon: Icon(Icons.skip_next, color: canPlayNext ? const Color(0xFF172438) : Colors.grey, size: 32),
                onPressed: canPlayNext ? onPlayNext : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Slider y tiempos optimizados para el panel expandido.
class _PlayerSlider extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final Duration duration;
  const _PlayerSlider({required this.audioPlayer, required this.duration});
  @override
  State<_PlayerSlider> createState() => _PlayerSliderState();
}

class _PlayerSliderState extends State<_PlayerSlider> {
  double? _dragValue;
  bool _isDragging = false;

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    if (minutes >= 60) {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return '${hours}:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final double sliderMax = widget.duration.inSeconds.toDouble();
        final double sliderValue = _isDragging
            ? (_dragValue ?? 0.0)
            : position.inSeconds.clamp(0, sliderMax.toInt()).toDouble();
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(sliderValue.toInt()), style: TextStyle(color: const Color(0xFF172438).withOpacity(0.6), fontSize: 12)),
                Text(_formatDuration(sliderMax.toInt()), style: TextStyle(color: const Color(0xFF172438).withOpacity(0.6), fontSize: 12)),
              ],
            ),
            Slider(
              value: sliderValue,
              min: 0.0,
              max: sliderMax > 0 ? sliderMax : 1.0,
              onChanged: sliderMax > 0
                  ? (value) {
                      setState(() {
                        _isDragging = true;
                        _dragValue = value;
                      });
                    }
                  : null,
              onChangeEnd: sliderMax > 0
                  ? (value) async {
                      setState(() {
                        _isDragging = false;
                        _dragValue = null;
                      });
                      await widget.audioPlayer.seek(Duration(seconds: value.toInt()));
                    }
                  : null,
            ),
          ],
        );
      },
    );
  }
}

/// Botón play/pause optimizado para el panel expandido.
class _ExpandedPlayerPlayPause extends StatelessWidget {
  final AudioPlayer audioPlayer;
  const _ExpandedPlayerPlayPause({required this.audioPlayer});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? PlayerState(false, ProcessingState.idle);
        return GestureDetector(
          onTap: () async {
            if (state.playing) {
              await audioPlayer.pause();
            } else {
              await audioPlayer.play();
            }
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFF172438),
              shape: BoxShape.circle,
            ),
            child: Icon(state.playing ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
          ),
        );
      },
    );
  }
}
