

import 'package:flutter_app/interfaces/Coordinate.dart';
import 'package:flutter_app/interfaces/Pixel.dart';
import 'package:image/image.dart';

import 'dart:math';
import 'dart:io';

class PageTransform {
  Image _image;
  List _cords;

  List<List<Pixel>> _getPixelArray() {
    List<List<Pixel>> pixels = new List.generate(
        _image.height, (_) => new List<Pixel>(_image.width));
    int row = 0;

    for (int i = 0; i < _image.data.length; i++) {
      if (i % _image.width == 0 && i != 0) row++;
      pixels[row][i % _image.width] = Pixel(_image.data[i] & 0x000000FF,
          (_image.data[i] & (0x000000FF << 8)) >> 8,
          (_image.data[i] & (0x000000FF << 16)) >> 16,
          (_image.data[i] & (0x000000FF << 24)) >> 24);
    }
    return pixels;
  }

  PageTransform(this._cords, this._image);

  void transformPage() {
    this._image = grayscale(this._image);
    List<List<Pixel>> pixels = _getPixelArray();
    Image target = _saveArrayAsImage(_trapezeCorrection(_centering(_verticalProjection(_rotate(pixels)))));
    target = convolution(target, [0, -0.2, 0, -0.2, 2, -0.2, 0, -0.2, 0]);
    File('thumbnail.png')..writeAsBytesSync(encodeJpg(target));
    print(_calculatePageCenter().x);
    print(_calculatePageCenter().y);
  }

  Image _saveArrayAsImage(List<List<Pixel>> array) {
    Image img = Image.rgb(array[0].length, array.length);
    for(int i=0; i< array.length; i++) {
      for(int j=0; j < array[i].length; j++) {
        Pixel pix = array[i][j];
        img.setPixel(j, i, pix.r + (256*pix.g) + (256*256*pix.b) + (256*256*256*pix.a));
      }
    }
    return img;
  }

  _fillAllPixelsBlack(List<List<Pixel>> array) {
    for(int i=0; i< array.length; i++) {
      for(int j=0; j < array[i].length; j++) {
        array[i][j] = new Pixel();
      }
    }
    return array;
  }

  List<List<double>> _matrixMultipy(List<List<double>> a, List<List<double>> b) {
    List<List<double>> fixedMatrix = new List.generate(
        a.length, (_) => new List<double>(b[0].length));

    for(int i=0; i<fixedMatrix.length; i++) {
      for(int j=0; j<fixedMatrix[0].length; j++) {
        double sum = 0;
        for(int k=0; k<a[0].length; k++) {
          sum += a[i][k] * b[k][j];
        }
        fixedMatrix[i][j] = sum;
      }
    }
    return fixedMatrix;
  }

  List<List<Pixel>> _differentialFiltering(List<List<Pixel>> pixels) {
    const filteringThreshold = 100;

    for(int i=0; i < pixels.length; i++) {
      for(int j=0; j < pixels[0].length; j++) {
        Pixel pix = pixels[i][j];
        int sum = pix.r + pix.b + pix.g;
        double multiplier = 1.2;

        if(sum < filteringThreshold * 3) {
          pix.r = max(0,(pix.r / multiplier).round());
          pix.g = max(0,(pix.g / multiplier).round());
          pix.b = max(0,(pix.b / multiplier).round());
        } else {
          pix.r = min(255,(pix.r * multiplier).round());
          pix.g = min(255,(pix.g * multiplier).round());
          pix.b = min(255,(pix.b * multiplier).round());
        }
        pixels[i][j] = pix;
      }
    }
    return pixels;
  }

  Coordinate _calculatePageCenter() {
    double a_1 = (_cords[3].y - _cords[0].y) / (_cords[3].x - _cords[0].x);
    double b_1 = _cords[3].y - (_cords[3].x * a_1);

    double a_2 = (_cords[2].y - _cords[1].y) / (_cords[2].x - _cords[1].x);
    double b_2 = _cords[2].y - (_cords[2].x * a_1);

    int x_center = ((b_2 - b_1) / (a_1 - a_2)).round();

    return Coordinate(x_center, ((x_center * a_1) + b_1).round());
  }

