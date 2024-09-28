import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image_gallery_saver_v3/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() => runApp(MaterialApp(home: CanvasPainting()));

// Main stateful widget for the canvas painting
class CanvasPainting extends StatefulWidget {
  const CanvasPainting({Key? key}) : super(key: key);

  @override
  _CanvasPaintingState createState() => _CanvasPaintingState();
}

class _CanvasPaintingState extends State<CanvasPainting> {
  // Global key to capture the widget's state for saving an image
  GlobalKey globalKey = GlobalKey();

  // Variables to manage stroke properties and color
  double opacity = 1.0;
  StrokeCap strokeType = StrokeCap.round;
  double strokeWidth = 3.0;
  Color selectedColor = Colors.black;

  // Background color and text settings
  Color backgroundColor = Colors.white; // Initialize background color
  String selectedFont = 'Arial';
  String inputText = "";
  double fontSize = 30.0; // Default font size
  ui.Image? backgroundImage;

  // Position of the draggable text
  Offset textPosition = Offset(20, 300);

  // List of points for the drawing strokes
  List<TouchPoints?> points = [];
  List<TouchPoints?> _undoStack = []; // Stack for undo actions
  bool _isTextFieldVisible = false; // Toggle text field visibility

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        // Capture drawing start
        onPanStart: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            points.add(TouchPoints(
              points: renderBox.globalToLocal(details.globalPosition),
              paint: Paint()
                ..strokeCap = strokeType
                ..isAntiAlias = true
                ..color = selectedColor.withOpacity(opacity)
                ..strokeWidth = strokeWidth,
            ));
          });
        },
        // Capture drawing updates
        onPanUpdate: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            points.add(TouchPoints(
              points: renderBox.globalToLocal(details.globalPosition),
              paint: Paint()
                ..strokeCap = strokeType
                ..isAntiAlias = true
                ..color = selectedColor.withOpacity(opacity)
                ..strokeWidth = strokeWidth,
            ));
          });
        },
        // Capture end of drawing stroke
        onPanEnd: (details) {
          setState(() {
            points.add(null); // Add null to mark the end of the stroke
          });
        },
        // Render the canvas
        child: RepaintBoundary(
          key: globalKey, // Key for saving the canvas
          child: Stack(
            children: <Widget>[
              // Custom paint widget for drawing
              CustomPaint(
                size: Size.infinite,
                painter: MyPainter(
                  pointsList: points,
                  inputText: inputText,
                  selectedFont: selectedFont,
                  fontSize: fontSize,
                  textPosition: textPosition,
                  backgroundImage: backgroundImage,
                  backgroundColor: backgroundColor, // Pass background color to painter
                ),
              ),
              // Conditionally display text input field
              if (_isTextFieldVisible)
                Positioned(
                  bottom: 80,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      // Input field for text overlay
                      Expanded(
                        child: TextField(
                          onChanged: (text) {
                            setState(() {
                              inputText = text; // Update text
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Type your text here...',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      // Button to clear the input
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          setState(() {
                            inputText = ""; // Clear input after submission
                          });
                        },
                      ),
                    ],
                  ),
                ),
              // Draggable text on the canvas
              Positioned(
                top: textPosition.dy,
                left: textPosition.dx,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      textPosition += details.delta; // Update position on drag
                    });
                  },
                  child: Text(
                    inputText,
                    style: TextStyle(
                      fontFamily: selectedFont,
                      fontSize: fontSize,
                      color: selectedColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Floating action button menu for different functionalities
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Colors.blue,
        children: [
          SpeedDialChild(
            child: Icon(Icons.brush),
            label: 'Stroke',
            onTap: _pickStroke, // Stroke width picker
          ),
          SpeedDialChild(
            child: Icon(Icons.opacity),
            label: 'Opacity',
            onTap: _opacity, // Opacity picker
          ),
          SpeedDialChild(
            child: Icon(Icons.clear),
            label: 'Erase',
            onTap: () {
              setState(() {
                _undoStack.clear(); // Clear undo stack
                points.clear(); // Clear drawing
                inputText = ""; // Clear text
              });
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.undo),
            label: 'Undo',
            onTap: () {
              // Undo last action
              if (points.isNotEmpty) {
                setState(() {
                  _undoStack.add(points.removeLast()); // Add last point to undo stack
                });
              }
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.redo),
            label: 'Redo',
            onTap: () {
              // Redo last undone action
              if (_undoStack.isNotEmpty) {
                setState(() {
                  points.add(_undoStack.removeLast()); // Re-add point from undo stack
                });
              }
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.color_lens),
            label: 'Color',
            onTap: _showColorPicker, // Color picker dialog
          ),
          SpeedDialChild(
            child: Icon(Icons.format_color_fill),
            label: 'Background Color',
            onTap: _showBackgroundColorPicker, // Background color picker
          ),
          SpeedDialChild(
            child: Icon(Icons.image),
            label: 'Import Background',
            onTap: _importBackground, // Import background image
          ),
          SpeedDialChild(
            child: Icon(Icons.text_fields),
            label: 'Font',
            onTap: _showFontPicker, // Font picker dialog
          ),
          SpeedDialChild(
            child: Icon(Icons.save),
            label: 'Save',
            onTap: _save, // Save the canvas as an image
          ),
          SpeedDialChild(
            child: Icon(Icons.text_fields),
            label: 'Toggle Text Field',
            onTap: () {
              setState(() {
                _isTextFieldVisible = !_isTextFieldVisible; // Toggle text field visibility
              });
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.format_size),
            label: 'Font Size',
            onTap: _showFontSizePicker, // Font size picker dialog
          ),
        ],
      ),
    );
  }

  // Method to import an image from the gallery as background
  Future<void> _importBackground() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final File imageFile = File(image.path);
      final Uint8List bytes = await imageFile.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      setState(() {
        backgroundImage = frameInfo.image; // Set the selected image as the background
      });
    }
  }

  // Method to save the canvas as an image in the gallery
  Future<void> _save() async {
    var status = await Permission.storage.status;

    // Request storage permission if not granted
    if (!status.isGranted) {
      var result = await Permission.storage.request();
      if (result.isDenied || result.isPermanentlyDenied) {
        return;
      }
    }

    RenderRepaintBoundary boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(); // Capture the canvas as an image
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    // Save the image to the gallery
    final saveResult = await ImageGallerySaver.saveImage(
      Uint8List.fromList(pngBytes),
      quality: 60,
      name: "canvas_image",
    );

    // Show a snackbar confirmation after saving
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image Saved to Gallery'),
      ),
    );
  }

  // Method to show color picker dialog
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Stroke Color'),
          content: SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                colorMenuItem(Colors.red),
                colorMenuItem(Colors.green),
                colorMenuItem(Colors.blue),
                colorMenuItem(Colors.black),
                colorMenuItem(Colors.orange),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to show background color picker dialog
  void _showBackgroundColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Background Color'),
          content: SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                colorMenuItem(Colors.white),
                colorMenuItem(Colors.yellow),
                colorMenuItem(Colors.grey),
                colorMenuItem(Colors.black),
                // Add more colors as needed
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to create color menu item for pickers
  Widget colorMenuItem(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (backgroundColor == color) {
            return; // Prevent setting the same color again
          }
          backgroundColor = color; // Set the selected background color
        });
        Navigator.of(context).pop();
      },
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: color,
        ),
      ),
    );
  }

  // Method to show stroke width picker dialog
  void _pickStroke() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Stroke Width'),
          content: Slider(
            value: strokeWidth,
            min: 1.0,
            max: 10.0,
            divisions: 9,
            label: strokeWidth.round().toString(),
            onChanged: (value) {
              setState(() {
                strokeWidth = value; // Update stroke width
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // Method to show opacity picker dialog
  void _opacity() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Opacity'),
          content: Slider(
            value: opacity,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: opacity.toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                opacity = value; // Update opacity
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // Method to show font picker dialog
  void _showFontPicker() {
    // Add your font picker logic here (not implemented)
  }

  // Method to show font size picker dialog
  void _showFontSizePicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Font Size'),
          content: Slider(
            value: fontSize,
            min: 10.0,
            max: 100.0,
            divisions: 90,
            label: fontSize.round().toString(),
            onChanged: (value) {
              setState(() {
                fontSize = value; // Update font size
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }
}

// Custom painter class for drawing
class MyPainter extends CustomPainter {
  final List<TouchPoints?> pointsList;
  final String inputText;
  final String selectedFont;
  final double fontSize;
  final Offset textPosition;
  final ui.Image? backgroundImage;
  final Color backgroundColor; // Added background color variable

  MyPainter({
    required this.pointsList,
    required this.inputText,
    required this.selectedFont,
    required this.fontSize,
    required this.textPosition,
    required this.backgroundImage,
    required this.backgroundColor, // Initialize background color
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();

    // Draw the background color
    paint.color = backgroundColor; // Set the paint color to background color
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint); // Fill the canvas with the background color

    // Draw the background image if present
    if (backgroundImage != null) {
      canvas.drawImage(backgroundImage!, Offset.zero, paint);
    }

    // Draw the lines between points for strokes
    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        canvas.drawLine(pointsList[i]!.points, pointsList[i + 1]!.points,
            pointsList[i]!.paint);
      } else if (pointsList[i] != null && pointsList[i + 1] == null) {
        canvas.drawPoints(
            ui.PointMode.points, [pointsList[i]!.points], pointsList[i]!.paint);
      }
    }

    // Draw the input text if not empty
    if (inputText.isNotEmpty) {
      TextSpan span = TextSpan(
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontFamily: selectedFont,
        ),
        text: inputText,
      );
      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, textPosition); // Paint the text at its position
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint
  }
}

// Class to represent touch points for drawing strokes
class TouchPoints {
  Offset points;
  Paint paint;

  TouchPoints({required this.points, required this.paint});
}
