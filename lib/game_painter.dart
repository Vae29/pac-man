import 'dart:math';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'constants.dart';
import 'game_map.dart';

class GamePainter extends CustomPainter {
  final double pacmanX;
  final double pacmanY;
  final String direction;
  final bool mouthOpen;
  final List<Offset> ghosts;

  GamePainter({
    required this.pacmanX,
    required this.pacmanY,
    required this.direction,
    required this.mouthOpen,
    required this.ghosts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / kMapWidth;
    final cellHeight = size.height / kMapHeight;

    // Fondo negro
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    // Dibujar el mapa
    for (int y = 0; y < kMapHeight; y++) {
      for (int x = 0; x < kMapWidth; x++) {
        final rect = Rect.fromLTWH(
          x * cellWidth,
          y * cellHeight,
          cellWidth,
          cellHeight,
        );

        switch (GameMap.layout[y][x]) {
          case 1: // Pared
            final wallPaint = Paint()..color = kWallColor;
            canvas.drawRect(rect, wallPaint);

            final borderPaint = Paint()..color = kWallBorderColor;
            canvas.drawRect(
              Rect.fromLTWH(rect.left, rect.top, rect.width, 2),
              borderPaint,
            );
            canvas.drawRect(
              Rect.fromLTWH(rect.left, rect.top, 2, rect.height),
              borderPaint,
            );
            break;

          case 2: // Punto normal
            canvas.drawCircle(
              rect.center,
              cellWidth * 0.1,
              Paint()..color = kDotColor,
            );
            break;

          case 3: // Punto grande (power pellet)
            canvas.drawCircle(
              rect.center,
              cellWidth * 0.2,
              Paint()..color = kPowerDotColor,
            );
            final glowPaint = Paint()
              ..color = kPowerDotColor.withAlpha(77)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
            canvas.drawCircle(rect.center, cellWidth * 0.25, glowPaint);
            break;
        }
      }
    }

    _drawGhosts(canvas, cellWidth, cellHeight);
    _drawPacman(canvas, cellWidth, cellHeight);
  }

  void _drawPacman(Canvas canvas, double cellWidth, double cellHeight) {
    final pacRect = Rect.fromCenter(
      center: Offset(
        pacmanX * cellWidth + cellWidth / 2,
        pacmanY * cellHeight + cellHeight / 2,
      ),
      width: cellWidth * 0.88,
      height: cellHeight * 0.88,
    );
    final center = pacRect.center;
    final radius = pacRect.width / 2;
    final pacPaint = Paint()
      ..color = kPacmanColor
      ..isAntiAlias = true;

    final directionAngle = switch (direction) {
      'left' => pi,
      'up' => -pi / 2,
      'down' => pi / 2,
      _ => 0.0,
    };
    final mouthHalfAngle = mouthOpen ? 0.42 : 0.12;
    final pacmanPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        pacRect,
        directionAngle + mouthHalfAngle,
        2 * pi - mouthHalfAngle * 2,
        false,
      )
      ..close();
    canvas.drawPath(pacmanPath, pacPaint);

    final eyeDirection = switch (direction) {
      'left' => const Offset(-0.22, -0.35),
      'up' => const Offset(0.35, -0.22),
      'down' => const Offset(0.35, 0.22),
      _ => const Offset(0.22, -0.35),
    };
    final eyeCenter = Offset(
      center.dx + eyeDirection.dx * radius,
      center.dy + eyeDirection.dy * radius,
    );
    canvas.drawCircle(
      eyeCenter,
      radius * 0.16,
      Paint()
        ..color = Colors.white
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      Offset(
        eyeCenter.dx + cos(directionAngle) * radius * 0.035,
        eyeCenter.dy + sin(directionAngle) * radius * 0.035,
      ),
      radius * 0.09,
      Paint()
        ..color = kEyeColor
        ..isAntiAlias = true,
    );
  }

  void _drawGhosts(Canvas canvas, double cellWidth, double cellHeight) {
    const colors = [Colors.red, Colors.pink];
    for (var index = 0; index < ghosts.length; index++) {
      final center = Offset(
        ghosts[index].dx * cellWidth + cellWidth / 2,
        ghosts[index].dy * cellHeight + cellHeight / 2,
      );
      final rect = Rect.fromCenter(
        center: center,
        width: cellWidth * 0.82,
        height: cellHeight * 0.84,
      );
      final radius = rect.width / 2;
      final body = Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, center.dy)
        ..arcTo(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy),
            width: rect.width,
            height: rect.height,
          ),
          pi,
          pi,
          false,
        )
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(
          rect.left + rect.width * 2 / 3,
          rect.bottom - rect.height * 0.13,
        )
        ..lineTo(rect.left + rect.width / 3, rect.bottom)
        ..lineTo(
          rect.left,
          rect.bottom - rect.height * 0.13,
        )
        ..close();

      canvas.drawPath(
        body,
        Paint()
          ..color = colors[index % colors.length]
          ..isAntiAlias = true,
      );

      for (final eyeOffset in [-0.2, 0.2]) {
        final eyeCenter = Offset(
          center.dx + eyeOffset * rect.width,
          center.dy - rect.height * 0.04,
        );
        canvas.drawCircle(
          eyeCenter,
          radius * 0.24,
          Paint()
            ..color = Colors.white
            ..isAntiAlias = true,
        );
        canvas.drawCircle(
          Offset(eyeCenter.dx + radius * 0.07, eyeCenter.dy),
          radius * 0.11,
          Paint()
            ..color = Colors.blue.shade900
            ..isAntiAlias = true,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return oldDelegate.pacmanX != pacmanX ||
        oldDelegate.pacmanY != pacmanY ||
        oldDelegate.direction != direction ||
        oldDelegate.mouthOpen != mouthOpen ||
        !listEquals(oldDelegate.ghosts, ghosts);
  }
}
