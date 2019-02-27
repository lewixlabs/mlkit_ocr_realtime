import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'ocr_engine.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  cameras = await availableCameras();
  runApp(OcrApp());
}

class OcrApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter OCR",
      home: Scaffold(
        appBar: AppBar(
          title: Text("Flutter OCR"),
        ),
        body: CameraPage(),
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraPage> {
  CameraController controller;
  bool _isScanBusy = false;
  Timer _timer;
  String _textDetected = "no text detected...";

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return Column(children: [
      Expanded(child: _cameraPreviewWidget()),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
          Text(_textDetected, style: TextStyle(fontStyle: FontStyle.italic,fontSize: 34),)
        ]),
      Container(
        height: 100,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
          MaterialButton(
              child: Text("Start Scanning"),
              textColor: Colors.white,
              color: Colors.blue,
              onPressed: () async {
                _timer = Timer.periodic(Duration(seconds: 3), (currentTimer) async {
                  await controller.startImageStream((CameraImage availableImage) async {
                    if (_isScanBusy) {
                      print("1.5 -------- isScanBusy, skipping...");
                      return;
                    }

                    print("1 -------- isScanBusy = true");
                    _isScanBusy = true;

                    OcrManager.scanText(availableImage).then((textVision) {
                      setState(() {
                        _textDetected = textVision ?? "";
                      });

                      _isScanBusy = false;
                    }).catchError((error) {
                      _isScanBusy = false;
                    });
                  });
                });
              }),
          MaterialButton(
              child: Text("Stop Scanning"),
              textColor: Colors.white,
              color: Colors.red,
              onPressed: () async {
                _timer?.cancel();
                await controller.stopImageStream();
              })
        ]),
      ),
    ]);
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }
}
