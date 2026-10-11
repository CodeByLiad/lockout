import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/screens/about_screen.dart';
import 'package:lockout/widgets/house/nv_cards.dart';

import 'test_helpers.dart';

/// True when [span] or any of its children carries a gesture recognizer.
bool _hasRecognizer(InlineSpan span) {
  if (span is TextSpan && span.recognizer != null) return true;
  var found = false;
  span.visitChildren((child) {
    if (child != span && _hasRecognizer(child)) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

void main() {
  testWidgets('it names the maker, the version and the licence',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: const AboutScreen()),
    );
    await tester.pumpAndSettle();

    // Corrected against the brief: Nuvetrix is the design system this app's
    // screens are built from, not Lockout's publisher. Jinatra Ltd. is named
    // in settings_screen.dart and theme_controller.dart, and that is the
    // attribution this screen must keep carrying.
    expect(find.textContaining('Published by Jinatra Ltd.'), findsOneWidget);
    expect(find.textContaining('GPL'), findsOneWidget);
  });

  testWidgets('it uses a simple top bar with a back button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
  });

  // `1.1.0` is hand-copied into three places — pubspec.yaml, backup_service
  // and this copy — with nothing tying them together. The one screen whose
  // entire job is stating facts about the build is the worst of the three to
  // let go stale, and it would go stale silently on the next release bump.
  //
  // Read test-side from the manifest rather than pinned to a
  // `static const String version` on AboutScreen: a constant would be a
  // fourth copy of the number, which is the problem, not the fix. Same shape
  // as the manifest read at no_legacy_theme_test.dart.
  testWidgets('the version in the copy is the version in pubspec.yaml',
      (tester) async {
    final pubspec = File('pubspec.yaml');
    expect(pubspec.existsSync(), isTrue,
        reason: 'pubspec.yaml was not found, so this check proves nothing');

    // `version: 1.1.0+2` — the build number after `+` is not user-facing.
    final declared = pubspec
        .readAsLinesSync()
        .map((line) => line.split('#').first.trim())
        .firstWhere((line) => line.startsWith('version:'),
            orElse: () => throw StateError('pubspec.yaml declares no version'))
        .substring('version:'.length)
        .trim()
        .split('+')
        .first;
    expect(declared, isNotEmpty);

    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: const AboutScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('v$declared'), findsOneWidget,
        reason: 'the About copy states a version the build does not have; '
            'it must say v$declared');
  });

  // Scoped to the body and asserted on tappability, not on one widget type.
  // `find.byType(InkWell), findsNothing` over the whole tree was blind twice
  // over: no house component uses an InkWell at all — NvListItem and NvButton
  // both route a press through GestureDetector plus MorphingSurface — so a
  // link built the way this codebase builds things sailed through it; and on
  // a pushed route the only InkWell present is the AppBar's BackButton, so
  // the guard was really measuring whether a back button existed.
  testWidgets('it renders policy references as text, not live links',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: const AboutScreen()),
    );
    await tester.pumpAndSettle();

    // The card holding the copy, which excludes the AppBar and its back
    // button. Anchored on the card rather than on the scroll view that
    // happens to wrap it, so a later change of scrolling widget does not
    // fail a test about links.
    final body = find.byType(NvInfoCard);
    expect(body, findsOneWidget,
        reason: 'this anchors every assertion below; without it they would '
            'range over the whole screen and prove nothing about the copy');

    Finder inBody(Finder matching) =>
        find.descendant(of: body, matching: matching);

    // Two ways to ship a link: a tap handler on a widget, and a recognizer
    // buried in a span. Neither belongs here.
    //
    // The handler check is deliberately not `find.byType(InkWell)` or
    // `InkResponse`. Material ink builds a GestureDetector of its own, and
    // the house components build one directly (NvListItem, NvButton, through
    // MorphingSurface), so asking what is tappable catches both — where
    // asking for a widget type catches only the exact type named.
    final tappable = tester
        .widgetList<GestureDetector>(inBody(find.byType(GestureDetector)))
        .where((g) =>
            g.onTap != null ||
            g.onTapUp != null ||
            g.onDoubleTap != null ||
            g.onLongPress != null)
        .toList();
    expect(tappable, isEmpty,
        reason: 'the app is zero-network at runtime; a dead link is worse '
            'than none');

    final recognizers = tester
        .widgetList<RichText>(inBody(find.byType(RichText)))
        .where((rich) => _hasRecognizer(rich.text))
        .toList();
    expect(recognizers, isEmpty,
        reason: 'a TextSpan with a tap recognizer is a link wearing body '
            'copy as a disguise');
  });

  // The body is one long paragraph and `Text` clips by default: excess
  // lines are simply not painted, with no exception, no indicator and no way
  // to reach them. Measured natural card height against the viewport —
  // 861dp needed at 320dp wide and scale 1.15, 832dp at 360/1.30 — so the
  // clip starts inside the range config.md pins layouts to (1.0 to 1.15),
  // and the sentence that falls off the end is the network-use disclosure.
  // This is also a regression: the same copy used to live inside Settings'
  // SingleChildScrollView and was always reachable.
  testWidgets('the whole body can be read on a short screen at scale 1.15',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    // A pushed route with an AppBar and no bottomNavigationBar runs to the
    // physical bottom of an edge-to-edge window, exactly as SettingsScreen
    // does, so the last line has to clear the navigation bar too.
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.15)),
            child: const AboutScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final copy = find.textContaining('streaming exercise form videos');
    expect(copy, findsOneWidget);

    // First: the paragraph is painted whole. A clipped `Text` throws no
    // exception and `tester.takeException()` stays null — the only evidence
    // is the box being shorter than the lines it was given, so measure that.
    final paragraph = tester.renderObject<RenderBox>(copy);
    expect(
      paragraph.size.height,
      greaterThanOrEqualTo(
          paragraph.getMaxIntrinsicHeight(paragraph.size.width)),
      reason: 'the About copy needs more height than the viewport gives it, '
          'and an unscrollable body silently drops the overflow',
    );

    // Second: it is reachable. Scroll to the very end and the tail must sit
    // above the navigation bar, not behind it.
    await tester.drag(find.byType(NvInfoCard), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(tester.getBottomLeft(copy).dy, lessThanOrEqualTo(640.0 - 48.0),
        reason: 'the tail of the About copy — the network-use disclosure — '
            'must be reachable, not silently clipped');
  });

  // Moved from settings_restyle_test.dart: this content used to live inside
  // SettingsScreen's About card and is carried here intact by Task 10, not
  // rewritten. The Watch control's real on-screen label is 'Watch', in the
  // routine editor, and the house document forbids all-caps labels (section
  // 4.2, register entry D8).
  testWidgets('it names the Watch control as it is labelled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: const AboutScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('when you tap Watch'), findsOneWidget);
    expect(find.textContaining('WATCH'), findsNothing);
  });
}
