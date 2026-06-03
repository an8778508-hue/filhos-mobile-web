const String oldBaseUrl = "https://escola.spotlayer.com/api/v1/";
const String newBaseUrl = "https://platform.filhos.app/api/v1/";
const String newestBaseUrl = "https://beta.filhos.app/api/v1/";
const String productionBaseUrl = "https://criarte.filhos.app/api/v1/";
const String productionNewBaseUrl = "https://disney.filhos.app/api/v1/";

class ApiConst {
  /// Base URL for the Filhos REST API.
  ///
  /// Overridable at build time via `--dart-define=API_BASE_URL=…` so we can
  /// point at a local backend (e.g. `http://localhost:8000/api/v1/`) once the
  /// real Server-Driven Auth backend ships — without touching source.
  /// Default stays at the current production URL.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionNewBaseUrl,
  );
}
