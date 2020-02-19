class Pixel
{
  int r;
  int g;
  int b;
  int a;

  Pixel([_r=0,_g=0,_b=0,_a=1]) {
    r=_r;
    g=_g;
    b=_b;
    a=_a;
  }

  String toString() {
    return "${r}:${g}:${b}";
  }
}