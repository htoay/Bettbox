part of 'view.dart';

typedef _LineSlice = ({
  String text,
  int start,
  int end,
  int scalarStart,
  int scalarEnd,
  Offset origin,
  Rect cover,
  ui.Paragraph paragraph,
});

class _CodeFieldRenderer extends RenderBox implements MouseTrackerAnnotation {
  final CodeForgeController controller;
  final ScrollController vscrollController, hscrollController;
  final FocusNode focusNode;
  final AnimationController caretBlinkController;
  final AnimationController lineHighlightController;
  final bool isMobile;
  final ValueNotifier<bool> selectionActiveNotifier;
  final ValueNotifier<Rect?> caretRectNotifier;
  final ValueChanged<Offset> onContextMenuRequest;
  final ValueChanged<PointerSignalEvent> onPointerSignal;
  final ValueNotifier<MagnifierInfo?> magnifierNotifier;
  final Map<int, double> _lineWidthCache = {};
  final Map<int, String> _lineTextCache = {};
  final Map<
    int,
    ({String text, ui.Paragraph paragraph, bool highlighted, bool comment})
  >
  _paragraphCache = {};
  final _blockComments = BlockCommentStates();
  final Map<int, _LineSlice> _lineSlices = {};
  bool _wholeLines = false;
  late TextSelection _seenSelection;
  ({String source, String shown})? _bufferLineCut;
  ui.Paragraph? _cutMarker, _foldMarker;
  final Map<int, FoldRange?> _foldRanges = {};
  final Map<int, int?> _bracketCache = {};
  final Map<
    int,
    List<({int startLine, int endLine, int indentLevel, double guideX})>
  >
  _indentGuideCache = {};
  final Map<
    int,
    ({int lineIndex, int columnIndex, Offset offset, double height})
  >
  _caretInfoCache = {};
  final Map<int, int> _lineIndentCache = {};
  final _dtap = DoubleTapGestureRecognizer();
  final _onetap = TapGestureRecognizer();
  late double _gutterPadding;
  final Paint _caretPainter = Paint();
  final Paint _bracketHighlightPainter = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  late final ViewLineLayout _layout;
  late double _lineHeight;
  late ui.ParagraphStyle _paragraphStyle;
  late ui.TextStyle _uiTextStyle;
  late SyntaxHighlighter _syntaxHighlighter;
  late double _gutterWidth;
  Map<String, TextStyle> _editorTheme;
  Mode _language;
  EdgeInsets? _innerPadding;
  TextStyle? _textStyle;
  GutterStyle _gutterStyle;
  CodeSelectionStyle _selectionStyle;
  int _cachedCaretOffset = -1, _cachedCaretLine = 0, _cachedCaretLineStart = 0;
  Rect? _lastImeCaretRect;
  Rect? _lastImeComposingRect;
  Size? _lastImeEditableSize;
  double _imeComposingCaretDx = 0.0, _imeComposingWidth = 0.0;
  _Press? _press;
  final Set<int> _pointers = {};
  bool _multiTouch = false;
  int _multiTouchEndedAt = 0;
  ({
    int line,
    double fraction,
    double lead,
    double screenY,
    double scale,
    double shiftX,
  })?
  _zoomAnchor;
  ({double y, double dy, double scale, double shiftX})? _zoomFocus;
  ({int start, int end})? _pressWord;
  _DraggedHandle? _draggedHandle;
  Offset _handleGrip = Offset.zero;
  ({int start, int end})? _gutterSelectionAnchor;
  bool _foldTapped = false;
  Timer? _selectionTimer;
  Offset _currentPosition = Offset.zero;
  bool _isFoldToggleInProgress = false, _lineWrap;
  bool _hasActiveFoldsCache = false, _foldLayoutPending = false;
  bool _foldedLineCacheDirty = true;
  bool _asyncFoldComputationPending = false;
  int _asyncFoldsVersion = -1;
  Timer? _foldComputeTimer, _foldCacheRecheckTimer;
  bool _isDragging = false, _showBubble = false, _readOnly;
  bool _caretSyncAfterLayoutScheduled = false;
  bool _caretBlinkShown = false;
  Rect? _startHandleRect, _endHandleRect, _normalHandle;
  double _longLineWidth = 0.0, _wrapWidth = double.infinity;
  bool _wrappedRowEstimateStale = true;
  bool _extentUpdateScheduled = false;
  List<int> _paintLines = const [];
  Timer? _resizeTimer;
  Timer? _bracketHighlightResumeTimer;
  int? _highlightedLine;
  bool _suspendBracketHighlight = false;
  int _cachedLineCount = 0;
  late final CurvedAnimation _lineHighlightCurve;
  late final Animation<double> _lineHighlightAnimation;

  _CodeFieldRenderer({
    required this.controller,
    required this.vscrollController,
    required this.hscrollController,
    required this.focusNode,
    required this.caretBlinkController,
    required this.lineHighlightController,
    required this.isMobile,
    required this.selectionActiveNotifier,
    required this.onContextMenuRequest,
    required this.onPointerSignal,
    required this.caretRectNotifier,
    required this.magnifierNotifier,
    required this._lineWrap,
    required this._editorTheme,
    required this._language,
    required this._readOnly,
    required this._gutterStyle,
    required this._selectionStyle,
    this._innerPadding,
    this._textStyle,
  }) {
    _applyTextStyle();
    _syntaxHighlighter = SyntaxHighlighter(
      language: _language,
      editorTheme: _editorTheme,
      baseTextStyle: _textStyle,
    );
    _layout = ViewLineLayout(rowHeight: _lineHeight)
      ..reset(controller.lineCount);

    _updateGutterWidth();
    _cachedLineCount = controller.lineCount;
    controller.takeChange();
    if (!isMobile) {
      _onetap.onTap = () => controller.suggestionsNotifier.value = null;
    }

    vscrollController.addListener(_onScroll);
    hscrollController.addListener(_onScroll);
    caretBlinkController.addListener(_onCaretBlink);
    controller.addListener(_onControllerChange);
    _seenSelection = controller.selection;

    _lineHighlightCurve = CurvedAnimation(
      parent: lineHighlightController,
      curve: Curves.easeOut,
    );
    _lineHighlightAnimation = Tween<double>(
      begin: 0.55,
      end: 0.0,
    ).animate(_lineHighlightCurve)..addListener(markNeedsPaint);

    _adoptControllerFolds();
    if (_foldsInBackground) _scheduleAsyncFoldComputation();
  }

  Map<String, TextStyle> get editorTheme => _editorTheme;
  Mode get language => _language;
  TextStyle? get textStyle => _textStyle;
  EdgeInsets? get innerPadding => _innerPadding;
  bool get readOnly => _readOnly;
  bool get _selectionActive => selectionActiveNotifier.value;
  set _selectionActive(bool value) => selectionActiveNotifier.value = value;
  bool get lineWrap => _lineWrap;
  GutterStyle get gutterStyle => _gutterStyle;
  CodeSelectionStyle get selectionStyle => _selectionStyle;

  set editorTheme(Map<String, TextStyle> theme) {
    if (identical(theme, _editorTheme)) return;
    _editorTheme = theme;
    _applyColors();
    _rebuildHighlighter();
  }

  set language(Mode lang) {
    if (identical(lang, _language)) return;
    _language = lang;
    _rebuildHighlighter();
  }