  void _rotatePageEdges(double angle, Coordinate center) {
    var rotatioMatrix = [
      [cos(angle), sin(angle)],
      [sin(-angle), cos(angle)]
    ];
    for(int i=0; i < 4; i++) {
      double relativeY = (_cords[i].y - center.y).toDouble();
      double relativeX = (_cords[i].x - center.x).toDouble();

      List<List<double>> result = _matrixMultipy(rotatioMatrix, [[relativeX], [relativeY]]);

      int fixedY = result[1][0].round() + center.y;
      int fixedX = result[0][0].round() + center.x;

      _cords[i]=new Coordinate(fixedX, fixedY);
    }
  }

  List<List<Pixel>> _rotate(List<List<Pixel>> pixels) {
    double angle = atan((_cords[1].y - _cords[0].y)/(_cords[1].x - _cords[0].x));
    if(angle.abs() > pi / 30) {
      var rotatioMatrix = [
        [cos(angle), -sin(angle)],
        [sin(angle), cos(angle)]
      ];

      List<List<Pixel>> fixedMatrix = new List<List<Pixel>>.generate(
          pixels.length, (_) => new List<Pixel>(pixels[0].length));

      fixedMatrix = _fillAllPixelsBlack(fixedMatrix);

      Coordinate center = new Coordinate(_cords[0].x, _cords[0].y);

      for(int i=0; i < fixedMatrix.length; i++) {
        for(int j=0; j< fixedMatrix[0].length; j++) {
            double relativeY = (i - center.y).toDouble();
            double relativeX = (j - center.x).toDouble();

            List<List<double>> result = _matrixMultipy(rotatioMatrix, [[relativeX], [relativeY]]);

            int fixedY = result[1][0].round() + center.y;
            int fixedX = result[0][0].round() + center.x;

            if(fixedX >= 0 && fixedX < pixels[0].length && fixedY >= 0 && fixedY < pixels.length) {
              fixedMatrix[i][j] = pixels[fixedY][fixedX];
            }
        }
      }
      _rotatePageEdges(angle, center);
      fixedMatrix[_cords[0].y][_cords[0].x] = new Pixel(255,0,0);
      fixedMatrix[_cords[1].y][_cords[1].x] = new Pixel(255,0,0);
      fixedMatrix[_cords[2].y][_cords[2].x] = new Pixel(255,0,0);
      fixedMatrix[_cords[3].y][_cords[3].x] = new Pixel(255,0,0);
      return fixedMatrix;
    }
    return pixels;
  }

  List<List<Pixel>> _centering(List<List<Pixel>> pixels) {
    int topCenter = ((this._cords[0].x + this._cords[1].x) / 2).round();
    int bottomCenter = ((this._cords[2].x + this._cords[3].x) / 2).round();

    if((topCenter - bottomCenter).abs() > 20) {
      List<List<Pixel>> fixedMatrix = new List.generate(
          pixels.length, (_) => new List<Pixel>(pixels[0].length));

      fixedMatrix = _fillAllPixelsBlack(fixedMatrix);
      double rightCoef = ((_cords[3].x - _cords[1].x) / (_cords[3].y - _cords[1].y));
      double leftCoef = ((_cords[2].x - _cords[0].x) / (_cords[2].y - _cords[0].y));

      double rightB = (_cords[3].x - (rightCoef * _cords[3].y));
      double leftB = (_cords[2].x - (leftCoef * _cords[2].y));

      int globalCenter = ((topCenter + bottomCenter) / 2 ).round();

      for (int i = 0; i < pixels.length; i++) {
        int rightFixed = min((rightB + (rightCoef * i)).round(), pixels.length - 1);
        int leftFixed = max(0, (leftB + (leftCoef * i)).round());

        int center = ((rightFixed + leftFixed) / 2 ).round();

        int translation = center - globalCenter;

        for(int j=0; j < fixedMatrix[0].length; j++) {
          int desiredPixel = j + translation;
          desiredPixel = min(desiredPixel, fixedMatrix[0].length - 1);
          desiredPixel = max(0, desiredPixel);
          fixedMatrix[i][j] = pixels[i][desiredPixel];
        }
      }

      int centerDist = ((topCenter - bottomCenter)/2).round().abs();

      if(topCenter > bottomCenter) {
        _cords[0].x -= centerDist;
        _cords[1].x -= centerDist;
        _cords[2].x += centerDist;
        _cords[3].x += centerDist;
      } else {
        _cords[0].x += centerDist;
        _cords[1].x += centerDist;
        _cords[2].x -= centerDist;
        _cords[3].x -= centerDist;
      }

      return fixedMatrix;
    } else {
     return pixels;
    }
  }

