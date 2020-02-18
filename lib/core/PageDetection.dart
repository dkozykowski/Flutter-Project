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

  int square(int a) {
    return a * a;
  }

  int maxint(int a, int b) {
    if (a >= b) return a;
    return b;
  }

  int minint(int a, int b) {
    if (a <= b) return a;
    return b;
  }

  //convert android.color system to RGB values
  RGB getRGB(int a) {
    return RGB((a >> 16) & 0xff, (a >> 8) & 0xff, a & 0xff);
  }

  //set values in the range 0 - 255
  RGB fixRGB(RGB a) {
    return RGB((a.r).abs(), (a.g).abs(), (a.b).abs());
  }

  //add red green blue values separately
  RGB addRGB(RGB a, RGB b) {
    return RGB(a.r + b.r, a.g + b.g, a.b + b.b);
  }

  RGB substractRGB(RGB a, RGB b) {
    return RGB(a.r - b.r, a.g - b.g, a.b - b.b);
  }

  int avarageRGB(RGB a) {
    return (a.r + a.g + a.b);
  }

  Pair find(Pair a, List<List<Pair>> _agent) {
    if (_agent[a.first][a.second] == a) return a;
    _agent[a.first][a.second] = find(_agent[a.first][a.second], _agent);
    return _agent[a.first][a.second];
  }

  void union(Pair a, Pair b, List<List<Pair>> _agent, List<List<int>> _quantity) {
    a = find(a, _agent);
    b = find(b, _agent);
    if (a == b) return;
    if (_quantity[a.first][a.second] >= _quantity[b.first][b.second]) {
      _quantity[a.first][a.second] += _quantity[b.first][b.second];
      _agent[b.first][b.second] = a;
    }
    _quantity[b.first][b.second] += _quantity[a.first][a.second];
    _agent[a.first][a.second] = a;
  }

  //check if there is sharp difference in brightness between two points
  bool edge(Pair a, Pair b, List<List<RGB>> _laplacian, _width, _height) {
    RGB _laplacianA = RGB(0, 0, 0);
    RGB _laplacianB = RGB(0, 0, 0);
    for (int i = maxint(a.first - 1, 1); i <= minint(a.first + 1, _width - 2); i++) {
      for (int o = maxint(a.second - 1, 1); o <= minint(a.second + 1, _height - 2); o++) {
        _laplacianA = addRGB(_laplacianA, _laplacian[i][o]);
      }
    }
    for (int i = maxint(b.first - 1, 1); i <= minint(b.first + 1, _width - 2); i++) {
      for (int o = maxint(b.second - 1, 1); o <= minint(b.second + 1, _height - 2); o++) {
        _laplacianB = addRGB(_laplacianB, _laplacian[i][o]);
      }
    }
    return ((avarageRGB(_laplacianB)-avarageRGB(_laplacianA)).abs() > 220);
  }

  //find and return _corners coordinates of a page in the _picture
  List<Pair> getPageCoordinates() {
    int _height = _picture.height;
    int _width = _picture.width;
    bool _bigPicture = false;

    if (_width * _height > 10e6) {
      _bigPicture = true;
      _width = _width ~/ 3 + 1;
      _height = _height ~/ 3 + 1;
    }


    List<List<RGB>> _pixels = new List.generate(_width, (_)=> new List(_height));
    List<List<RGB>> _laplacian = new List.generate(_width, (_)=> new List(_height));
    List<List<RGB>> _filtered = new List.generate(_width, (_)=> new List(_height));
    List<List<int>> _quantity = new List.generate(_width, (_)=> new List(_height));
    List<List<Pair>> _agent = new List.generate(_width, (_)=> new List(_height));
    List<List<bool>> _visited = new List.generate(_width, (_)=> new List(_height));

    for (int i = 0; i < _width; i++) {
      for (int o = 0; o < _height; o++) {
        _pixels[i][o] = RGB(0, 0, 0);
        _filtered[i][o] = RGB(0, 0, 0);
        _laplacian[i][o] = RGB(0, 0, 0);
      }
    }

    //compress _picture: 3x3 -> 1 pixel
    if (_bigPicture == true) {
      for (int i = 0; i < (_width - 1) * 3; i++) {
        for (int o = 0; o < (_height - 1) * 3; o++) {
          _pixels[i ~/ 3][o ~/ 3] =
              addRGB(_pixels[i ~/ 3][o ~/ 3], getRGB(_picture[i + o * _picture.width]));
        }
      }

      for (int i = 0; i < _width; i++) {
        for (int o = 0; o < _height; o++) {
          _pixels[i][o] = RGB(
              _pixels[i][o].r ~/ 9, _pixels[i][o].g ~/ 9, _pixels[i][o].b ~/ 9);
        }
      }
    }
    else {
      for (int i = 0; i < _width; i++) {
        for (int o = 0; o < _height; o++) {
          _pixels[i][o] = getRGB(_picture[i + o * _width]);
        }
      }
    }

    //create an array of RGB values of each pixel and applay Gaussian filter for noice removal:
    //121
    //242
    //121
    for (int i = 1; i < _width; i++) {
      for (int o = 1; o < _height; o++) {
        if (i == 1 || i == _width - 1 || o == 1 || o == _height - 1) _filtered[i][o] = _pixels[i][o];
        else {
          _filtered[i][o] = RGB(
              _pixels[i - 1][o - 1].r + _pixels[i - 1][o].r * 2 +
                  _pixels[i - 1][o + 1].r * 2 +
                  _pixels[i][o - 1].r * 2 +
                  _pixels[i][o].r * 4 +
                  _pixels[i][o + 1].r * 2 +
                  _pixels[i + 1][o - 1].r +
                  _pixels[i + 1][o].r * 2 +
                  _pixels[i + 1][o + 1].r * 2,

              _pixels[i - 1][o - 1].g +
                  _pixels[i - 1][o].g * 2 +
                  _pixels[i - 1][o + 1].g * 2 +
                  _pixels[i][o - 1].g * 2 +
                  _pixels[i][o].g * 4 +
                  _pixels[i][o + 1].g * 2 +
                  _pixels[i + 1][o - 1].g +
                  _pixels[i + 1][o].g * 2 +
                  _pixels[i + 1][o + 1].g * 2,

              _pixels[i - 1][o - 1].b +
                  _pixels[i - 1][o].b * 2 +
                  _pixels[i - 1][o + 1].b * 2 +
                  _pixels[i][o - 1].b * 2 +
                  _pixels[i][o].b * 4 +
                  _pixels[i][o + 1].b * 2 +
                  _pixels[i + 1][o - 1].b +
                  _pixels[i + 1][o].b * 2 +
                  _pixels[i + 1][o + 1].b * 2);
          _filtered[i][o] = RGB(_filtered[i][o].r  ~/ 8, _filtered[i][o].g ~/ 8, _filtered[i][o].b ~/8);
        }
      }
    }

    //use Laplacian Algorithm to find sharp brightness changes
    for (int i = 2; i < _width - 1; i++) {
      for (int o = 2; o < _height - 1; o++) {
        _visited[i][o] = false;
        _laplacian[i][o] = RGB(
            _filtered[i][o].r * 9, _filtered[i][o].g * 9, _filtered[i][o].b * 9);
        for (int z = i - 1; z <= i + 1; z++) {
          for (int x = o - 1; x <= o + 1; x++) {
            _laplacian[i][o] = substractRGB(_laplacian[i][o], _filtered[z][x]);
          }
        }
        _laplacian[i][o] = fixRGB(_laplacian[i][o]);
      }
    }

    final _distance = 4;
    Queue _queue = new Queue();
    _queue.add(Pair(_distance, ((_height - 6) ~/ _distance) * _distance));
    _queue.add(Pair(_distance, _distance));
    _queue.add(Pair(((_width - 6) ~/ _distance) * _distance, _distance));
    _queue.add(Pair(((_width - 6) ~/ _distance) * _distance, ((_height - 6) ~/ _distance) * _distance));
    _visited[_distance][((_height - 6) ~/ _distance) * _distance] = true;
    _visited[_distance][_distance] = true;
    _visited[((_width - 6) ~/ _distance) * _distance][_distance] = true;
    _visited[((_width - 6) ~/ _distance) * _distance][((_height - 6) ~/ _distance) * _distance] = true;

    //Breadth First Search to find borders of the page
    while(_queue.isNotEmpty) {
      Pair a = _queue.first;
      _queue.removeFirst();

      if (a.first - _distance >= _distance && _visited[a.first - _distance][a.second] == false
          && edge(a, Pair(a.first - _distance, a.second), _laplacian, _width, _height) == false) {
        _queue.add(Pair(a.first - _distance, a.second));
        _visited[a.first - _distance][a.second] = true;
      }
      if (a.first + _distance <= ((_width - 6) ~/ _distance) * _distance && _visited[a.first + _distance][a.second] == false
          && edge(a, Pair(a.first + _distance, a.second), _laplacian, _width, _height) == false) {
        _queue.add(Pair(a.first + _distance, a.second));
        _visited[a.first + _distance][a.second] = true;
      }
      if (a.second - _distance >= _distance && _visited[a.first][a.second - _distance] == false
          && edge(a, Pair(a.first, a.second - _distance), _laplacian, _width, _height) == false) {
        _queue.add(Pair(a.first, a.second - _distance));
        _visited[a.first][a.second - _distance] = true;
      }
      if (a.second + _distance <= ((_height - 6) ~/ _distance) * _distance && _visited[a.first][a.second + _distance] == false
          && edge(a, Pair(a.first, a.second + _distance), _laplacian, _width, _height) == false) {
        _queue.add(Pair(a.first, a.second + _distance));
        _visited[a.first][a.second + _distance] = true;
      }
    }

    for (int i = _distance; i <= ((_width - 6) ~/ _distance) * _distance; i += _distance) {
      for (int o = _distance; o <= ((_height - 6) ~/ _distance) * _distance; o += _distance) {
        _agent[i][o] = Pair(i, o);
        _quantity[i][o] = 1;
      }
    }

    //use find & union algorithm to connect groups of _pixels with similar laplacian color
    //if there is a group of bright _pixels, but there are only few _pixels in that group
    //they are not considered a page, but a noise, we can ignore them in further considerations
    for (int i = _distance; i <= ((_width - 6) ~/ _distance) * _distance; i += _distance) {
      for (int o = _distance; o <= ((_height - 6) ~/ _distance) * _distance; o += _distance) {
        if (_visited[i][o] == false) {
          if (i - _distance >= _distance && _visited[i - _distance][o] == false)
            union(Pair(i, o), Pair(i - _distance, o), _agent, _quantity);
          if (i + _distance <= ((_width - 6) ~/ _distance) * _distance && _visited[i + _distance][o] == false)
            union(Pair(i, o), Pair(i + _distance, o), _agent, _quantity);
          if (o - _distance >= _distance && _visited[i][o - _distance] == false)
            union(Pair(i, o), Pair(i, o - _distance), _agent, _quantity);
          if (o + _distance <= ((_height - 6) ~/ _distance) * _distance && _visited[i][o + _distance] == false)
            union(Pair(i, o), Pair(i, o + _distance), _agent, _quantity);
        }
      }
    }

    int _startx = _width ~/ 2;
    int _starty = _height ~/ 2;
    List<Pair> _corners = new List();
    for (int i = 0; i < 4; i++) _corners.add(Pair(_startx, _starty));

    //find the farthest point from the center of image on each quarter
    //it is considered as a corner of the page
    for (int i = _distance; i <= ((_width - 6) ~/ _distance) * _distance; i += _distance) {
      for (int o = _distance; o <= ((_height - 6) ~/ _distance) * _distance; o += _distance) {
        if (_visited[i][o] == false && _quantity[i][o] >= 400) {
          if (i >= _startx && o >= _starty &&
              square(i - _startx) + square(o - _starty) >
                  square(_corners[0].first - _startx) +
                      square(_corners[0].second - _starty))
            _corners[0] = Pair(i, o);
          if (i <= _startx && o >= _starty &&
              square(i - _startx) + square(o - _starty) >
                  square(_corners[1].first - _startx) +
                      square(_corners[1].second - _starty))
            _corners[1] = Pair(i, o);
          if (i <= _startx && o <= _starty &&
              square(i - _startx) + square(o - _starty) >
                  square(_corners[2].first - _startx) +
                      square(_corners[2].second - _starty))
            _corners[2] = Pair(i, o);
          if (i >= _startx && o <= _starty &&
              square(i - _startx) + square(o - _starty) >
                  square(_corners[3].first - _startx) +
                      square(_corners[3].second - _starty))
            _corners[3] = Pair(i, o);
        }
      }
    }

    if (_bigPicture == true) {
      _corners[0] = Pair(3 * (_corners[0].first - 10), 3 * (_corners[0].second - 10));
      _corners[1] = Pair(3 * (_corners[1].first + 10), 3 * (_corners[1].second - 10));
      _corners[2] = Pair(3 * (_corners[2].first + 10), 3 * (_corners[2].second + 10));
      _corners[3] = Pair(3 * (_corners[3].first - 10), 3 * (_corners[3].second + 10));
    }
    else {
      _corners[0] = Pair(_corners[0].first - 10, _corners[0].second - 10);
      _corners[1] = Pair(_corners[1].first + 10, _corners[1].second - 10);
      _corners[2] = Pair(_corners[2].first + 10, _corners[2].second + 10);
      _corners[3] = Pair(_corners[3].first - 10, _corners[3].second + 10);
    }

    return _corners;
  }
}
