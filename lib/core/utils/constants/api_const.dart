const String oldBaseUrl = "https://escola.spotlayer.com/api/v1/";
const String newBaseUrl = "https://platform.filhos.app/api/v1/";
const String newestBaseUrl = "https://beta.filhos.app/api/v1/";
const String productionBaseUrl = "https://criarte.filhos.app/api/v1/";
const String productionNewBaseUrl = "https://disney.filhos.app/api/v1/";

// Local backend for development/testing (run with `php artisan serve`, which
// listens on 127.0.0.1:8000). The remote prod hosts above run older code that
// is missing the email-otp routes (hence 404) and don't allow the
// http://localhost:8080 origin (hence CORS). Point at this while testing,
// then switch `baseUrl` back to `productionNewBaseUrl` before release.
const String localBaseUrl = "http://localhost:8000/api/v1/";

class ApiConst {
  // ⚠️ LOCAL TESTING: switch to `localBaseUrl` to point at the local backend.
  static const String baseUrl = productionNewBaseUrl;
}
