// Device-matrix checks for the shared breakpoint system: the window classes
// classify the three device tiers the app ships to, and dialogs that declare
// a preferred width stay fully on-screen at every viewport width.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/widgets/base_screen.dart';

void main() {
  group('AppBreakpoints.classify', () {
    test('phones in portrait are compact', () {
      expect(AppBreakpoints.classify(360), WindowSize.compact);
      expect(AppBreakpoints.classify(600), WindowSize.compact);
    });

    test('small tablets in landscape are medium', () {
      expect(AppBreakpoints.classify(601), WindowSize.medium);
      expect(AppBreakpoints.classify(800), WindowSize.medium);
      expect(AppBreakpoints.classify(1024), WindowSize.medium);
    });

    test('iPad landscape and desktop are expanded', () {
      expect(AppBreakpoints.classify(1025), WindowSize.expanded);
      expect(AppBreakpoints.classify(1366), WindowSize.expanded);
    });

    test('chrome thresholds sit where the layouts need them', () {
      // Sidebar beats the drawer on a 900px window but not a phone.
      expect(AppBreakpoints.wideChromeAt, greaterThan(600));
      // The POS cart rail needs more room than the sidebar switch.
      expect(AppBreakpoints.posRailAt, greaterThanOrEqualTo(AppBreakpoints.wideChromeAt));
    });
  });

  group('FormDialog width at each viewport', () {
    Future<void> pumpDialogAt(WidgetTester tester, Size size) async {
      // Logical viewport = physical size with dpr 1: the view is the only
      // thing driving MediaQuery in a widget test.
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => FormDialog(
                    title: 'New Category',
                    labelText: 'Name',
                    onSave: (_) async => true,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    // The Dialog's child Container sets width, so read the rendered width
    // off its RenderBox (robust for the clamped and preferred cases).
    double renderedDialogWidth(WidgetTester tester) {
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      final container = dialog.child! as Container;
      final box = tester.renderObject<RenderBox>(find.byWidget(container));
      return box.size.width;
    }

    testWidgets('phone portrait 360px: dialog clamps to fit', (tester) async {
      await pumpDialogAt(tester, const Size(360, 800));
      // The clamp offers 328px, but Material's Dialog inset padding (40px
      // per side) is the tighter limit: 360 - 80 = 280. Either way the
      // dialog stays fully on-screen, which is what this asserts.
      expect(renderedDialogWidth(tester), closeTo(280, 0.5));
      expect(find.text('New Category'), findsOneWidget);
    });

    testWidgets('tablet portrait 820px: preferred width used', (tester) async {
      await pumpDialogAt(tester, const Size(820, 1180));
      expect(renderedDialogWidth(tester), closeTo(400, 0.5));
    });

    testWidgets('desktop 1280px: preferred width used', (tester) async {
      await pumpDialogAt(tester, const Size(1280, 800));
      expect(renderedDialogWidth(tester), closeTo(400, 0.5));
    });
  });
}