import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

// import 'package:image/image.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: CameraScreen()),
      // home: MatrixView(),
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

  double _xVal_1 = 5.0;
  double _xVal_2 = 5.0;
  double _yVal_1 = 5.0;
  double _yVal_2 = 5.0;

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

  Future<void> _sendMatrix(double widgetWidth, double widgetHeight) async {
    double botX;
    double topX;
    double botY;
    double topY;

    if (_xVal_1 < _xVal_2) {
      botX = _xVal_1 / widgetWidth;
      topX = _xVal_2 / widgetWidth;
    } else {
      botX = _xVal_2 / widgetWidth;
      topX = _xVal_1 / widgetWidth;
    }
    if (_yVal_1 < _yVal_2) {
      botY = _yVal_1 / widgetHeight;
      topY = _yVal_2 / widgetHeight;
    } else {
      botY = _yVal_2 / widgetHeight;
      topY = _yVal_1 / widgetHeight;
    }

    var request = http.MultipartRequest(
        'POST', Uri.parse('http://10.192.38.26:8000/image/raw/'));
    request.fields['bot_x'] = botX.toString();
    request.fields['top_x'] = topX.toString();
    request.fields['bot_y'] = botY.toString();
    request.fields['top_y'] = topY.toString();

    request.files.add(await http.MultipartFile.fromPath('media', imagePath));
    print(request.files);
    var response = await request.send();
    // print(json.decode(response.body));
  }

  @override
  Widget build(BuildContext context) {
    double widgetWidth = MediaQuery.of(context).size.width;
    double widgetHeight = 500;

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
                    // return Expanded(child: Image.file(File(imagePath)));
                  } else {
                    return Expanded(
                        child: Center(child: CameraPreview(_controller)));
                  }
                } else {//
                  return Center(
                      child:
                          CircularProgressIndicator()); // Otherwise, display a loading indicator.
                }
              },
            )),
            Transform.translate(
              offset: Offset(_xVal_1, 0.0),
              child: Container(
                color: Colors.red,
                width: 2,
                height: double.infinity,
              ),
            ),
            Transform.translate(
              offset: Offset(_xVal_2, 0.0),
              child: Container(
                color: Colors.blue,
                width: 2,
                height: double.infinity,
              ),
            ),
            Transform.translate(
              offset: Offset(0.0, _yVal_1),
              child: Container(
                color: Colors.green,
                width: double.infinity,
                height: 2,
              ),
            ),
            Transform.translate(
              offset: Offset(0.0, _yVal_2),
              child: Container(
                color: Colors.yellow,
                width: double.infinity,
                height: 2,
              ),
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
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.red[700],
            inactiveTrackColor: Colors.red[100],
            trackHeight: 4.0,
            thumbColor: Colors.redAccent,
            overlayColor: Colors.red.withAlpha(32),
          ),
          child: Slider(
            min: 0,
            max: widgetWidth,
            value: _xVal_1,
            onChanged: (value) {
              setState(() {
                _xVal_1 = value;
              });
            },
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blue[700],
            inactiveTrackColor: Colors.blue[100],
            trackHeight: 4.0,
            thumbColor: Colors.blueAccent,
            overlayColor: Colors.blue.withAlpha(32),
          ),
          child: Slider(
            min: 0,
            max: widgetWidth,
            value: _xVal_2,
            onChanged: (value) {
              setState(() {
                _xVal_2 = value;
              });
            },
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.green[700],
            inactiveTrackColor: Colors.green[100],
            trackHeight: 4.0,
            thumbColor: Colors.greenAccent,
            overlayColor: Colors.green.withAlpha(32),
          ),
          child: Slider(
            min: 0,
            max: widgetHeight,
            value: _yVal_1,
            onChanged: (value) {
              setState(() {
                _yVal_1 = value;
              });
            },
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.yellow[700],
            inactiveTrackColor: Colors.yellow[100],
            trackHeight: 4.0,
            thumbColor: Colors.yellow,
            overlayColor: Colors.yellow.withAlpha(32),
          ),
          child: Slider(
            min: 0,
            max: widgetHeight,
            value: _yVal_2,
            onChanged: (value) {
              setState(() {
                _yVal_2 = value;
              });
            },
          ),
        ),
        FlatButton(
            onPressed: () => _sendMatrix(widgetWidth, widgetHeight),
            child: Text("Calculate")),
      ],
    );
  }
}
// class MatrixView extends StatefulWidget {
//   @override
//   _MatrixViewState createState() => _MatrixViewState();
// }

// class _MatrixViewState extends State<MatrixView> {
//   Future<void> sendImage(File image) async {
//     var request = http.MultipartRequest(
//         'POST', Uri.parse('http://0.0.0.0:8000/image/raw/'));

//     request.files.add(await http.MultipartFile(
//       'picture',
//       image.readAsBytes().asStream(),
//       image.lengthSync(),
//     ));

