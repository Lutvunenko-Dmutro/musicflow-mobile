import 'package:get_it/get_it.dart';
import 'package:music_flow_mobile/services/database_service.dart';
import 'package:music_flow_mobile/services/download_service.dart';
import 'package:music_flow_mobile/services/youtube_service.dart';
import 'package:music_flow_mobile/providers/local_library_provider.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<DatabaseService>(() => DatabaseService());
  locator.registerLazySingleton<YoutubeService>(() => YoutubeService());
  locator.registerLazySingleton<DownloadService>(() => DownloadService());
  locator.registerLazySingleton<LocalLibraryProvider>(() => LocalLibraryProvider());
}
