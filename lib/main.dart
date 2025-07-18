import 'package:flutter/material.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MusicPlayerScreen(),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  PanelController _panelController = PanelController();
  double _currentPosition = 2.0;
  bool _isPlaying = true;
  bool _isPanelExpanded = false;
  double _panelPosition = 0.0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // Iconos blancos en la barra de estado
      child: Scaffold(
        backgroundColor: Color(0xFF172438),
        body: Stack(
          children: [
            // Contenido principal (pantalla de tracks)
            _buildTrackListScreen(),
            // Panel deslizante
            SlidingUpPanel(
              controller: _panelController,
              minHeight: 120,
              maxHeight:
                  MediaQuery.of(context).size.height -
                  100, // Reducido para no cubrir el título
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              color: Color(0xFFFEFFFF),
              backdropEnabled: false, // Deshabilitado el fondo oscuro
              onPanelSlide: (double pos) {
                setState(() {
                  _panelPosition = pos;
                  _isPanelExpanded = pos > 0.5;
                });
              },
              panelBuilder: () => _buildExpandedPlayer(),
              body: Container(), // Cuerpo vacío porque usamos Stack
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalHeader() {
    return Container(
      key: ValueKey('normal_header'),
      height: 80,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
      key: ValueKey('normal_header'),
      height: 80,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.more_horiz, color: Colors.white, size: 20),
          Column(
            children: [
              Text(
                'Playing from',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Row(
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
          Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildTrackListScreen() {
    return Container(
      color: Color(0xFF172438),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildTrackList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: _isPanelExpanded ? _buildExpandedHeader() : _buildNormalHeader(),
    );
  }

  Widget _buildTrackList() {
    final tracks = [
      {
        'title': 'No Problem (feat. Lil Wayne, 2...',
        'artist': 'Chance the Rapper',
        'duration': '19d',
        'color': Color(0xFFFF6B6B),
        'category': 'Hiphop Rap',
      },
      {
        'title': 'Lonely ft. Lil Skies (Prod. Chris...',
        'artist': 'Yung Bans',
        'duration': '21d',
        'color': Color(0xFF6B7AFF),
        'category': 'Hiphop Rap',
      },
      {
        'title': 'Humility (feat. George Benson)',
        'artist': 'Gorillaz',
        'duration': '3d',
        'color': Color(0xFF4ECDC4),
        'category': 'Alternative',
      },
      {
        'title': 'Fuck Love (feat. Trippie Redd)',
        'artist': 'XXXTENTACION',
        'duration': '29d',
        'color': Color(0xFFE8E8E8),
        'category': 'Hiphop Rap',
      },
      {
        'title': 'Old Town Road',
        'artist': '',
        'duration': '28d',
        'color': Color(0xFF2C2C2C),
        'category': 'Hiphop Rap',
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        100,
      ), // Padding inferior para espacio del miniplayer
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: track['color'] as Color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: track['title'] == 'No Problem (feat. Lil Wayne, 2...'
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
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track['title'] as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((track['artist'] as String).isNotEmpty)
                      Text(
                        track['artist'] as String,
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    track['duration'] as String,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  Text(
                    track['category'] as String,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 8),
              Icon(Icons.more_vert, color: Colors.white60, size: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniPlayer() {
    return AnimatedOpacity(
      opacity: _isPanelExpanded ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: _isPanelExpanded ? 0 : 80,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Color(0xFFFEFFFF)),
        child: _isPanelExpanded
            ? SizedBox.shrink()
            : Row(
                children: [
                  SizedBox(width: 16),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(0xFF172438),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bag (feat. Yung Bans)',
                      style: TextStyle(
                        color: Color(0xFF172438),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.skip_previous, color: Color(0xFF172438), size: 24),
                  SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPlaying = !_isPlaying;
                      });
                    },
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Color(0xFF172438),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.skip_next, color: Color(0xFF172438), size: 24),
                  SizedBox(width: 16),
                ],
              ),
      ),
    );
  }

  Widget _buildExpandedPlayer() {
    return Column(
      children: [
        _buildMiniPlayer(),
        Expanded(child: _buildPlayerContent()),
      ],
    );
  }

  Widget _buildPlayerContent() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 20), // Reducido para dar más espacio
          _buildAlbumArt(),
          SizedBox(height: 30),
          _buildSongInfo(),
          SizedBox(height: 30),
          _buildProgressBar(),
          SizedBox(height: 30),
          _buildControls(),
          SizedBox(height: 20),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      width: 240, // Reducido para ajustarse mejor
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Color(0xFF172438),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: Text(
                '3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            right: 15,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'EXPLICIT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongInfo() {
    return Column(
      children: [
        Text(
          'Bag (feat. Yung Bans)',
          style: TextStyle(
            color: Color(0xFF172438),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Chance the Rapper',
          style: TextStyle(
            color: Color(0xFF172438).withOpacity(0.6),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '2:10',
              style: TextStyle(
                color: Color(0xFF172438).withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            Text(
              '4:33',
              style: TextStyle(
                color: Color(0xFF172438).withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Color(0xFF172438),
            inactiveTrackColor: Color(0xFF172438).withOpacity(0.2),
            thumbColor: Color(0xFF172438),
            trackHeight: 3,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: _currentPosition,
            max: 4.55,
            onChanged: (value) {
              setState(() {
                _currentPosition = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Icon(Icons.skip_previous, color: Color(0xFF172438), size: 32),
        GestureDetector(
          onTap: () {
            setState(() {
              _isPlaying = !_isPlaying;
            });
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Color(0xFF172438),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        Icon(Icons.skip_next, color: Color(0xFF172438), size: 32),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          children: [
            Icon(Icons.shuffle, color: Color(0xFF172438), size: 20),
            SizedBox(width: 4),
            Text(
              '2/14',
              style: TextStyle(color: Color(0xFF172438), fontSize: 12),
            ),
          ],
        ),
        Row(
          children: [
            Icon(Icons.repeat, color: Color(0xFF172438), size: 20),
            SizedBox(width: 4),
            Text(
              '15',
              style: TextStyle(color: Color(0xFF172438), fontSize: 12),
            ),
          ],
        ),
        Row(
          children: [
            Icon(Icons.access_time, color: Color(0xFF172438), size: 20),
            SizedBox(width: 4),
            Text(
              '2:003',
              style: TextStyle(color: Color(0xFF172438), fontSize: 12),
            ),
          ],
        ),
        Icon(Icons.add, color: Color(0xFF172438), size: 20),
      ],
    );
  }
}
