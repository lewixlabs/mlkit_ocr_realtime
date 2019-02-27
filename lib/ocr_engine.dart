import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class OcrManager {

  static Future<String> scanText(CameraImage availableImage) async {

    print("scanning!...");

    /*
     * https://firebase.google.com/docs/ml-kit/android/recognize-text
     * .setWidth(480)   // 480x360 is typically sufficient for
     * .setHeight(360)  // image recognition
     */

    final FirebaseVisionImageMetadata metadata = FirebaseVisionImageMetadata(
        rawFormat: availableImage.format.raw,
        size: Size(availableImage.width.toDouble(),availableImage.height.toDouble()),
        planeData: availableImage.planes.map((currentPlane) => FirebaseVisionImagePlaneMetadata(
            bytesPerRow: currentPlane.bytesPerRow,
            height: currentPlane.height,
            width: currentPlane.width
        )).toList(),
        rotation: ImageRotation.rotation90
    );

    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromBytes(availableImage.planes[0].bytes, metadata);
    final TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
    final VisionText visionText = await textRecognizer.processImage(visionImage);

    print("--------------------visionText:${visionText.text}");
    for (TextBlock block in visionText.blocks) {
      // final Rectangle<int> boundingBox = block.boundingBox;
      // final List<Point<int>> cornerPoints = block.cornerPoints;
      print(block.text);
      //final List<RecognizedLanguage> languages = block.recognizedLanguages;

      for (TextLine line in block.lines) {
        // Same getters as TextBlock
        print(line.text);
        for (TextElement element in line.elements) {
          // Same getters as TextBlock
          print(element.text);
        }
      }
    }

    return visionText?.text;
  }

  /*
    * code by
    * https://github.com/bparrishMines/mlkit_demo/blob/master/lib/main.dart
    */

  Uint8List concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    planes.forEach((Plane plane) => allBytes.putUint8List(plane.bytes));
    return allBytes.done().buffer.asUint8List();
  }

  FirebaseVisionImageMetadata buildMetaData(CameraImage image) {
    return FirebaseVisionImageMetadata(
      rawFormat: image.format.raw,
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: ImageRotation.rotation90,
      planeData: image.planes.map((Plane plane) {
        return FirebaseVisionImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      }).toList(),
    );
  }
}