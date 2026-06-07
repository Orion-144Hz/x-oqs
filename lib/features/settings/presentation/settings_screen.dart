import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:x_oqs/core/constants/app_constants.dart';
import 'package:x_oqs/core/providers.dart';
import 'package:x_oqs/features/settings/providers/settings_notifier.dart';
import 'package:x_oqs/shared/widgets/storage_meter.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final cache = ref.watch(cacheProvider);
    final dl = ref.watch(downloadServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Streaming quality', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          settings.when(
            data: (s) => Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Auto'),
                  selected: s.streamKbps == null,
                  onSelected: (_) => notifier.setStreamKbps(null),
                ),
                for (final k in [128, 256, 320])
                  ChoiceChip(
                    label: Text('$k kbps'),
                    selected: s.streamKbps == k,
                    onSelected: (_) => notifier.setStreamKbps(k),
                  ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 24),
          Text('Download quality', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          settings.when(
            data: (s) => Wrap(
              spacing: 8,
              children: [
                for (final k in [128, 192, 256, 320])
                  ChoiceChip(
                    label: Text('$k kbps'),
                    selected: s.downloadKbps == k,
                    onSelected: (_) => notifier.setDownloadKbps(k),
                  ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          Text('Storage', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          settings.when(
            data: (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Slider(
                  value: s.storageLimitBytes.toDouble().clamp(
                    AppConstants.minStorageLimitBytes.toDouble(),
                    AppConstants.maxStorageLimitBytes.toDouble(),
                  ),
                  min: AppConstants.minStorageLimitBytes.toDouble(),
                  max: AppConstants.maxStorageLimitBytes.toDouble(),
                  divisions: 49,
                  label: '${(s.storageLimitBytes / (1024 * 1024 * 1024)).toStringAsFixed(0)} GB',
                  onChanged: (v) => notifier.setStorageLimitBytes(v.round()),
                ),
                FutureBuilder<int>(
                  future: dl.getTotalBytesUsed(),
                  builder: (context, snap) {
                    final used = snap.data ?? 0;
                    return StorageMeter(
                      usedBytes: used,
                      limitBytes: s.storageLimitBytes,
                    );
                  },
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Import from Spotify'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/import/spotify'),
          ),
          SwitchListTile(
            title: const Text('Dynamic theme (Material You seed)'),
            subtitle: const Text('Uses green seed; extend with dynamic color extraction later.'),
            value: settings.valueOrNull?.useDynamicTheme ?? false,
            onChanged: (v) => notifier.setDynamicTheme(v),
          ),
          const SizedBox(height: 8),
          Text('Language', style: Theme.of(context).textTheme.headlineMedium),
          settings.when(
            data: (s) => DropdownButton<String>(
              value: s.localeCode,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
              ],
              onChanged: (c) {
                if (c != null) notifier.setLocaleCode(c);
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Download manager'),
            onTap: () => context.push('/downloads'),
          ),
          ListTile(
            title: const Text('Clear URL & search cache'),
            onTap: () async {
              await cache.clearStreamAndSearchCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              }
            },
          ),
          const SizedBox(height: 24),
          Text('X-oqS v1.0.0', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
