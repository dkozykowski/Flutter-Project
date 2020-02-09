import 'dart:io';

import 'package:image/image.dart';


int main() {
  Image img = decodeImage(File('img.jpg').readAsBytesSync());
  print(img.height);
  print(img.width);
  return 0;
}