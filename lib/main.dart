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
import 'package:marquee/marquee.dart';

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

  // --- NUEVO: Estados de repetición y aleatorio ---
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;
  List<int> _shuffledIndices = [];

  // Buscador
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  // Streams para sincronización UI/estado
  Stream<Duration> get _positionStream => _audioPlayer.positionStream;
  Stream<PlayerState> get _playerStateStream => _audioPlayer.playerStateStream;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        if (_repeatMode == RepeatMode.one && _currentTrackIndex != null) {
          try {
            await _audioPlayer.seek(Duration.zero);
            await _audioPlayer.play();
          } catch (e) {
            debugPrint('Error al repetir la pista: $e');
          }
        } else {
          _playNext();
        }
      }
    });
    _loadTracks();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
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
    // Extraer metadatos
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
    // Ordenar por artista y luego por título
    trackList.sort((a, b) {
      int artistComparison = a.artist.toLowerCase().compareTo(
        b.artist.toLowerCase(),
      );
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
      return;
    }

    setState(() {
      _currentTrackIndex = index;
      if (_isShuffle) {
        _shuffledIndices = List.generate(_trackList.length, (i) => i)..shuffle();
        _shuffledIndices.remove(index);
        _shuffledIndices.insert(0, index);
      }
    });

    try {
      await _audioPlayer.setFilePath(_trackList[index].file.path);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error al reproducir: $e');
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

  /// Reproduce el siguiente track si existe, considerando aleatorio y repetición.
  void _playNext() {
    if (_trackList.isEmpty || _currentTrackIndex == null) return;

    int? nextIndex;

    if (_isShuffle) {
      int currentShuffledPos = _shuffledIndices.indexOf(_currentTrackIndex!);
      if (currentShuffledPos < _shuffledIndices.length - 1) {
        nextIndex = _shuffledIndices[currentShuffledPos + 1];
      } else if (_repeatMode == RepeatMode.all) {
        _shuffledIndices = List.generate(_trackList.length, (i) => i)..shuffle();
        if (_shuffledIndices.first == _currentTrackIndex! && _trackList.length > 1) {
          final first = _shuffledIndices.removeAt(0);
          _shuffledIndices.insert(1, first);
        }
        nextIndex = _shuffledIndices.first;
      }
    } else {
      if (_currentTrackIndex! < _trackList.length - 1) {
        nextIndex = _currentTrackIndex! + 1;
      } else if (_repeatMode == RepeatMode.all) {
        nextIndex = 0;
      }
    }

    if (nextIndex != null) {
      _onTrackSelected(nextIndex);
    }
  }

  /// Reproduce el track anterior si existe, considerando aleatorio.
  void _playPrevious() {
    if (_trackList.isEmpty || _currentTrackIndex == null) return;

    int? prevIndex;

    if (_isShuffle) {
      int currentShuffledPos = _shuffledIndices.indexOf(_currentTrackIndex!);
      if (currentShuffledPos > 0) {
        prevIndex = _shuffledIndices[currentShuffledPos - 1];
      } else if (_repeatMode == RepeatMode.all) {
        prevIndex = _shuffledIndices.last;
      }
    } else {
      if (_currentTrackIndex! > 0) {
        prevIndex = _currentTrackIndex! - 1;
      } else if (_repeatMode == RepeatMode.all) {
        prevIndex = _trackList.length - 1;
      }
    }

    if (prevIndex != null) {
      _onTrackSelected(prevIndex);
    }
  }

  // --- NUEVO: Alternar modos ---
  void _toggleShuffle() {
    setState(() {
      _isShuffle = !_isShuffle;
      if (_isShuffle) {
        if (_repeatMode == RepeatMode.one) {
          _repeatMode = RepeatMode.all;
        }
        _shuffledIndices = List.generate(_trackList.length, (i) => i)..shuffle();
        if (_currentTrackIndex != null) {
          _shuffledIndices.remove(_currentTrackIndex);
          _shuffledIndices.insert(0, _currentTrackIndex!);
        }
      } else {
        _shuffledIndices = [];
      }
    });
  }

  void _toggleRepeat() {
    setState(() {
      if (_repeatMode == RepeatMode.off) {
        _repeatMode = RepeatMode.all;
      } else if (_repeatMode == RepeatMode.all) {
        _repeatMode = RepeatMode.one;
        // Al repetir una, el aleatorio se desactiva
        if (_isShuffle) {
          _isShuffle = false;
          _shuffledIndices = [];
        }
      } else {
        // De .one a .off
        _repeatMode = RepeatMode.off;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1d2738),
        body: Stack(
          children: [
            _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          _loadingMessage,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                : _buildTrackListScreen(),
            SlidingUpPanel(
              controller: _panelController,
              minHeight: _currentTrackIndex != null ? 120 : 0,
              maxHeight: MediaQuery.of(context).size.height - 100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(40),
              ),
              color: const Color(0xFFfafbff),
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
    // Filtrar la lista según el texto de búsqueda
    List<TrackData> filteredList = _searchText.isEmpty
        ? _trackList
        : _trackList.where((track) {
            return track.title.toLowerCase().contains(_searchText) ||
                (track.artist.toLowerCase().contains(_searchText));
          }).toList();
    return Container(
      color: const Color(0xFF1d2738),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar por título o artista...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: const Color.fromARGB(60, 0, 0, 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 0,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TrackListWidget(
                trackList: filteredList,
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          //Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          Text(
            'Lista de reproducción',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          //Icon(Icons.more_horiz, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildExpandedHeader() {
    return Container(
      key: const ValueKey('expanded_header'),
      height: 80,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //const Icon(Icons.more_horiz, color: Colors.white, size: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'En reproducción',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pantalla de reproducción',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              _panelController.close();
            },
            child: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Mini reproductor sincronizado con el estado del player.
  Widget _buildMiniPlayer() {
    final track = _currentTrackIndex != null
        ? _trackList[_currentTrackIndex!]
        : null;
    final bool hasTrack = track != null;
    final bool canPlayPrev =
        hasTrack &&
        (_currentTrackIndex! > 0 ||
            _repeatMode == RepeatMode.all ||
            _isShuffle);
    final bool canPlayNext =
        hasTrack &&
        (_currentTrackIndex! < _trackList.length - 1 ||
            _repeatMode == RepeatMode.all ||
            _isShuffle);
    if (!hasTrack || _isPanelExpanded) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        _panelController.open();
      },
      child: Container(
        height: 80,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFFFF),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                borderRadius: BorderRadius.circular(25),
              ),
              child: track.artwork != null
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
                  Text(
                    track.title,
                    style: const TextStyle(
                      color: Color(0xFF172438),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: TextStyle(
                      color: const Color(0xFF172438).withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(
                Icons.skip_previous,
                color: canPlayPrev ? const Color(0xFF172438) : Colors.grey,
                size: 24,
              ),
              onPressed: canPlayPrev ? _playPrevious : null,
            ),
            _MiniPlayerPlayPause(audioPlayer: _audioPlayer),
            IconButton(
              icon: Icon(
                Icons.skip_next,
                color: canPlayNext ? const Color(0xFF172438) : Colors.grey,
                size: 24,
              ),
              onPressed: canPlayNext ? _playNext : null,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  // Panel expandido sincronizado con el estado del player.
  Widget _buildExpandedPlayer() {
    final track = _currentTrackIndex != null
        ? _trackList[_currentTrackIndex!]
        : null;
    final bool hasTrack = track != null;
    final bool canPlayPrev =
        hasTrack &&
        (_currentTrackIndex! > 0 ||
            _repeatMode == RepeatMode.all ||
            _isShuffle);
    final bool canPlayNext =
        hasTrack &&
        (_currentTrackIndex! < _trackList.length - 1 ||
            _repeatMode == RepeatMode.all ||
            _isShuffle);
    return hasTrack
        ? Column(
            children: [
              _buildMiniPlayer(),
              Expanded(
                child: _ExpandedPlayerContent(
                  track: track,
                  canPlayPrev: canPlayPrev,
                  canPlayNext: canPlayNext,
                  audioPlayer: _audioPlayer,
                  onPlayPrevious: _playPrevious,
                  onPlayNext: _playNext,
                  isShuffle: _isShuffle,
                  repeatMode: _repeatMode,
                  onToggleShuffle: _toggleShuffle,
                  onToggleRepeat: _toggleRepeat,
                ),
              ),
            ],
          )
        : const SizedBox.shrink();
  }
}

// --- Clases auxiliares al nivel superior ---

// --- NUEVO: Enum para modo de repetición ---
enum RepeatMode { off, all, one }

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
        return Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(0, 0, 0, 0.08), // color de fondo
            shape: BoxShape.circle, // forma circular
          ),
          child: IconButton(
            icon: Icon(
              state.playing ? Icons.pause : Icons.play_arrow,
              color: const Color(0xFF172438),
              size: 24,
            ),
            onPressed: () async {
              if (state.playing) {
                await audioPlayer.pause();
              } else {
                await audioPlayer.play();
              }
            },
          ),
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
  // --- NUEVO: Props para shuffle y repeat ---
  final bool isShuffle;
  final RepeatMode repeatMode;
  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleRepeat;
  const _ExpandedPlayerContent({
    required this.track,
    required this.canPlayPrev,
    required this.canPlayNext,
    required this.audioPlayer,
    required this.onPlayPrevious,
    required this.onPlayNext,
    required this.isShuffle,
    required this.repeatMode,
    required this.onToggleShuffle,
    required this.onToggleRepeat,
  });

  @override
  Widget build(BuildContext context) {
    final duration = track.duration != null
        ? Duration(seconds: track.duration!)
        : Duration.zero;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: const Color(0xFFFF6B6B),
            ),
            child: track.artwork != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(track.artwork!, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 30,
            width: 300,
            child: MarqueeOrStaticText(
              text: track.title,
              style: const TextStyle(
                color: Color(0xFF172438),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            track.artist,
            style: TextStyle(
              color: Color(0xFF172438).withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          _PlayerSlider(audioPlayer: audioPlayer, duration: duration),
          const SizedBox(height: 30),
          // --- NUEVO: Fila de controles con shuffle y repeat ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  isShuffle ? Icons.shuffle_on : Icons.shuffle,
                  color: isShuffle ? Color(0xFF172438) : Colors.grey,
                  size: 28,
                ),
                onPressed: onToggleShuffle,
                tooltip: 'Aleatorio',
              ),
              IconButton(
                icon: Icon(
                  Icons.skip_previous,
                  color: canPlayPrev ? const Color(0xFF172438) : Colors.grey,
                  size: 32,
                ),
                onPressed: canPlayPrev ? onPlayPrevious : null,
              ),
              _ExpandedPlayerPlayPause(audioPlayer: audioPlayer),
              IconButton(
                icon: Icon(
                  Icons.skip_next,
                  color: canPlayNext ? const Color(0xFF172438) : Colors.grey,
                  size: 32,
                ),
                onPressed: canPlayNext ? onPlayNext : null,
              ),
              IconButton(
                icon: Icon(
                  repeatMode == RepeatMode.off
                      ? Icons.repeat
                      : repeatMode == RepeatMode.all
                      ? Icons.repeat
                      : Icons.repeat_one,
                  color: repeatMode == RepeatMode.off
                      ? Colors.grey
                      : Color(0xFF172438),
                  size: 28,
                ),
                onPressed: onToggleRepeat,
                tooltip: repeatMode == RepeatMode.off
                    ? 'Repetir desactivado'
                    : repeatMode == RepeatMode.all
                    ? 'Repetir todo'
                    : 'Repetir una sola',
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
      return '$hours:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
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
                Text(
                  _formatDuration(sliderValue.toInt()),
                  style: TextStyle(
                    color: const Color(0xFF172438).withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDuration(sliderMax.toInt()),
                  style: TextStyle(
                    color: const Color(0xFF172438).withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
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
                      await widget.audioPlayer.seek(
                        Duration(seconds: value.toInt()),
                      );
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
            child: Icon(
              state.playing ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}

class MarqueeOrStaticText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  const MarqueeOrStaticText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: text, style: style);
        final painter = TextPainter(
          text: span,
          maxLines: 1,
          textDirection: TextDirection.ltr,
        );
        painter.layout();

        if (painter.width > constraints.maxWidth) {
          return Marquee(
            text: text,
            style: style,
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            blankSpace: 100.0,
            velocity: 100.0,
            pauseAfterRound: const Duration(seconds: 1),
            startPadding: 10.0,
            accelerationDuration: const Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          );
        } else {
          return Text(text, style: style, textAlign: textAlign);
        }
      },
    );
  }
}
