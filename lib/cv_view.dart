// Handles OpenCV analysis of an image.
// Used as the image result widget (?)

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class CvImageView extends StatefulWidget {
  final Uint8List image;

  const CvImageView({Key? swKey, required this.image}) : super(key: swKey);
  
  @override
  CvImageViewState createState() {
    // Detect objects and draw bounding boxes
    final cvImage = cv.imdecode(image, cv.IMREAD_COLOR);
    final imgSubtractor = cv.createBackgroundSubtractorMOG2(detectShadows: false);
    
    // - Find contours in the image
    final subMaskImage = imgSubtractor.apply(cvImage);

    // Image of contours sans threshold
    // final contoursImage = cv.drawContours(cvImage, contours, -1, cv.Scalar.fromRgb(0, 255, 0));
    // Get threshold
    //     _thresholdValue
    final (_, maskThreshold) = cv.threshold(subMaskImage , 180, 255, cv.THRESH_BINARY);

    // Apply erosion
    final kernel = cv.getStructuringElement(cv.MORPH_ELLIPSE, (1, 3));
    final subMaskImageEroded = cv.morphologyEx(maskThreshold, cv.MORPH_OPEN, kernel);
    
    // Get contours now
    //               _hierarchy
    final (contours, _) = cv.findContours(subMaskImageEroded, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);

    // Filter contour areas.
    const minContourArea = 500; // TODO : Probably have to determine this from the image size.
    // mfw the openCv allocation is needlessly boilerplate and i have to do this because the lib maintainer didn't do a VecVecPoint.fromList that has the List<VecPoint> argument type
    final largeContours = cv.VecVecPoint.fromList(contours.where((contElement) => cv.contourArea(contElement) > minContourArea).map((contElement) => contElement.toList()).toList());

    // Draw bounding boxes
    cv.Mat output = cvImage.clone();
    for (final count in largeContours) {
      final r = cv.boundingRect(count);

      output = cv.rectangle(output, r, cv.Scalar.fromRgb(255, 0, 0));
    }

    return CvImageViewState(cvProcessImage: cv.imencode(".png", cvImage));
  }
}

class CvImageViewState extends State<CvImageView> {
  Uint8List cvProcessImage;

  CvImageViewState({required this.cvProcessImage});

  @override
  Widget build(BuildContext context) {
    return Image.memory(cvProcessImage);
  }
}
