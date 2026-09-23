import 'package:get_it/get_it.dart';
import 'services/database_service.dart';
import 'services/download_service.dart';
import 'services/youtube_service.dart';
import 'providers/local_library_provider.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<DatabaseService>(() => DatabaseService());
  locator.registerLazySingleton<YoutubeService>(() => YoutubeService());
  locator.registerLazySingleton<DownloadService>(() => DownloadService());
  locator.registerLazySingleton<LocalLibraryProvider>(() => LocalLibraryProvider());
}
