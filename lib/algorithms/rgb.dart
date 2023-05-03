class RGBDouble {
  double red;
  double blue;
  double green;

  RGBDouble(this.red, this.green, this.blue);

  RGB toRGB() {
    var rgb = RGB(red.round(), green.round(), blue.round());
    rgb.normalize();
    return rgb;
  }

  RGBDouble operator +(RGBDouble o) {
    return RGBDouble(red + o.red, green + o.green, blue + o.blue);
  }

  RGBDouble operator *(double a) {
    return RGBDouble(red * a, green * a, blue * a);
  }


  RGBDouble mulScalar(num scalar) {
    return RGBDouble(red * scalar, green * scalar, blue * scalar);
  }

  static RGBDouble sumTwo(RGBDouble first, RGBDouble second) {
    return RGBDouble(first.red + second.red, first.green + second.green,
        first.blue + second.blue);
  }

  static RGBDouble sum(List<RGBDouble> args) {
    RGBDouble res = RGBDouble(0, 0, 0);
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

  RGBDouble toRGBDouble() {
    return RGBDouble(red.toDouble(), green.toDouble(), blue.toDouble());
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