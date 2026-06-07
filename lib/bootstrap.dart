import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';

/// Optional early init hook (audio session is configured in [main]).
Future<void> ensureBindings() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
}
