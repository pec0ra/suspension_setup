import 'package:flutter/material.dart';

/// A 2-D drag-and-drop grid where items are arranged in rows of equal width.
class DraggableGrid extends StatefulWidget {
  const DraggableGrid({
    super.key,
    required this.layout,
    required this.itemBuilder,
    required this.onLayoutChanged,
    this.onItemTap,
  });

  final List<List<String>> layout;
  final Widget Function(String id) itemBuilder;
  final void Function(List<List<String>>) onLayoutChanged;
  final void Function(String id)? onItemTap;

  @override
  State<DraggableGrid> createState() => _DraggableGridState();
}

class _DraggableGridState extends State<DraggableGrid> {
  _DropTarget? _lastTarget;
  bool _seenInRowSinceLastBetweenRows = true;
  bool _isDragging = false;
  Offset? _dragTouchOffset;
  Size? _dragSize;
  final _cardKeys = <String, GlobalKey>{};
  final _enteringCards = <String>{};
  String? _draggingId;
  final _cardCols = <String, int>{};
  final _cardSlideOffsets = <String, Offset>{};
  double _rowWidth = 0;
  // True for exactly one frame after _rowWidth changes; suppresses the
  // AnimatedContainer width animation so cards snap to the new size and
  // never exceed the row's immediately-updated width (which would overflow).
  bool _rowWidthSnapping = false;
  GlobalKey _cardKey(String id) => _cardKeys.putIfAbsent(id, () => GlobalKey());

