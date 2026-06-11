// Custom Flutter web bootstrap template.
//
// Flutter 3.29 removed the HTML renderer; the only web renderers available are
// CanvasKit (default) and Skwasm. By default the loader fetches CanvasKit from
// the gstatic CDN (https://www.gstatic.com/flutter-canvaskit/<rev>/canvaskit.wasm).
// In environments where that CDN is blocked/reset, the app shows a blank screen
// with `canvaskit.wasm ERR_CONNECTION_RESET`.
//
// Pinning `canvasKitBaseUrl` to the local "canvaskit/" folder makes the loader
// use the CanvasKit assets bundled in the build output instead of the CDN, which
// fixes the blank screen for ALL flavors (parents + professores).
//
// NOTE: to guarantee the local canvaskit/ assets are bundled in the output, build
// with `--no-web-resources-cdn`:
//   flutter build web --no-web-resources-cdn --flavor professores -t lib/main_professores.dart
//   flutter build web --no-web-resources-cdn --flavor parents      -t lib/main.dart

{{flutter_js}}
{{flutter_build_config}}

// Drop any previously-registered Flutter service worker, and do NOT register a
// new one. The bundled SW aggressively caches main.dart.js per-origin, which
// made the professores web app keep serving a STALE pre-fix bundle: email OTP
// routed through the REST backend (criarte.filhos.app) instead of the Node OTP
// server, surfacing as "Server Error" with no email sent — even after a
// rebuild. Not registering the SW (and purging existing ones) guarantees the
// browser always loads the freshly-built bundle, so both flavors behave
// identically. NOTE: a browser already controlled by the old SW must be hard-
// reloaded once (or have its site data cleared) to break out of that SW.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then(function (regs) {
    for (var i = 0; i < regs.length; i++) regs[i].unregister();
  });
}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/"
  }
});
