import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/hive_service.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final HiveService hiveService;

  SettingsRepositoryImpl({
    required this.hiveService,
  });

  @override
  Future<bool> getDarkMode() async {
    return hiveService.getDarkMode();
  }

  @override
  Future<void> setDarkMode(bool isDark) async {
    await hiveService.setDarkMode(isDark);
  }

  @override
  Future<bool> getShowColoredSegments() async {
    return hiveService.getShowColoredSegments();
  }

  @override
  Future<void> setShowColoredSegments(bool show) async {
    await hiveService.setShowColoredSegments(show);
  }
}
