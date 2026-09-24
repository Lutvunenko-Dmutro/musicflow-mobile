import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  final Map<String, String> moves = {
    // Player Feature
    'lib/screens/player_screen.dart': 'lib/features/player/screens/player_screen.dart',
    'lib/screens/queue_screen.dart': 'lib/features/player/screens/queue_screen.dart',
    'lib/widgets/audio_visualizer.dart': 'lib/features/player/widgets/audio_visualizer.dart',
    'lib/widgets/visualizer_painter.dart': 'lib/features/player/widgets/visualizer_painter.dart',
    'lib/widgets/visualizer_settings_sheet.dart': 'lib/features/player/widgets/visualizer_settings_sheet.dart',
    'lib/widgets/mini_player.dart': 'lib/features/player/widgets/mini_player.dart',
    'lib/widgets/mini_player_controls.dart': 'lib/features/player/widgets/mini_player_controls.dart',
    'lib/widgets/mini_player_progress.dart': 'lib/features/player/widgets/mini_player_progress.dart',
    'lib/widgets/player_controls.dart': 'lib/features/player/widgets/player_controls.dart',
    'lib/widgets/player_header.dart': 'lib/features/player/widgets/player_header.dart',
    'lib/widgets/smart_cover.dart': 'lib/features/player/widgets/smart_cover.dart',

    // Library Feature
    'lib/screens/library_screen.dart': 'lib/features/library/screens/library_screen.dart',
    'lib/screens/history_screen.dart': 'lib/features/library/screens/history_screen.dart',
    'lib/widgets/library_app_bar.dart': 'lib/features/library/widgets/library_app_bar.dart',
    'lib/widgets/library_list_item.dart': 'lib/features/library/widgets/library_list_item.dart',

    // Search Feature
    'lib/screens/search_screen.dart': 'lib/features/search/screens/search_screen.dart',
    'lib/widgets/search_input_card.dart': 'lib/features/search/widgets/search_input_card.dart',

    // Lyrics Feature
    'lib/screens/lyrics_screen.dart': 'lib/features/lyrics/screens/lyrics_screen.dart',

    // Settings Feature
    'lib/screens/settings_screen.dart': 'lib/features/settings/screens/settings_screen.dart',

    // Main App
    'lib/screens/main_screen.dart': 'lib/features/main/screens/main_screen.dart',

    // Core Widgets
    'lib/widgets/custom_card.dart': 'lib/core/widgets/custom_card.dart',
    'lib/widgets/song_list_item.dart': 'lib/core/widgets/song_list_item.dart',
    'lib/widgets/song_download_button.dart': 'lib/core/widgets/song_download_button.dart',
  };

  // Step 1: Normalize all imports to absolute package imports first
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();

  for (final file in files) {
    String content = file.readAsStringSync();
    final importRegex = RegExp(r"import\s+['""]([^'""]+)['""];");
    
    final newContent = content.replaceAllMapped(importRegex, (match) {
      final importPath = match.group(1)!;
      if (importPath.startsWith('package:') || importPath.startsWith('dart:')) return match.group(0)!;
      
      final fileDir = file.parent.path;
      final absolutePath = p.normalize(p.join(fileDir, importPath));
      final libIndex = absolutePath.indexOf('lib' + Platform.pathSeparator);
      if (libIndex != -1) {
        final packagePath = absolutePath.substring(libIndex + 4).replaceAll('\\', '/');
        return "import 'package:music_flow_mobile/$packagePath';";
      }
      return match.group(0)!;
    });

    if (content != newContent) file.writeAsStringSync(newContent);
  }

  // Step 2: Create directories and Move files
  for (final entry in moves.entries) {
    final oldPath = p.normalize(entry.key);
    final newPath = p.normalize(entry.value);
    
    final oldFile = File(oldPath);
    if (oldFile.existsSync()) {
      final newFile = File(newPath);
      newFile.parent.createSync(recursive: true);
      oldFile.renameSync(newPath);
      print('Moved $oldPath -> $newPath');
    }
  }

  // Step 3: Update package imports to reflect new locations
  final updatedFiles = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  
  for (final file in updatedFiles) {
    String content = file.readAsStringSync();
    bool changed = false;
    
    for (final entry in moves.entries) {
      final oldPackagePath = entry.key.substring(4).replaceAll('\\', '/'); // remove 'lib/'
      final newPackagePath = entry.value.substring(4).replaceAll('\\', '/');
      
      final searchString = "package:music_flow_mobile/$oldPackagePath";
      final replaceString = "package:music_flow_mobile/$newPackagePath";
      
      if (content.contains(searchString)) {
        content = content.replaceAll(searchString, replaceString);
        changed = true;
      }
    }
    
    if (changed) {
      file.writeAsStringSync(content);
      print('Updated imports in ${file.path}');
    }
  }
}
