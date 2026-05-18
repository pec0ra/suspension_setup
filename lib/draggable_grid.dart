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
  int _draggingCount = 0;
  bool get _isDragging => _draggingCount > 0;
  _DropTarget? _hoveredTarget;

  bool _isHoveredInRow(int r, int c) {
    final t = _hoveredTarget;
    return t is _InRowTarget && t.rowIndex == r && t.position == c;
  }

  bool _isHoveredBetweenRows(int p) {
    final t = _hoveredTarget;
    return t is _NewRowTarget && t.position == p;
  }

  void _drop(String id, _DropTarget target) {
    setState(() => _hoveredTarget = null);
    widget.onLayoutChanged(_computeNewLayout(id, target));
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

  Widget _inRowZone(int rowIndex, int position) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) {
        if (!_isHoveredInRow(rowIndex, position)) {
          setState(() => _hoveredTarget =
              _InRowTarget(rowIndex: rowIndex, position: position));
        }
        return true;
      },
      onMove: (_) {
        if (!_isHoveredInRow(rowIndex, position)) {
          setState(() => _hoveredTarget =
              _InRowTarget(rowIndex: rowIndex, position: position));
        }
      },
      onLeave: (_) {
        if (_isHoveredInRow(rowIndex, position)) {
          setState(() => _hoveredTarget = null);
        }
      },
      onAcceptWithDetails: (d) {
        _drop(d.data, _InRowTarget(rowIndex: rowIndex, position: position));
      },
      builder: (context, _, __) {
        if (_isHoveredInRow(rowIndex, position)) {
          return Padding(
            padding: const EdgeInsets.all(4),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: _isDragging ? 12 : 0,
        );
      },
    );
  }

  Widget _betweenRowsZone(int position) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) {
        if (!_isHoveredBetweenRows(position)) {
          setState(() => _hoveredTarget = _NewRowTarget(position: position));
        }
        return true;
      },
      onMove: (_) {
        if (!_isHoveredBetweenRows(position)) {
          setState(() => _hoveredTarget = _NewRowTarget(position: position));
        }
      },
      onLeave: (_) {
        if (_isHoveredBetweenRows(position)) {
          setState(() => _hoveredTarget = null);
        }
      },
      onAcceptWithDetails: (d) {
        _drop(d.data, _NewRowTarget(position: position));
      },
      builder: (context, _, __) {
        if (_isHoveredBetweenRows(position)) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: SizedBox(
              height: 72,
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        }
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: _isDragging ? 12 : 0,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _betweenRowsZone(0),
        for (int r = 0; r < widget.layout.length; r++) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int c = 0; c <= widget.layout[r].length; c++) ...[
                  if (_isHoveredInRow(r, c))
                    Expanded(child: _inRowZone(r, c))
                  else
                    _inRowZone(r, c),
                  if (c < widget.layout[r].length)
                    Expanded(
                      child: _DraggableItem(
                        id: widget.layout[r][c],
                        itemBuilder: widget.itemBuilder,
                        onTap: widget.onItemTap,
                        onDragStarted: () => setState(() => _draggingCount++),
                        onDragEnded: () => setState(() => _draggingCount--),
                      ),
                    ),
                ],
              ],
            ),
          ),
          _betweenRowsZone(r + 1),
        ],
      ],
    );
  }
}

// ── draggable item ─────────────────────────────────────────────────────────

class _DraggableItem extends StatefulWidget {
  const _DraggableItem({
    required this.id,
    required this.itemBuilder,
    this.onTap,
    this.onDragStarted,
    this.onDragEnded,
  });

  final String id;
  final Widget Function(String) itemBuilder;
  final void Function(String)? onTap;
  final VoidCallback? onDragStarted;
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
    return rb.globalToLocal(position);
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
      onDragStarted: widget.onDragStarted,
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
}

final class _NewRowTarget extends _DropTarget {
  _NewRowTarget({required this.position});
  final int position;
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
