import 'dart:collection';
import 'dart:io';
import 'package:image/image.dart';

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
    final T1 = 90;
    final T2 = 40;
    dynamic visited = new List.generate(width, (_)=> new List(height));
    dynamic pixels = new List.generate(width, (_)=> new List(height));
    dynamic laplacian = new List.generate(width, (_)=> new List(height));
    dynamic done = new List.generate(width, (_)=> new List(height));
    dynamic filtered = new List.generate(width, (_)=> new List(height));
    dynamic boss = new List.generate(width, (_)=> new List(height));
    dynamic quantity = new List.generate(width, (_)=> new List(height));


    Queue queue = new Queue();
    Queue type1 = new Queue();
    Queue type2 = new Queue();
    Queue type3 = new Queue();
    Queue type4 = new Queue();
    Queue type5 = new Queue();

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

    find(dynamic a) {
      int x = a.first;
      int y = a.second;
      if (boss[x][y] == a) return a;
      boss[x][y] = find(boss[x][y]);
      return boss[x][y];
    }

    union(dynamic a, dynamic b) {
      a = find(a);
      b = find(b);
      if (a == b) return;
      if (quantity[a.first][a.second] >= quantity[b.first][b.second]) {
        quantity[a.first][a.second] += quantity[b.first][b.second];
        boss[b.first][b.second] = a;
      }
      quantity[b.first][b.second] += quantity[a.first][a.second];
      boss[a.first][a.second] = a;
    }

    for (int i = 0; i < width; i++) {
      for (int o = 0; o < height; o++) {
        pixels[i][o] = RGB(0, 0, 0);
        filtered[i][o] = RGB(0, 0, 0);
        laplacian[i][o] = RGB(0, 0, 0);
      }
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

    int maxRGB = 0;
    //use Laplacian Algorithm to find edges
    for (int i = 2; i < width - 1; i++) {
      for (int o = 2; o < height - 1; o++) {
        visited[i][o] = 0;
        boss[i][o] = Pair(i, o);
        quantity[i][o] = 1;
        laplacian[i][o] = RGB(
            filtered[i][o].r * 9, filtered[i][o].g * 9, filtered[i][o].b * 9);
        for (int z = i - 1; z <= i + 1; z++) {
          for (int x = o - 1; x <= o + 1; x++) {
            laplacian[i][o] = substractRGB(laplacian[i][o], filtered[z][x]);
          }
        }
        laplacian[i][o] = fixRGB(laplacian[i][o]);
        maxRGB = maxint(maxRGB, avarageRGB(laplacian[i][o]));
      }
    }

    //apply hard and low pixels to find real and fake edges
    for (int i = 2; i < width - 1; i++) {
      for (int o = 2; o < height - 1; o++) {
        if (avarageRGB(laplacian[i][o]) >= T2) {
          type5.add(Pair(i, o));
          visited[i][o] = 1;
        }
        else
          done[i][o] = RGB(0, 0, 0);
      }
    }


    //Breadth-First Search on pixels to remove lonely 'edges'
    //type 5 for strong pixels (over 120 avarage RGB)
    //type under 5 - for weaker pixels (under 120 but
    //over T1 avarage RGB), number shows how many tiles away is
    //the nearest strong pixel
    while(type5.isNotEmpty) {
      int i = type5.first.first;
      int o = type5.first.second;
      type5.removeFirst();
      if (i - 1 >= 2) {
        if (visited[i - 1][0] == 1) union(Pair(i, o), Pair (i - 1, o));
        else if (visited[i - 1][o] == 0 && avarageRGB(laplacian[i - 1][o]) > T1) {
          type4.add(Pair(i - 1, o));
          visited[i - 1][o] = 1;
          union(Pair(i - 1, o), Pair(i, o));
        }
      }
      if (i + 1 < width - 1) {
        if (visited[i + 1][o] == 1) union(Pair(i + 1, o), Pair(i, o));
        if (visited[i + 1][o] == 0 && avarageRGB(laplacian[i + 1][o]) > T1) {
          type4.add(Pair(i + 1, o));
          visited[i + 1][o] = 1;
          union(Pair(i + 1, o), Pair(i, o));
        }
      }
      if (o - 1 >= 2) {
        if (visited[i][o - 1] == 1) union(Pair(i, o - 1), Pair(i, o));
        if (visited[i][o - 1] == 0 && avarageRGB(laplacian[i][o - 1]) > T1) {
          type4.add(Pair(i, o - 1));
          visited[i][o - 1] = 1;
          union(Pair(i, o - 1), Pair(i, o));
        }
      }
      if (o + 1 < height - 1) {
        if (visited[i][o + 1] == 1) union(Pair(i, o + 1), Pair(i, o));
        if (visited[i][o + 1] == 0 && avarageRGB(laplacian[i][o + 1]) > T1) {
          type4.add(Pair(i, o + 1));
          visited[i][o + 1] = 1;
          union(Pair(i, o + 1), Pair(i, o));
        }
      }
      done[i][o] = RGB(255, 255, 255);
    }
    while(type4.isNotEmpty) {
      int i = type4.first.first;
      int o = type4.first.second;
      type4.removeFirst();
      if (i - 1 >= 2) {
        if (visited[i - 1][0] == 1) union(Pair(i, o), Pair (i - 1, o));
        else if (visited[i - 1][o] == 0 && avarageRGB(laplacian[i - 1][o]) > T1) {
          type4.add(Pair(i - 1, o));
          visited[i - 1][o] = 1;
          union(Pair(i - 1, o), Pair(i, o));
        }
      }
      if (i + 1 < width - 1) {
        if (visited[i + 1][o] == 1) union(Pair(i + 1, o), Pair(i, o));
        if (visited[i + 1][o] == 0 && avarageRGB(laplacian[i + 1][o]) > T1) {
          type4.add(Pair(i + 1, o));
          visited[i + 1][o] = 1;
          union(Pair(i + 1, o), Pair(i, o));
        }
      }
      if (o - 1 >= 2) {
        if (visited[i][o - 1] == 1) union(Pair(i, o - 1), Pair(i, o));
        if (visited[i][o - 1] == 0 && avarageRGB(laplacian[i][o - 1]) > T1) {
          type4.add(Pair(i, o - 1));
          visited[i][o - 1] = 1;
          union(Pair(i, o - 1), Pair(i, o));
        }
      }
      if (o + 1 < height - 1) {
        if (visited[i][o + 1] == 1) union(Pair(i, o + 1), Pair(i, o));
        if (visited[i][o + 1] == 0 && avarageRGB(laplacian[i][o + 1]) > T1) {
          type4.add(Pair(i, o + 1));
          visited[i][o + 1] = 1;
          union(Pair(i, o + 1), Pair(i, o));
        }
      }
      done[i][o] = RGB(255, 255, 255);
    }
    while(type3.isNotEmpty) {
      int i = type3.first.first;
      int o = type3.first.second;
      type3.removeFirst();
      if (i - 1 >= 2) {
        if (visited[i - 1][0] == 1) union(Pair(i, o), Pair (i - 1, o));
        else if (visited[i - 1][o] == 0 && avarageRGB(laplacian[i - 1][o]) > T1) {
          type3.add(Pair(i - 1, o));
          visited[i - 1][o] = 1;
          union(Pair(i - 1, o), Pair(i, o));
        }
      }
      if (i + 1 < width - 1) {
        if (visited[i + 1][o] == 1) union(Pair(i + 1, o), Pair(i, o));
        if (visited[i + 1][o] == 0 && avarageRGB(laplacian[i + 1][o]) > T1) {
          type3.add(Pair(i + 1, o));
          visited[i + 1][o] = 1;
          union(Pair(i + 1, o), Pair(i, o));
        }
      }
      if (o - 1 >= 2) {
        if (visited[i][o - 1] == 1) union(Pair(i, o - 1), Pair(i, o));
        if (visited[i][o - 1] == 0 && avarageRGB(laplacian[i][o - 1]) > T1) {
          type3.add(Pair(i, o - 1));
          visited[i][o - 1] = 1;
          union(Pair(i, o - 1), Pair(i, o));
        }
      }
      if (o + 1 < height - 1) {
        if (visited[i][o + 1] == 1) union(Pair(i, o + 1), Pair(i, o));
        if (visited[i][o + 1] == 0 && avarageRGB(laplacian[i][o + 1]) > T1) {
          type3.add(Pair(i, o + 1));
          visited[i][o + 1] = 1;
          union(Pair(i, o + 1), Pair(i, o));
        }
      }
      done[i][o] = RGB(255, 255, 255);
    }
    while(type2.isNotEmpty) {
      int i = type2.first.first;
      int o = type2.first.second;
      type2.removeFirst();
      if (i - 1 >= 2) {
        if (visited[i - 1][0] == 1) union(Pair(i, o), Pair (i - 1, o));
        else if (visited[i - 1][o] == 0 && avarageRGB(laplacian[i - 1][o]) > T1) {
          type2.add(Pair(i - 1, o));
          visited[i - 1][o] = 1;
          union(Pair(i - 1, o), Pair(i, o));
        }
      }
      if (i + 1 < width - 1) {
        if (visited[i + 1][o] == 1) union(Pair(i + 1, o), Pair(i, o));
        if (visited[i + 1][o] == 0 && avarageRGB(laplacian[i + 1][o]) > T1) {
          type2.add(Pair(i + 1, o));
          visited[i + 1][o] = 1;
          union(Pair(i + 1, o), Pair(i, o));
        }
      }
      if (o - 1 >= 2) {
        if (visited[i][o - 1] == 1) union(Pair(i, o - 1), Pair(i, o));
        if (visited[i][o - 1] == 0 && avarageRGB(laplacian[i][o - 1]) > T1) {
          type2.add(Pair(i, o - 1));
          visited[i][o - 1] = 1;
          union(Pair(i, o - 1), Pair(i, o));
        }
      }
      if (o + 1 < height - 1) {
        if (visited[i][o + 1] == 1) union(Pair(i, o + 1), Pair(i, o));
        if (visited[i][o + 1] == 0 && avarageRGB(laplacian[i][o + 1]) > T1) {
          type2.add(Pair(i, o + 1));
          visited[i][o + 1] = 1;
          union(Pair(i, o + 1), Pair(i, o));
        }
      }
      done[i][o] = RGB(255, 255, 255);
    }
    while(type1.isNotEmpty) {
      int i = type1.first.first;
      int o = type1.first.second;
      type1.removeFirst();
      if (i - 1 >= 2) {
        if (visited[i - 1][0] == 1) union(Pair(i, o), Pair (i - 1, o));
        else if (visited[i - 1][o] == 0 && avarageRGB(laplacian[i - 1][o]) > T1) {
          type1.add(Pair(i - 1, o));
          visited[i - 1][o] = 1;
          union(Pair(i - 1, o), Pair(i, o));
        }
      }
      if (i + 1 < width - 1) {
        if (visited[i + 1][o] == 1) union(Pair(i + 1, o), Pair(i, o));
        if (visited[i + 1][o] == 0 && avarageRGB(laplacian[i + 1][o]) > T1) {
          type1.add(Pair(i + 1, o));
          visited[i + 1][o] = 1;
          union(Pair(i + 1, o), Pair(i, o));
        }
      }
      if (o - 1 >= 2) {
        if (visited[i][o - 1] == 1) union(Pair(i, o - 1), Pair(i, o));
        if (visited[i][o - 1] == 0 && avarageRGB(laplacian[i][o - 1]) > T1) {
          type1.add(Pair(i, o - 1));
          visited[i][o - 1] = 1;
          union(Pair(i, o - 1), Pair(i, o));
        }
      }
      if (o + 1 < height - 1) {
        if (visited[i][o + 1] == 1) union(Pair(i, o + 1), Pair(i, o));
        if (visited[i][o + 1] == 0 && avarageRGB(laplacian[i][o + 1]) > T1) {
          type1.add(Pair(i, o + 1));
          visited[i][o + 1] = 1;
          union(Pair(i, o + 1), Pair(i, o));
        }
      }
      done[i][o] = RGB(255, 255, 255);
    }

    //remove noise using find & union
    for (int i = 2; i < width - 1; i++) {
      for (int o = 2; o < height - 1; o++) {
        dynamic a = find(Pair(i, o));
        if (quantity[a.first][a.second] < (height * width ~/ 9000))
          done[i][o] = RGB(0, 0, 0);
      }
    }


    //do usuniecia
    for (int i = 3; i < width - 2; i++) {
      for (int o = 3; o < height - 2; o++) {
        picture[i + o * picture.width] = getintcolor(done[i][o]);
      }
    }

    File('img2_new.png').writeAsBytesSync(encodePng(picture));
    exit(0);
    //dotad

















    int startx = width ~/ 2;
    int starty = height ~/ 2;


    dynamic corners = new List();
    for (int i = 0; i < 4; i++) corners.add(Pair(startx, starty));

    //Breadth First Search to find borders of the page
    while(queue.isNotEmpty) {
      dynamic a = queue.first;
      //find the farthest point of the paper on each quarter - those should be corners of page
      if (a.first >= startx && a.second >= starty &&
          square(a.first - startx) + square(a.second - starty) >
              square(corners[0].first - startx) +
                  square(corners[0].second - starty))
        corners[0] = a;
      if (a.first <= startx && a.second >= starty &&
          square(a.first - startx) + square(a.second - starty) >
              square(corners[1].first - startx) +
                  square(corners[1].second - starty))
        corners[1] = a;
      if (a.first <= startx && a.second <= starty &&
          square(a.first - startx) + square(a.second - starty) >
              square(corners[2].first - startx) +
                  square(corners[2].second - starty))
        corners[2] = a;
      if (a.first >= startx && a.second <= starty &&
          square(a.first - startx) + square(a.second - starty) >
              square(corners[3].first - startx) +
                  square(corners[3].second - starty))
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