  set textStyle(TextStyle? style) {
    if (identical(style, _textStyle)) return;
    final previous = _textStyle;
    final sizeOnly =
        style != null &&
        previous != null &&
        style.copyWith(fontSize: previous.fontSize) == previous;
    final scale = sizeOnly
        ? (style.fontSize ?? 14.0) / (previous.fontSize ?? 14.0)
        : 1.0;
    if (sizeOnly && attached && vscrollController.hasClients) {
      final focus = _zoomFocus;
      final y =
          vscrollController.offset -
          (innerPadding?.top ?? 0) +
          (focus == null ? 0.0 : (focus.y - focus.dy) / focus.scale);
      final line = _lineAtY(max(0.0, y));
      final extent = _lineExtent(line);
      _zoomAnchor = (
        line: line,
        fraction: extent > 0 ? (max(0.0, y) - _lineTop(line)) / extent : 0.0,
        lead: min(0.0, y),
        screenY: focus?.y ?? 0.0,
        scale: scale,
        shiftX: focus?.shiftX ?? 0.0,
      );
    }
    _zoomFocus = null;
    _textStyle = style;
    _applyTextStyle();
    _updateGutterWidth();
    _wrapWidth = double.infinity;
    if (!sizeOnly) {
      _rebuildHighlighter(layout: true);
      return;
    }
    final longLineWidth = _longLineWidth * scale;
    _invalidateAll(layout: true);
    _longLineWidth = longLineWidth;
    markNeedsLayout();
    markNeedsPaint();
  }

  set innerPadding(EdgeInsets? padding) {
    if (identical(padding, _innerPadding)) return;
    _innerPadding = padding;
    markNeedsLayout();
    markNeedsPaint();
  }

  set readOnly(bool value) {
    if (_readOnly == value) return;
    _readOnly = value;
    markNeedsPaint();
  }

  set lineWrap(bool value) {
    if (_lineWrap == value) return;
    _lineWrap = value;
    _invalidateAll(layout: true);
    markNeedsLayout();
    markNeedsPaint();
  }

  set gutterStyle(GutterStyle style) {
    if (identical(style, _gutterStyle)) return;
    _gutterStyle = style;
    _updateGutterWidth();
    markNeedsLayout();
    markNeedsPaint();
  }

  set selectionStyle(CodeSelectionStyle style) {
    if (identical(style, _selectionStyle)) return;
    _selectionStyle = style;
    _applyColors();
    markNeedsPaint();
  }

  // The caret only shows or hides as the blink crosses the midpoint, so the
  // ticks in between leave the painted field untouched.
  void _onCaretBlink() {
    final shown = caretBlinkController.value > 0.5;
    if (shown == _caretBlinkShown) return;
    _caretBlinkShown = shown;
    markNeedsPaint();
  }

  void _onScroll() {
    if (controller.suggestions != null) _publishCaretRect();
    markNeedsPaint();
  }

  void _onControllerChange() {
    final change = controller.takeChange();
    if (change.replaced) {
      _seenSelection = controller.selection;
      _resetForReplacedDocument();
      return;
    }
    final edit = change.lines;
    if (edit != null) _applyEdit(edit);
    _showWholeLinesPastCaret();
    if (change.isEmpty) return;

    final caretMoved = change.selection || change.composition || change.typing;
    if (caretMoved) _revealCaret();
    if (change.composition) _caretInfoCache.clear();
    if (edit == null && change.typing) {
      _invalidateCaret();
      _pauseBracketHighlightDuringTyping();
    } else if (edit == null &&
        change.selection &&
        isMobile &&
        controller.selection.isCollapsed) {
      _showBubble = true;
    }
    markNeedsPaint();

    // An edit from the find panel leaves the view where it is.
    if (!_isFoldToggleInProgress &&
        (caretMoved || (edit != null && focusNode.hasFocus))) {
      _ensureCaretVisible();
    }
  }

  void _applyEdit(({int line, int removed, int inserted}) edit) {
    if (isMobile) _showBubble = false;
    _pauseBracketHighlightDuringTyping();
    _invalidateFrom(edit);
    if (_spliceLayout(edit)) _foldedLineCacheDirty = true;
    _applyLineEditToFolds(edit);

    final lineCount = controller.lineCount;
    if (lineCount != _cachedLineCount) {
      _cachedLineCount = lineCount;
      _longLineWidth = 0.0;
      _updateGutterWidth();
      markNeedsLayout();
      _scheduleCaretSyncAfterLayout();
      return;
    }
    final width = _getLineWidth(edit.line);
    final contentWidth =
        size.width - _gutterWidth - (innerPadding?.horizontal ?? 0);
    if (width > contentWidth || width > _longLineWidth) {
      _longLineWidth = width;
      markNeedsLayout();
      // The view can follow the caret only once layout has widened it.
      if (focusNode.hasFocus) _scheduleCaretSyncAfterLayout();
    }
  }

  void _updateGutterWidth() {
    _gutterWidth = _gutterWidthFor(_lineNumberFontSize);
  }

  static const _gutterInset = 8.0;

  double _gutterWidthFor(double fontSize) {
    final digits = controller.lineCount.toString().length;
    return _gutterInset + digits * fontSize * 0.6 + fontSize + 8;
  }

  double get _lineNumberFontSize =>
      gutterStyle.lineNumberStyle?.fontSize ?? _gutterPadding;

  double get _foldIconSize => _lineNumberFontSize + 4;

  double get _foldIconStripWidth => _foldIconSize + 4;

  void _resetForReplacedDocument() {
    _cachedLineCount = controller.lineCount;
    _showBubble = false;

    _layout.reset(_cachedLineCount);
    _invalidateAll(layout: true);
    _updateGutterWidth();

    _invalidateFoldRanges();

    markNeedsLayout();
    markNeedsPaint();
    if (focusNode.hasFocus) _scheduleCaretSyncAfterLayout();
  }

  void _holdScroll(ScrollController scroll) {
    if (!scroll.hasClients) return;
    scroll.position.jumpTo(scroll.position.pixels);
  }

  void _applyZoomAnchor() {
    final anchor = _zoomAnchor;
    if (anchor == null) return;
    _zoomAnchor = null;
    if (vscrollController.hasClients) {
      final position = vscrollController.position;
      final target =
          _lineTop(anchor.line) +
          anchor.fraction * _lineExtent(anchor.line) +
          (innerPadding?.top ?? 0) +
          anchor.lead -
          anchor.screenY;
      position.correctPixels(
        target.clamp(0.0, max(0.0, size.height - position.viewportDimension)),
      );
    }
    if (!lineWrap && hscrollController.hasClients) {
      final position = hscrollController.position;
      position.correctPixels(
        (position.pixels * anchor.scale - anchor.shiftX).clamp(
          0.0,
          max(0.0, size.width - position.viewportDimension),
        ),
      );
    }
  }

  ({double dx, double dy, double shiftX}) _pinchPreview(
    Offset focal,
    double scale,
    double lineNumberScale,
  ) {
    final padding = innerPadding ?? EdgeInsets.zero;
    final vertical = vscrollController.position;
    final scrolledY = vertical.pixels * scale + padding.top * (1 - scale);
    final maxY = max(
      0.0,
      _lines.totalHeight * scale +
          padding.vertical -
          vertical.viewportDimension,
    );
    final dy = ((1 - scale) * focal.dy).clamp(scrolledY - maxY, scrolledY);
    final gutterWidth = _gutterWidthFor(_lineNumberFontSize * lineNumberScale);
    final left =
        gutterWidth + padding.left - scale * (_gutterWidth + padding.left);
    if (lineWrap) return (dx: left, dy: dy, shiftX: 0.0);
    final horizontal = hscrollController.position;
    final scrolledX = horizontal.pixels * scale;
    final maxX = max(
      0.0,
      _longLineWidth * scale +
          gutterWidth +
          padding.horizontal -
          horizontal.viewportDimension,
    );
    final x = scale > 1
        ? (left + scrolledX - (1 - scale) * focal.dx).clamp(0.0, maxX)
        : min(scrolledX, maxX);
    return (dx: left + scrolledX - x, dy: dy, shiftX: scrolledX - x);
  }

  @override
  void detach() {
    _bracketHighlightResumeTimer?.cancel();
    _resizeTimer?.cancel();
    _foldComputeTimer?.cancel();
    _foldCacheRecheckTimer?.cancel();
    _selectionTimer?.cancel();
    super.detach();
  }

