import 'package:flutter/material.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/services/lyrics_service.dart';

class LyricsPanel extends StatefulWidget {
  const LyricsPanel({
    required this.lyrics,
    required this.artist,
    required this.title,
    required this.duration,
    super.key,
  });

  final LyricsService lyrics;
  final String artist;
  final String title;
  final Duration duration;

  @override
  State<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends State<LyricsPanel> {
  late final Future<LyricDocument?> _f = widget.lyrics.fetchLyrics(
    artist: widget.artist,
    title: widget.title,
    duration: widget.duration,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LyricDocument?>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final doc = snap.data;
        if (doc == null || doc.lines.isEmpty) {
          return Center(
            child: Text(
              'No synced lyrics found (LRCLIB).',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          itemCount: doc.lines.length,
          itemBuilder: (c, i) {
            final line = doc.lines[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                line.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ObsidianColors.primaryText,
                      height: 1.35,
                    ),
              ),
            );
          },
        );
      },
    );
  }
}
