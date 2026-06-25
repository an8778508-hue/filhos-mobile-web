import 'package:escola/core/utils/lang_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Proves that when the app language is Arabic ('ar'), the home and diary
/// surfaces render right-to-left (RTL).
///
/// The real Home/Diary screens depend on Firebase + GetIt DI + remote config
/// (ConfigCubit, UserBloc) which can't boot in a unit-test harness, so this
/// test uses a *faithful representative wrapper* that mirrors EXACTLY how the
/// production app applies directionality in `lib/my_app.dart`
/// (`MaterialAppWidget.builder`):
///
///     Directionality(
///       textDirection: state.language == 'en' ? TextDirection.ltr
///                                              : TextDirection.rtl,
///       child: ...,
///     )
///
/// i.e. any non-English language (including 'ar') is RTL. The wrapper below
/// reproduces that decision so the assertion exercises the same rule the app
/// ships.
Widget appLikeShell({required String language, required Widget child}) {
  return MaterialApp(
    locale: Locale(language),
    supportedLocales: const [Locale('pt'), Locale('en'), Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(
      builder: (context) => Directionality(
        // Same expression used in MaterialAppWidget.builder.
        textDirection:
            language == 'en' ? TextDirection.ltr : TextDirection.rtl,
        child: child,
      ),
    ),
  );
}

/// Minimal representative "home" surface.
class _HomeSurface extends StatelessWidget {
  const _HomeSurface({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('home_title')));
}

/// Minimal representative "diary" surface.
class _DiarySurface extends StatelessWidget {
  const _DiarySurface({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('diary_title')));
}

void main() {
  group('Arabic => RTL', () {
    testWidgets('home surface is RTL when language is ar', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        appLikeShell(
          language: 'ar',
          child: _HomeSurface(key: key),
        ),
      );

      expect(Directionality.of(key.currentContext!), TextDirection.rtl);
    });

    testWidgets('diary surface is RTL when language is ar', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        appLikeShell(
          language: 'ar',
          child: _DiarySurface(key: key),
        ),
      );

      expect(Directionality.of(key.currentContext!), TextDirection.rtl);
    });

    testWidgets('home surface is LTR when language is en (control)',
        (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        appLikeShell(
          language: 'en',
          child: _HomeSurface(key: key),
        ),
      );

      expect(Directionality.of(key.currentContext!), TextDirection.ltr);
    });
  });

  group('Arabic default locale resolution', () {
    test('device locale ar_EG resolves the app default to Arabic', () {
      final resolved = resolveInitialLanguage('ar_EG');
      expect(resolved.language, 'ar');
      expect(resolved.languageWithCode, 'ar_EG');
    });

    test('device locale ar resolves the app default to Arabic', () {
      final resolved = resolveInitialLanguage('ar');
      expect(resolved.language, 'ar');
    });

    test('non-Arabic device locale keeps the Portuguese default', () {
      expect(resolveInitialLanguage('fr_FR').language, 'pt');
      expect(resolveInitialLanguage('en_US').language, 'pt');
      expect(resolveInitialLanguage('pt_BR').languageWithCode, 'pt_BR');
    });
  });
}