  @override
  void performLayout() {
    if (lineWrap) {
      final newWrapWidth =
          constraints.maxWidth - _gutterWidth - (innerPadding?.horizontal ?? 0);
      final clampedWrapWidth = newWrapWidth < 100 ? 100.0 : newWrapWidth;

      if (_wrapWidth == double.infinity) {
        _resizeTimer?.cancel();
        _wrapWidth = clampedWrapWidth;
      } else if ((_wrapWidth - clampedWrapWidth).abs() > 1) {
        _resizeTimer?.cancel();
        _resizeTimer = Timer(const Duration(milliseconds: 150), () {
          _wrapWidth = clampedWrapWidth;
          _invalidateAll(layout: true);
          markNeedsLayout();
        });
      }
      _estimateWrappedRows();
    } else {
      _wrapWidth = double.infinity;
      _updateLongLineWidth(controller.lineCount);
    }

    final computedContentHeight = _lines.totalHeight + (innerPadding?.top ?? 0);
    final computedWidth = lineWrap
        ? constraints.maxWidth
        : _longLineWidth + (innerPadding?.left ?? 0) + _gutterWidth;

    size = constraints.constrain(
      Size(
        computedWidth + (innerPadding?.right ?? 0),
        computedContentHeight + (innerPadding?.bottom ?? 0),
      ),
    );
    _foldLayoutPending = false;
    _applyZoomAnchor();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final viewTop = _paintViewTop;
    final viewBottom = viewTop + vscrollController.position.viewportDimension;
    final bgColor = editorTheme['root']?.backgroundColor ?? Colors.white;
    final textColor = textStyle?.color ?? editorTheme['root']!.color!;

    canvas.save();

    canvas.drawPaint(
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill,
    );

    final hasActiveFolds = _hasActiveFolds;
    final paintLines = _collectPaintLines(viewTop, viewBottom);
    _paintLines = paintLines;
    final firstVisibleLine = paintLines.first;
    final lastVisibleLine = paintLines.last;

    _pruneViewportCaches(firstVisibleLine, lastVisibleLine);
    var needsSyntaxHighlight = false;
    for (final i in paintLines) {
      if (!_syntaxHighlighter.hasLineSpan(_lineText(i))) {
        needsSyntaxHighlight = true;
        break;
      }
    }
    if (needsSyntaxHighlight) {
      unawaited(
        _syntaxHighlighter
            .preHighlightLines(paintLines, controller.getLineText)
            .then((_) {
              _paragraphCache.removeWhere(
                (line, entry) =>
                    !entry.highlighted &&
                    line >= firstVisibleLine &&
                    line <= lastVisibleLine,
              );
              if (lineWrap && attached) markNeedsLayout();
              if (attached) markNeedsPaint();
            }),
      );
    }

    _drawSearchHighlights(canvas, offset, firstVisibleLine, lastVisibleLine);

    _drawLineHighlight(
      canvas,
      offset,
      firstVisibleLine,
      lastVisibleLine,
      hasActiveFolds,
    );

    _drawFoldedLineHighlights(
      canvas,
      offset,
      firstVisibleLine,
      lastVisibleLine,
      hasActiveFolds,
    );

    _drawSelection(canvas, offset, firstVisibleLine, lastVisibleLine);

    if ((lastVisibleLine - firstVisibleLine) < 200) {
      _drawIndentGuides(
        canvas,
        offset,
        firstVisibleLine,
        lastVisibleLine,
        textColor,
      );
    }

    for (final i in paintLines) {
      final contentTop = _lineTop(i);
      final paragraph = _paragraphFor(i);

      final foldRange = _getFoldRangeAtLine(i);
      final isFoldStart =
          foldRange != null && foldRange.endIndex > foldRange.startIndex;

      final screenY = _screenY(offset, contentTop);
      _drawLine(canvas, i, paragraph, Offset(_screenX(offset, 0), screenY));

      var lineEnd = paragraph.longestLine;
      if (_isCut(i)) {
        canvas.drawParagraph(
          _cutMarkerParagraph,
          Offset(_screenX(offset, lineEnd), screenY),
        );
        lineEnd += _cutMarkerParagraph.longestLine;
      }
      if (isFoldStart && foldRange.isFolded) {
        canvas.drawParagraph(
          _foldMarkerParagraph,
          Offset(_screenX(offset, lineEnd), screenY),
        );
      }
    }

    _lineSlices.removeWhere(
      (line, _) => line < firstVisibleLine || line > lastVisibleLine,
    );

    _drawGutter(
      canvas,
      offset,
      bgColor,
      gutterStyle.lineNumberStyle ?? textStyle,
    );

    canvas.save();
    if (!lineWrap && hscrollController.offset > 0) {
      canvas.clipRect(
        Rect.fromLTRB(
          offset.dx + _gutterWidth,
          offset.dy,
          offset.dx + size.width,
          offset.dy + size.height,
        ),
      );
    }

    if (focusNode.hasFocus) {
      _drawBracketHighlight(
        canvas,
        offset,
        firstVisibleLine,
        lastVisibleLine,
        hasActiveFolds,
        textColor,
      );
    }

    _drawImeComposition(canvas, offset, hasActiveFolds);

    if (!_readOnly &&
        focusNode.hasFocus &&
        caretBlinkController.value > 0.5 &&
        controller.imeComposition == null) {
      final caretInfo = _getCaretInfo();
      canvas.drawRect(
        Rect.fromLTWH(
          _screenX(offset, caretInfo.offset.dx),
          _screenY(offset, caretInfo.offset.dy),
          1.5,
          caretInfo.height,
        ),
        _caretPainter,
      );
    }
    canvas.restore();

    if (isMobile) _paintMobileHandles(canvas, offset);
    _publishMagnifier();

    canvas.restore();

    _updateImeGeometry();
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChange);
    vscrollController.removeListener(_onScroll);
    hscrollController.removeListener(_onScroll);
    caretBlinkController.removeListener(_onCaretBlink);
    _lineHighlightAnimation.removeListener(markNeedsPaint);
    _lineHighlightCurve.dispose();
    _syntaxHighlighter.dispose();
    _dtap.dispose();
    _onetap.dispose();
    super.dispose();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final isHit =
        size.contains(position) ||
        (_startHandleRect?.contains(position) ?? false) ||
        (_endHandleRect?.contains(position) ?? false) ||
        _hitsCaretHandle(position);
    if (isHit) result.add(BoxHitTestEntry(this, position));
    return isHit;
  }

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    _currentPosition = event.localPosition;
    switch (event) {
      case PointerDownEvent():
        _pointers.add(event.pointer);
        if (_pointers.length > 1) {
          if (!_multiTouch) {
            _multiTouch = true;
            _gutterSelectionAnchor = null;
            _endGesture();
            _holdScroll(vscrollController);
            _holdScroll(hscrollController);
            markNeedsPaint();
          }
          return;
        }
        _onPointerDown(event);
      case PointerMoveEvent():
        if (_multiTouch) return;
        _onPointerMove(event);
      case PointerUpEvent() || PointerCancelEvent():
        _pointers.remove(event.pointer);
        if (_multiTouch) {
          if (_pointers.isEmpty) {
            _multiTouch = false;
            _multiTouchEndedAt = DateTime.now().millisecondsSinceEpoch;
          }
          return;
        }
        _onPointerUp(event);
      case PointerSignalEvent():
        onPointerSignal(event);
    }
  }

  @override
  MouseCursor get cursor {
    final position = _currentPosition;
    if (_foldMarkerAt(position) != null) return SystemMouseCursors.click;
    if (position.dx < 0 || position.dx >= _gutterWidth) {
      return SystemMouseCursors.text;
    }
    final line = _lineAtY(_toContent(position).dy);
    return _foldIconAt(position, line) != null
        ? SystemMouseCursors.click
        : MouseCursor.defer;
  }

  @override
  PointerEnterEventListener? get onEnter => null;

  @override
  PointerExitEventListener? get onExit => null;

  @override
  bool get validForMouseTracker => true;
}

