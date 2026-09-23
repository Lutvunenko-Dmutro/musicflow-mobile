import 'package:get_it/get_it.dart';
import 'services/database_service.dart';
import 'services/download_service.dart';
import 'services/youtube_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<DatabaseService>(() => DatabaseService());
  locator.registerLazySingleton<YoutubeService>(() => YoutubeService());
  locator.registerLazySingleton<DownloadService>(() => DownloadService());
}
