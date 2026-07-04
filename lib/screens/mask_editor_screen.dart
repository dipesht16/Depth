import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DrawingStroke {
  final List<Offset> points;
  final double brushSize;
  final bool isErase;

  DrawingStroke({
    required this.points,
    required this.brushSize,
    required this.isErase,
  });
}

class MaskEditorScreen extends StatefulWidget {
  final String originalImagePath;
  final String? initialMaskPath;

  const MaskEditorScreen({
    super.key,
    required this.originalImagePath,
    this.initialMaskPath,
  });

  @override
  State<MaskEditorScreen> createState() => _MaskEditorScreenState();
}

class _MaskEditorScreenState extends State<MaskEditorScreen> {
  ui.Image? _originalImage;
  ui.Image? _initialMask;
  bool _isImagesLoaded = false;
  bool _isLoading = false;

  final List<DrawingStroke> _strokes = [];
  final List<DrawingStroke> _redoStrokes = []; // REDO stack
  bool _isEraseMode = false;
  double _brushSize = 25.0;

  // Active stroke
  List<Offset> _activePoints = [];

  // Track touch position for rendering the brush size cursor indicator
  Offset? _touchPosition;

  // Zoom/Pan State
  final TransformationController _transformationController = TransformationController();
  bool _isPanMode = false;
  bool _isZoomedIn = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _transformationController.addListener(_onZoomChanged);
  }

  @override
  void dispose() {
    _originalImage?.dispose();
    _initialMask?.dispose();
    _transformationController.removeListener(_onZoomChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onZoomChanged() {
    final double scale = _transformationController.value.getMaxScaleOnAxis();
    final bool zoomed = scale > 1.001;
    if (zoomed != _isZoomedIn) {
      setState(() {
        _isZoomedIn = zoomed;
      });
    }
  }

  void _resetZoom() {
    HapticFeedback.lightImpact();
    setState(() {
      _transformationController.value = Matrix4.identity();
      _isZoomedIn = false;
    });
  }

  Future<void> _loadImages() async {
    try {
      final originalBytes = await File(widget.originalImagePath).readAsBytes();
      final originalCodec = await ui.instantiateImageCodec(originalBytes);
      final originalFrame = await originalCodec.getNextFrame();

      ui.Image? maskImage;
      if (widget.initialMaskPath != null) {
        final maskFile = File(widget.initialMaskPath!);
        if (maskFile.existsSync()) {
          final maskBytes = await maskFile.readAsBytes();
          final maskCodec = await ui.instantiateImageCodec(maskBytes);
          final maskFrame = await maskCodec.getNextFrame();
          maskImage = maskFrame.image;
        }
      }

      if (mounted) {
        setState(() {
          _originalImage = originalFrame.image;
          _initialMask = maskImage;
          _isImagesLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Composite canvas drawing and png cutout generation
  Future<Uint8List> _generateCutout(double viewWidth, double viewHeight) async {
    final original = _originalImage!;
    final originalWidth = original.width.toDouble();
    final originalHeight = original.height.toDouble();

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    final double scaleX = originalWidth / viewWidth;
    final double scaleY = originalHeight / viewHeight;

    // 1. Draw composite mask layer
    canvas.saveLayer(Rect.fromLTWH(0, 0, originalWidth, originalHeight), Paint());

    // Draw initial mask if loaded
    if (_initialMask != null) {
      canvas.drawImageRect(
        _initialMask!,
        Rect.fromLTWH(0, 0, _initialMask!.width.toDouble(), _initialMask!.height.toDouble()),
        Rect.fromLTWH(0, 0, originalWidth, originalHeight),
        Paint(),
      );
    }

    // Draw user paint/erase strokes scaled up
    for (final stroke in _strokes) {
      final Paint strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.brushSize * scaleX;

      if (stroke.isErase) {
        strokePaint.blendMode = BlendMode.clear;
      } else {
        strokePaint.color = Colors.white; // opaque pixels for mask
      }

      final Path path = Path();
      if (stroke.points.isNotEmpty) {
        path.moveTo(stroke.points.first.dx * scaleX, stroke.points.first.dy * scaleY);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx * scaleX, stroke.points[i].dy * scaleY);
        }
        canvas.drawPath(path, strokePaint);
      }
    }

    // 2. Draw background image over composite mask using srcIn BlendMode
    final Paint compositePaint = Paint()..blendMode = BlendMode.srcIn;
    canvas.drawImageRect(
      original,
      Rect.fromLTWH(0, 0, originalWidth, originalHeight),
      Rect.fromLTWH(0, 0, originalWidth, originalHeight),
      compositePaint,
    );

    canvas.restore(); // restore saveLayer

    final ui.Picture picture = recorder.endRecording();
    final ui.Image cutoutImage = await picture.toImage(
      originalWidth.toInt(),
      originalHeight.toInt(),
    );

    final ByteData? pngBytes = await cutoutImage.toByteData(format: ui.ImageByteFormat.png);
    cutoutImage.dispose();
    return pngBytes!.buffer.asUint8List();
  }

  void _saveCutout(double viewWidth, double viewHeight) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cutoutBytes = await _generateCutout(viewWidth, viewHeight);
      if (mounted) {
        Navigator.of(context).pop(cutoutBytes);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate cutout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _redoStrokes.add(_strokes.removeLast());
      });
    }
  }

  void _redo() {
    if (_redoStrokes.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _strokes.add(_redoStrokes.removeLast());
      });
    }
  }

  void _resetStrokes() {
    if (_strokes.isNotEmpty || _redoStrokes.isNotEmpty) {
      HapticFeedback.mediumImpact();
      setState(() {
        _strokes.clear();
        _redoStrokes.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isImagesLoaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
        ),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    // Reserve space for top appbar and bottom controls
    final double maxCanvasWidth = screenWidth - 32;
    final double maxCanvasHeight = screenHeight - kToolbarHeight - 200;

    final double imgWidth = _originalImage!.width.toDouble();
    final double imgHeight = _originalImage!.height.toDouble();
    final double imgAspect = imgWidth / imgHeight;

    // Compute fitting layout canvas size preserving original aspect ratio
    double canvasWidth = maxCanvasWidth;
    double canvasHeight = maxCanvasWidth / imgAspect;

    if (canvasHeight > maxCanvasHeight) {
      canvasHeight = maxCanvasHeight;
      canvasWidth = maxCanvasHeight * imgAspect;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (_strokes.isNotEmpty) {
              // Ask to discard changes
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF121212),
                  title: const Text('Discard Changes?', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'You have unsaved refinement strokes. Discard them?',
                    style: TextStyle(color: Color(0xFFB0B0B0)),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFFB0B0B0))),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: const Text('Discard', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).pop(); // dialog
                        Navigator.of(context).pop(); // screen
                      },
                    ),
                  ],
                ),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Refine Object Mask',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.undo_rounded, color: _strokes.isNotEmpty ? Colors.white : Colors.white24),
            tooltip: 'Undo',
            onPressed: _strokes.isNotEmpty ? _undo : null,
          ),
          IconButton(
            icon: Icon(Icons.redo_rounded, color: _redoStrokes.isNotEmpty ? Colors.white : Colors.white24),
            tooltip: 'Redo',
            onPressed: _redoStrokes.isNotEmpty ? _redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Reset Strokes',
            onPressed: _resetStrokes,
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Color(0xFFFFD700)),
            tooltip: 'Apply Refinements',
            onPressed: _isLoading ? null : () => _saveCutout(canvasWidth, canvasHeight),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 16),
              // Interactive Canvas Container
              Expanded(
                child: Center(
                  child: Container(
                    width: canvasWidth,
                    height: canvasHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          InteractiveViewer(
                            transformationController: _transformationController,
                            panEnabled: _isPanMode,
                            scaleEnabled: _isPanMode,
                            minScale: 1.0,
                            maxScale: 6.0,
                            child: Stack(
                              children: [
                                // Base Original Image
                                Image.file(
                                  File(widget.originalImagePath),
                                  width: canvasWidth,
                                  height: canvasHeight,
                                  fit: BoxFit.fill,
                                ),
                                // Mask Painter Layer
                                GestureDetector(
                                  onPanStart: _isPanMode ? null : (details) {
                                    _redoStrokes.clear();
                                    setState(() {
                                      _activePoints = [details.localPosition];
                                      _touchPosition = details.localPosition;
                                    });
                                  },
                                  onPanUpdate: _isPanMode ? null : (details) {
                                    setState(() {
                                      _activePoints.add(details.localPosition);
                                      _touchPosition = details.localPosition;
                                    });
                                  },
                                  onPanEnd: _isPanMode ? null : (details) {
                                    if (_activePoints.isNotEmpty) {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _strokes.add(DrawingStroke(
                                          points: List.from(_activePoints),
                                          brushSize: _brushSize,
                                          isErase: _isEraseMode,
                                        ));
                                        _activePoints.clear();
                                        _touchPosition = null;
                                      });
                                    }
                                  },
                                  child: CustomPaint(
                                    size: Size(canvasWidth, canvasHeight),
                                    painter: MaskPainter(
                                      initialMask: _initialMask,
                                      strokes: _strokes,
                                      activePoints: _activePoints,
                                      brushSize: _brushSize,
                                      isEraseMode: _isEraseMode,
                                      touchPosition: _touchPosition,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Floating Reset Zoom Button (Overlay)
                          if (_isZoomedIn)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: _resetZoom,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_out_map_rounded, size: 14, color: Color(0xFFFFD700)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Reset Zoom',
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom Controls Section
              Container(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 32, top: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F0F0F),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brush Size Control Row
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 12, color: Colors.white54),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFFFFD700),
                              inactiveTrackColor: const Color(0xFF2C2C2C),
                              thumbColor: const Color(0xFFFFD700),
                              overlayColor: const Color(0xFFFFD700).withValues(alpha: 0.12),
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: _brushSize,
                              min: 5.0,
                              max: 60.0,
                              onChanged: (val) {
                                setState(() {
                                  _brushSize = val;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_brushSize.toInt()} px',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Brush Mode Selectors (Paint vs Erase vs Zoom)
                    Row(
                      children: [
                        // Brush Button
                        Expanded(
                          child: _buildModeButton(
                            icon: Icons.brush_rounded,
                            label: 'Brush',
                            isActive: !_isEraseMode && !_isPanMode,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _isEraseMode = false;
                                _isPanMode = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Eraser Button
                        Expanded(
                          child: _buildModeButton(
                            icon: Icons.cleaning_services_rounded,
                            label: 'Eraser',
                            isActive: _isEraseMode && !_isPanMode,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _isEraseMode = true;
                                _isPanMode = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Zoom/Pan Button
                        Expanded(
                          child: _buildModeButton(
                            icon: Icons.pan_tool_rounded,
                            label: 'Zoom/Pan',
                            isActive: _isPanMode,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _isPanMode = true;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Generating refined cutout...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2C2C1A) : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? const Color(0xFFFFD700) : const Color(0xFF2C2C2C),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFFFD700) : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFFFFD700) : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MaskPainter extends CustomPainter {
  final ui.Image? initialMask;
  final List<DrawingStroke> strokes;
  final List<Offset> activePoints;
  final double brushSize;
  final bool isEraseMode;
  final Offset? touchPosition;

  MaskPainter({
    this.initialMask,
    required this.strokes,
    required this.activePoints,
    required this.brushSize,
    required this.isEraseMode,
    this.touchPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Setup transparent layer to do clear blend modes for eraser
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Draw initial mask if loaded
    if (initialMask != null) {
      canvas.drawImageRect(
        initialMask!,
        Rect.fromLTWH(0, 0, initialMask!.width.toDouble(), initialMask!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
    }

    // Draw past strokes
    for (final stroke in strokes) {
      final Paint strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.brushSize;

      if (stroke.isErase) {
        strokePaint.blendMode = BlendMode.clear;
      } else {
        strokePaint.color = Colors.white;
      }

      final Path path = Path();
      if (stroke.points.isNotEmpty) {
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, strokePaint);
      }
    }

    // Draw active stroke
    if (activePoints.isNotEmpty) {
      final Paint activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = brushSize;

      if (isEraseMode) {
        activePaint.blendMode = BlendMode.clear;
      } else {
        activePaint.color = Colors.white;
      }

      final Path path = Path();
      path.moveTo(activePoints.first.dx, activePoints.first.dy);
      for (int i = 1; i < activePoints.length; i++) {
        path.lineTo(activePoints[i].dx, activePoints[i].dy);
      }
      canvas.drawPath(path, activePaint);
    }

    // 2. Tint mask pixels to semi-transparent red overlay
    final Paint tintPaint = Paint()
      ..color = const Color(0x99FF0000) // red color with opacity
      ..blendMode = BlendMode.srcIn;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tintPaint);

    canvas.restore(); // restore layer

    // 3. Draw brush size circle indicator under touch position
    if (touchPosition != null) {
      final Paint outerCirclePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final Paint innerCirclePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      canvas.drawCircle(touchPosition!, brushSize / 2, outerCirclePaint);
      canvas.drawCircle(touchPosition!, brushSize / 2, innerCirclePaint);
    }
  }

  @override
  bool shouldRepaint(covariant MaskPainter oldDelegate) {
    return oldDelegate.initialMask != initialMask ||
        oldDelegate.strokes != strokes ||
        oldDelegate.activePoints != activePoints ||
        oldDelegate.brushSize != brushSize ||
        oldDelegate.isEraseMode != isEraseMode ||
        oldDelegate.touchPosition != touchPosition;
  }
}