// As in VS Code, an unwrapped line is shown up to this many characters
// until a tap past them or a caret beyond them shows every line whole.
const _cutLength = 10000;

extension _RendererLayout on _CodeFieldRenderer {
  ViewLineLayout get _lines {
    _ensureFoldedLineCacheValid();
    return _layout;
  }

  double _lineTop(int line) => _lines.lineTop(line);

  int _lineAtY(double y) => _lines.lineAt(y);

  double _lineExtent(int line) {
    final lines = _lines;
    if (lineWrap && !lines.isMeasured(line)) _measureWrappedLine(line);
    return lines.lineHeight(line);
  }

  void _measureWrappedLine(int line) =>
      _recordExtent(line, _paragraphFor(line));

  // Layout measures the widest line only near the viewport, so an unwrapped
  // line wider than that widens the content once it is painted.
  void _recordExtent(int line, ui.Paragraph para) {
    if (lineWrap) {
      final rows = max(1, (para.height / _lineHeight).round());
      if (!_lines.setRows(line, rows)) return;
      _caretInfoCache.clear();
    } else {
      final width = para.maxIntrinsicWidth + _cutMarkerWidth(line);
      if (width <= _longLineWidth) return;
      _longLineWidth = width;
    }
    if (_extentUpdateScheduled) return;
    _extentUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extentUpdateScheduled = false;
      if (attached) markNeedsLayout();
    });
  }

  void _estimateWrappedRows() {
    if (!_wrappedRowEstimateStale || !_wrapWidth.isFinite) return;
    _wrappedRowEstimateStale = false;
    final lines = _lines;
    final lineCount = lines.lineCount;
    if (lineCount <= kExactWrappedHeightThreshold) {
      for (var i = 0; i < lineCount; i++) {
        if (!lines.isMeasured(i)) _measureWrappedLine(i);
      }
      return;
    }
    final step = max(1, lineCount ~/ kWrappedHeightSampleSize);
    var rows = 0.0;
    var sampled = 0;
    for (var i = 0; i < lineCount; i += step) {
      if (!lines.isMeasured(i)) _measureWrappedLine(i);
      rows += lines.rowsOf(i);
      sampled++;
    }
    lines.setEstimate(rows / sampled);
    for (
      var i = max(0, lineCount - kExactWrappedTailLines);
      i < lineCount;
      i++
    ) {
      if (!lines.isMeasured(i)) _measureWrappedLine(i);
    }
  }

  // Widget listeners on the controller run before the renderer's and can
  // read the layout while an edit is still pending, so either side may apply
  // it; the line count shows whether it already has.
  bool _spliceLayout(({int line, int removed, int inserted}) edit) {
    if (_layout.lineCount - edit.removed + edit.inserted !=
        controller.lineCount) {
      return false;
    }
    _layout.splice(edit.line, edit.removed + 1, edit.inserted + 1);
    return true;
  }

  void _resetLineLayout() {
    _layout
      ..rowHeight = _lineHeight
      ..setEstimate(1)
      ..invalidateAll();
    _wrappedRowEstimateStale = true;
    _caretInfoCache.clear();
  }

  // A paragraph is checked against its text before reuse, so it can follow
  // its line past the edit and a long line keeps its layout.
  void _invalidateFrom(({int line, int removed, int inserted}) edit) {
    final line = edit.line;
    final replacedEnd = line + edit.removed;
    final shift = edit.inserted - edit.removed;
    final moved =
        <
          int,
          ({
            String text,
            ui.Paragraph paragraph,
            bool highlighted,
            bool comment,
          })
        >{};
    _paragraphCache.removeWhere((key, paragraph) {
      if (key < line) return false;
      if (key > replacedEnd && shift == 0) return false;
      if (key > replacedEnd) moved[key + shift] = paragraph;
      return true;
    });
    _paragraphCache.addAll(moved);
    bool stale(int key, Object? _) => key >= line;
    _lineTextCache.removeWhere(stale);
    _lineWidthCache.removeWhere(stale);
    _indentGuideCache.removeWhere(stale);
    _lineIndentCache.removeWhere(stale);
    _bracketCache.clear();
    _blockComments.invalidateFrom(line);
    _invalidateCaret();
  }

  /// [layout] also drops the measured wrapped rows and the widest line.
  void _invalidateAll({bool layout = false}) {
    _paragraphCache.clear();
    _blockComments.reset();
    _lineSlices.clear();
    _bufferLineCut = null;
    _cutMarker = _foldMarker = null;
    _lineTextCache.clear();
    _lineWidthCache.clear();
    _indentGuideCache.clear();
    _lineIndentCache.clear();
    _bracketCache.clear();
    _invalidateCaret();
    if (!layout) return;
    _resetLineLayout();
    _longLineWidth = 0.0;
  }

  void _invalidateCaret() {
    _caretInfoCache.clear();
    _cachedCaretOffset = -1;
  }

  void _rebuildHighlighter({bool layout = false}) {
    _syntaxHighlighter.dispose();
    _syntaxHighlighter = SyntaxHighlighter(
      language: language,
      editorTheme: editorTheme,
      baseTextStyle: textStyle,
    );
    _invalidateAll(layout: layout);
    markNeedsLayout();
    markNeedsPaint();
  }

  void _applyTextStyle() {
    final fontSize = _textStyle?.fontSize ?? 14.0;
    final lineHeightMultiplier = _textStyle?.height ?? 1.2;
    _lineHeight = fontSize * lineHeightMultiplier;
    _gutterPadding = fontSize;
    _paragraphStyle = _buildParagraphStyle(
      _textStyle?.fontFamily,
      fontSize,
      lineHeightMultiplier,
    );
    _applyColors();
  }

  void _applyColors() {
    final color =
        _textStyle?.color ?? _editorTheme['root']?.color ?? Colors.black;
    _uiTextStyle = ui.TextStyle(
      color: color,
      fontSize: _textStyle?.fontSize ?? 14.0,
      fontFamily: _textStyle?.fontFamily,
      fontFamilyFallback: _textStyle?.fontFamilyFallback,
    );
    _caretPainter.color = _selectionStyle.cursorColor ?? color;
  }

  // Forcing the strut keeps every row exactly _lineHeight tall, even where a
  // fallback font would grow it, so a line's height is its row count times
  // _lineHeight.
  ui.ParagraphStyle _buildParagraphStyle(
    String? fontFamily,
    double fontSize,
    double lineHeightMultiplier,
  ) {
    return ui.ParagraphStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: lineHeightMultiplier,
      textDirection: TextDirection.ltr,
      textAlign: ui.TextAlign.start,
      strutStyle: ui.StrutStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: lineHeightMultiplier,
        forceStrutHeight: true,
      ),
    );
  }

  ui.Paragraph _buildParagraph(String text, {double? width}) {
    final builder = ui.ParagraphBuilder(_paragraphStyle)
      ..pushStyle(_uiTextStyle)
      ..addText(text.isEmpty ? ' ' : text);
    final p = builder.build();
    p.layout(ui.ParagraphConstraints(width: width ?? double.infinity));
    return p;
  }

  String _lineText(int line) {
    if (controller.isBufferActive && line == controller.bufferLineIndex) {
      return _shownBufferLine(controller.bufferLineText!);
    }
    return _lineTextCache[line] ??= _fetchLineText(line);
  }

  bool get _cutsLongLines => !lineWrap && !_wholeLines;

  String _fetchLineText(int line) {
    if (!_cutsLongLines) return controller.getLineText(line);
    final rope = controller.rope;
    final start = rope.getLineStartOffset(line);
    if (_ropeLineEnd(line) - start <= _cutLength) {
      return controller.getLineText(line);
    }
    return rope.substring(start, start + _cutLength);
  }

  String _shownBufferLine(String text) {
    final cut = _bufferLineCut;
    if (cut != null && identical(cut.source, text)) return cut.shown;
    final end = _cutsLongLines ? text.toUtf16Offset(_cutLength) : text.length;
    final shown = end < text.length ? text.substring(0, end) : text;
    _bufferLineCut = (source: text, shown: shown);
    return shown;
  }

  int _ropeLineEnd(int line) {
    final rope = controller.rope;
    return line + 1 < rope.lineCount
        ? rope.getLineStartOffset(line + 1) - 1
        : rope.length;
  }

  bool _isCut(int line) {
    if (!_cutsLongLines) return false;
    final text = _lineText(line);
    if (text.length < _cutLength) return false;
    if (controller.isBufferActive && line == controller.bufferLineIndex) {
      return !identical(text, controller.bufferLineText);
    }
    return _ropeLineEnd(line) - controller.rope.getLineStartOffset(line) >
        _cutLength;
  }

  ui.Paragraph get _cutMarkerParagraph => _cutMarker ??= _buildParagraph(' …');

  ui.Paragraph get _foldMarkerParagraph =>
      _foldMarker ??= _buildParagraph(' ...');

  double _cutMarkerWidth(int line) =>
      _isCut(line) ? _cutMarkerParagraph.maxIntrinsicWidth : 0;

  bool _pastCut(Offset position) {
    if (!_cutsLongLines || controller.lineCount == 0) return false;
    final line = _lineAtY(position.dy);
    return _isCut(line) && position.dx > _paragraphFor(line).longestLine;
  }

  void _showWholeLinesPastCaret() {
    final selection = controller.selection;
    if (selection == _seenSelection) return;
    _seenSelection = selection;
    if (!_cutsLongLines || !selection.isCollapsed) return;
    final line = controller.getLineAtOffset(selection.extentOffset);
    if (!_isCut(line) ||
        selection.extentOffset - controller.getLineStartOffset(line) <=
            _cutLength) {
      return;
    }
    _showWholeLines();
    _getLineWidth(line);
    // The view can scroll to the caret only once layout has widened it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) _ensureCaretVisible();
    });
  }

  void _showWholeLines() {
    _wholeLines = true;
    _invalidateAll();
    markNeedsLayout();
    markNeedsPaint();
  }

  // A wrapped line's row count must not change when highlighting lands late.
  ui.Paragraph _paragraphFor(int line) {
    final text = _lineText(line);
    final cached = _paragraphCache[line];
    final synchronous = lineWrap || line == controller.bufferLineIndex;
    final comment =
        controller.blockComments &&
        _blockComments.startsInside(controller, line);
    final highlighted =
        comment || synchronous || _syntaxHighlighter.hasLineSpan(text);
    if (cached != null &&
        cached.text == text &&
        cached.comment == comment &&
        (cached.highlighted || !highlighted)) {
      return cached.paragraph;
    }
    final paragraph = comment
        ? _syntaxHighlighter.buildBlockCommentParagraph(
            text,
            _paragraphStyle,
            textStyle?.fontSize ?? 14.0,
            textStyle?.fontFamily,
            width: lineWrap ? _wrapWidth : null,
          )
        : _syntaxHighlighter.buildHighlightedParagraph(
            text,
            _paragraphStyle,
            textStyle?.fontSize ?? 14.0,
            textStyle?.fontFamily,
            width: lineWrap ? _wrapWidth : null,
            allowSynchronousHighlight: synchronous,
          );
    _paragraphCache[line] = (
      text: text,
      paragraph: paragraph,
      highlighted: highlighted,
      comment: comment,
    );
    _recordExtent(line, paragraph);
    return paragraph;
  }

  ({int lineIndex, int columnIndex, Offset offset, double height})
  _getCaretInfo() {
    final cursorOffset = controller.selection.extentOffset;

    final lineCount = controller.lineCount;
    if (lineCount == 0) {
      final result = (
        lineIndex: 0,
        columnIndex: 0,
        offset: Offset.zero,
        height: _lineHeight,
      );
      _caretInfoCache[cursorOffset] = result;
      return result;
    }

    if (_caretInfoCache.containsKey(cursorOffset)) {
      return _caretInfoCache[cursorOffset]!;
    }

    int lineIndex;
    int lineStartOffset;
    if (cursorOffset == _cachedCaretOffset) {
      lineIndex = _cachedCaretLine;
      lineStartOffset = _cachedCaretLineStart;
    } else {
      lineIndex = controller.getLineAtOffset(cursorOffset);
      lineStartOffset = controller.getLineStartOffset(lineIndex);
      _cachedCaretOffset = cursorOffset;
      _cachedCaretLine = lineIndex;
      _cachedCaretLineStart = lineStartOffset;
    }

    final columnIndex = cursorOffset - lineStartOffset;
    final lineY = _lineTop(lineIndex);
    final lineText = _lineText(lineIndex);

    final utf16Col = lineText.toUtf16Offset(columnIndex);
    final clampedCol = utf16Col.clamp(0, lineText.length);
    double caretX = 0.0, caretYInLine = 0.0;

    if (lineText.isNotEmpty && clampedCol > 0) {
      final box =
          _boxBefore(lineIndex, lineText, clampedCol) ??
          _boxBefore(lineIndex, lineText, 1);
      if (box != null) {
        caretX = box.right;
        caretYInLine = _rowTopForBox(box);
      }
    }

    final result = (
      lineIndex: lineIndex,
      columnIndex: columnIndex,
      offset: Offset(caretX, lineY + caretYInLine),
      height: _lineHeight,
    );
    _caretInfoCache[cursorOffset] = result;
    return result;
  }

  int _getTextOffsetFromPosition(Offset position) {
    final lineCount = controller.lineCount;
    if (lineCount == 0) return 0;

    final tappedLineIndex = _lineAtY(position.dy);
    final lineText = _lineText(tappedLineIndex);
    final para = _paragraphFor(tappedLineIndex);

    final double localX = position.dx;

    final localY = position.dy - _lineTop(tappedLineIndex);

    final textPosition = para.getPositionForOffset(
      Offset(localX, localY.clamp(0, para.height)),
    );
    final utf16Column = textPosition.offset.clamp(0, lineText.length);
    final scalarColumn = lineText.toScalarOffset(utf16Column);

    final lineStartOffset = controller.getLineStartOffset(tappedLineIndex);
    final absoluteOffset = lineStartOffset + scalarColumn;

    return absoluteOffset.clamp(0, controller.length);
  }

  double get _handleRadius => (_lineHeight / 2).clamp(6.0, 12.0);

  double get _handleSize => _handleRadius * 2 * 1.2;

  // A selection handle hangs this far outside the text position it marks.
  double get _handleOverhang => (textStyle?.fontSize ?? 14) / 2;

  // Only below the caret line, so a press on the text at the caret still
  // reaches the text.
  bool _hitsCaretHandle(Offset local) {
    final handle = _normalHandle;
    return handle != null &&
        local.dy >= handle.top &&
        handle.inflate(_handleRadius * 1.5).contains(local);
  }

  Offset _toContent(Offset local) => Offset(
    local.dx - _textLeft,
    local.dy - (innerPadding?.top ?? 0) + vscrollController.offset,
  );

  FoldRange? _foldIconAt(Offset local, int line) {
    if (local.dx < _gutterWidth - _foldIconStripWidth) return null;
    final fold = _getFoldRangeAtLine(line);
    return fold != null && fold.endIndex > fold.startIndex ? fold : null;
  }

  FoldRange? _foldMarkerAt(Offset local) {
    if (local.dx < _gutterWidth || controller.lineCount == 0) return null;
    final content = _toContent(local);
    final line = _lineAtY(content.dy);
    final fold = _getFoldRangeAtLine(line);
    if (fold == null || !fold.isFolded || fold.endIndex <= fold.startIndex) {
      return null;
    }
    final marker = _foldMarkerParagraph;
    var left = _paragraphFor(line).longestLine;
    if (_isCut(line)) left += _cutMarkerParagraph.longestLine;
    final top = _lineTop(line);
    return content.dx >= left &&
            content.dx <= left + marker.longestLine &&
            content.dy >= top &&
            content.dy <= top + marker.height
        ? fold
        : null;
  }

  // A folded block is selected whole, as it shows as a single line.
  ({int start, int end}) _gutterLineRange(int line) {
    final fold = _getFoldRangeAtLine(line);
    final last = fold != null && fold.isFolded ? fold.endIndex : line;
    return (
      start: controller.getLineStartOffset(line),
      end: last + 1 < controller.lineCount
          ? controller.getLineStartOffset(last + 1)
          : controller.length,
    );
  }

  void _selectLinesFromGutter(int line) {
    final base = controller.selection.baseOffset;
    _gutterSelectionAnchor =
        !isMobile && HardwareKeyboard.instance.isShiftPressed
        ? (start: base, end: base)
        : _gutterLineRange(line);
    _extendGutterSelection(line);
    if (isMobile) _selectionActive = true;
  }

  void _extendGutterSelection(int line) {
    final anchor = _gutterSelectionAnchor!;
    final range = _gutterLineRange(line);
    controller.selection = range.start < anchor.start
        ? TextSelection(baseOffset: anchor.end, extentOffset: range.start)
        : TextSelection(baseOffset: anchor.start, extentOffset: range.end);
  }

  Offset getCaretOffset() => _getCaretInfo().offset;

  int getScrollbarLineNumberAtScrollOffset(double scrollOffset) {
    if (!vscrollController.hasClients || controller.lineCount == 0) {
      return 1;
    }

    final lineIndex = _lineAtY(scrollOffset).clamp(0, controller.lineCount - 1);
    return lineIndex + 1;
  }

  double _getLineWidth(int lineIndex) {
    final text = _lineText(lineIndex);
    return _lineWidthCache[lineIndex] ??=
        (SyntaxHighlighter.isPlain(text)
            ? _paragraphFor(lineIndex).maxIntrinsicWidth
            : _buildParagraph(text).maxIntrinsicWidth) +
        _cutMarkerWidth(lineIndex);
  }

  // Plain text looks the same from any cluster on, so a slice around the
  // view spares the engine every glyph of a megabyte line on each frame.
  void _drawLine(Canvas canvas, int line, ui.Paragraph paragraph, Offset at) {
    final slice = _sliceInView(line, _lineText(line), paragraph);
    if (slice == null) {
      canvas.drawParagraph(paragraph, at);
    } else {
      canvas.drawParagraph(slice.paragraph, at + slice.origin);
    }
  }

  _LineSlice? _sliceInView(int line, String text, ui.Paragraph paragraph) {
    if (!SyntaxHighlighter.isPlain(text)) return null;
    final view = Rect.fromLTWH(
      -_textLeft,
      _paintViewTop - _lineTop(line),
      hscrollController.position.viewportDimension,
      vscrollController.position.viewportDimension,
    );
    final old = _lineSlices[line];
    final reusable = old != null && old.text == text ? old : null;
    if (reusable != null &&
        reusable.cover.left <= view.left &&
        reusable.cover.right >= view.right &&
        reusable.cover.top <= view.top &&
        reusable.cover.bottom >= view.bottom) {
      return reusable;
    }
    final slice = lineWrap
        ? _sliceRows(text, paragraph, view, reusable)
        : _sliceColumns(text, paragraph, view, reusable);
    _lineSlices[line] = slice;
    return slice;
  }

  _LineSlice _sliceRows(
    String text,
    ui.Paragraph paragraph,
    Rect view,
    _LineSlice? old,
  ) {
    final rows = max(1, (paragraph.height / _lineHeight).round());
    final firstRow = max(0, ((view.top - view.height) / _lineHeight).floor());
    final lastRow = min(
      rows - 1,
      ((view.bottom + view.height) / _lineHeight).ceil(),
    );
    int rowStart(int row) =>
        paragraph
            .getClosestGlyphInfoForOffset(Offset(0, (row + 0.5) * _lineHeight))
            ?.graphemeClusterCodeUnitRange
            .start ??
        text.length;
    final start = firstRow == 0 ? 0 : rowStart(firstRow);
    final end = lastRow == rows - 1
        ? text.length
        : max(start, rowStart(lastRow + 1));
    return _slice(
      text,
      start,
      end,
      old,
      origin: Offset(0, firstRow * _lineHeight),
      cover: Rect.fromLTRB(
        double.negativeInfinity,
        firstRow == 0 ? double.negativeInfinity : firstRow * _lineHeight,
        double.infinity,
        lastRow == rows - 1 ? double.infinity : (lastRow + 1) * _lineHeight,
      ),
      width: _wrapWidth,
    );
  }

  // The previous slice places one edge without walking the whole line, and
  // the other edge is reached by laying out characters until they cover it.
  _LineSlice _sliceColumns(
    String text,
    ui.Paragraph paragraph,
    Rect view,
    _LineSlice? old,
  ) {
    final from = view.left - view.width;
    final to = view.right + view.width;
    final margin = 2 * (textStyle?.fontSize ?? 14.0);
    final oldRight = old == null
        ? 0.0
        : old.origin.dx + old.paragraph.maxIntrinsicWidth;
    if (old != null && from > 0 && from >= old.origin.dx && from < oldRight) {
      final first = _clusterIn(old, from);
      if (first != null) {
        var end = first.start;
        ui.Paragraph built;
        do {
          end = _codeUnitBoundary(
            text,
            end + max(64, ((to - first.left) / _advanceOf(old)).ceil()),
          );
          built = _plainParagraph(text.substring(first.start, end));
        } while (end < text.length &&
            built.maxIntrinsicWidth - margin < to - first.left);
        return _slice(
          text,
          first.start,
          end,
          old,
          origin: Offset(first.left, 0),
          cover: Rect.fromLTRB(
            first.left,
            double.negativeInfinity,
            end >= text.length
                ? double.infinity
                : first.left + built.maxIntrinsicWidth - margin,
            double.infinity,
          ),
          paragraph: built,
        );
      }
    }
    if (old != null && to > old.origin.dx && to < oldRight) {
      final last = _clusterIn(old, to);
      if (last != null) {
        var start = last.end;
        ui.Paragraph built;
        do {
          start = _codeUnitBoundary(
            text,
            start - max(64, ((last.right - from) / _advanceOf(old)).ceil()),
          );
          built = _plainParagraph(text.substring(start, last.end));
        } while (start > 0 &&
            built.maxIntrinsicWidth - margin < last.right - from);
        final left = last.right - built.maxIntrinsicWidth;
        return _slice(
          text,
          start,
          last.end,
          old,
          origin: Offset(left, 0),
          cover: Rect.fromLTRB(
            start == 0 ? double.negativeInfinity : left + margin,
            double.negativeInfinity,
            last.right,
            double.infinity,
          ),
          paragraph: built,
        );
      }
    }
    final y = _lineHeight / 2;
    final first = from > 0
        ? paragraph.getClosestGlyphInfoForOffset(Offset(from, y))
        : null;
    final last = to < paragraph.maxIntrinsicWidth
        ? paragraph.getClosestGlyphInfoForOffset(Offset(to, y))
        : null;
    final start = first?.graphemeClusterCodeUnitRange.start ?? 0;
    final end = max(
      start,
      last?.graphemeClusterCodeUnitRange.end ?? text.length,
    );
    final x = start == 0 ? 0.0 : first!.graphemeClusterLayoutBounds.left;
    return _slice(
      text,
      start,
      end,
      old,
      origin: Offset(x, 0),
      cover: Rect.fromLTRB(
        start == 0 ? double.negativeInfinity : x,
        double.negativeInfinity,
        end >= text.length
            ? double.infinity
            : last!.graphemeClusterLayoutBounds.right,
        double.infinity,
      ),
    );
  }

  _LineSlice _slice(
    String text,
    int start,
    int end,
    _LineSlice? old, {
    required Offset origin,
    required Rect cover,
    ui.Paragraph? paragraph,
    double? width,
  }) {
    final shown = text.substring(start, end);
    final scalarStart = old == null
        ? text.toScalarOffset(start)
        : start >= old.start
        ? old.scalarStart + text.substring(old.start, start).runes.length
        : old.scalarStart - text.substring(start, old.start).runes.length;
    return (
      text: text,
      start: start,
      end: end,
      scalarStart: scalarStart,
      scalarEnd: scalarStart + shown.runes.length,
      origin: origin,
      cover: cover,
      paragraph: paragraph ?? _plainParagraph(shown, width: width),
    );
  }

  ui.Paragraph _plainParagraph(String text, {double? width}) =>
      _syntaxHighlighter.buildPlainParagraph(
        text,
        _paragraphStyle,
        textStyle?.fontSize ?? 14.0,
        textStyle?.fontFamily,
        width: width,
      );

  ({int start, int end, double left, double right})? _clusterIn(
    _LineSlice slice,
    double x,
  ) {
    final glyph = slice.paragraph.getClosestGlyphInfoForOffset(
      Offset(x - slice.origin.dx, _lineHeight / 2),
    );
    if (glyph == null) return null;
    return (
      start: slice.start + glyph.graphemeClusterCodeUnitRange.start,
      end: slice.start + glyph.graphemeClusterCodeUnitRange.end,
      left: slice.origin.dx + glyph.graphemeClusterLayoutBounds.left,
      right: slice.origin.dx + glyph.graphemeClusterLayoutBounds.right,
    );
  }

  double _advanceOf(_LineSlice slice) => max(
    1.0,
    slice.paragraph.maxIntrinsicWidth / max(1, slice.end - slice.start),
  );

  int _codeUnitBoundary(String text, int index) {
    final clamped = index.clamp(0, text.length);
    return text.isLowSurrogateAt(clamped) ? clamped + 1 : clamped;
  }

  void _updateLongLineWidth(int lineCount) {
    if (_longLineWidth != 0 || lineCount == 0) return;
    final viewTop = vscrollController.hasClients
        ? vscrollController.offset
        : 0.0;
    final viewBottom =
        viewTop +
        (vscrollController.hasClients
            ? vscrollController.position.viewportDimension
            : constraints.minHeight);
    const buffer = 50;
    final start = max(0, _lineAtY(viewTop) - buffer);
    final end = min(lineCount - 1, _lineAtY(viewBottom) + buffer);
    for (var i = _lines.nextVisible(start); i <= end;) {
      final width = _getLineWidth(i);
      if (width > _longLineWidth) _longLineWidth = width;
      final next = _lines.nextVisible(i + 1);
      if (next <= i) break;
      i = next;
    }
  }

  // The engine walks every run of a paragraph for any range, so a megabyte
  // plain line is asked only about the character before [column], and its
  // slice answers when it holds that character.
  ui.TextBox? _boxBefore(
    int line,
    String text,
    int column, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
  }) {
    if (column <= 0) return null;
    final paragraph = _paragraphFor(line);
    if (SyntaxHighlighter.isPlain(text)) {
      final from = text.isLowSurrogateAt(column - 1) ? column - 2 : column - 1;
      final boxes =
          _sliceBoxes(line, text, from, column, boxHeightStyle) ??
          paragraph.getBoxesForRange(
            from,
            column,
            boxHeightStyle: boxHeightStyle,
          );
      if (boxes.isNotEmpty) return boxes.last;
    }
    final boxes = paragraph.getBoxesForRange(
      0,
      column,
      boxHeightStyle: boxHeightStyle,
    );
    return boxes.isEmpty ? null : boxes.last;
  }

  List<ui.TextBox>? _sliceBoxes(
    int line,
    String text,
    int from,
    int to, [
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
  ]) {
    final slice = _lineSlices[line];
    if (slice == null ||
        slice.text != text ||
        from < slice.start ||
        to > slice.end) {
      return null;
    }
    return [
      for (final box in slice.paragraph.getBoxesForRange(
        from - slice.start,
        to - slice.start,
        boxHeightStyle: boxHeightStyle,
      ))
        ui.TextBox.fromLTRBD(
          box.left + slice.origin.dx,
          box.top + slice.origin.dy,
          box.right + slice.origin.dx,
          box.bottom + slice.origin.dy,
          box.direction,
        ),
    ];
  }

  double _rowTopForBox(ui.TextBox box) {
    final center = (box.top + box.bottom) / 2.0;
    final rowIndex = (center / _lineHeight).floor();
    return (rowIndex < 0 ? 0 : rowIndex) * _lineHeight;
  }

  // Lines scrolled into the top padding stay visible, so a toolbar floating
  // over the editor shows the text passing beneath it.
  double get _paintViewTop =>
      max(0.0, vscrollController.offset - (innerPadding?.top ?? 0));

  // The visible lines intersecting [viewTop, viewBottom), measured, in order;
  // a folded run is stepped over rather than walked.
  List<int> _collectPaintLines(double viewTop, double viewBottom) {
    final lines = _lines;
    final lineCount = lines.lineCount;
    if (lineCount == 0) return const [0];
    final result = <int>[];
    var line = lines.lineAt(viewTop);
    while (true) {
      final height = _lineExtent(line);
      result.add(line);
      if (lines.lineTop(line) + height >= viewBottom) break;
      final next = lines.nextVisible(line + 1);
      if (next <= line) break;
      line = next;
    }
    return result;
  }

  void _pruneViewportCaches(int firstVisibleLine, int lastVisibleLine) {
    const int keepMargin = 400;
    const int maxLineBoundedCacheEntries = 3000;

    final minKeep = max(0, firstVisibleLine - keepMargin);
    final maxKeep = min(controller.lineCount - 1, lastVisibleLine + keepMargin);

    bool shouldPrune(Map<int, dynamic> cache) {
      return cache.length > maxLineBoundedCacheEntries;
    }

    void pruneIntKeyed(Map<int, dynamic> cache) {
      if (!shouldPrune(cache)) return;
      cache.removeWhere((line, _) => line < minKeep || line > maxKeep);
    }

    pruneIntKeyed(_lineTextCache);
    pruneIntKeyed(_lineWidthCache);
    pruneIntKeyed(_paragraphCache);
    pruneIntKeyed(_lineIndentCache);
    for (final offsetKeyed in [_bracketCache, _caretInfoCache]) {
      if (shouldPrune(offsetKeyed)) offsetKeyed.clear();
    }

    if (_indentGuideCache.length > maxLineBoundedCacheEntries) {
      _indentGuideCache.removeWhere(
        (line, _) => line < minKeep || line > maxKeep,
      );
    }
  }
}

