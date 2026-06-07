import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:x_oqs/core/audio/audio_handler.dart';
import 'package:x_oqs/core/providers.dart';
import 'package:x_oqs/shared/widgets/mini_player.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _indexForLocation(String loc) {
    if (loc.startsWith('/search')) return 1;
    if (loc.startsWith('/library')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    final index = _indexForLocation(loc);

    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 140,
            ),
            child: widget.child,
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: MediaQuery.paddingOf(context).bottom + 72,
            child: Consumer(
              builder: (context, ref, _) {
                final handler = ref.watch(audioHandlerProvider);
                return StreamBuilder<PlaybackState>(
                  stream: handler.playbackState,
                  builder: (context, snap) {
                    final st = snap.data;
                    final hasQueue = handler.songs.isNotEmpty;
                    if (!hasQueue) return const SizedBox.shrink();
                    return MiniPlayer(
                      handler: handler,
                      playing: st?.playing ?? false,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
            case 1:
              context.go('/search');
            case 2:
              context.go('/library');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
