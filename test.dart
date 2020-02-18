import 'dart:collection';
import 'dart:io';
import 'package:image/image.dart';

void main() {
  Image img = decodeImage(File('img2.jpg').readAsBytesSync());
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
  //find and return corners coordinates of a page in the picture
  static List getPageCoordinates(Image picture) {
    var height = picture.height;
    var width = picture.width;

    bool bigPicture = false;
    if (width * height > 10e6) {
      bigPicture = true;
      width = width ~/ 3 + 1;
      height = height ~/ 3 + 1;
    }

    dynamic visited = new List.generate(width, (_)=> new List(height));
    dynamic pixels = new List.generate(width, (_)=> new List(height));
    dynamic laplacian = new List.generate(width, (_)=> new List(height));
    dynamic filtered = new List.generate(width, (_)=> new List(height));
    dynamic agent = new List.generate(width, (_)=> new List(height));
    dynamic quantity = new List.generate(width, (_)=> new List(height));

    //do usuniecia
    getintcolor(dynamic a) {
      return (a.r & 0xff) << 16 | (a.g & 0xff) << 8 | (a.b & 0xff);
      //(A & 0xff) << 24 | (R & 0xff) << 16 | (G & 0xff) << 8 | (B & 0xff);
    }
    //dotad

    square(int a) {
      return a * a;
    }

    maxint(int a, int b) {
      if (a >= b) return a;
      return b;
    }

    minint(int a, int b) {
      if (a <= b) return a;
      return b;
    }

    //get RGB from android.color system
    getRGB(int a) {
      return RGB((a >> 16) & 0xff, (a >> 8) & 0xff, a & 0xff);
    }

    fixRGB(dynamic a) {
      return RGB((a.r).abs(), (a.g).abs(), (a.b).abs());
    }

    //add red green blue values separately
    addRGB(dynamic a, dynamic b) {
      return RGB(a.r + b.r, a.g + b.g, a.b + b.b);
    }

    substractRGB(dynamic a, dynamic b) {
      return RGB(a.r - b.r, a.g - b.g, a.b - b.b);
    }

    avarageRGB(dynamic a) {
      return (a.r + a.g + a.b);
    }


    //Find & Union
    find(dynamic a) {
      if (agent[a.first][a.second] == a) return a;
      agent[a.first][a.second] = find(agent[a.first][a.second]);
      return agent[a.first][a.second];
    }

    union(dynamic a, dynamic b) {
      a = find(a);
      b = find(b);
      if (a == b) return;
      if (quantity[a.first][a.second] >= quantity[b.first][b.second]) {
        quantity[a.first][a.second] += quantity[b.first][b.second];
        agent[b.first][b.second] = a;
      }
      quantity[b.first][b.second] += quantity[a.first][a.second];
      agent[a.first][a.second] = a;
    }


    for (int i = 0; i < width; i++) {
      for (int o = 0; o < height; o++) {
        pixels[i][o] = RGB(0, 0, 0);
        filtered[i][o] = RGB(0, 0, 0);
        laplacian[i][o] = RGB(0, 0, 0);
      }
    }

    //return false if too few white pixels in laplacian colors found
    //or if no change in colors of the given picture found
    //otherwise there is an edge, return true
    edge(dynamic a, dynamic b) {
      dynamic laplacianA = RGB(0, 0, 0);
      dynamic laplacianB = RGB(0, 0, 0);
      for (int i = maxint(a.first - 1, 1); i <= minint(a.first + 1, width - 2); i++) {
        for (int o = maxint(a.second - 1, 1); o <= minint(a.second + 1, height - 2); o++) {
          laplacianA = addRGB(laplacianA, laplacian[i][o]);
        }
      }
      for (int i = maxint(b.first - 1, 1); i <= minint(b.first + 1, width - 2); i++) {
        for (int o = maxint(b.second - 1, 1); o <= minint(b.second + 1, height - 2); o++) {
          laplacianB = addRGB(laplacianB, laplacian[i][o]);
        }
      }
      return ((avarageRGB(laplacianB)-avarageRGB(laplacianA)).abs() > 220);
    }

    //make smaller copy of picture by compressing 3x3 -> 1 pixel
    if (bigPicture == true) {
      for (int i = 0; i < (width - 1) * 3; i++) {
        for (int o = 0; o < (height - 1) * 3; o++) {
          pixels[i ~/ 3][o ~/ 3] =
              addRGB(pixels[i ~/ 3][o ~/ 3], getRGB(picture[i + o * picture.width]));
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
          pixels[i][o] = getRGB(picture[i + o * width]);
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

    //use Laplacian Algorithm
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
      dynamic a = queue.first;
      queue.removeFirst();

      if (a.first - distance >= distance && visited[a.first - distance][a.second] == false
            && edge(a, Pair(a.first - distance, a.second)) == false) {
        queue.add(Pair(a.first - distance, a.second));
        visited[a.first - distance][a.second] = true;
      }
      if (a.first + distance <= ((width - 6) ~/ distance) * distance && visited[a.first + distance][a.second] == false
            && edge(a, Pair(a.first + distance, a.second)) == false) {
        queue.add(Pair(a.first + distance, a.second));
        visited[a.first + distance][a.second] = true;
      }
      if (a.second - distance >= distance && visited[a.first][a.second - distance] == false
            && edge(a, Pair(a.first, a.second - distance)) == false) {
        queue.add(Pair(a.first, a.second - distance));
        visited[a.first][a.second - distance] = true;
      }
      if (a.second + distance <= ((height - 6) ~/ distance) * distance && visited[a.first][a.second + distance] == false
            && edge(a, Pair(a.first, a.second + distance)) == false) {
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

    for (int i = distance; i <= ((width - 6) ~/ distance) * distance; i += distance) {
      for (int o = distance; o <= ((height - 6) ~/ distance) * distance; o += distance) {
        if (visited[i][o] == false) {
          if (i - distance >= distance && visited[i - distance][o] == false)
            union(Pair(i, o), Pair(i - distance, o));
          if (i + distance <= ((width - 6) ~/ distance) * distance && visited[i + distance][o] == false)
            union(Pair(i, o), Pair(i + distance, o));
          if (o - distance >= distance && visited[i][o - distance] == false)
            union(Pair(i, o), Pair(i, o - distance));
          if (o + distance <= ((height - 6) ~/ distance) * distance && visited[i][o + distance] == false)
            union(Pair(i, o), Pair(i, o + distance));
        }
      }
    }

    int startx = width ~/ 2;
    int starty = height ~/ 2;
    dynamic corners = new List();
    for (int i = 0; i < 4; i++) corners.add(Pair(startx, starty));

    //find the farthest point from the center of image on each quarter
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

        //do usuniecia
    if (bigPicture == false) {
      for (int i = 3; i < width - 2; i++) {
        for (int o = 3; o < height - 2; o++)
          picture[i + o * picture.width] = getintcolor(laplacian[i][o]);
      }
    }
    else {
      for (int i = 6; i < (picture.width ~/3) * 3 - 6; i++) {
        for (int o = 6; o < (picture.height ~/3) * 3 - 6; o++)
          picture[i + o * picture.width] = getintcolor(laplacian[i~/3][o~/3]);
      }
      for (int i = distance; i <= ((width - 6) ~/ distance) * distance; i += distance) {
        for (int o = distance; o <= ((height - 6) ~/ distance) * distance; o += distance) {
          if (visited[i][o] == true ||
              (visited[i][o] == false &&
                  quantity[find(Pair(i,o)).first][find(Pair(i, o)).second] < 400)) {
            picture[3 * i - 1 + 3 * o * picture.width] =
                getintcolor(RGB(0, 0, 255));
            picture[3 * i + 3 * o * picture.width] = getintcolor(RGB(0, 0, 255));
            picture[3 * i + 1 + 3 * o * picture.width] =
                getintcolor(RGB(0, 0, 255));
            picture[3 * i - 1 + 3 * o * picture.width - picture.width] =
                getintcolor(RGB(0, 0, 255));
            picture[3 * i +  3 * o * picture.width - picture.width] =
                getintcolor(RGB(0, 0, 255));
            picture[3 * i + 1 + 3 * o * picture.width - picture.width] =
                getintcolor(RGB(0, 0, 255));
            picture[3 * i - 1 + 3 * o * picture.width + picture.width] =
                getintcolor(RGB(0, 0, 255));
            picture[3 * i + 3 * o * picture.width + picture.width] =
                getintcolor(RGB(0, 0, 255));
            picture[3 * i + 1 + 3 * o * picture.width + picture.width] =
                getintcolor(RGB(0, 0, 255));
          }
        }
      }
    }
    //dotad
    corners[0] = Pair(corners[0].first - 10, corners[0].second - 10);
    corners[1] = Pair(corners[1].first + 10, corners[1].second - 10);
    corners[2] = Pair(corners[2].first + 10, corners[2].second + 10);
    corners[3] = Pair(corners[3].first - 10, corners[3].second + 10);

    for (int i=0; i<4; i++)
    {
      print(corners[i].first);
      print(corners[i].second);
      print("kolejny");
      for (int j=corners[i].first-5; j<=corners[i].first+5; j++) {
        for (int z=corners[i].second-5; z<=corners[i].second+5; z++) {
          picture[3*j + 3*z*picture.width] = getintcolor(RGB(0, 255, 0));
        }
      }
    }

    //do usuniecia
    File('img_done.png').writeAsBytesSync(encodePng(picture));
    exit(0);
    //dotad

    return corners;
  }
}
