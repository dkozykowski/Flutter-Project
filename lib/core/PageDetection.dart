import 'dart:collection';
import 'package:image/image.dart';

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
  Image _picture;
  PageDetection(this._picture);

  int square(int _a) {
    return _a * _a;
  }

  int maxint(int _a, int _b) {
    if (_a >= _b) return _a;
    return _b;
  }

  int minint(int _a, int _b) {
    if (_a <= _b) return _a;
    return _b;
  }

  //convert android.color system to RGB values
  RGB getRGB(int _a) {
    return RGB((_a >> 16) & 0xff, (_a >> 8) & 0xff, _a & 0xff);
  }

  //set values in the range 0 - 255
  RGB fixRGB(RGB _a) {
    return RGB((_a.r).abs(), (_a.g).abs(), (_a.b).abs());
  }

  //add red green blue values separately
  RGB addRGB(RGB _a, RGB _b) {
    return RGB(_a.r + _b.r, _a.g + _b.g, _a.b + _b.b);
  }

  RGB substractRGB(RGB _a, RGB _b) {
    return RGB(_a.r - _b.r, _a.g - _b.g, _a.b - _b.b);
  }

  int avarageRGB(RGB _a) {
    return (_a.r + _a.g + _a.b);
  }

  Pair find(Pair _a, List<List<Pair>> _agent) {
    if (_agent[_a.first][_a.second] == _a) return _a;
    _agent[_a.first][_a.second] = find(_agent[_a.first][_a.second], _agent);
    return _agent[_a.first][_a.second];
  }

  void union(Pair _a, Pair _b, List<List<Pair>> _agent, List<List<int>> _quantity) {
    _a = find(_a, _agent);
    _b = find(_b, _agent);
    if (_a == _b) return;
    if (_quantity[_a.first][_a.second] >= _quantity[_b.first][_b.second]) {
      _quantity[_a.first][_a.second] += _quantity[_b.first][_b.second];
      _agent[_b.first][_b.second] = _a;
    }
    _quantity[_b.first][_b.second] += _quantity[_a.first][_a.second];
    _agent[_a.first][_a.second] = _a;
  }

  //check if there is sharp difference in brightness between two points
  bool edge(Pair _a, Pair _b, List<List<RGB>> _laplacian, _width, _height) {
    RGB _laplacianA = RGB(0, 0, 0);
    RGB _laplacianB = RGB(0, 0, 0);
    for (int i = maxint(_a.first - 1, 1); i <= minint(_a.first + 1, _width - 2); i++) {
      for (int o = maxint(_a.second - 1, 1); o <= minint(_a.second + 1, _height - 2); o++) {
        _laplacianA = addRGB(_laplacianA, _laplacian[i][o]);
      }
    }
    for (int i = maxint(_b.first - 1, 1); i <= minint(_b.first + 1, _width - 2); i++) {
      for (int o = maxint(_b.second - 1, 1); o <= minint(_b.second + 1, _height - 2); o++) {
        _laplacianB = addRGB(_laplacianB, _laplacian[i][o]);
      }
    }
    return ((avarageRGB(_laplacianB)-avarageRGB(_laplacianA)).abs() > 220);
  }

  //find and return _corners coordinates of a page in the _picture
  List<Pair> getPageCoordinates() {
    int height = _picture.height;
    int width = _picture.width;
    bool bigPicture = false;

    if (width * height > 10e6) {
      bigPicture = true;
      width = width ~/ 3 + 1;
      height = height ~/ 3 + 1;
    }


    List<List<RGB>> pixels = new List.generate(width, (_)=> new List(height));
    List<List<RGB>> laplacian = new List.generate(width, (_)=> new List(height));
    List<List<RGB>> filtered = new List.generate(width, (_)=> new List(height));
    List<List<int>> quantity = new List.generate(width, (_)=> new List(height));
    List<List<Pair>> agent = new List.generate(width, (_)=> new List(height));
    List<List<bool>> visited = new List.generate(width, (_)=> new List(height));

    for (int i = 0; i < width; i++) {
      for (int o = 0; o < height; o++) {
        pixels[i][o] = RGB(0, 0, 0);
        filtered[i][o] = RGB(0, 0, 0);
        laplacian[i][o] = RGB(0, 0, 0);
      }
    }

    //compress picture: 3x3 -> 1 pixel
    if (bigPicture == true) {
      for (int i = 0; i < (width - 1) * 3; i++) {
        for (int o = 0; o < (height - 1) * 3; o++) {
          pixels[i ~/ 3][o ~/ 3] =
              addRGB(pixels[i ~/ 3][o ~/ 3], getRGB(_picture[i + o * _picture.width]));
        }
      }

      for (int i = 0; i < width; i++) {
        for (int o = 0; o < height; o++) {
          pixels[i][o] = RGB(
              pixels[i][o].r ~/ 9, pixels[i][o].g ~/ 9, pixels[i][o].b ~/ 9);
        }
      }
    }
    else {
      for (int i = 0; i < width; i++) {
        for (int o = 0; o < height; o++) {
          pixels[i][o] = getRGB(_picture[i + o * width]);
        }
      }
    }

    //create an array of RGB values of each pixel and applay Gaussian filter for noice removal:
    //121
    //242
    //121
    for (int i = 1; i < width; i++) {
      for (int o = 1; o < height; o++) {
        if (i == 1 || i == width - 1 || o == 1 || o == height - 1) filtered[i][o] = pixels[i][o];
        else {
          filtered[i][o] = RGB(
              pixels[i - 1][o - 1].r + pixels[i - 1][o].r * 2 +
                  pixels[i - 1][o + 1].r * 2 +
                  pixels[i][o - 1].r * 2 +
                  pixels[i][o].r * 4 +
                  pixels[i][o + 1].r * 2 +
                  pixels[i + 1][o - 1].r +
                  pixels[i + 1][o].r * 2 +
                  pixels[i + 1][o + 1].r * 2,

              pixels[i - 1][o - 1].g +
                  pixels[i - 1][o].g * 2 +
                  pixels[i - 1][o + 1].g * 2 +
                  pixels[i][o - 1].g * 2 +
                  pixels[i][o].g * 4 +
                  pixels[i][o + 1].g * 2 +
                  pixels[i + 1][o - 1].g +
                  pixels[i + 1][o].g * 2 +
                  pixels[i + 1][o + 1].g * 2,

              pixels[i - 1][o - 1].b +
                  pixels[i - 1][o].b * 2 +
                  pixels[i - 1][o + 1].b * 2 +
                  pixels[i][o - 1].b * 2 +
                  pixels[i][o].b * 4 +
                  pixels[i][o + 1].b * 2 +
                  pixels[i + 1][o - 1].b +
                  pixels[i + 1][o].b * 2 +
                  pixels[i + 1][o + 1].b * 2);
          filtered[i][o] = RGB(filtered[i][o].r  ~/ 8, filtered[i][o].g ~/ 8, filtered[i][o].b ~/8);
        }
      }
    }

    //use Laplacian Algorithm to find sharp brightness changes
    for (int i = 2; i < width - 1; i++) {
      for (int o = 2; o < height - 1; o++) {
        visited[i][o] = false;
        laplacian[i][o] = RGB(
            filtered[i][o].r * 9, filtered[i][o].g * 9, filtered[i][o].b * 9);
        for (int z = i - 1; z <= i + 1; z++) {
          for (int x = o - 1; x <= o + 1; x++) {
            laplacian[i][o] = substractRGB(laplacian[i][o], filtered[z][x]);
          }
        }
        laplacian[i][o] = fixRGB(laplacian[i][o]);
      }
    }

    final distance = 4;
    Queue queue = new Queue();
    queue.add(Pair(distance, ((height - 6) ~/ distance) * distance));
    queue.add(Pair(distance, distance));
    queue.add(Pair(((width - 6) ~/ distance) * distance, distance));
    queue.add(Pair(((width - 6) ~/ distance) * distance, ((height - 6) ~/ distance) * distance));
    visited[distance][((height - 6) ~/ distance) * distance] = true;
    visited[distance][distance] = true;
    visited[((width - 6) ~/ distance) * distance][distance] = true;
    visited[((width - 6) ~/ distance) * distance][((height - 6) ~/ distance) * distance] = true;

    //Breadth First Search to find borders of the page
    while(queue.isNotEmpty) {
      Pair a = queue.first;
      queue.removeFirst();

      if (a.first - distance >= distance && visited[a.first - distance][a.second] == false
          && edge(a, Pair(a.first - distance, a.second), laplacian, width, height) == false) {
        queue.add(Pair(a.first - distance, a.second));
        visited[a.first - distance][a.second] = true;
      }
      if (a.first + distance <= ((width - 6) ~/ distance) * distance && visited[a.first + distance][a.second] == false
          && edge(a, Pair(a.first + distance, a.second), laplacian, width, height) == false) {
        queue.add(Pair(a.first + distance, a.second));
        visited[a.first + distance][a.second] = true;
      }
      if (a.second - distance >= distance && visited[a.first][a.second - distance] == false
          && edge(a, Pair(a.first, a.second - distance), laplacian, width, height) == false) {
        queue.add(Pair(a.first, a.second - distance));
        visited[a.first][a.second - distance] = true;
      }
      if (a.second + distance <= ((height - 6) ~/ distance) * distance && visited[a.first][a.second + distance] == false
          && edge(a, Pair(a.first, a.second + distance), laplacian, width, height) == false) {
        queue.add(Pair(a.first, a.second + distance));
        visited[a.first][a.second + distance] = true;
      }
    }

    for (int i = distance; i <= ((width - 6) ~/ distance) * distance; i += distance) {
      for (int o = distance; o <= ((height - 6) ~/ distance) * distance; o += distance) {
        agent[i][o] = Pair(i, o);
        quantity[i][o] = 1;
      }
    }

    //use find & union algorithm to connect groups of pixels with similar laplacian color
    //if there is a group of bright pixels, but there are only few pixels in that group
    //they are not considered a page, but a noise, we can ignore them in further considerations
    for (int i = distance; i <= ((width - 6) ~/ distance) * distance; i += distance) {
      for (int o = distance; o <= ((height - 6) ~/ distance) * distance; o += distance) {
        if (visited[i][o] == false) {
          if (i - distance >= distance && visited[i - distance][o] == false)
            union(Pair(i, o), Pair(i - distance, o), agent, quantity);
          if (i + distance <= ((width - 6) ~/ distance) * distance && visited[i + distance][o] == false)
            union(Pair(i, o), Pair(i + distance, o), agent, quantity);
          if (o - distance >= distance && visited[i][o - distance] == false)
            union(Pair(i, o), Pair(i, o - distance), agent, quantity);
          if (o + distance <= ((height - 6) ~/ distance) * distance && visited[i][o + distance] == false)
            union(Pair(i, o), Pair(i, o + distance), agent, quantity);
        }
      }
    }

    int startx = width ~/ 2;
    int starty = height ~/ 2;
    List<Pair> corners = new List();
    for (int i = 0; i < 4; i++) corners.add(Pair(startx, starty));

    //find the farthest point from the center of image on each quarter
    //it is considered as a corner of the page
    for (int i = distance; i <= ((width - 6) ~/ distance) * distance; i += distance) {
      for (int o = distance; o <= ((height - 6) ~/ distance) * distance; o += distance) {
        if (visited[i][o] == false && quantity[i][o] >= 400) {
          if (i >= startx && o >= starty &&
              square(i - startx) + square(o - starty) >
                  square(corners[0].first - startx) +
                      square(corners[0].second - starty))
            corners[0] = Pair(i, o);
          if (i <= startx && o >= starty &&
              square(i - startx) + square(o - starty) >
                  square(corners[1].first - startx) +
                      square(corners[1].second - starty))
            corners[1] = Pair(i, o);
          if (i <= startx && o <= starty &&
              square(i - startx) + square(o - starty) >
                  square(corners[2].first - startx) +
                      square(corners[2].second - starty))
            corners[2] = Pair(i, o);
          if (i >= startx && o <= starty &&
              square(i - startx) + square(o - starty) >
                  square(corners[3].first - startx) +
                      square(corners[3].second - starty))
            corners[3] = Pair(i, o);
        }
      }
    }

    if (bigPicture == true) {
      corners[0] = Pair(3 * (corners[0].first - 10), 3 * (corners[0].second - 10));
      corners[1] = Pair(3 * (corners[1].first + 10), 3 * (corners[1].second - 10));
      corners[2] = Pair(3 * (corners[2].first + 10), 3 * (corners[2].second + 10));
      corners[3] = Pair(3 * (corners[3].first - 10), 3 * (corners[3].second + 10));
    }
    else {
      corners[0] = Pair(corners[0].first - 10, corners[0].second - 10);
      corners[1] = Pair(corners[1].first + 10, corners[1].second - 10);
      corners[2] = Pair(corners[2].first + 10, corners[2].second + 10);
      corners[3] = Pair(corners[3].first - 10, corners[3].second + 10);
    }

    return corners;
  }
}
