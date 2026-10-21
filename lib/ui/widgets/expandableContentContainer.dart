import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Shows [child] in full when it is short, and folds it down to
/// [collapsedHeight] with a Show more / Show less control when it is not.
///
/// Panel authored content has no length anyone can plan for: one school writes
/// three bank rows, the next writes three tables and a QR code. Rendering both
/// the same way means the second one buries whatever follows it — on the fee
/// screen, the amount and the upload the parent actually came to use. Folding
/// keeps that reachable without hiding anything: the full text is one tap away
/// and nothing is truncated on the way to the server.
///
/// Short content gets no control at all, so the common case stays plain.
class ExpandableContentContainer extends StatefulWidget {
  final Widget child;

  /// Height the content folds down to. Chosen to leave enough visible that the
  /// reader can tell what has been folded away.
  final double collapsedHeight;

  const ExpandableContentContainer({
    super.key,
    required this.child,
    this.collapsedHeight = 300.0,
  });

  @override
  State<ExpandableContentContainer> createState() =>
      _ExpandableContentContainerState();
}

class _ExpandableContentContainerState
    extends State<ExpandableContentContainer> {
  bool _isExpanded = false;

  /// Whether the content is actually taller than [collapsedHeight]. Only known
  /// once it has been laid out, so it starts false and the control appears on
  /// the frame after the measurement lands.
  bool _overflows = false;

  void _onMeasured(bool overflows) {
    if (_overflows == overflows || !mounted) {
      return;
    }
    setState(() => _overflows = overflows);
  }

  /// Fades the cut edge so a folded block reads as continuing rather than
  /// ending on a clipped row.
  Widget _buildFade() {
    final background = Theme.of(context).scaffoldBackgroundColor;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 48.0,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [background.withValues(alpha: 0.0), background],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: GestureDetector(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Utils.getTranslatedLabel(
                _isExpanded ? showLessKey : showMoreKey,
              ),
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4.0),
            Icon(
              _isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20.0,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFolded = _overflows && !_isExpanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            _MeasuredMaxHeight(
              maxHeight: widget.collapsedHeight,
              isCollapsed: isFolded,
              onMeasured: _onMeasured,
              child: widget.child,
            ),
            if (isFolded) _buildFade(),
          ],
        ),
        if (_overflows) _buildToggle(),
      ],
    );
  }
}

/// Lays its child out unconstrained, reports whether it exceeded [maxHeight],
/// and clips to that height while [isCollapsed].
///
/// The measurement has to happen during layout — the content is html whose
/// height nothing upstream can predict, and its intrinsic height is not
/// reported reliably enough to ask for it directly.
class _MeasuredMaxHeight extends SingleChildRenderObjectWidget {
  final double maxHeight;
  final bool isCollapsed;
  final ValueChanged<bool> onMeasured;

  const _MeasuredMaxHeight({
    required this.maxHeight,
    required this.isCollapsed,
    required this.onMeasured,
    required Widget super.child,
  });

  @override
  _RenderMeasuredMaxHeight createRenderObject(BuildContext context) =>
      _RenderMeasuredMaxHeight(maxHeight, isCollapsed, onMeasured);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasuredMaxHeight renderObject,
  ) {
    renderObject
      ..maxHeight = maxHeight
      ..isCollapsed = isCollapsed
      ..onMeasured = onMeasured;
  }
}

class _RenderMeasuredMaxHeight extends RenderProxyBox {
  _RenderMeasuredMaxHeight(this._maxHeight, this._isCollapsed, this.onMeasured);

  double _maxHeight;
  bool _isCollapsed;
  ValueChanged<bool> onMeasured;

  set maxHeight(double value) {
    if (_maxHeight == value) {
      return;
    }
    _maxHeight = value;
    markNeedsLayout();
  }

  set isCollapsed(bool value) {
    if (_isCollapsed == value) {
      return;
    }
    _isCollapsed = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    //measured at its natural height, whatever the incoming constraint says, so
    //the overflow answer is about the content and not about the fold
    child.layout(
      BoxConstraints(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
      ),
      parentUsesSize: true,
    );

    //a hair of tolerance, so content that lands exactly on the limit does not
    //offer a control that reveals nothing
    final overflows = child.size.height > _maxHeight + 1.0;
    final height = _isCollapsed && overflows ? _maxHeight : child.size.height;

    size = constraints.constrain(Size(child.size.width, height));

    //reporting during layout would rebuild mid-layout, so it waits a frame
    if (overflows != _lastReported) {
      _lastReported = overflows;
      final callback = onMeasured;
      WidgetsBinding.instance.addPostFrameCallback((_) => callback(overflows));
    }
  }

  bool? _lastReported;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      return;
    }

    if (!_isCollapsed) {
      context.paintChild(child, offset);
      return;
    }

    //folded: everything past the cut is clipped away rather than painted over
    //the widgets below, the way an unclipped overflow would
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) => context.paintChild(child, offset),
    );
  }
}
