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
  void _drop(String id, _DropTarget target) {
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
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) {
        _drop(d.data, _InRowTarget(rowIndex: rowIndex, position: position));
      },
      builder: (context, candidates, _) {
        final active = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: active ? 28 : 20,
          alignment: Alignment.center,
          child: active
              ? Container(
                  width: 2,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        );
      },
    );
  }

  Widget _betweenRowsZone(int position) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) {
        _drop(d.data, _NewRowTarget(position: position));
      },
      builder: (context, candidates, _) {
        final active = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: active ? 28 : 12,
          alignment: Alignment.center,
          child: active
              ? Container(
                  height: 2,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _betweenRowsZone(0),
        for (int r = 0; r < widget.layout.length; r++) ...[
          IntrinsicHeight(
            child: Row(
              children: [
                _inRowZone(r, 0),
                for (int c = 0; c < widget.layout[r].length; c++) ...[
                  Expanded(
                    child: _DraggableItem(
                      id: widget.layout[r][c],
                      itemBuilder: widget.itemBuilder,
                      onTap: widget.onItemTap,
                    ),
                  ),
                  _inRowZone(r, c + 1),
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
  });

  final String id;
  final Widget Function(String) itemBuilder;
  final void Function(String)? onTap;

  @override
  State<_DraggableItem> createState() => _DraggableItemState();
}

class _DraggableItemState extends State<_DraggableItem> {
  final _childKey = GlobalKey();
  Size _size = const Size(100, 60);

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
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: _size.width,
          height: _size.height,
          child: widget.itemBuilder(widget.id),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: widget.itemBuilder(widget.id),
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
