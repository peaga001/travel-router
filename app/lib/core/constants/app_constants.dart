abstract final class AppConstants {
  static const String appName = 'Travel Surprise';

  // Hive box names
  static const String timelineBox = 'timeline_events';
  static const String checklistBox = 'checklist_items';
  static const String financeBox = 'finance_data';
  static const String tripsBox = 'travel_trips';

  // Asset paths
  static const String timelineDataPath = 'assets/data/timeline.json';
  static const String checklistDataPath = 'assets/data/checklist.json';
  static const String financeDataPath = 'assets/data/finance.json';

  // Hive seed flag key
  static const String seedFlagKey = '__seeded__';

  // Spacing
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // Border radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPill = 100;

  // Animation durations (ms)
  static const int animFast = 200;
  static const int animMedium = 350;
  static const int animSlow = 500;
}
