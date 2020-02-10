import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'lib/interfaces/Coordinate.dart';
import 'lib/core/PageTransform.dart';



int main() {
  Image img = decodeImage(File('img.jpg').readAsBytesSync());

  List cords = new List(4);
  cords[0] = new Coordinate(165,155);
  cords[1] = new Coordinate(783,155);
  cords[2] = new Coordinate(0,1048);
  cords[3] = new Coordinate(968,1048);

  PageTransform transform = PageTransform(cords, img);
  transform.transformPage();

  return 0;
}