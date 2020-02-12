class Coordinate
{
  int _x, _y;

  Coordinate([int x=0, int y=0]) {
    _x = x;
    _y = y;
  }

  get x {
    return _x;
  }

  set x(int value) {
    this._x = value;
  }

  set y(int value) {
    this._y = value;
  }

  get y {
    return _y;
  }
}