  @override
  void didUpdateWidget(DraggableGrid old) {
    super.didUpdateWidget(old);
    final dragId = _draggingId;
    if (dragId == null) return;
    int? oldR;
    for (int r = 0; r < old.layout.length; r++) {
      if (old.layout[r].contains(dragId)) {
        oldR = r;
        break;
      }
    }
    if (oldR == null) return;
    final oldRowIds = old.layout[oldR].toSet();
    final entering = <String>{};

    // Rule 1: dragged card crossed into a different logical row.
    int? newR;
    for (int r = 0; r < widget.layout.length; r++) {
      if (!widget.layout[r].contains(dragId)) continue;
      newR = r;
      final movedToNewRowIndex = r != oldR;
      final joinedNewCompanions =
          widget.layout[r].any((c) => c != dragId && !oldRowIds.contains(c));
      if (movedToNewRowIndex || joinedNewCompanions) entering.add(dragId);
      break;
    }

    // Rule 2: when the dragged card's Row column index stayed the same but gained
    // new cards, those new cards' target widths would overflow alongside the dragged
    // card's existing (large) AC width — so they must also start at 0.
    if (newR != null &&
        entering.contains(dragId) &&
        newR < old.layout.length &&
        old.layout[newR].contains(dragId)) {
      final oldAtNewR = old.layout[newR].toSet();
      for (final id in widget.layout[newR]) {
        if (id != dragId && !oldAtNewR.contains(id)) entering.add(id);
      }
    }

    if (entering.isNotEmpty) {
      _enteringCards.addAll(entering);
      // Clear any active slide offsets: the entering animation takes over
      // visually, and residual slide transforms corrupt zone calculations.
      _cardSlideOffsets.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _enteringCards.removeAll(entering));
      });
    }

    // Slide animation: only when no card is entering. Still update _cardCols
    // every frame so future slide detections start from the correct column.
    final slideCards = <String>{};
    for (int r = 0; r < widget.layout.length; r++) {
      for (int c = 0; c < widget.layout[r].length; c++) {
        final id = widget.layout[r][c];
        final prevC = _cardCols[id];
        final wasInSameRow =
            r < old.layout.length && old.layout[r].contains(id);
        if (entering.isEmpty && wasInSameRow && prevC != null && prevC != c) {
          _cardSlideOffsets[id] = Offset((prevC - c).toDouble(), 0);
          slideCards.add(id);
        }
        _cardCols[id] = c;
      }
    }
    if (slideCards.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            for (final id in slideCards) {
              _cardSlideOffsets.remove(id);
            }
          });
        }
      });
    }
  }

  bool _isNoOp(String id, _DropTarget target) {
    int srcRow = -1, srcCol = -1;
    outer:
    for (int r = 0; r < widget.layout.length; r++) {
      for (int c = 0; c < widget.layout[r].length; c++) {
        if (widget.layout[r][c] == id) {
          srcRow = r;
          srcCol = c;
          break outer;
        }
      }
    }
    if (srcRow < 0) return false;
    return switch (target) {
      _InRowTarget(:final rowIndex, :final position) =>
        srcRow == rowIndex && (position == srcCol || position == srcCol + 1),
      _NewRowTarget(:final position) => widget.layout[srcRow].length == 1 &&
          (position == srcRow || position == srcRow + 1),
    };
  }

  List<List<String>> _computeNewLayout(String id, _DropTarget target) {
    final rows = widget.layout.map((r) => List<String>.from(r)).toList();

    int srcRow = -1, srcCol = -1;
    outer:
    for (int r = 0; r < rows.length; r++) {
      for (int c = 0; c < rows[r].length; c++) {
        if (rows[r][c] == id) {
          srcRow = r;
          srcCol = c;
          break outer;
        }
      }
    }
    if (srcRow < 0) return widget.layout;

    switch (target) {
      case _InRowTarget(:final rowIndex, :final position):
        if (srcRow == rowIndex) {
          rows[rowIndex].removeAt(srcCol);
          final insertAt = (srcCol < position ? position - 1 : position)
              .clamp(0, rows[rowIndex].length);
          rows[rowIndex].insert(insertAt, id);
        } else {
          final willEmpty = rows[srcRow].length == 1;
          rows[srcRow].removeAt(srcCol);
          int adjRow = rowIndex;
          if (willEmpty && srcRow < rowIndex) adjRow--;
          rows.removeWhere((r) => r.isEmpty);
          if (adjRow < rows.length) {
            final insertAt = position.clamp(0, rows[adjRow].length);
            rows[adjRow].insert(insertAt, id);
          }
        }

      case _NewRowTarget(:final position):
        final willEmpty = rows[srcRow].length == 1;
        rows[srcRow].removeAt(srcCol);
        int adjPos = position;
        if (willEmpty && srcRow < position) adjPos--;
        rows.removeWhere((r) => r.isEmpty);
        final insertAt = adjPos.clamp(0, rows.length);
        rows.insert(insertAt, [id]);
    }

    rows.removeWhere((r) => r.isEmpty);
    return rows;
  }

  void _onBottomHover(DragTargetDetails<String> details) {
    final target = _NewRowTarget(position: widget.layout.length);
    if (target == _lastTarget) return;
    _lastTarget = target;
    _seenInRowSinceLastBetweenRows = false;
    if (_isNoOp(details.data, target)) return;
    widget.onLayoutChanged(_computeNewLayout(details.data, target));
  }

  void _onCardHover(
      DragTargetDetails<String> details, int r, int c, String hoveredId) {
    final rb =
        _cardKey(hoveredId).currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;

    final cardTopLeft = rb.localToGlobal(Offset.zero);
    final touchOffset =
        _dragTouchOffset ?? Offset(rb.size.width / 2, rb.size.height / 2);
    final dragSize = _dragSize ?? rb.size;

    final feedbackCenterY =
        details.offset.dy - touchOffset.dy + dragSize.height / 2;

    const betweenRowsBuffer = 28.0;
    final _DropTarget target;
    if (feedbackCenterY < cardTopLeft.dy - betweenRowsBuffer) {
      target = _NewRowTarget(position: r);
    } else if (feedbackCenterY >
        cardTopLeft.dy + rb.size.height + betweenRowsBuffer) {
      target = _NewRowTarget(position: r + 1);
    } else {
      final pointerX = details.offset.dx + touchOffset.dx;
      final rowLen = widget.layout[r].length;
      final nominalCardWidth =
          _rowWidth > 0 ? _rowWidth / rowLen : rb.size.width;
      // Card 0 always sits at the row's left edge regardless of its own width.
      // Using it gives a stable rowLeft even while entering cards animate.
      final firstRb = c == 0
          ? rb
          : (_cardKey(widget.layout[r][0]).currentContext?.findRenderObject()
                  as RenderBox?) ??
              rb;
      final rowLeft = firstRb.localToGlobal(Offset.zero).dx;
      final rowWidth = nominalCardWidth * rowLen;
      final position = ((pointerX - rowLeft) * (rowLen + 1) / rowWidth)
          .floor()
          .clamp(0, rowLen);
      target = _InRowTarget(rowIndex: r, position: position);
    }

    if (target == _lastTarget) return;
    _lastTarget = target;

    if (target is _NewRowTarget && !_seenInRowSinceLastBetweenRows) return;
    if (target is _InRowTarget) _seenInRowSinceLastBetweenRows = true;
    if (_isNoOp(details.data, target)) return;
    if (target is _NewRowTarget) _seenInRowSinceLastBetweenRows = false;

    widget.onLayoutChanged(_computeNewLayout(details.data, target));
  }

  Widget _buildCardContent(int r, int c) {
    final id = widget.layout[r][c];
    // Key includes column so a new AnimatedSlide is created when the card
    // shifts columns. When entering, a special key forces a fresh instance at
    // Offset.zero so no residual slide transform corrupts zone calculations.
    return AnimatedSlide(
      key: _enteringCards.contains(id)
          ? ValueKey('${id}_slide_entering')
          : ValueKey('${id}_slide_$c'),
      offset: _cardSlideOffsets[id] ?? Offset.zero,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: DragTarget<String>(
        key: _cardKey(id),
        onWillAcceptWithDetails: (details) {
          _onCardHover(details, r, c, id);
          return true;
        },
        onMove: (details) => _onCardHover(details, r, c, id),
        builder: (_, __, ___) => _DraggableItem(
          key: ValueKey(id),
          id: id,
          itemBuilder: widget.itemBuilder,
          onTap: widget.onItemTap,
          onDragStarted: (touchOffset, size) {
            setState(() {
              _isDragging = true;
              _dragTouchOffset = touchOffset;
              _dragSize = size;
              _draggingId = id;
            });
          },
          onDragEnded: () {
            _seenInRowSinceLastBetweenRows = true;
            setState(() {
              _isDragging = false;
              _lastTarget = null;
              _draggingId = null;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int r = 0; r < widget.layout.length; r++)
          LayoutBuilder(
            builder: (context, constraints) {
              final newRowWidth = constraints.maxWidth;
              if (newRowWidth != _rowWidth && !_rowWidthSnapping) {
                _rowWidthSnapping = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _rowWidthSnapping = false);
                });
              }
              _rowWidth = newRowWidth;
              final rowLen = widget.layout[r].length;
              final cardWidth = _rowWidth / rowLen;
              // ClipRect clips the visual overflow from AnimatedSlide during
              // in-row slide animations (paint-only, no layout impact).
              return ClipRect(
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int c = 0; c < rowLen; c++)
                        AnimatedContainer(
                          key: ValueKey(widget.layout[r][c]),
                          width: _enteringCards.contains(widget.layout[r][c])
                              ? 0.0
                              : cardWidth,
                          duration: _rowWidthSnapping
                              ? Duration.zero
                              : const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: _buildCardContent(r, c),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        DragTarget<String>(
          onWillAcceptWithDetails: (details) {
            _onBottomHover(details);
            return true;
          },
          onMove: _onBottomHover,
          builder: (_, __, ___) => SizedBox(height: _isDragging ? 64 : 0),
        ),
      ],
    );
  }
}

// ── draggable item ─────────────────────────────────────────────────────────

class _DraggableItem extends StatefulWidget {
  const _DraggableItem({
    super.key,
    required this.id,
    required this.itemBuilder,
    this.onTap,
    this.onDragStarted,
    this.onDragEnded,
  });

  final String id;
  final Widget Function(String) itemBuilder;
  final void Function(String)? onTap;
  final void Function(Offset touchOffset, Size size)? onDragStarted;
  final VoidCallback? onDragEnded;

  @override
  State<_DraggableItem> createState() => _DraggableItemState();
}

class _DraggableItemState extends State<_DraggableItem> {
  final _childKey = GlobalKey();
  Size _size = const Size(200, 88);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSize());
  }

  @override
  void didUpdateWidget(_DraggableItem old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSize());
  }

  void _measureSize() {
    if (!mounted) return;
    final rb = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final newSize = rb.size;
    if (newSize != _size) setState(() => _size = newSize);
  }

  Offset _dragAnchor(Draggable<Object?> _, BuildContext __, Offset position) {
    final rb = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return Offset.zero;
    final anchor = rb.globalToLocal(position);
    widget.onDragStarted?.call(anchor, rb.size);
    return anchor;
  }

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(
      key: _childKey,
      child: widget.itemBuilder(widget.id),
    );
    return LongPressDraggable<String>(
      data: widget.id,
      dragAnchorStrategy: _dragAnchor,
      onDragEnd: (_) => widget.onDragEnded?.call(),
      feedback: Transform.scale(
        scale: 1.05,
        child: Material(
          color: Colors.transparent,
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: _size.width,
            height: _size.height,
            child: widget.itemBuilder(widget.id),
          ),
        ),
      ),
      childWhenDragging: Padding(
        padding: const EdgeInsets.all(4),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _size.height - 8),
          child: CustomPaint(
            painter: _DashedBorderPainter(
                color: Theme.of(context).colorScheme.outline),
            child: const SizedBox.expand(),
          ),
        ),
      ),
      child: widget.onTap != null
          ? GestureDetector(
              onTap: () => widget.onTap!(widget.id),
              child: child,
            )
          : child,
    );
  }
}

// ── drop-target descriptors ────────────────────────────────────────────────

sealed class _DropTarget {}

final class _InRowTarget extends _DropTarget {
  _InRowTarget({required this.rowIndex, required this.position});
  final int rowIndex;
  final int position;

  @override
  bool operator ==(Object other) =>
      other is _InRowTarget &&
      other.rowIndex == rowIndex &&
      other.position == position;

  @override
  int get hashCode => Object.hash(rowIndex, position);
}

final class _NewRowTarget extends _DropTarget {
  _NewRowTarget({required this.position});
  final int position;

  @override
  bool operator ==(Object other) =>
      other is _NewRowTarget && other.position == position;

  @override
  int get hashCode => position.hashCode;
}

// ── dashed placeholder painter ─────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});
  final Color color;

  static const _dashWidth = 6.0;
  static const _dashGap = 4.0;
  static const _radius = 12.0;
  static const _strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(_radius),
      ));
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + _dashWidth),
          paint,
        );
        distance += _dashWidth + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
