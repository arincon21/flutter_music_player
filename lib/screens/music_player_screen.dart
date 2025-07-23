import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import '../models/track_data.dart';
import '../widgets/track_list_widget.dart';
import '../utils/enums.dart';
import '../utils/track_finder.dart';
import '../widgets/common/header.dart';
import '../widgets/player/expanded_player.dart';
import '../widgets/player/mini_player.dart';

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

  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;
  List<int> _shuffledIndices = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

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

  void _playNext() {
    if (_trackList.isEmpty || _currentTrackIndex == null) return;

    int? nextIndex;

    if (_isShuffle) {
      int currentShuffledPos = _shuffledIndices.indexOf(_currentTrackIndex!);
      if (currentShuffledPos < _shuffledIndices.length - 1) {
        nextIndex = _shuffledIndices[currentShuffledPos + 1];
      } else if (_repeatMode == RepeatMode.all) {
        _shuffledIndices = List.generate(_trackList.length, (i) => i)
          ..shuffle();
        if (_shuffledIndices.first == _currentTrackIndex! &&
            _trackList.length > 1) {
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

  void _toggleShuffle() {
    setState(() {
      _isShuffle = !_isShuffle;
      if (_isShuffle) {
        if (_repeatMode == RepeatMode.one) {
          _repeatMode = RepeatMode.all;
        }
        _shuffledIndices = List.generate(_trackList.length, (i) => i)
          ..shuffle();
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
        if (_isShuffle) {
          _isShuffle = false;
          _shuffledIndices = [];
        }
      } else {
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
              body: Container(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackListScreen() {
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isPanelExpanded
                  ? ExpandedHeader(onCollapse: () => _panelController.close())
                  : const NormalHeader(),
            ),
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
}