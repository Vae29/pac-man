import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';
import 'game_map.dart';
import 'game_painter.dart';
import 'lose_dialog.dart';
import 'score_display.dart';
import 'win_dialog.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  double pacmanX = 1.0;
  double pacmanY = 1.0;
  int score = 0;
  String direction = 'right';
  List<Offset> ghostPositions = [const Offset(13, 1), const Offset(13, 7)];
  List<Offset?> previousGhostPositions = [null, null];
  final Random random = Random();
  final FocusNode keyboardFocusNode = FocusNode();
  late Timer gameTimer;
  bool gameRunning = true;
  bool mouthOpen = false;
  int gameTicks = 0;

  @override
  void initState() {
    super.initState();
    GameMap.resetMap();
    startGame();
  }

  void startGame() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (gameRunning) {
        gameTick();
      }
    });
  }

  @override
  void dispose() {
    gameTimer.cancel();
    keyboardFocusNode.dispose();
    super.dispose();
  }

  void resetGame() {
    setState(() {
      pacmanX = 1.0;
      pacmanY = 1.0;
      score = 0;
      direction = 'right';
      ghostPositions = [const Offset(13, 1), const Offset(13, 7)];
      previousGhostPositions = [null, null];
      gameTicks = 0;
      mouthOpen = false;
      gameRunning = true;
      GameMap.resetMap();
    });
  }

  void gameTick() {
    var outcome = '';
    setState(() {
      mouthOpen = !mouthOpen;
      gameTicks++;

      double newX = pacmanX;
      double newY = pacmanY;

      switch (direction) {
        case 'right':
          newX += 0.5;
          break;
        case 'left':
          newX -= 0.5;
          break;
        case 'up':
          newY -= 0.5;
          break;
        case 'down':
          newY += 0.5;
          break;
      }

      int gridX = newX.round();
      int gridY = newY.round();

      if (!GameMap.isWall(gridX, gridY)) {
        pacmanX = newX;
        pacmanY = newY;

        final cell = GameMap.layout[gridY][gridX];
        if (cell == 2) {
          GameMap.layout[gridY][gridX] = 0;
          score += kNormalDotPoints;
        } else if (cell == 3) {
          GameMap.layout[gridY][gridX] = 0;
          score += kPowerDotPoints;
        }
      }

      if (gameTicks.isEven) {
        moveGhosts();
      }

      if (hasCollision) {
        gameRunning = false;
        outcome = 'lose';
      } else if (allDotsEaten) {
        gameRunning = false;
        outcome = 'win';
      }
    });

    if (outcome == 'lose') {
      showLoseDialog(context, resetGame);
    } else if (outcome == 'win') {
      showWinDialog(context, score, resetGame);
    }
  }

  void moveGhosts() {
    final nextPositions = List<Offset>.of(ghostPositions);
    for (var index = 0; index < ghostPositions.length; index++) {
      final current = ghostPositions[index];
      final occupiedByOtherGhosts = ghostPositions
          .asMap()
          .entries
          .where((entry) => entry.key != index)
          .map((entry) => entry.value)
          .toSet();
      final neighbors =
          [
            Offset(current.dx + 1, current.dy),
            Offset(current.dx - 1, current.dy),
            Offset(current.dx, current.dy + 1),
            Offset(current.dx, current.dy - 1),
          ].where((position) {
            return !GameMap.isWall(position.dx.toInt(), position.dy.toInt()) &&
                !occupiedByOtherGhosts.contains(position);
          }).toList();

      if (neighbors.isEmpty) continue;

      final alternatives = neighbors
          .where((position) => position != previousGhostPositions[index])
          .toList();
      final options = alternatives.isNotEmpty ? alternatives : neighbors;
      final next = options[random.nextInt(options.length)];

      previousGhostPositions[index] = current;
      nextPositions[index] = next;
    }
    ghostPositions = nextPositions;
  }

  bool get hasCollision => ghostPositions.any(
    (ghost) =>
        (pacmanX - ghost.dx).abs() <= 0.5 && (pacmanY - ghost.dy).abs() <= 0.5,
  );

  bool get allDotsEaten {
    for (final row in GameMap.layout) {
      if (row.any((cell) => cell == 2 || cell == 3)) return false;
    }
    return true;
  }

  void changeDirection(String newDirection) {
    setState(() {
      direction = newDirection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      autofocus: true,
      focusNode: keyboardFocusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent && gameRunning) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            changeDirection('right');
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            changeDirection('left');
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            changeDirection('up');
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            changeDirection('down');
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            ScoreDisplay(score: score, onReset: resetGame),
            Expanded(
              child: Center(
                child: Container(
                  width: 450,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: CustomPaint(
                    painter: GamePainter(
                      pacmanX: pacmanX,
                      pacmanY: pacmanY,
                      direction: direction,
                      mouthOpen: mouthOpen,
                      ghosts: ghostPositions,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Usa las flechas del teclado para mover a Pac-Man',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gameRunning ? '🎮 Jugando...' : '⏸️ Juego terminado',
                    style: TextStyle(
                      color: gameRunning ? Colors.green : Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
