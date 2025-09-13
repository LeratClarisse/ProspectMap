abstract class SettingsRepository {
  /// Get dark mode setting
  Future<bool> getDarkMode();

  /// Set dark mode setting
  Future<void> setDarkMode(bool isDark);

  /// Get show colored segments setting
  Future<bool> getShowColoredSegments();

  /// Set show colored segments setting
  Future<void> setShowColoredSegments(bool show);
}
