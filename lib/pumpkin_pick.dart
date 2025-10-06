import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'next_page.dart';

class PickPumpkinPage extends StatefulWidget {
  const PickPumpkinPage({Key? key}) : super(key: key);

  @override
  State<PickPumpkinPage> createState() => _PickPumpkinPageState();
}

class _PickPumpkinPageState extends State<PickPumpkinPage> with SingleTickerProviderStateMixin {
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

  final int pumpkinCount = 3; // 3 pumpkins
  final Random _rand = Random();
  final double pumpkinWidth = 100;
  final double pumpkinHeight = 100;

  @override
  void initState() {
    super.initState();
    correctIndex = _rand.nextInt(pumpkinCount);
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _playBackgroundMusic();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generatePumpkinPositions();
    });
  }

  Future<void> _playBackgroundMusic() async {
    await _player.play(AssetSource('audio/spooky_bgm.mp3'));
    _player.setReleaseMode(ReleaseMode.loop);
  }

  void _generatePumpkinPositions() {
    final maxRadiusX = MediaQuery.of(context).size.width / 2 - pumpkinWidth / 2;
    final maxRadiusY = MediaQuery.of(context).size.height / 2 - pumpkinHeight / 2;
    final maxRadius = min(maxRadiusX, maxRadiusY);

    radii = List.generate(pumpkinCount, (index) => 50 + _rand.nextDouble() * (maxRadius - 50));

    angles = List.generate(pumpkinCount, (index) => (2 * pi / pumpkinCount) * index);

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
      await _player.play(AssetSource('audio/success.mp3'));
    } else {
      setState(() {
        _showJumpScare = true;
        _showTryAgainButton = true;
      });
      await _player.play(AssetSource('audio/jump_scare.mp3'));
    }
  }

  void _tryAgain() {
    setState(() {
      _showJumpScare = false;
      _showTryAgainButton = false;
      _resetGame();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    centerX = MediaQuery.of(context).size.width / 2 - pumpkinWidth / 2;
    centerY = MediaQuery.of(context).size.height / 2 - pumpkinHeight / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Title
          Align(
            alignment: const Alignment(0, -0.85),
            child: Text(
              '🎃 Pick the Pumpkin 🎃',
              style: TextStyle(
                color: Colors.orangeAccent.shade100,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(blurRadius: 10, color: Colors.deepOrange, offset: Offset(2, 2)),
                ],
              ),
            ),
          ),

          // Pumpkins
          ...List.generate(pumpkinCount, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double angle = angles[index] + _controller.value * 2 * pi;
                final double x = centerX + radii[index] * cos(angle) + shakeOffsets[index].dx;
                final double y = centerY + radii[index] * sin(angle) + shakeOffsets[index].dy;

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

          // Correct image overlay with Next button
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NextPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Next'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Jump scare overlay with Try Again button
          if (_showJumpScare)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Stack(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/ghost.png',
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
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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