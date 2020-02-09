import 'dart:collection';
import 'dart:io';
import 'package:image/image.dart';
import 'dart:math';


void main() {
  Image img = decodeImage(File('img.jpg').readAsBytesSync());
  PageDetection.getPageCoordinates(img);
  return;
}

class Pair
{
  final first;
  final second;
  const Pair(this.first, this.second);
}

class RGB
{
  final r;
  final g;
  final b;
  const RGB(this.r, this.g, this.b);
}

class PageDetection
{
  static const MAX_DIFFERENCE = 10; //maximum % of color differences between pixels on paper

  //find and return corners coordinates of a page in the picture
  static List getPageCoordinates(Image picture) {
    final height = picture.height;
    final width = picture.width;
    dynamic visited = new List.generate(height, (_)=> new List(width));
    dynamic pixels = new List.generate(height, (_)=> new List(width));

    //create an array of RGB values of each pixel
    for (int i = 0; i < height; i++) {
      for (int o = 0; o < width; o++) {
        var pixNumber = picture.getPixel(i, o);
        pixels[i][o] = RGB((pixNumber >> 16) & 0xff, (pixNumber >> 8) & 0xff, pixNumber & 0xff);
        }
      }

    //return an average RGB of pixels nearby
    getAverageColor(dynamic a) {
      int sumR = 0;
      int sumG = 0;
      int sumB = 0;
      int howMany = 0;
      for (int i = min(0, a.first - 10); i < max(a.first + 10, width); i++) {
        for (int o = min (0, a.second - 10); o < max(a.second + 10, height); o++) {
          howMany++;
          sumR += pixels[i][o].r;
        }
      }
      return RGB((sumR / howMany) as int, (sumG / howMany) as int, (sumB / howMany) as int);
    }

    //returns true if colors of pixels are similar
    sameColor(dynamic a, dynamic b) {
      return ((a.r - b.r).abs() <= MAX_DIFFERENCE && (a.g - b.g).abs() <= MAX_DIFFERENCE && (a.b - b.b).abs() <= MAX_DIFFERENCE);
      }

    var sumR = 0;
    var sumG = 0;
    var sumB = 0;
    var startx = width / 2;
    var starty = height / 2;
    for (int i = (startx - width / 10) as int; i < startx + width / 10; i++) {
      for (int o = (starty - height / 10) as int; o < starty + height / 10; i++) {
        sumR+=pixels[i][o].R;
        sumG+=pixels[i][o].G;
        sumB+=pixels[i][o].B;
      }
    }
    RGB paperColor = RGB((sumR / (width / 5 + height / 5)) as int, (sumG / (width / 5 + height / 5)) as int, (sumB / (width / 5 + height / 5)) as int);

    Queue queue = new Queue();
    for (int i = (startx - width / 10) as int; i < startx + width / 10; i++) {
      for (int o = (starty - height / 10) as int; o < starty + height / 10; i++) {
        if (sameColor(paperColor, getAverageColor(Pair(i, o)))) {
          visited[i][o] = true;
          queue.add(Pair(i, o));
        }
      }
    }

    while(!queue.isEmpty){

    }

    print(height);
    print(width);
    return null;
  }
}