import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import '../models/track_data.dart';
import '../widgets/track_list_widget.dart';
import '../utils/enums.dart';
import '../utils/track_finder.dart';
import '../widgets/player/expanded_player.dart';

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

  bool _isPlaying = false;

  // Variables unificadas para shuffle y repeat
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;
  List<int> _shuffledIndices = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Escuchar cambios en el estado del reproductor
    _audioPlayer.playerStateStream.listen((state) async {
      setState(() {
        _isPlaying = state.playing;
      });

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

  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Buscando archivos MP3...';
    });
    List<TrackData> tracks = await TrackFinder().findTracks();
    setState(() {
      _trackList = tracks;
      _isLoading = false;
    });
  }

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
        _shuffledIndices = List.generate(_trackList.length, (i) => i)
          ..shuffle();
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

  // Función para reproducir/pausar
  void _togglePlayPause() async {
    if (_currentTrackIndex == null) {
      // Si no hay canción seleccionada, seleccionar la primera
      if (_trackList.isNotEmpty) {
        _onTrackSelected(0);
      }
      return;
    }

    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  void _playNext() {
    if (_trackList.isEmpty || _currentTrackIndex == null) return;

    int? nextIndex;

    if (_isShuffle && _shuffledIndices.isNotEmpty) {
      int currentShuffledPos = _shuffledIndices.indexOf(_currentTrackIndex!);
      if (currentShuffledPos < _shuffledIndices.length - 1) {
        nextIndex = _shuffledIndices[currentShuffledPos + 1];
      } else if (_repeatMode == RepeatMode.all) {
        // Crear nueva lista mezclada
        _shuffledIndices = List.generate(_trackList.length, (i) => i)
          ..shuffle();
        // Asegurar que no repita la misma canción inmediatamente
        if (_shuffledIndices.first == _currentTrackIndex! &&
            _trackList.length > 1) {
          final first = _shuffledIndices.removeAt(0);
          _shuffledIndices.insert(1, first);
        }
        nextIndex = _shuffledIndices.first;
      }
    } else {
      // Modo normal (sin shuffle)
      if (_currentTrackIndex! < _trackList.length - 1) {
        nextIndex = _currentTrackIndex! + 1;
      } else if (_repeatMode == RepeatMode.all) {
        nextIndex = 0;
      }
    }

    if (nextIndex != null) {
      _onTrackSelected(nextIndex);
    } else {
      // Si no hay siguiente canción y no está en repeat all, detener reproducción
      _audioPlayer.pause();
    }
  }

  void _playPrevious() {
    if (_trackList.isEmpty || _currentTrackIndex == null) return;

    int? prevIndex;

    if (_isShuffle && _shuffledIndices.isNotEmpty) {
      int currentShuffledPos = _shuffledIndices.indexOf(_currentTrackIndex!);
      if (currentShuffledPos > 0) {
        prevIndex = _shuffledIndices[currentShuffledPos - 1];
      } else if (_repeatMode == RepeatMode.all) {
        prevIndex = _shuffledIndices.last;
      }
    } else {
      // Modo normal (sin shuffle)
      if (_currentTrackIndex! > 0) {
        prevIndex = _currentTrackIndex! - 1;
      } else if (_repeatMode == RepeatMode.all) {
        prevIndex = _trackList.length - 1;
      }
    }

    if (prevIndex != null) {
      _onTrackSelected(prevIndex);
    } else {
      // Si no hay canción anterior y no está en repeat all, detener reproducción
      _audioPlayer.pause();
    }
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffle = !_isShuffle;
      if (_isShuffle) {
        // Si activamos shuffle y está en repeat one, cambiar a repeat all
        if (_repeatMode == RepeatMode.one) {
          _repeatMode = RepeatMode.all;
        }
        // Crear lista mezclada
        _shuffledIndices = List.generate(_trackList.length, (i) => i)
          ..shuffle();
        // Poner la canción actual al principio si existe
        if (_currentTrackIndex != null) {
          _shuffledIndices.remove(_currentTrackIndex);
          _shuffledIndices.insert(0, _currentTrackIndex!);
        }
      } else {
        // Limpiar lista mezclada al desactivar shuffle
        _shuffledIndices.clear();
      }
    });
    debugPrint('Shuffle ${_isShuffle ? 'activado' : 'desactivado'}');
  }

  void _toggleRepeat() {
    setState(() {
      switch (_repeatMode) {
        case RepeatMode.off:
          _repeatMode = RepeatMode.all;
          break;
        case RepeatMode.all:
          _repeatMode = RepeatMode.one;
          // Si activamos repeat one, desactivar shuffle
          if (_isShuffle) {
            _isShuffle = false;
            _shuffledIndices.clear();
          }
          break;
        case RepeatMode.one:
          _repeatMode = RepeatMode.off;
          break;
      }
    });

    // Debug para ver el estado actual
    String modeText = '';
    switch (_repeatMode) {
      case RepeatMode.off:
        modeText = 'desactivado';
        break;
      case RepeatMode.all:
        modeText = 'repetir todas';
        break;
      case RepeatMode.one:
        modeText = 'repetir una';
        break;
    }
    debugPrint('Modo repeat: $modeText');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Simulación de un borde debajo de la barra de estado
          Container(
            height: MediaQuery.of(context).padding.top,
            color: Colors.white,
          ),
          const Divider(height: 0.5, thickness: 0.5, color: Color(0x42000000)),

          // Contenido principal arriba
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 90,
                  height: double.infinity,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Expanded(child: SizedBox()),
                      _buildControlIcon(
                        icon: Icons.skip_next,
                        onTap: _playNext,
                      ),
                      const SizedBox(height: 12),
                      _buildPlayButton(),
                      const SizedBox(height: 12),
                      _buildControlIcon(
                        icon: Icons.skip_previous,
                        onTap: _playPrevious,
                      ),
                      const SizedBox(height: 12),
                      _buildControlIcon(
                        icon: _getRepeatIcon(),
                        isActive: _repeatMode != RepeatMode.off,
                        onTap: _toggleRepeat,
                      ),
                      const SizedBox(height: 12),
                      _buildControlIcon(
                        icon: Icons.shuffle,
                        isActive: _isShuffle,
                        onTap: _toggleShuffle,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: constraints.maxWidth,
                        child: Column(
                          children: [
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: InputDecoration(
                                    hintText: 'Buscar por título o artista...',
                                    hintStyle: TextStyle(color: Colors.black87),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Colors.black87,
                                    ),
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      40,
                                      0,
                                      0,
                                      0,
                                    ),
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
                            ),
                            Expanded(
                              child: Container(
                                color: Colors.white,
                                child: _isLoading
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const CircularProgressIndicator(
                                              color: Colors.black87,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _loadingMessage,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : TrackListWidget(
                                        trackList: _searchText.isEmpty
                                            ? _trackList
                                            : _trackList.where((track) {
                                                return track.title
                                                        .toLowerCase()
                                                        .contains(
                                                          _searchText,
                                                        ) ||
                                                    (track.artist
                                                        .toLowerCase()
                                                        .contains(_searchText));
                                              }).toList(),
                                        currentPlayingIndex: _currentTrackIndex,
                                        onTrackSelected: _onTrackSelected,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Footer SIEMPRE abajo, ocupa todo el ancho
          SizedBox(
            width: double.infinity,
            child: SlidingUpPanel(
              controller: _panelController,
              minHeight: _currentTrackIndex != null ? 150 : 0,
              maxHeight: MediaQuery.of(context).size.height,
              panelBuilder: () => ExpandedPlayer(
                track: _currentTrackIndex != null
                    ? _trackList[_currentTrackIndex!]
                    : null,
                isPanelExpanded: _isPanelExpanded,
                onOpen: () => _panelController.open(),
                onPlayPrevious: _playPrevious,
                onPlayNext: _playNext,
                onToggleShuffle: _toggleShuffle,
                onToggleRepeat: _toggleRepeat,
                audioPlayer: _audioPlayer,
                repeatMode: _repeatMode,
                isShuffle: _isShuffle,
                currentTrackIndex: _currentTrackIndex,
                trackListLength: _trackList.length,
              ),
              onPanelSlide: (double pos) {
                setState(() {
                  _isPanelExpanded = pos > 0.5;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlIcon({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 30,
            color: isActive ? Color(0xFF6B7AFF) : Colors.black54,
          ),
        ),
      ),
    );
  }

  IconData _getRepeatIcon() {
    switch (_repeatMode) {
      case RepeatMode.one:
        return Icons.repeat_one;
      case RepeatMode.all:
        return Icons.repeat;
      case RepeatMode.off:
        return Icons.repeat;
    }
  }

  Widget _buildPlayButton() {
    return Container(
      decoration: BoxDecoration(
        color: _isPlaying
            ? Color.fromARGB(18, 107, 122, 255)
            : const Color.fromARGB(255, 233, 233, 233),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _togglePlayPause, // Usar la función corregida
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 40,
              color: _isPlaying ? Color(0xFF6B7AFF) : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