//     var response = await request.send();
//   }

//   var someList = List.generate(3, (i) => List.generate(3, (j) => i + j));

//   double _xVal_1 = 5.0;
//   double _xVal_2 = 5.0;
//   double _yVal_1 = 5.0;
//   double _yVal_2 = 5.0;

//   @override
//   Widget build(BuildContext context) {
//     var rawImage = new Image.asset('assets/IMG_0022.HEIC');
//     var newImage =
//         ResizeImage(rawImage.image, width: 400, height: 500).imageProvider;

//     return Scaffold(
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: double.infinity,
//           ),
//           Container(
//               width: 400,
//           ,    height: 500
//               child: Stack(
//                 children: <Widget>[
//                   Container(
//                     width: MediaQuery.of(context).size.width,
//                     height: MediaQuery.of(context).size.height,
//                     decoration: BoxDecoration(
//                       image: DecorationImage(
//                         fit: BoxFit.fill,
//                         image: newImage,
//                       ),
//                     ),
//                   ),
//                   Transform.translate(
//                     offset: Offset(_xVal_1, 0.0),
//                     child: Container(
//                       color: Colors.red,
//                       width: 2,
//                       height: double.infinity,
//                     ),
//                   ),
//                   Transform.translate(
//                     offset: Offset(_xVal_2, 0.0),
//                     child: Container(
//                       color: Colors.blue,
//                       width: 2,
//                       height: double.infinity,
//                     ),
//                   ),
//                   Transform.translate(
//                     offset: Offset(0.0, _yVal_1),
//                     child: Container(
//                       color: Colors.green,
//                       width: double.infinity,
//                       height: 2,
//                     ),
//                   ),
//                   Transform.translate(
//                     offset: Offset(0.0, _yVal_2),
//                     child: Container(
//                       color: Colors.yellow,
//                       width: double.maxFinite,
//                       height: 2,
//                     ),
//                   ),
//                 ],
//               )),
//           SliderTheme(
//             data: SliderTheme.of(context).copyWith(
//               activeTrackColor: Colors.red[700],
//               inactiveTrackColor: Colors.red[100],
//               trackHeight: 4.0,
//               thumbColor: Colors.redAccent,
//               overlayColor: Colors.red.withAlpha(32),
//             ),
//             child: Slider(
//               min: 0,
//               max: 400,
//               value: _xVal_1,
//               onChanged: (value) {
//                 setState(() {
//                   _xVal_1 = value;
//                 });
//               },
//             ),
//           ),
//           SliderTheme(
//             data: SliderTheme.of(context).copyWith(
//               activeTrackColor: Colors.blue[700],
//               inactiveTrackColor: Colors.blue[100],
//               trackHeight: 4.0,
//               thumbColor: Colors.blueAccent,
//               overlayColor: Colors.blue.withAlpha(32),
//             ),
//             child: Slider(
//               min: 0,
//               max: 400,
//               value: _xVal_2,
//               onChanged: (value) {
//                 setState(() {
//                   _xVal_2 = value;
//                 });
//               },
//             ),
//           ),
//           SliderTheme(
//             data: SliderTheme.of(context).copyWith(
//               activeTrackColor: Colors.green[700],
//               inactiveTrackColor: Colors.green[100],
//               trackHeight: 4.0,
//               thumbColor: Colors.greenAccent,
//               overlayColor: Colors.green.withAlpha(32),
//             ),
//             child: Slider(
//               min: 0,
//               max: 500,
//               value: _yVal_1,
//               onChanged: (value) {
//                 setState(() {
//                   _yVal_1 = value;
//                 });
//               },
//             ),
//           ),
//           SliderTheme(
//             data: SliderTheme.of(context).copyWith(
//               activeTrackColor: Colors.yellow[700],
//               inactiveTrackColor: Colors.yellow[100],
//               trackHeight: 4.0,
//               thumbColor: Colors.yellow,
//               overlayColor: Colors.yellow.withAlpha(32),
//             ),
//             child: Slider(
//               min: 0,
//               max: 500,
//               value: _yVal_2,
//               onChanged: (value) {
//                 setState(() {
//                   _yVal_2 = value;
//                 });
//               },
//             ),
//           ),
//           RaisedButton(onPressed: () => sendImage(imageFile), child: null),
//         ],
//       ),
//     );
//   }

//   List<Widget> _createMatrixRow(List<List<int>> list) {
//     return new List<Widget>.generate(list.length, (int index) {
//       return Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: _createMatrixColumn(list[index]));
//     });
//   }

//   List<Widget> _createMatrixColumn(List<int> list) {
//     return new List<Widget>.generate(list.length, (int index) {
//       return TextButton(
//           onPressed: null,
//           child: Text(
//             list[index].toString(),
//             style: TextStyle(color: Colors.black87, fontSize: 32),
//           ));
//     });
//   }
// }
