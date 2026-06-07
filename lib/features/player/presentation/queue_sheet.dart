import 'package:flutter/material.dart';
import 'package:x_oqs/core/audio/audio_handler.dart';
import 'package:x_oqs/core/theme/obsidian_colors.dart';
import 'package:x_oqs/shared/widgets/song_row.dart';

class QueueSheet extends StatelessWidget {
  const QueueSheet({required this.handler, super.key});

  final XoqsAudioHandler handler;

  @override
  Widget build(BuildContext context) {
    final songs = handler.songs;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scroll) {
        return ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
          itemCount: songs.length + 1,
          itemBuilder: (c, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Queue', style: Theme.of(context).textTheme.headlineMedium),
              );
            }
            final s = songs[i - 1];
            final active = (i - 1) == handler.currentIndex;
            return Opacity(
              opacity: active ? 1 : 0.75,
              child: SongRow(
                song: s,
                trailing: Icon(
                  active ? Icons.equalizer : Icons.drag_handle,
                  color: ObsidianColors.secondaryText,
                ),
                onTap: () async {
                  await handler.loadQueue(songs, initialIndex: i - 1);
                  await handler.play();
                },
              ),
            );
          },
        );
      },
    );
  }
}
