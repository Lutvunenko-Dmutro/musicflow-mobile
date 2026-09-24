import 'dart:io';

void main() {
  final Map<String, String> colorMap = {
    'const Color(0xFFE52D27)': 'AppColors.primary',
    'const Color(0xFFF59E0B)': 'AppColors.accentOrange',
    'const Color(0xFFFBBF24)': 'AppColors.accentYellow',
    'const Color(0xFF38BDF8)': 'AppColors.accentBlue',
    'const Color(0xFF3B82F6)': 'AppColors.accentDeepBlue',
    'const Color(0xFFFF4B4B)': 'AppColors.dotRed',
    'const Color(0xFFFCD34D)': 'AppColors.dotOrange',
    'const Color(0xFFFDE68A)': 'AppColors.dotYellow',
    'const Color(0xFF7DD3FC)': 'AppColors.dotLightBlue',
    'const Color(0xFF93C5FD)': 'AppColors.dotBlue',
    'const Color(0xFF0F0F0F)': 'AppColors.background',
    'const Color(0xFF161616)': 'AppColors.surface',
    'const Color(0xFF1E1E1E)': 'AppColors.surfaceElevated',
    'const Color(0xFF2C2C2C)': 'AppColors.surfaceLight',
    'const Color(0xFFE53935)': 'AppColors.primary',
    'Color(0xFFE53935)': 'AppColors.primary',
    'const Color(0xFF212121)': 'AppColors.surfaceElevated',
    'const Color(0xFF2A2A2A)': 'AppColors.surfaceMuted',
    'Color(0xFF555555)': 'AppColors.iconMuted',
  };

  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart') && !f.path.contains('app_colors.dart') && !f.path.contains('app_theme.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;
    
    for (final entry in colorMap.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        changed = true;
      }
    }
    
    if (changed) {
      // Calculate relative path to core/app_colors.dart
      final parts = file.path.split(Platform.pathSeparator);
      final depth = parts.length - 2; // -1 for 'lib', -1 for filename
      final prefix = depth == 0 ? '' : List.filled(depth, '..').join('/') + '/';
      final importStmt = "import '${prefix}core/app_colors.dart';\n";
      
      if (!content.contains('app_colors.dart')) {
        // Insert after first import
        final firstImportIdx = content.indexOf('import ');
        if (firstImportIdx != -1) {
          final endOfLine = content.indexOf('\n', firstImportIdx);
          content = content.substring(0, endOfLine + 1) + importStmt + content.substring(endOfLine + 1);
        } else {
          content = importStmt + content;
        }
      }
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
