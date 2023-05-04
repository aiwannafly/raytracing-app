class RGBD {
  double red;
  double blue;
  double green;

  RGBD(this.red, this.green, this.blue);

  RGB toRGB() {
    var rgb = RGB(red.round(), green.round(), blue.round());
    rgb.normalize();
    return rgb;
  }

  RGBD operator +(RGBD o) {
    return RGBD(red + o.red, green + o.green, blue + o.blue);
  }

  RGBD operator *(double a) {
    return RGBD(red * a, green * a, blue * a);
  }


  RGBD mulScalar(num scalar) {
    return RGBD(red * scalar, green * scalar, blue * scalar);
  }

  static RGBD sumTwo(RGBD first, RGBD second) {
    return RGBD(first.red + second.red, first.green + second.green,
        first.blue + second.blue);
  }

  static RGBD sum(List<RGBD> args) {
    RGBD res = RGBD(0, 0, 0);
    for (var arg in args) {
      res.red += arg.red;
      res.green += arg.green;
      res.blue += arg.blue;
    }
    return res;
  }
}

class RGB {
  late int red;
  late int blue;
  late int green;

  RGB(this.red, this.green, this.blue);

  RGB.mono(int value) {
    red = value;
    blue = value;
    green = value;
    normalize();
  }

  RGBD toRGBDouble() {
    return RGBD(red.toDouble(), green.toDouble(), blue.toDouble());
  }

  void addAll(int val) {
    red += val;
    green += val;
    blue += val;
    normalize();
  }

  static RGB sum(RGB first, RGB second) {
    return RGB(first.red + second.red, first.green + second.green,
        first.blue + second.blue);
  }

  static RGB diff(RGB first, RGB second) {
    return RGB(first.red - second.red, first.green - second.green,
        first.blue - second.blue);
  }

  static RGB resize(RGB value, double k) {
    return RGB((value.red * k).floor(), (value.green * k).floor(),
        (value.blue * k).floor());
  }

  RGB add(int r, int g, int b, double k) {
    red += (k * r).round();
    green += (k * g).round();
    blue += (k * b).round();
    normalize();
    return this;
  }

  void normalize() {
    red = _normalizeChannel(red);
    green = _normalizeChannel(green);
    blue = _normalizeChannel(blue);
  }

  int _normalizeChannel(int old) {
    if (old < 0) {
      return 0;
    }
    if (old > 255) {
      return 255;
    }
    return old;
  }
}