typedef _Press = ({Offset position, int offset});

enum _DraggedHandle { caret, start, end }

extension _RendererPointer on _CodeFieldRenderer {
  void _onPointerDown(PointerDownEvent event) {
    final position = event.localPosition;
    final content = _toContent(position);
    if (event.buttons == kPrimaryButton && _toggleFoldAt(position, content)) {
      _foldTapped = true;
      controller.suggestionsNotifier.value = null;
      return;
    }
    if (_pastCut(content)) _showWholeLines();
    switch (event.buttons) {
      case kSecondaryButton:
        _openContextMenu(position);
      case kPrimaryButton:
        _onPrimaryDown(event, content);
    }
  }

  bool _toggleFoldAt(Offset position, Offset content) {
    final fold = _foldControlAt(position, content);
    return fold != null && _toggleFold(fold);
  }

  FoldRange? _foldControlAt(Offset position, Offset content) {
    if (_isOnTouchHandle(position)) return null;
    if (position.dx >= _gutterWidth) return _foldMarkerAt(position);
    return _foldIconAt(position, _lineAtY(content.dy));
  }

  void _takeFocus() {
    if (!(controller.connection?.attached ?? false) || !focusNode.hasFocus) {
      focusNode.requestFocus();
    }
    controller.suggestionsNotifier.value = null;
  }

