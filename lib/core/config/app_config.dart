/// Build-time configuration.
///
/// Override at build/run time, e.g.:
/// flutter run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
class AppConfig {
  AppConfig._();

  static const String appName = 'Lumé';

  /// Base URL of the Python backend (FastAPI/Django). 10.0.2.2 = host machine from Android emulator.
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api/v1');

  /// While the backend is not built yet, the Dio client answers from an in-memory mock.
  static const bool useMockApi = bool.fromEnvironment('USE_MOCK_API', defaultValue: true);

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Chat refresh interval until the backend exposes WebSockets.
  static const Duration chatPollInterval = Duration(seconds: 5);
}
