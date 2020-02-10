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
  static const MAX_DIFFERENCE = 3; //maximum % of color differences between pixels on paper

  //find and return corners coordinates of a page in the picture
  static List getPageCoordinates(Image picture) {
    final height = picture.height;
    final width = picture.width;
    dynamic visited = new List.generate(width, (_)=> new List(height));
    dynamic pixels = new List.generate(width, (_)=> new List(height));
    Queue queue = new Queue();
    //create an array of RGB values of each pixel
    for (int i = 0; i < width; i++) {
      for (int o = 0; o < height; o++) {
        var pixNumber = picture.getPixel(i, o);
        pixels[i][o] = RGB((pixNumber >> 16) & 0xff, (pixNumber >> 8) & 0xff, pixNumber & 0xff);
      }
    }

    square(int a) {
      return a*a;
    }

    maxint(int a, int b) {
      if (a >= b) return a;
      return b;
    }

    minint(int a, int b) {
      if (a <= b) return a;
      return b;
    }

    //return an average RGB of pixels nearby
    getAverageColor(dynamic a) {
      int sumR = 0;
      int sumG = 0;
      int sumB = 0;
      int howMany = 0;
      for (int i = max(0, a.first - 5); i < min(a.first + 5, width); i++) {
        for (int o = max(0, a.second - 5); o < min(a.second + 5, height); o++) {
          howMany++;
          sumR += pixels[i][o].r;
          sumG += pixels[i][o].g;
          sumB += pixels[i][o].b;
        }
      }
      return RGB((sumR / max(1, howMany)).toInt(), (sumG / max(1, howMany)).toInt(), (sumB / max(1, howMany)).toInt());
    }

    //returns true if colors of pixels are similar
    sameColor(dynamic a, dynamic b) {
      return ((a.r - b.r).abs() <= MAX_DIFFERENCE && (a.g - b.g).abs() <= MAX_DIFFERENCE && (a.b - b.b).abs() <= MAX_DIFFERENCE);
    }

    //if object has similar color to the paper and was not visited yet, add it to queue
    addToQueue (dynamic a, dynamic b) {
      if (visited[a.first][a.second] != true && sameColor(getAverageColor(a), getAverageColor(b))) {
        visited[a.first][a.second] = true;
        queue.add(a);
      }
    }

    int sumR = 0;
    int sumG = 0;
    int sumB = 0;
    int startx = (width / 2).toInt();
    int starty = (height / 2).toInt();
    int howMany = 0;

    //find the avarage color of the paper
    for (int i = (startx - width / 20).toInt(); i < (startx + width / 20).toInt(); i++) {
      for (int o = (starty - height / 20).toInt(); o < (starty + height / 20).toInt(); o++) {
        sumR += pixels[i][o].r;
        sumG += pixels[i][o].g;
        sumB += pixels[i][o].b;
        howMany++;
      }
    }
    RGB paperColor = RGB((sumR / howMany).toInt(), (sumG / howMany).toInt(), (sumB / howMany).toInt());

    //add pixels in the centre of the photo to paper (by putting it on queue)
    for (int i = (startx - width / 20).toInt(); i < (startx + width / 20).toInt(); i++) {
      for (int o = (starty - height / 20).toInt(); o < (starty + height / 20).toInt(); o++) {
        if (sameColor(paperColor, getAverageColor(Pair(i, o)))) {
          visited[i][o] = true;
          queue.add(Pair(i, o));
        }
      }
    }

    dynamic corners = new List();
    for (int i = 0; i < 4; i++) corners.add(Pair(startx, starty));

    //Breadth First Search to find borders of the page
    while(queue.isNotEmpty) {
      dynamic a = queue.first;
      addToQueue(Pair(maxint(0, a.first - 10), a.second), a);
      addToQueue(Pair(minint(width - 1, a.first + 10), a.second), a);
      addToQueue(Pair(a.first, maxint(0, a.second - 10)), a);
      addToQueue(Pair(a.first, minint(height - 1, a.second + 10)), a);

      //find the farthest point of the paper on each quarter - those should be corners of page
      if(a.first >= startx && a.second >= starty && square(a.first - startx) + square(a.second - starty) > square(corners[0].first - startx) + square(corners[0].second - starty))
        corners[0] = a;
      if(a.first <= startx && a.second >= starty && square(a.first - startx) + square(a.second - starty) > square(corners[1].first - startx) + square(corners[1].second - starty))
        corners[1] = a;
      if(a.first <= startx && a.second <= starty && square(a.first - startx) + square(a.second - starty) > square(corners[2].first - startx) + square(corners[2].second - starty))
        corners[2] = a;
      if(a.first >= startx && a.second <= starty && square(a.first - startx) + square(a.second - starty) > square(corners[3].first - startx) + square(corners[3].second - starty))
        corners[3] = a;
      queue.removeFirst();
    }

    for (int i=0; i<4; i++)
    {
      print(corners[i].first);
      print(corners[i].second);
      print("kolejny");

    }
    return null;
  }
}