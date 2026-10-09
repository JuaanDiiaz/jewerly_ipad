import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/theme_provider.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

void main() {
  testWidgets('dark mode applies live without restart (main.dart structure)', (
    tester,
  ) async {
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        builder: (context, child) => MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: context.watch<ThemeProvider>().mode,
          home: _StaticScreen(),
        ),
      ),
    );

    Color renderedColor() =>
        tester.widget<Container>(find.byKey(const Key('target'))).color!;

    expect(find.text('Dark'), findsNothing);
    expect(renderedColor(), AppTheme.textColor);

    // Toggle dark from inside the nested screen — exactly what the
    // Settings radio tiles do.
    await tester.tap(find.text('Switch to dark'));
    await tester.pumpAndSettle();

    expect(
      renderedColor(),
      AppTheme.darkTextLight,
      reason: 'A screen already mounted (settings/IndexedStack state) must '
          'repaint its static-token colors when themeMode changes — '
          'no restart required',
    );

    await tester.tap(find.text('Switch to light'));
    await tester.pumpAndSettle();
    expect(renderedColor(), AppTheme.textColor);
  });
}

/// Mirrors the Settings screen pattern: a stateful page showing static
/// AppTheme token colors, with the theme-toggle control on it.
class _StaticScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Container(key: const Key('target'), color: AppTheme.textColor, height: 40),
          TextButton(
            onPressed: () => themeProvider.setMode(ThemeMode.dark),
            child: const Text('Switch to dark'),
          ),
          TextButton(
            onPressed: () => themeProvider.setMode(ThemeMode.light),
            child: const Text('Switch to light'),
          ),
        ],
      ),
    );
  }
}