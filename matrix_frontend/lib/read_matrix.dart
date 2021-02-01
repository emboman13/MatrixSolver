import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import 'solve_matrix.dart';

// Takes the dimensions of the image, the positions of all the sliders, and
// the path to the image. Normalizes all slider positions based on image
// dimensions, and reorders these values so that the lower value is either the
// bottom (botY) or on the right (botX)
Future<List<List<int>>> readMatrix(double widgetWidth, double widgetHeight,
    Map<String, double> sliderPositions, String imagePath) async {
  double botX = sliderPositions['x1'] / widgetWidth;
  double topX = sliderPositions['x2'] / widgetWidth;
  double botY = sliderPositions['y1'] / widgetHeight;
  double topY = sliderPositions['y2'] / widgetHeight;

  if (botX > topX) {
    double temp1 = botX;
    botX = topX;
    topX = temp1;
  }
  if (botY > topY) {
    double temp2 = botY;
    botY = topY;
    topY = temp2;
  }

  return await sendRequest(imagePath, botX, topX, botY, topY);
}

// Sends an http POST request to the web server that contains the image file
// and the coordinates of the actual matrix.
Future<List<List<int>>> sendRequest(String imagePath, double botX, double topX,
    double botY, double topY) async {
  var request = http.MultipartRequest(
      'POST', Uri.parse('http://10.192.38.26:8000/image/raw/'));
  request.fields['bot_x'] = botX.toString();
  request.fields['top_x'] = topX.toString();
  request.fields['bot_y'] = botY.toString();
  request.fields['top_y'] = topY.toString();

  request.files.add(await http.MultipartFile.fromPath('media', imagePath));

  var response = await request.send();
  String matrixString =
      json.decode(await response.stream.bytesToString())['matrix'];

  return parseMatrix(matrixString);
}

// Web server returns a string representation of the matrix. This function takes
// that string and creates a two dimensional array of int values from ints. It
// first creates a 2-D array of strings, then converts the strings to ints.
List<List<int>> parseMatrix(String matrixString) {
  matrixString = matrixString.split("[[")[1].split("]]")[0];

  List<String> rows = matrixString.split("], [");
  List<List<String>> matrixStr =
      List.generate(3, (i) => rows[i].split(", "), growable: false);

  List<List<int>> matrixInt =
      List.generate(3, (i) => List.generate(3, (j) => 0));

  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      matrixInt[i][j] = int.parse(matrixStr[i][j]);
    }
  }
  return matrixInt;
}

class SliderNotifier extends ChangeNotifier {
  Map<String, double> sliderPositions = {
    'x1': 5.0,
    'x2': 5.0,
    'y1': 5.0,
    'y2': 5.0,
  };

  void changePosition(String sliderLabel, double newPos) {
    sliderPositions[sliderLabel] = newPos;
    notifyListeners();
  }
}

class ReadMatrix extends StatefulWidget {
  @override
  _ReadMatrixState createState() => _ReadMatrixState();
}

class _ReadMatrixState extends State<ReadMatrix> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SliderNotifier>(
      create: (context) => SliderNotifier(),
      child: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  bool isCameraReady = false;
  bool showCapturedPhoto = false;
  String imagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(firstCamera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      isCameraReady = true;
    });
  }

  void _takePhoto() async {
    try {
      imagePath = join((await getTemporaryDirectory()).path, 'image.png');
      await _controller.takePicture(imagePath);

      setState(() {
        showCapturedPhoto = true;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    double widgetWidth = MediaQuery.of(context).size.width;
    double widgetHeight = 500;

    return Consumer<SliderNotifier>(builder: (context, sliderNotifier, child) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 500,
            child: Stack(children: <Widget>[
              Container(
                  child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (showCapturedPhoto) {
                      return Container(
                        width: widgetWidth,
                        height: widgetHeight,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.fill,
                            image: Image.file(File(imagePath)).image,
                          ),
                        ),
                      );
                    } else {
                      return Container(
                          width: widgetWidth,
                          height: widgetHeight,
                          child: Center(child: CameraPreview(_controller)));
                    }
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              )),
              BorderLine(
                color: Colors.red,
                sliderName: 'x1',
              ),
              BorderLine(
                color: Colors.blue,
                sliderName: 'x2',
              ),
              BorderLine(
                color: Colors.yellow,
                sliderName: 'y1',
              ),
              BorderLine(
                color: Colors.green,
                sliderName: 'y2',
              ),
            ]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                  onPressed: () => _takePhoto(), child: Text("Take photo")),
              RaisedButton(
                  onPressed: () {
                    setState(() {
                      showCapturedPhoto = false;
                      imageCache.clear();
                    });
                  },
                  child: Text("Redo"))
            ],
          ),
          SliderWidget(
            color: Colors.red,
            accentColor: Colors.redAccent,
            maxSize: widgetWidth,
            sliderName: 'x1',
          ),
          SliderWidget(
            color: Colors.blue,
            accentColor: Colors.blueAccent,
            maxSize: widgetWidth,
            sliderName: 'x2',
          ),
          SliderWidget(
            color: Colors.yellow,
            accentColor: Colors.yellowAccent,
            maxSize: widgetHeight,
            sliderName: 'y1',
          ),
          SliderWidget(
            color: Colors.green,
            accentColor: Colors.greenAccent,
            maxSize: widgetHeight,
            sliderName: 'y2',
          ),
          RaisedButton(
              onPressed: () async {
                List<List<int>> matrix = await readMatrix(widgetWidth,
                    widgetHeight, sliderNotifier.sliderPositions, imagePath);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SolveMatrix(matrix: matrix)),
                );
              },
              child: Text("Calculate")),
        ],
      );
    });
  }
}

class BorderLine extends StatelessWidget {
  final MaterialColor color;
  final String sliderName;

  BorderLine({this.color, this.sliderName});

  @override
  Widget build(BuildContext context) {
    if (sliderName.contains('x')) {
      return Transform.translate(
        offset: Offset(
            Provider.of<SliderNotifier>(context).sliderPositions[sliderName],
            0.0),
        child: Container(
          color: color,
          width: 2,
          height: double.infinity,
        ),
      );
    } else {
      return Transform.translate(
        offset: Offset(0.0,
            Provider.of<SliderNotifier>(context).sliderPositions[sliderName]),
        child: Container(
          color: color,
          width: double.infinity,
          height: 2,
        ),
      );
    }
  }
}

class SliderWidget extends StatelessWidget {
  final MaterialColor color;
  final MaterialAccentColor accentColor;
  final double maxSize;
  final String sliderName;

  SliderWidget({this.color, this.accentColor, this.maxSize, this.sliderName});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: color[700],
        inactiveTrackColor: color[100],
        trackHeight: 4.0,
        thumbColor: accentColor,
        overlayColor: color.withAlpha(32),
      ),
      child: Slider(
        min: 0,
        max: maxSize,
        value: Provider.of<SliderNotifier>(context).sliderPositions[sliderName],
        onChanged: (value) {
          Provider.of<SliderNotifier>(context, listen: false)
              .changePosition(sliderName, value);
        },
      ),
    );
  }
}
