import 'dart:math' as math;

import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// Renders the school's manual payment instructions, which the panel stores as
/// a single block of HTML.
///
/// Two things are deliberately not left to the renderer's defaults:
///
/// * **Images.** The panel embeds the payment QR as a full resolution base64
///   image carrying no width attribute, so the renderer lays it out at its
///   intrinsic size — wider than the card it sits in, and drawn well past 1:1
///   on a high density screen, which is exactly what makes a QR look blurry.
///   Every `img` is routed through a fixed [qrSize] box instead, so the code is
///   always downsampled rather than upscaled.
/// * **Typography.** Raw markup would otherwise render at browser defaults and
///   read as a foreign document inside the app.
class PaymentInstructionsHtml extends StatelessWidget {
  final String html;

  /// Edge of the square the payment QR is drawn in. Matches the design, and
  /// stays below the source resolution so the code renders crisply.
  final double qrSize;

  const PaymentInstructionsHtml({
    super.key,
    required this.html,
    this.qrSize = 124.0,
  });

  /// Cell padding given to tables that do not set their own, so a bordered
  /// grid reads like it does in the panel's editor rather than at the 1px the
  /// html default would give it.
  static const String _defaultCellPadding = '6';

  static final RegExp _tableOpenTag =
      RegExp(r'<table\b([^>]*)>', caseSensitive: false);

  static bool _hasAttribute(String attributes, String name) =>
      RegExp('(?:^|\\s)$name\\s*=', caseSensitive: false).hasMatch(attributes);

  /// Drops any `height` declaration from a table's inline style.
  ///
  /// CSS treats a height on a table as a *minimum* — the table still grows to
  /// fit its rows, which is why the editor shows every row of a table the
  /// school dragged to a smaller height. The renderer instead applies it as a
  /// fixed box and clips whatever does not fit, so a `height: 20px` left behind
  /// by a resize hides every row but the first. The width is left alone: that
  /// one the renderer and the browser agree on.
  static String _withoutFixedHeight(String declarations) {
    return declarations
        .split(';')
        .where(
          (declaration) => !RegExp(r'^\s*height\s*:', caseSensitive: false)
              .hasMatch(declaration),
        )
        .map((declaration) => declaration.trim())
        .where((declaration) => declaration.isNotEmpty)
        .map((declaration) => '$declaration;')
        .join(' ');
  }

  /// Fills in the table presentation the editor shows but does not write into
  /// the markup.
  ///
  /// The panel's editor draws a grid around every table, including ones saved
  /// with no `border` at all — those lines are an editing aid, not content, so
  /// the school sees a bordered table and the app used to render a borderless
  /// one. Worse, the renderer only draws the *cell* grid when the table carries
  /// a `border` attribute: a css border alone outlines the table and leaves the
  /// cells bare.
  ///
  /// Only the gaps are filled. A table that states its own `border`,
  /// `cellpadding` or `border-collapse` — as one written through the editor's
  /// table properties does — keeps exactly what the school chose.
  @visibleForTesting
  static String withEditorTableDefaults(String html) {
    return html.replaceAllMapped(_tableOpenTag, (match) {
      var attributes = match.group(1) ?? '';

      if (!_hasAttribute(attributes, 'border')) {
        attributes += ' border="1"';
      }
      if (!_hasAttribute(attributes, 'cellpadding')) {
        attributes += ' cellpadding="$_defaultCellPadding"';
      }

      final style = RegExp(r'style\s*=\s*"([^"]*)"', caseSensitive: false)
          .firstMatch(attributes);

      if (style == null) {
        attributes += ' style="border-collapse: collapse;"';
      } else {
        var declarations = _withoutFixedHeight(style.group(1) ?? '');

        if (!declarations.toLowerCase().contains('border-collapse')) {
          final separator =
              declarations.isEmpty || declarations.endsWith(';') ? '' : ';';
          declarations = '$declarations$separator border-collapse: collapse;';
        }

        attributes = attributes.replaceRange(
          style.start,
          style.end,
          'style="${declarations.trim()}"',
        );
      }

      return '<table$attributes>';
    });
  }

