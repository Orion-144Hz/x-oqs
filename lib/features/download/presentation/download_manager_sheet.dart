import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_oqs/core/providers.dart';
import 'package:x_oqs/shared/models/download_job.dart';

class DownloadManagerScreen extends ConsumerWidget {
  const DownloadManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = ref.watch(downloadServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: StreamBuilder<List<DownloadJob>>(
        stream: dl.watchJobs(),
        builder: (context, snap) {
          final jobs = snap.data ?? [];
          if (jobs.isEmpty) {
            return Center(
              child: Text(
                'No active downloads.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (c, i) {
              final j = jobs[i];
              return Card(
                child: ListTile(
                  title: Text(j.songId),
                  subtitle: LinearProgressIndicator(value: j.progress),
                  trailing: Text(j.status.name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
