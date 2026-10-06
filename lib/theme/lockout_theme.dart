import 'package:flutter/material.dart';

import 'lockout_semantics.dart';

/// Builds the app's `ThemeData` from a colour scheme.
///
/// There is deliberately no static colour accessor here. The token class this
/// replaces exposed colours without a `BuildContext`, which is what made a
/// dynamic (Material You) scheme impossible to support: the platform scheme
/// only exists below the widget that resolves it. Everything a widget needs
/// arrives through `Theme.of(context)`; the constants below are the only
/// things safe to read statically, because none of them are colours.
class LockoutTheme {
  LockoutTheme._();

  // Shape scale. SHAPE IS A STATE, NOT A CONSTANT: every interactive
  // surface carries a rest radius and an active (pressed or selected)
  // radius and animates between them. The pairs come from
  // `docs/design/nuvetrix-app-design-system.md` section 5.2.
  static const double radiusButtonRest = 999;
  static const double radiusButtonActive = 12;
  static const double radiusButtonLargeActive = 16;

  static const double radiusRowRest = 8;
  static const double radiusRowActive = 20;

  static const double radiusChipRest = 12;
  static const double radiusChipActive = 999;

  static const double radiusSegmentInner = 8;
  static const double radiusSegmentEnd = 22;

  /// The outer corners of a connected group's first and last child.
  static const double radiusGroupEnd = 26;

  /// How far apart rows sit inside a connected group.
  static const double groupGap = 3;

  /// How far a pressed surface shrinks.
  static const double pressScale = 0.97;

  // Non-interactive surfaces keep a single radius: shape-as-state applies to
  // interaction, and a dialog does not have a pressed state.
  static const double radiusCard = 28;
  static const double radiusDialog = 32;
  static const double radiusSheet = 32;
  static const double radiusField = 16;
  static const double radiusPill = 999;

