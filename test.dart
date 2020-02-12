import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'lib/interfaces/Coordinate.dart';
import 'lib/core/PageTransform.dart';



int main() {
  Image img = decodeImage(File('hard2.jpg').readAsBytesSync());

  List cords = new List(4);
  cords[0] = new Coordinate(418,243);
  cords[1] = new Coordinate(946,322);
  cords[2] = new Coordinate(15,870);
  cords[3] = new Coordinate(712,1100);

  PageTransform transform = PageTransform(cords, img);
  transform.transformPage();

  return 0;
}