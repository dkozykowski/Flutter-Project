import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:flutter_app/interfaces/Coordinate.dart';
import 'lib/core/PageTransform.dart';
import 'lib/core/PageDetection.dart';


int main() {
  Image img = decodeImage(File('test.jpg').readAsBytesSync());

  PageDetection detector = new PageDetection(img);

  List<Pair> corners = detector.getPageCoordinates();

  List<Coordinate> cords = new List<Coordinate>.generate(4, (int i) => new Coordinate(corners[i].first, corners[i].second));

  PageTransform transform = PageTransform(cords, img);
  transform.fixCornerOrder();
  transform.transformPage();

  return 0;
}