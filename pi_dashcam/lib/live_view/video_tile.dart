import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

class VideoTile extends StatelessWidget {
  final int cameraId;
  final VoidCallback onTap;

  const VideoTile({super.key, required this.cameraId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(12),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 72,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 16,
              child: Text(
                'Camera $cameraId',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoStreamPage extends StatelessWidget {
  final int cameraId;
  final String ip;

  const VideoStreamPage({super.key, required this.ip, required this.cameraId});

  @override
  Widget build(BuildContext context) {
    final streamUrl = 'http://$ip:5000/stream/$cameraId';

    return Scaffold(
      appBar: AppBar(title: Text('Camera $cameraId')),
      body: Center(
        child: Mjpeg(stream: streamUrl,
            isLive: true,
            fit: BoxFit.contain,
            error: (context, error, stack) => Text('Stream error: $error')
        )
      ),
    );
  }
}
