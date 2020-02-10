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

  transformPage() {
    List<List<Pixel>> pixels = _getPixelArray();
    Image target = _saveArrayAsImage(_secondStage(pixels));
    File('thumbnail.png')..writeAsBytesSync(encodeJpg(target));
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

  List<List<Pixel>> _secondStage(List<List<Pixel>> pixels) {
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