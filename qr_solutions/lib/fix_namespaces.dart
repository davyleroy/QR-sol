import 'dart:io';

void main() async {
  final pluginsToFix = [
    'contacts_service-0.6.3',
    'image_gallery_saver-2.0.3',
    'share_plus-6.3.4',
    'flutter_secure_storage',
    'path_provider_android',
    'permission_handler_android',
    // Add any other plugins that might need fixing
  ];

  for (final plugin in pluginsToFix) {
    try {
      // Find the actual plugin directory
      final pubCacheDir =
          'C:/Users/mbuto/AppData/Local/Pub/Cache/hosted/pub.dev';
      final Directory pubCache = Directory(pubCacheDir);
      final List<FileSystemEntity> entities = await pubCache.list().toList();

      String? pluginDir;
      for (var entity in entities) {
        if (entity is Directory && entity.path.contains(plugin)) {
          pluginDir = entity.path;
          break;
        }
      }

      if (pluginDir == null) {
        print('Could not find directory for $plugin');
        continue;
      }

      final buildGradlePath = '$pluginDir/android/build.gradle';
      final manifestPath = '$pluginDir/android/src/main/AndroidManifest.xml';

      // Read manifest to find package name
      final manifestFile = File(manifestPath);
      if (!await manifestFile.exists()) {
        print('Manifest not found for $plugin at $manifestPath');
        continue;
      }

      final manifestContent = await manifestFile.readAsString();
      final packageRegex = RegExp(r'package="([^"]+)"');
      final match = packageRegex.firstMatch(manifestContent);
      if (match == null) {
        print('Could not find package name in manifest for $plugin');
        continue;
      }

      final packageName = match.group(1)!;

      // Update build.gradle
      final buildGradleFile = File(buildGradlePath);
      if (!await buildGradleFile.exists()) {
        print('build.gradle not found for $plugin at $buildGradlePath');
        continue;
      }

      var content = await buildGradleFile.readAsString();
      if (content.contains('namespace')) {
        print('$plugin already has namespace');
        continue;
      }

      content = content.replaceAllMapped(
        RegExp(r'android\s*\{'),
        (match) => '${match.group(0)}\n    namespace "$packageName"',
      );

      await buildGradleFile.writeAsString(content);
      print('Fixed namespace for $plugin with package $packageName');
    } catch (e) {
      print('Error fixing $plugin: $e');
    }
  }
}