  void _onPrimaryDown(PointerDownEvent event, Offset content) {
    _takeFocus();
    _onetap.addPointer(event);

    final position = event.localPosition;
    if (position.dx < _gutterWidth && !_isOnTouchHandle(position)) {
      _selectLinesFromGutter(_lineAtY(content.dy));
      return;
    }

    _dtap
      ..onDoubleTap = () {
        if (_afterMultiTouch) return;
        _selectWordAtOffset(_committedOffsetAt(position));
        if (isMobile) onContextMenuRequest(position);
      }
      ..addPointer(event);
    if (isMobile) {
      _onMobileDown(position, _getTextOffsetFromPosition(content));
    } else {
      _onDesktopDown(position, _committedOffsetAt(position));
    }
  }

  // The layout holds the document without a composition in progress, which
  // is only painted over it; a press that places the caret commits it first.
  int _committedOffsetAt(Offset position) {
    controller.commitComposition();
    return _getTextOffsetFromPosition(_toContent(position));
  }

  void _onMobileDown(Offset position, int offset) {
    _press = (position: position, offset: offset);
    final handle = _draggedHandle = _handleAt(position);
    if (handle == null) {
      _isDragging = false;
      _selectionActive = false;
      _selectionTimer?.cancel();
      _selectionTimer = Timer(const Duration(milliseconds: 500), () {
        final word = _committedOffsetAt(position);
        _press = (position: position, offset: word);
        _selectionActive = true;
        _selectWordAtOffset(word);
        final selection = controller.selection;
        _pressWord = (start: selection.start, end: selection.end);
        unawaited(hapticLongPress());
      });
      return;
    }
    _handleGrip = _textPointOf(handle) - position;
    controller.commitComposition();
    _selectionActive = true;
    markNeedsPaint();
  }

