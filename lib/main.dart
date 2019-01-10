import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

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

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }

      // controller.startImageStream((CameraImage availableImage) {
      //   controller.stopImageStream();
      //   _scanText(availableImage);
      // });

      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return Column(
          children: [
            Expanded(
              child: _cameraPreviewWidget()
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,              
              children: <Widget>[
                MaterialButton(
                  child: Text("Start Scanning"),
                  textColor: Colors.white,
                  color: Colors.blue,
                  onPressed: () async {
                    await controller.startImageStream((CameraImage availableImage) {
                      //controller.stopImageStream();

                      if (!_isScanBusy)
                        _scanText(availableImage);
                    });
                  }
                ),
                MaterialButton(
                  child: Text("Stop Scanning"),
                  textColor: Colors.white,
                  color: Colors.red,
                  onPressed: () async => await controller.stopImageStream()
                )
              ]
            ) 
          ]
    );
            
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

  void _scanText(CameraImage availableImage) async {
    _isScanBusy = true;

    print("scanning!...");

    final FirebaseVisionImageMetadata metadata =
        FirebaseVisionImageMetadata(
      rawFormat: 35,
      size: const Size(1.0, 1.0),
      planeData: <FirebaseVisionImagePlaneMetadata>[
        FirebaseVisionImagePlaneMetadata(
          bytesPerRow: 1000,
          height: 480,
          width: 480,
        ),
      ],
    );

    // final FirebaseVisionImageMetadata metadata = FirebaseVisionImageMetadata(
    //   rawFormat: availableImage.format.raw,
    //   size: Size(1.0, 1.0),
    //   planeData: <FirebaseVisionImagePlaneMetadata>[
    //     FirebaseVisionImagePlaneMetadata(
    //       bytesPerRow: availableImage.planes[0].bytesPerRow,
    //       height: availableImage.planes[0].height,
    //       width: availableImage.planes[0].width,
    //     ),
    //   ],
    // );

    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromBytes(availableImage.planes[0].bytes, metadata);
    final TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
    final VisionText visionText = await textRecognizer.processImage(visionImage);

    print(visionText.text);
    for (TextBlock block in visionText.blocks) {
      // final Rectangle<int> boundingBox = block.boundingBox;
      // final List<Point<int>> cornerPoints = block.cornerPoints;
      print(block.text);
      final List<RecognizedLanguage> languages = block.recognizedLanguages;

      for (TextLine line in block.lines) {
        // Same getters as TextBlock
        print(line.text);
        for (TextElement element in line.elements) {
          // Same getters as TextBlock
          print(element.text);
        }
      }
    }

    _isScanBusy = false;
  }
}