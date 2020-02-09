import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'lib/interfaces/Coordinate.dart';

class Pixel
{
  int r;
  int g;
  int b;
  int a;

  Pixel([_r=0,_g=0,_b=0,_a=0]) {
    r=_r;
    g=_g;
    b=_b;
    a=_a;
  }

  String toString() {
    return "${r}:${g}:${b}";
  }
}

int main() {
  Image img = decodeImage(File('img.jpg').readAsBytesSync());

  int row = 0;
  dynamic pixels = new List.generate(img.height, (_)=> new List(img.width));

  List cords = new List(4);
  cords[0] = new Coordinate(165,155);
  cords[1] = new Coordinate(783,155);
  cords[2] = new Coordinate(0,1048);
  cords[3] = new Coordinate(968,1048);


  for(int i=0; i<img.data.length; i++) {
    pixels[row][i % img.width] = Pixel(img.data[i] & 0x000000FF, (img.data[i] & (0x000000FF << 2)) >> 2, (img.data[i] & (0x000000FF << 4)) >> 4, (img.data[i] & (0x000000FF << 6)) >> 6);
    if(i % img.width == 0 && i != 0) row++;
  }

  int leftCenter = ((cords[0].x - cords[2].x) / 2).round().abs();
  int rightCenter = ((cords[1].x - cords[3].x) / 2).round().abs();

  for(int i=0;i<img.height; i++) {

  }

  return 0;
}