  // The middle of the line at the text position [handle] hangs below, which
  // the finger then moves from wherever on the handle it came down.
  Offset _textPointOf(_DraggedHandle handle) {
    final rise = -_handleRadius - _lineHeight / 2;
    return switch (handle) {
      _DraggedHandle.caret => _normalHandle!.center.translate(0, rise),
      _DraggedHandle.start => _startHandleRect!.center.translate(
        _handleOverhang,
        rise,
      ),
      _DraggedHandle.end => _endHandleRect!.center.translate(
        -_handleOverhang,
        rise,
      ),
    };
  }

  // A handle at the start of a line hangs over the gutter.
  bool _isOnTouchHandle(Offset position) =>
      isMobile &&
      [
        _normalHandle,
        _startHandleRect,
        _endHandleRect,
      ].any((handle) => handle?.contains(position) ?? false);

  _DraggedHandle? _handleAt(Offset position) {
    if (controller.selection.isCollapsed) {
      return _hitsCaretHandle(position) ? _DraggedHandle.caret : null;
    }
    if (_startHandleRect?.contains(position) ?? false) {
      return _DraggedHandle.start;
    }
    if (_endHandleRect?.contains(position) ?? false) return _DraggedHandle.end;
    return null;
  }

  void _onDesktopDown(Offset position, int offset) {
    final base = HardwareKeyboard.instance.isShiftPressed
        ? controller.selection.baseOffset
        : offset;
    _press = (position: position, offset: base);
    controller.selection = TextSelection(
      baseOffset: base,
      extentOffset: offset,
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    final content = _toContent(event.localPosition);
    if (_gutterSelectionAnchor != null) {
      _extendGutterSelection(_lineAtY(content.dy));
    } else if (_press case final press?) {
      if (isMobile) {
        _onMobileMove(event.localPosition, content, press);
      } else {
        _selectFrom(press.offset, content);
      }
    }
  }

  void _onMobileMove(Offset position, Offset content, _Press press) {
    if (_draggedHandle case final handle?) {
      _dragHandle(handle, _getTextOffsetFromPosition(content + _handleGrip));
      return;
    }
    if ((position - press.position).distance > 10) {
      _isDragging = true;
      controller.suggestionsNotifier.value = null;
      _selectionTimer?.cancel();
    }
    if (!_selectionActive) return;
    final word = _pressWord;
    if (word == null) {
      _selectFrom(press.offset, content);
    } else {
      _extendWordSelection(word, _getTextOffsetFromPosition(content));
    }
    markNeedsPaint();
  }

  void _extendWordSelection(({int start, int end}) word, int offset) {
    final selection = offset < word.start
        ? TextSelection(baseOffset: word.end, extentOffset: offset)
        : offset > word.end
        ? TextSelection(baseOffset: word.start, extentOffset: offset)
        : TextSelection(baseOffset: word.start, extentOffset: word.end);
    if (selection == controller.selection) return;
    controller.selection = selection;
    unawaited(hapticHandleMove());
  }

  void _selectFrom(int base, Offset content) {
    controller.selection = TextSelection(
      baseOffset: base,
      extentOffset: _getTextOffsetFromPosition(content),
    );
  }

  void _dragHandle(_DraggedHandle handle, int offset) {
    final selection = controller.selection;
    if (offset != selection.extentOffset) unawaited(hapticHandleMove());
    switch (handle) {
      case _DraggedHandle.caret:
        controller.selection = TextSelection.collapsed(offset: offset);
        _showBubble = true;
      case _DraggedHandle.start:
        controller.selection = TextSelection(
          baseOffset: selection.end,
          extentOffset: offset,
        );
        if (offset > selection.end) _draggedHandle = _DraggedHandle.end;
      case _DraggedHandle.end:
        controller.selection = TextSelection(
          baseOffset: selection.start,
          extentOffset: offset,
        );
        if (offset < selection.start) _draggedHandle = _DraggedHandle.start;
    }
    markNeedsLayout();
    markNeedsPaint();
  }

  void _onPointerUp(PointerEvent event) {
    _gutterSelectionAnchor = null;
    if (_foldTapped) {
      _foldTapped = false;
      return;
    }
    final position = event.localPosition;
    if (isMobile &&
        event is PointerUpEvent &&
        _selectionActive &&
        !controller.selection.isCollapsed) {
      _openContextMenu(position);
      return;
    }
    final wasDragging = _isDragging;
    if (isMobile && !wasDragging && !_selectionActive) {
      controller.selection = TextSelection.collapsed(
        offset: _committedOffsetAt(position),
      );
      if (!readOnly && (controller.connection?.attached ?? false)) {
        controller.connection!.show();
      }
    }
    _endGesture();
    markNeedsPaint();
    if (readOnly) return;
    if (!wasDragging) controller.notifyListeners();
    if (isMobile && controller.selection.isCollapsed) _showBubble = true;
  }

  void _openContextMenu(Offset position) {
    _endGesture();
    onContextMenuRequest(position);
    markNeedsPaint();
  }

  bool get _afterMultiTouch =>
      _multiTouch ||
      DateTime.now().millisecondsSinceEpoch - _multiTouchEndedAt <
          kDoubleTapTimeout.inMilliseconds;

  void _endGesture() {
    _press = null;
    _pressWord = null;
    _draggedHandle = null;
    _isDragging = false;
    _selectionActive = false;
    _selectionTimer?.cancel();
  }
}