  /// The payment QR at the size the design calls for.
  ///
  /// Downsampled with a better filter than the default, which is what keeps a
  /// dense code's edges separable. Tapping opens it full screen, since [qrSize]
  /// is tight for scanning.
  Widget _buildImage(BuildContext context, String source) {
    final imageProvider = Utils.imageProviderFromSource(source);
    if (imageProvider == null) {
      return const SizedBox();
    }

    return Center(
      child: GestureDetector(
        onTap: () => Utils.showImagePreview(context: context, imageUrl: source),
        child: Container(
          width: qrSize,
          height: qrSize,
          margin: const EdgeInsets.only(top: 4.0),
          child: Image(
            image: imageProvider,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //measured out here, above the html: the renderer dry lays parts of its own
    //subtree out, and a LayoutBuilder cannot take part in a dry layout
    return LayoutBuilder(
      builder: (context, constraints) => _AvailableWidth(
        width: constraints.maxWidth,
        child: _buildHtml(context),
      ),
    );
  }

  Widget _buildHtml(BuildContext context) {
    return HtmlWidget(
      withEditorTableDefaults(html),
      //tables are the one thing here that can refuse to fit
      factoryBuilder: () => _ScrollableTableFactory(),
      //the app supplies the typeface and the base size; everything else — bold
      //headers, alignment, emphasis — comes from the markup the school wrote,
      //so it is left alone
      textStyle: TextStyle(
        fontSize: 12.0,
        letterSpacing: 0.4,
        height: 16 / 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      customWidgetBuilder: (element) {
        if (element.localName != 'img') {
          return null;
        }
        return _buildImage(context, element.attributes['src'] ?? '');
      },
    );
  }
}

/// Renders `table` elements so they can scroll sideways.
///
/// A panel authored table can contain an unbreakable token — a UPI id, an
/// account number, a url — that is wider than the card it has to live in. The
/// html renderer lays such a table out at that minimum width regardless of the
/// constraint it was given, so it spills past the card and paints over whatever
/// follows it. Scrolling is the only honest answer: the alternative is
/// truncating the account details the parent is meant to copy.
class _ScrollableTableFactory extends WidgetFactory {
  @override
  void parse(BuildTree tree) {
    if (tree.element.localName == 'table') {
      tree.register(
        BuildOp(
          debugLabel: 'manual-payment-scrollable-table',
          alwaysRenderBlock: true,
          onRenderBlock: (_, placeholder) =>
              _HorizontalOverflowScroll(child: placeholder),
        ),
      );
    }

    super.parse(tree);
  }
}

/// Carries the width available to the instructions down to the tables.
///
/// The width has to be measured above [HtmlWidget] and passed in, because the
/// renderer dry lays parts of its subtree out and a `LayoutBuilder` placed
/// inside would assert the moment that happens.
class _AvailableWidth extends InheritedWidget {
  final double width;

  const _AvailableWidth({required this.width, required super.child});

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AvailableWidth>()?.width;

  @override
  bool updateShouldNotify(_AvailableWidth oldWidget) =>
      oldWidget.width != width;
}

/// Lets [child] scroll sideways, but only when it cannot fit.
///
/// Content that fits is laid out at exactly the available width and behaves as
/// though the scroll view were not there — no stray scroll on the tables that
/// were always fine.
class _HorizontalOverflowScroll extends StatelessWidget {
  final Widget child;

  const _HorizontalOverflowScroll({required this.child});

  @override
  Widget build(BuildContext context) {
    final availableWidth = _AvailableWidth.maybeOf(context);
    //nothing bounded the instructions, so there is no overflow to contain
    if (availableWidth == null || !availableWidth.isFinite) {
      return child;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: _WidthAtLeast(minWidth: availableWidth, child: child),
    );
  }
}

/// Lays its child out at [minWidth], or at the narrowest width the child can
/// legally take when that is wider.
///
/// A horizontal viewport hands its child an unbounded width, which would let a
/// table stretch every column to fit its text on one line — turning tables that
/// used to wrap neatly into ones that need scrolling. Deciding the width here
/// instead keeps that from happening.
class _WidthAtLeast extends SingleChildRenderObjectWidget {
  final double minWidth;

  const _WidthAtLeast({required this.minWidth, required Widget super.child});

  @override
  _RenderWidthAtLeast createRenderObject(BuildContext context) =>
      _RenderWidthAtLeast(minWidth);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderWidthAtLeast renderObject,
  ) {
    renderObject.minWidth = minWidth;
  }
}

class _RenderWidthAtLeast extends RenderProxyBox {
  _RenderWidthAtLeast(this._minWidth);

  double _minWidth;

  set minWidth(double value) {
    if (_minWidth == value) {
      return;
    }
    _minWidth = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    final width =
        math.max(_minWidth, child.getMinIntrinsicWidth(double.infinity));
    child.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
    size = constraints.constrain(Size(width, child.size.height));
  }
}
