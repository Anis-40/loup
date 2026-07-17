class AppConstants {
  static const String adminPassword = '1234';
  static const int discoveryPort    = 9999;
  static const int wsPort           = 8080;
  static const int minPlayers       = 4;
  static const int broadcastInterval = 2; // seconds
  static const Duration reconnectDelay = Duration(seconds: 3);
}