  List<List<Pixel>> _verticalProjection(List<List<Pixel>> pixels) {
    if((this._cords[2].y - this._cords[3].y).abs() > 20) {

      int topY = ((this._cords[0].y + this._cords[1].y) / 2).round();

      int centerY = ((this._cords[2].y + this._cords[3].y) / 2).round();
      
      int centerX = ((this._cords[2].x + this._cords[3].x) / 2).round();

      double a_coef = (this._cords[3].y - this._cords[2].y) / (this._cords[3].x - this._cords[2].x);
      double b_coef = (this._cords[2].y - (a_coef * this._cords[2].x));

      List<List<Pixel>> fixedMatrix = new List.generate(
          pixels.length, (_) => new List<Pixel>(pixels[0].length));
      
      fixedMatrix = _fillAllPixelsBlack(fixedMatrix);
      
      for(int i=0; i < pixels[0].length; i++) {
        int bottomY = ((a_coef * i) + b_coef).round();

        double projectionConstant = (centerY - topY) / (bottomY - topY);

        for(int j=topY; j < pixels.length; j++) {

          int fixedY = topY + ((j - topY) / projectionConstant).round();
          fixedY = min(pixels.length - 1, fixedY);
          fixedMatrix[j][i] = pixels[fixedY][i];
        }
      }

      this._cords[2].y = centerY;
      this._cords[3].y = centerY;

      return fixedMatrix;
    } else {
      return pixels;
    }
  }

  List<List<Pixel>> _trapezeCorrection(List<List<Pixel>> pixels) {
    int leftCenter = ((_cords[0].x + _cords[2].x) / 2).round().abs();
    int rightCenter = ((_cords[1].x + _cords[3].x) / 2).round().abs();

    int top = min(_cords[0].y, _cords[1].y);
    int bottom = max(_cords[2].y, _cords[3].y);

    double rightCoef = ((_cords[3].x - _cords[1].x) / (_cords[3].y - _cords[1].y));
    double leftCoef = ((_cords[2].x - _cords[0].x) / (_cords[2].y - _cords[0].y));

    int fixedWidth = (leftCenter - rightCenter).abs();

    List<List<Pixel>> fixedMatrix = new List.generate(
        bottom - top, (_) => new List<Pixel>(fixedWidth));

    fixedMatrix = _fillAllPixelsBlack(fixedMatrix);

    for (int i = top; i < bottom; i++) {
      int rightFixed = min(_cords[1].x + (rightCoef * (i-top)).round(), _image.width - 1);
      int leftFixed = max(0, _cords[0].x + (leftCoef * (i-top)).round());

      int center = ((rightFixed + leftFixed) / 2 ).round();
      int fixedCenter = (fixedWidth * ((center - leftFixed) / (rightFixed - leftFixed))).floor();

      if(fixedWidth % 2 == 1) fixedMatrix[i - top][((fixedWidth + 1) / 2).round()] = pixels[i][center];

      double projectionLeft;
      double projectionRight;

      if(leftFixed > leftCenter) {
        projectionLeft = (center - leftCenter) / (center - leftFixed);
      } else if(leftFixed < leftCenter) {
        projectionLeft = (center - leftFixed) / (center - leftCenter);
      } else {
        projectionLeft = 1;
      }

      if(rightFixed < rightCenter) {
        projectionRight = (rightCenter - center) / (rightFixed - center);
      } else if(rightFixed > rightCenter) {
        projectionRight = (rightFixed - center) / (rightCenter - center);
      } else {
        projectionRight = 1;
      }

      for(int j=0; j< fixedWidth; j++) {
        if(j <= fixedCenter) {
          int sourceX = center - ((center - leftCenter - j) / projectionLeft).round();
          fixedMatrix[i - top][j] = pixels[i][sourceX];
        } else if(j > fixedCenter) {
          int sourceX = center + ((j - fixedCenter) / projectionRight).round();
          fixedMatrix[i - top][j] = pixels[i][sourceX];
        }
      }
    }
    return fixedMatrix;
  }
}