  /// The family's signature card outline — 36dp on three corners, 12dp on
  /// the bottom-left.
  ///
  /// Static rather than a rest/active pair: the house document makes this
  /// outline the identity of a hero card, and a card has no pressed state.
  static const RoundedRectangleBorder heroCardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(36),
      topRight: Radius.circular(36),
      bottomRight: Radius.circular(36),
      bottomLeft: Radius.circular(12),
    ),
  );

  // 8dp spacing grid.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  static const double screenPadding = 20;
  static const double cardPadding = 16;
  static const double sectionGap = 28;

  /// The gap between a section heading and its content.
  static const double headingGap = 12;

  /// Bottom padding for a scrollable screen that carries both a nav bar and
  /// a FAB, so the last row is never hidden behind either.
  static const double scrollBottomPadding = 128;

  static const double navBarHeight = 80;
  static const double minTouchTarget = 48;
  static const double controlHeight = 52;

  /// The fixed height of a `StatTile` in a stat grid.
  ///
  /// Stated here rather than derived from tile width by a `childAspectRatio`,
  /// because a tile's content height has nothing to do with how wide the
  /// screen is: a ratio makes every narrower column a shorter tile, so the
  /// same grid that fits on a 430dp phone clips on a 360dp one.
  ///
  /// The number is set by text scale, not by design taste. It was 72, sized
  /// against Inter's `labelSmall` at 11pt with 1.2 leading — a 13.2dp label
  /// line. The house scale makes `labelSmall` 12/16, a 16dp line, so the
  /// tile needs 2.8dp more and 72 overflowed by exactly 3dp at text scale
  /// 1.15. The face change is incidental; the label style is the cause.
  ///
  /// 80 is the next step on the 8dp grid above the measured need, and the
  /// smallest that survives Android's "Large" font setting — the largest
  /// step a user reaches without opening accessibility settings.
  /// `measured_constants_test.dart` measures it against the real styles and
  /// `body_tab_test.dart` pins it.
  static const double statTileHeight = 80;

  static const String fontDisplay = 'BricolageGrotesque';
  static const String fontBody = 'Figtree';
  static const String fontMono = 'JetBrainsMono';

  /// The house type scale, stated rather than derived.
  ///
  /// Sizes, weights, line heights and tracking come from
  /// `docs/design/nuvetrix-app-design-system.md` section 4.1. They are
  /// written out instead of scaled from one base size so that changing
  /// `titleMedium` cannot silently move `bodySmall` with it.
  ///
  /// Flutter's `letterSpacing` is in logical pixels, not em, so each em
  /// figure from the house document is multiplied by its own size here.
  ///
  /// `displaySmall` and `headlineSmall` have no house entry: the document's
  /// scale has thirteen styles and Flutter's `TextTheme` has fifteen. They
  /// are interpolated between their neighbours at the same family, weight
  /// and tracking ratio, and are the only two styles in this method not
  /// copied from the document.
  static TextTheme textThemeFor(ColorScheme colors) {
    TextStyle display(
      double size,
      FontWeight weight,
      double lineHeight,
      double em, {
      Color? color,
    }) {
      return TextStyle(
        fontFamily: fontDisplay,
        fontSize: size,
        fontWeight: weight,
        height: lineHeight / size,
        letterSpacing: size * em,
        color: color ?? colors.onSurface,
      );
    }

    TextStyle body(
      double size,
      FontWeight weight,
      double lineHeight, {
      Color? color,
    }) {
      return TextStyle(
        fontFamily: fontBody,
        fontSize: size,
        fontWeight: weight,
        height: lineHeight / size,
        letterSpacing: 0,
        color: color ?? colors.onSurface,
      );
    }

    return TextTheme(
      displayLarge: display(44, FontWeight.w800, 46, -0.03),
      displayMedium: display(36, FontWeight.w800, 38, -0.03),
      displaySmall: display(32, FontWeight.w800, 34, -0.03),
      headlineLarge: display(28, FontWeight.w800, 31, -0.025),
      headlineMedium: display(22, FontWeight.w700, 26, -0.02),
      headlineSmall: display(20, FontWeight.w700, 24, -0.02),
      titleLarge: display(19, FontWeight.w700, 23, -0.01),
      titleMedium: body(16, FontWeight.w700, 22),
      titleSmall: body(14, FontWeight.w600, 20),
      bodyLarge: body(17, FontWeight.w400, 25),
      bodyMedium: body(15, FontWeight.w400, 22),
      bodySmall: body(13, FontWeight.w400, 18, color: colors.onSurfaceVariant),
      labelLarge: body(15, FontWeight.w600, 20),
      labelMedium: body(13, FontWeight.w700, 18),
      labelSmall: body(12, FontWeight.w600, 16,
          color: colors.onSurfaceVariant),
    );
  }

  /// The one big number on a hero card — the house `countdown` style.
  ///
  /// Not part of `TextTheme` because Flutter has no slot for it. At most one
  /// per screen; the house document is explicit about that.
  static TextStyle countdown(ColorScheme colors, {Color? color}) {
    return TextStyle(
      fontFamily: fontDisplay,
      fontSize: 88,
      fontWeight: FontWeight.w800,
      height: 72 / 88,
      letterSpacing: 88 * -0.05,
      color: color ?? colors.onSurface,
    );
  }

  /// Style for anything that must align in a column — set/rep/weight tables,
  /// the rest timer, log rows.
  ///
  /// Mono, so a digit does not change width between 1 and 8 and a column of
  /// numbers does not shimmer as it counts down. The house `numericTable`
  /// style.
  ///
  /// The house document defines no monospace face of its own; this is
  /// deviation register entry D1, and the role was filed upstream before use.
  ///
  /// [height] defaults to null, meaning the face's own metrics. The house
  /// `numericTable` leading — [numericTableHeight] — was authored for a 15pt
  /// table row, and applying that ratio at every call size is a category
  /// error: it gives a 28pt display numeral a table's airiness, and it is
  /// what pushed the stat tile 3dp past its box when this style first took
  /// the house metrics. Pass it explicitly where a real column of figures
  /// needs the house row rhythm.
  static TextStyle numeric(
    BuildContext context, {
    double size = 15,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontMono,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      letterSpacing: 0,
    );
  }

  /// The house `numericTable` leading, 15/22. See [numeric].
  ///
  /// The style's weight is 700, not the 500 the house table first carried:
  /// JetBrains Mono is bundled at 400 and 700 only, so a 500 request matches
  /// down to Regular and the weight silently stops meaning anything. The
  /// house document was corrected to agree.
  static const double numericTableHeight = 22 / 15;

  /// A shape that answers the interaction state, which is what the contract
  /// means by shape-as-state: a surface carries a rest radius and an active
  /// (pressed or selected) radius and resolves between them.
  ///
  /// `WidgetStateProperty` rather than an animated widget, because component
  /// themes have no build context to animate in. `MorphingSurface` is the
  /// animated form, for surfaces a screen owns directly.
  static WidgetStateProperty<OutlinedBorder?> _statefulShape(
    double rest,
    double active, {
    BorderSide? side,
  }) {
    return WidgetStateProperty.resolveWith((states) {
      final engaged = states.contains(WidgetState.pressed) ||
          states.contains(WidgetState.selected);
      return _rounded(engaged ? active : rest, side: side);
    });
  }

  static RoundedRectangleBorder _rounded(double radius, {BorderSide? side}) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: side ?? BorderSide.none,
    );
  }

  static ThemeData build({
    required ColorScheme colors,
    required LockoutSemantics semantics,
  }) {
    final text = textThemeFor(colors);

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[semantics],

      // Every component theme below sets `surfaceTintColor: transparent`.
      // M3's default tint overlays `primary` onto an elevated surface, which
      // on these dark schemes turns a raised card faintly green — the one
      // colour reserved for "complete". Tone is carried by the
      // surfaceContainer ladder instead.
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),

      cardTheme: CardThemeData(
        color: colors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: _rounded(
          radiusCard,
          side: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: _rounded(radiusDialog),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surfaceContainerLow,
        elevation: 6,
        showDragHandle: true,
        dragHandleColor: colors.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusSheet),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: spaceLg),
          textStyle: text.labelLarge,
        ).copyWith(
          shape: _statefulShape(radiusButtonRest, radiusButtonLargeActive),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: spaceLg),
          textStyle: text.labelLarge,
          foregroundColor: colors.onSurface,
        ).copyWith(
          shape: _statefulShape(
            radiusButtonRest,
            radiusButtonActive,
            ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, minTouchTarget),
          textStyle: text.labelLarge,
        ).copyWith(
          shape: _statefulShape(radiusButtonRest, radiusButtonActive),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          foregroundColor: colors.onSurfaceVariant,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceMd,
        ),
        labelStyle: text.labelMedium,
        hintStyle: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        suffixStyle: text.labelMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: navBarHeight,
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        // The house document assigns the nav indicator `secondaryContainer`
        // (sections 3.1 and 7.1), not the accent. The accent is for emphasis
        // on two or three elements per screen, and a persistent nav pill plus
        // the FAB would spend that budget before a screen drew anything.
        indicatorColor: colors.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelMedium?.copyWith(
            color:
                selected ? colors.onSecondaryContainer : colors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color:
                selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
          );
        }),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colors.secondaryContainer,
          selectedForegroundColor: colors.onSecondaryContainer,
          foregroundColor: colors.onSurfaceVariant,
          side: BorderSide(color: colors.outlineVariant),
          textStyle: text.labelLarge,
          minimumSize: const Size(0, minTouchTarget),
        ).copyWith(
          shape: _statefulShape(radiusSegmentInner, radiusChipActive),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        selectedColor: colors.secondaryContainer,
        side: BorderSide(color: colors.outlineVariant),
        labelStyle: text.labelMedium!,
        shape: _rounded(radiusChipRest,
            side: BorderSide(color: colors.outlineVariant)),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceSm,
          vertical: spaceXs,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainerHighest,
        linearMinHeight: 8,
        circularTrackColor: colors.surfaceContainerHighest,
      ),

      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: spaceLg,
      ),

      listTileTheme: ListTileThemeData(
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        iconColor: colors.onSurfaceVariant,
        shape: _rounded(radiusRowRest),
        // The pressed radius is applied by `MorphingSurface` where a row is
        // interactive; `ListTileThemeData.shape` takes no state resolver.
        contentPadding: const EdgeInsets.symmetric(horizontal: spaceMd),
        minTileHeight: minTouchTarget,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.inverseSurface,
        contentTextStyle:
            text.bodyMedium?.copyWith(color: colors.onInverseSurface),
        // `inversePrimary`, the primary tone meant for an inverse-surface
        // background. Nothing in this app builds a `SnackBarAction` today,
        // so this line has never painted; it is stated correctly so that the
        // first one that does is readable. `palette_test.dart` holds the
        // pairing at >= 4.5:1 across all ten brightness-and-accent
        // combinations, and `undo_banner.dart` (which borrows these colours)
        // is the live consumer.
        actionTextColor: colors.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: _rounded(radiusField),
        insetPadding: const EdgeInsets.all(spaceMd),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        elevation: 4,
        shape: _rounded(radiusDialog),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: _rounded(radiusField),
        textStyle: text.bodyMedium,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.onPrimary
              : colors.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.surfaceContainerHighest,
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.inverseSurface,
          borderRadius: BorderRadius.circular(radiusChipRest),
        ),
        textStyle: text.labelMedium?.copyWith(color: colors.onInverseSurface),
      ),
    );
  }
}
