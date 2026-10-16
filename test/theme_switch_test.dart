import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:p_a_jewerly/providers/theme_provider.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

void main() {
  setUp(() async {
    // Pin the stored mode so `pane-<n>-<mode.name>` keys are deterministic —
    // without it ThemeProvider falls back to ThemeMode.system.
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
  });
  testWidgets('dark mode applies live without restart (static-token screen)', (
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
          home: const _StaticScreen(),
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

  testWidgets('IndexedStack-held const screens remount on theme flip', (
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
          home: const _HomePatternScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The mode-flip keying: flipping the mode changes the KeyedSubtree keys
    // under the IndexedStack, which remounts the const screens. Both panes'
    // target containers re-resolve AppTheme's static getters. (IndexedStack
    // keeps inactive panes offstage, so every finder here uses
    // skipOffstage: false.)
    expect(find.byKey(const ValueKey('pane-1-light'), skipOffstage: false),
        findsOneWidget);
    expect(find.byKey(const ValueKey('pane-0-dark'), skipOffstage: false),
        findsNothing);

    // Navigate to pane 1, then flip dark: selection survives the remount and
    // the const pane re-renders in the new palette.
    await tester.tap(find.text('Select pane 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch to dark'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pane-1-dark'), skipOffstage: false),
        findsOneWidget,
        reason: 'the pane keys must carry the new theme mode');
    expect(find.byKey(const ValueKey('pane-1-light'), skipOffstage: false),
        findsNothing);
    expect(
      tester
          .widget<Container>(
              find.byKey(const Key('pane-1-target'), skipOffstage: false))
          .color,
      AppTheme.darkTextLight,
      reason: 'a const widget reused from the menu list must repaint after a '
          'theme flip — key change forces the remount',
    );
  });
}

/// Mirrors the Settings screen pattern: a stateful page showing static
/// AppTheme token colors, with the theme-toggle control on it.
class _StaticScreen extends StatelessWidget {
  const _StaticScreen();

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

/// HomeScreen's real structure, reduced to testable form: const screen
/// widgets held alive in an IndexedStack, each wrapped in a [KeyedSubtree]
/// whose key carries the theme mode.
class _HomePatternScreen extends StatefulWidget {
  const _HomePatternScreen();

  @override
  State<_HomePatternScreen> createState() => _HomePatternScreenState();
}

class _HomePatternScreenState extends State<_HomePatternScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).mode;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          SizedBox(
            height: 80,
            child: IndexedStack(
              index: _selected,
              children: [
                KeyedSubtree(
                  key: ValueKey('pane-0-${themeMode.name}'),
                  child: const _HomeLikePane(0),
                ),
                KeyedSubtree(
                  key: ValueKey('pane-1-${themeMode.name}'),
                  child: const _HomeLikePane(1),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _selected = 1),
            child: const Text('Select pane 2'),
          ),
          TextButton(
            onPressed: () => themeProvider.setMode(ThemeMode.dark),
            child: const Text('Switch to dark'),
          ),
        ],
      ),
    );
  }
}

/// const-instantiated like HomeScreen's `screen: const SaleScreen()` menu
/// entries — identical instances on every parent rebuild.
class _HomeLikePane extends StatelessWidget {
  final int index;
  const _HomeLikePane(this.index);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('pane-$index-target'),
      color: AppTheme.textColor,
      height: 40,
    );
  }
}