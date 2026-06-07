import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> tracksDirectory() async {
  final dir = await getApplicationDocumentsDirectory();
  final d = p.join(dir.path, 'tracks');
  return d;
}
