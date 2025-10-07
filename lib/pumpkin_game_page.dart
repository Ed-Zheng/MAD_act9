import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class PumpkinGamePage extends StatefulWidget {
  final int level; // Level number

  const PumpkinGamePage({Key? key, this.level = 1}) : super(key: key);

  @override
  State<PumpkinGamePage> createState() => _PumpkinGamePageState();
}

class _PumpkinGamePageState extends State<PumpkinGamePage>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  late int correctIndex;
  bool _showJumpScare = false;
  bool _showTryAgainButton = false;
  bool _showCorrectImage = false;
  bool _showNextButton = false;

  late List<double> angles;
  late List<double> radii;
  late List<Offset> shakeOffsets;
  late double centerX, centerY;
  late AnimationController _controller;
  final Random _rand = Random();

  double get pumpkinWidth => max(100 - widget.level * 5, 50); // smaller each level
  double get pumpkinHeight => pumpkinWidth;
  int get pumpkinCount => min(2 + widget.level, 5); // Max pumpkins = 5
  bool get isWinLevel => widget.level > 5; // Level 6 → Win Screen

  final List<String> _scareImages = [
    'assets/images/ghost.png',
    'assets/images/witch.png',
    'assets/images/spider.png',
    'assets/images/bats.png',
    'assets/images/skeleton.png',
  ];

  final List<String> _scareSounds = [
    'audios/ghost.mp3',
    'audios/witch.mp3',
    'audios/spider.mp3',
    'audios/bats.mp3',
    'audios/skeleton.mp3',
  ];

  int? _currentScareIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: max(20 - widget.level * 2, 8))) // faster each level
      ..repeat();

    if (!isWinLevel) {
      correctIndex = _rand.nextInt(pumpkinCount);
      _player.setVolume(1.0);
      _playBackgroundMusic();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generatePumpkinPositions();
      });
    }
  }

  Future<void> _playBackgroundMusic() async {
    await _player.play(AssetSource('audios/background_music.mp3'));
    _player.setReleaseMode(ReleaseMode.loop);
  }

  void _generatePumpkinPositions() {
    final maxRadiusX = MediaQuery.of(context).size.width / 2 - pumpkinWidth / 2;
    final maxRadiusY = MediaQuery.of(context).size.height / 2 - pumpkinHeight / 2;
    final maxRadius = min(maxRadiusX, maxRadiusY);

    radii = List.generate(
        pumpkinCount, (index) => 50 + _rand.nextDouble() * (maxRadius - 50));

    angles = List.generate(
        pumpkinCount, (index) => (2 * pi / pumpkinCount) * index);

    shakeOffsets = List.generate(pumpkinCount, (_) => Offset.zero);
  }

  void _shakePumpkins() {
    const int shakes = 6;
    int count = 0;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        shakeOffsets = List.generate(pumpkinCount, (_) {
          double dx = (_rand.nextDouble() * 20) - 10;
          double dy = (_rand.nextDouble() * 20) - 10;
          return Offset(dx, dy);
        });
      });
      count++;
      if (count >= shakes) {
        timer.cancel();
        setState(() {
          shakeOffsets = List.generate(pumpkinCount, (_) => Offset.zero);
        });
      }
    });
  }

  void _resetGame() {
    correctIndex = _rand.nextInt(pumpkinCount);
    _generatePumpkinPositions();
    _shakePumpkins();
  }

  void _pickPumpkin(int index) async {
    if (index == correctIndex) {
      setState(() {
        _showCorrectImage = true;
        _showNextButton = true;
      });
      await _player.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      await _player.play(AssetSource('audios/success.mp3'));
    } else {
      _currentScareIndex = _rand.nextInt(_scareImages.length);
      setState(() {
        _showJumpScare = true;
        _showTryAgainButton = true;
      });
      await _player.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      await _player.play(AssetSource(_scareSounds[_currentScareIndex!]));
    }
  }

  void _tryAgain() {
    setState(() {
      _showJumpScare = false;
      _showTryAgainButton = false;
      _resetGame();
    });
  }

  void _nextLevel() {
    if (isWinLevel) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PumpkinGamePage(level: 1)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PumpkinGamePage(level: widget.level + 1)),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isWinLevel) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🎉 You Win! 🎉',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _nextLevel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                child: const Text('Play Again'),
              )
            ],
          ),
        ),
      );
    }

    centerX = MediaQuery.of(context).size.width / 2 - pumpkinWidth / 2;
    centerY = MediaQuery.of(context).size.height / 2 - pumpkinHeight / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.85),
            child: Text(
              '🎃 Level ${widget.level} 🎃',
              style: TextStyle(
                color: Colors.orangeAccent.shade100,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                      blurRadius: 10,
                      color: Colors.deepOrange,
                      offset: Offset(2, 2)),
                ],
              ),
            ),
          ),
          ...List.generate(pumpkinCount, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double angle =
                    angles[index] + _controller.value * 2 * pi;
                final double x =
                    centerX + radii[index] * cos(angle) + shakeOffsets[index].dx;
                final double y =
                    centerY + radii[index] * sin(angle) + shakeOffsets[index].dy;

                return Positioned(
                  left: x,
                  top: y,
                  child: GestureDetector(
                    onTap: () => _pickPumpkin(index),
                    child: Image.asset(
                      'assets/images/pumpkin.png',
                      width: pumpkinWidth,
                    ),
                  ),
                );
              },
            );
          }),
          if (_showCorrectImage)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Stack(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/correct.png',
                        width: 300,
                        height: 300,
                      ),
                    ),
                    if (_showNextButton)
                      Positioned(
                        bottom: 50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ElevatedButton(
                            onPressed: _nextLevel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              textStyle: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            child: Text(
                                isWinLevel ? 'Play Again' : 'Next Level'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (_showJumpScare)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Stack(
                  children: [
                    Center(
                      child: Image.asset(
                        _currentScareIndex != null
                            ? _scareImages[_currentScareIndex!]
                            : 'assets/images/ghost.png',
                        width: 300,
                        height: 300,
                      ),
                    ),
                    if (_showTryAgainButton)
                      Positioned(
                        bottom: 50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ElevatedButton(
                            onPressed: _tryAgain,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              textStyle: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Try Again'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
