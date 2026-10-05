import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    
    // Replace all relative imports with package: imports
    final importRegex = RegExp(r"import\s+['""]([^'""]+)['""];");
    
    final newContent = content.replaceAllMapped(importRegex, (match) {
      final importPath = match.group(1)!;
      
      // Skip already package or dart imports
      if (importPath.startsWith('package:') || importPath.startsWith('dart:')) {
        return match.group(0)!;
      }
      
      // Resolve relative path
      final fileDir = file.parent.path;
      final absolutePath = p.normalize(p.join(fileDir, importPath));
      
      // Convert to package path
      // Extract everything after 'lib\' or 'lib/'
      final libIndex = absolutePath.indexOf('lib${Platform.pathSeparator}');
      if (libIndex != -1) {
        final packagePath = absolutePath.substring(libIndex + 4).replaceAll('\\', '/');
        return "import 'package:music_flow_mobile/$packagePath';";
      }
      
      return match.group(0)!;
    });

    if (content != newContent) {
      file.writeAsStringSync(newContent);
      // ignore: avoid_print
      print('Updated imports in ${file.path}');
    }
  }
}
