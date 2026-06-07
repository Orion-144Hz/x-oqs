import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_oqs/core/routing/app_router.dart';
import 'package:x_oqs/core/theme/obsidian_theme.dart';
import 'package:x_oqs/features/settings/providers/settings_notifier.dart';

final _router = createAppRouter();

class XoqsApp extends ConsumerWidget {
  const XoqsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = buildObsidianTheme(
      useDynamicGreen: settings.maybeWhen(
        data: (s) => s.useDynamicTheme,
        orElse: () => false,
      ),
    );
    return MaterialApp.router(
      title: 'X-oqS',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: _router,
    );
  }
}
