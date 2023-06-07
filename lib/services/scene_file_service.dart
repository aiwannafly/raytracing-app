import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:icg_raytracing/algorithms/types.dart';
import 'package:icg_raytracing/model/render/render_settings.dart';
import 'package:icg_raytracing/model/scene/figures/box.dart';
import 'package:icg_raytracing/model/scene/figures/quadrangle.dart';
import 'package:icg_raytracing/model/scene/figures/sphere.dart';
import 'package:icg_raytracing/model/scene/figures/triangle.dart';
import 'package:icg_raytracing/model/scene/light_source.dart';
import 'package:icg_raytracing/model/scene/scene.dart';

import '../algorithms/rgb.dart';
import '../model/scene/figures/figure.dart';

class OpenSceneResult {
  Scene scene;
  RenderSettings? settings;

  OpenSceneResult(this.scene, [this.settings]);
}

class SceneFileService {
  SceneFileService._internal();

  factory SceneFileService() {
    return SceneFileService._internal();
  }

  Future saveSettingsFile({required RenderSettings settings}) async {
    String? result = await FilePicker.platform
        .saveFile(type: FileType.custom, allowedExtensions: ['render']);
    if (result == null) return;
    String path = "$result.render";
    File file = await File(path).create();
    List<String> lines = [];
    lines.add('${settings.backColor}');
    lines.add('${settings.gamma}');
    lines.add('${settings.depth}');
    lines.add(settings.quality.name);
    lines.add(settings.eye.toString());
    lines.add(settings.view.toString());
    lines.add(settings.up.toString());
    lines.add('${settings.zNear} ${settings.zFar}');
    lines.add('${settings.planeWidth} ${settings.planeHeight}');
    String text = lines.fold("", (prev, curr) => "$prev$curr\n");
    await file.writeAsString(text);
  }

  Future saveSceneFile({required Scene scene}) async {
    String? result = await FilePicker.platform
        .saveFile(type: FileType.custom, allowedExtensions: ['scene']);
    if (result == null) return;
    String path = "$result.scene";
    File file = await File(path).create();
    List<String> lines = [];
    var ambient = scene.ambient * 255;
    lines.add(RGB(ambient.x.round(), ambient.y.round(), ambient.z.round())
        .toString());
    lines.add(scene.lightSources.length.toString());
    for (LightSource l in scene.lightSources) {
      lines.add(l.toString());
    }
    for (Figure f in scene.figures) {
      lines.add(f.toString());
    }
    String text = lines.fold("", (prev, curr) => "$prev$curr\n");
    await file.writeAsString(text);
  }

  Future<RenderSettings?> openSettingsFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['render']);
    if (result == null) return null;
    String path = result.files.first.path!;
    return await _openSettingsFileByPath(path);
  }

  Future<RenderSettings?> _openSettingsFileByPath(String path) async {
    File file = File.fromUri(Uri(path: path));
    String text = file.readAsStringSync();
    List<String> lines = _removeComments(text);
    int curr = 0;
    Point3D backColor = _pointFromLine(lines[curr++]);
    RGB backgroundColor =
        RGB(backColor.x.round(), backColor.y.round(), backColor.z.round());
    backgroundColor.normalize();
    double gamma = _numsFromLine(lines[curr++])[0];
    if (gamma < 0) {
      throw "Gamma must be a positive number";
    }
    int depth = _numsFromLine(lines[curr++])[0].round();
    if (depth < 0) {
      throw "Depth must be a positive number";
    }
    Quality quality = Quality.normal;
    var line = lines[curr++];
    if (line == "fine") {
      quality = Quality.fine;
    } else if (line == "normal") {
      quality = Quality.normal;
    } else if (line == "rough") {
      quality = Quality.rough;
    } else {
      throw "$line is not one a quality from normal, fine, rough";
    }
    var eye = _pointFromLine(lines[curr++]);
    var view = _pointFromLine(lines[curr++]);
    var up = _pointFromLine(lines[curr++]);
    var zs = _numsFromLine(lines[curr++]);
    double zNear = zs[0];
    double zFar = zs[1];
    var whs = _numsFromLine(lines[curr++]);
    double sWidth = whs[0];
    double sHeight = whs[1];
    var dir = view - eye;
    var right = dir.vectorMul(up);
    up = right.vectorMul(dir);
    up /= up.norm();
    return RenderSettings(
        backColor: backgroundColor,
        gamma: gamma,
        depth: depth,
        quality: quality,
        eye: eye,
        view: view,
        up: up,
        zNear: zNear,
        zFar: zFar,
        planeWidth: sWidth,
        planeHeight: sHeight);
  }

  Future<OpenSceneResult?> openSceneFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['scene']);
    if (result == null) return null;
    String path = result.files.first.path!;
    File file = File.fromUri(Uri(path: path));
    String text = file.readAsStringSync();
    List<String> lines = _removeComments(text);
    if (lines.length < 3) {
      return null;
    }
    int curr = 0;
    var line = lines[curr++];
    var aLight = _numsFromLine(line);
    if (aLight.length != 3) {
      return null;
    }
    aLight = aLight.map((e) => e / 255).toList();
    Point3D ambientColor = Point3D(aLight[0], aLight[1], aLight[2]);
    line = lines[curr++];
    int lCount = int.parse(line);
    List<LightSource> lightSources = [];
    for (int i = 0; i < lCount; i++) {
      var lNums = _numsFromLine(lines[curr++]);
      if (lNums.length != 6) {
        return null;
      }
      Point3D pos = Point3D(lNums[0], lNums[1], lNums[2]);
      Point3D color = Point3D(lNums[3] / 255, lNums[4] / 255, lNums[5] / 255);
      lightSources.add(LightSource(pos: pos, color: color));
    }
    List<Figure> figures = [];
    while (curr < lines.length) {
      line = lines[curr++];
      var point = _pointFromLine(line, ignoreFirstWord: true);
      if (line.startsWith('SPHERE')) {
        var center = point;
        var radius = _numsFromLine(lines[curr++])[0];
        var optics = _opticsFromLine(lines[curr++]);
        figures.add(Sphere(center: center, radius: radius, optics: optics));
      } else if (line.startsWith('BOX')) {
        var minPos = point;
        var maxPos = _pointFromLine(lines[curr++]);
        var optics = _opticsFromLine(lines[curr++]);
        figures.add(Box(minPos: minPos, maxPos: maxPos, optics: optics));
      } else if (line.startsWith('TRIANGLE')) {
        var first = point;
        var second = _pointFromLine(lines[curr++]);
        var third = _pointFromLine(lines[curr++]);
        var optics = _opticsFromLine(lines[curr++]);
        figures.add(Triangle(
            first: first, second: second, third: third, optics: optics));
      } else if (line.startsWith('QUADRANGLE')) {
        var first = point;
        var second = _pointFromLine(lines[curr++]);
        var third = _pointFromLine(lines[curr++]);
        var fourth = _pointFromLine(lines[curr++]);
        var optics = _opticsFromLine(lines[curr++]);
        figures.add(Quadrangle(
            first: first,
            second: second,
            third: third,
            fourth: fourth,
            optics: optics));
      }
    }
    var scene = Scene(
        figures: figures, lightSources: lightSources, ambient: ambientColor);
    String renderPath = path.replaceFirstMapped('.scene', (match) => '.render');
    RenderSettings? settings;
    try {
      settings = await _openSettingsFileByPath(renderPath);
    } catch (e) {
      return OpenSceneResult(scene);
    }
    return OpenSceneResult(scene, settings);
  }

  Optics _opticsFromLine(String line) {
    var optics = _numsFromLine(line);
    int idx = 0;
    var diff = Point3D(optics[idx++], optics[idx++], optics[idx++]);
    var sight = Point3D(optics[idx++], optics[idx++], optics[idx++]);
    var power = optics[idx++];
    return Optics(diff: diff, sight: sight, power: power.round());
  }

  Point3D _pointFromLine(String line, {bool ignoreFirstWord = false}) {
    var nums = _numsFromLine(line, ignoreFirst: ignoreFirstWord);
    return Point3D(nums[0], nums[1], nums[2]);
  }

  List<double> _numsFromLine(String line, {bool ignoreFirst = false}) {
    var words = line.split(' ');
    if (ignoreFirst) {
      words.removeAt(0);
    }
    List<double> res = [];
    for (var word in words) {
      double num = double.parse(word);
      res.add(num);
    }
    return res;
  }

  List<String> _removeComments(String text) {
    List<String> lines = text.split('\n');
    lines = lines.where((line) {
      if (line == '\n') {
        return false;
      }
      var words = line.split(' ');
      if (words.first.startsWith("//")) {
        return false;
      }
      return true;
    }).toList();
    for (int i = 0; i < lines.length; i++) {
      var words = lines[i].split(' ');
      for (int j = 0; j < words.length; j++) {
        if (words[j].startsWith("//")) {
          lines[i] = words
              .sublist(0, j)
              .fold("", (previousValue, element) => "$previousValue $element");
          break;
        }
      }
    }
    lines = lines.map((e) => e.trim()).toList();
    lines = lines.where((element) => element.isNotEmpty).toList();
    return lines;
  }

  void saveCustomScene() async {
    double width = 30;
    double length = 30;
    double height = 20;
    List<Figure> figures = [];
    var diffOptics =
        Optics(diff: Point3D(.5, .6, .3), sight: Point3D(0, 0, 0), power: 3);
    Box main = Box(
        minPos: Point3D(-width / 2, -length / 2, 0),
        maxPos: Point3D(width / 2, length / 2, height),
        optics: Optics(diff: Point3D(.5, .6, .3), sight: Point3D(0, 0, 0), power: 3));
    figures.add(main);
    double h = 0;
    double s = 8;
    var sightOptics = Optics(
        diff: Point3D(1, 1, 1),
        sight: Point3D(
          .9,
          .9,
          .9,
        ),
        power: 6);
    Point3D offset = Point3D(0, 0, 0);
    void buildPyramidLevel() {
      List<Point3D> p1 = [
        Point3D(-s, -s, h),
        Point3D(s, -s, h),
        Point3D(s, s, h),
        Point3D(-s, s, h)
      ];
      s -= 1;
      h += 2;
      List<Point3D> p2 = [
        Point3D(-s, -s, h),
        Point3D(s, -s, h),
        Point3D(s, s, h),
        Point3D(-s, s, h)
      ];
      for (int i = 0; i < 4; i++) {
        int next = (i + 1) % 4;
        var q = Quadrangle(
            first: p1[i],
            second: p2[i],
            third: p2[next],
            fourth: p1[next],
            optics: sightOptics);
        q.shift(-offset);
        figures.add(q);
      }
      var q = Quadrangle(
          first: p2[0],
          second: p2[1],
          third: p2[2],
          fourth: p2[3],
          optics: sightOptics);
      q.shift(-offset);
      figures.add(q);
      s--;
    }

    diffOptics.sight = Point3D(1, 1, 1);
    buildPyramidLevel();
    buildPyramidLevel();
    buildPyramidLevel();
    diffOptics.sight = Point3D(.3, .3, .3);
    void buildSphereBase(double x, double y, double z, double height, double radius) {
      double d = radius * 2;
      figures.add(Box(
          minPos: Point3D(x, y, z),
          maxPos: Point3D(x + d, y + d, z + height),
          optics: diffOptics));
      h = height;
      s = radius;
      offset = Point3D(x + radius, y + radius, z);
      buildPyramidLevel();
      figures.add(Sphere(
          center: Point3D(x + radius, y + radius, z + height + 2 + radius),
          radius: radius,
          optics: sightOptics));
    }
    sightOptics.sight = Point3D(1, 1, 1);
    diffOptics.diff = Point3D(1, 0, 1);
    sightOptics.diff = Point3D(1, 1, 0);
    diffOptics.sight = Point3D(1, 1, 1);
    buildSphereBase(-10, -10, 0, 4, 2);
    diffOptics.diff = Point3D(1, 1, 0);
    sightOptics.diff = Point3D(0, 1, 0);
    buildSphereBase(10, 10, 0, 2, 2);
    diffOptics.diff = Point3D(1, 1, 1);
    sightOptics.diff = Point3D(0, 0, 1);
    sightOptics.power = 8;
    buildSphereBase(10, -10, 0, 5, 2);
    diffOptics.diff = Point3D(1, 1, 0);
    sightOptics.diff = Point3D(0, 1, 0);
    buildSphereBase(-10, 10, 0, 5, 2.5);

    diffOptics.sight = Point3D(1, 1, 1);
    diffOptics.diff = Point3D(1, 1, 1);
    sightOptics.sight = Point3D(1, 1, 1);
    sightOptics.diff = Point3D(1, 1, 1);
    buildSphereBase(-2, -2, 6, 1, 2);

    h = height * .8;
    s = min(length, width) * .3;
    List<LightSource> lightSources = [
      LightSource(pos: Point3D(-s, -s, h), color: Point3D(1, 0, 0)),
      LightSource(pos: Point3D(s, -s, h), color: Point3D(.4, .7, 1)),
      LightSource(pos: Point3D(s, s, h), color: Point3D(1, .3, 1)),
      LightSource(pos: Point3D(-s, s, h), color: Point3D(1, 0, .7)),
      LightSource(pos: Point3D(-2*s, 0, h), color: Point3D(1, 1, 0)),
      LightSource(pos: Point3D(0, s * 2, h), color: Point3D(0, 1, .7)),
      LightSource(pos: Point3D(-2*s, -3, h), color: Point3D(1, 0, 0)),
      LightSource(pos: Point3D(2, s * 2, h), color: Point3D(0, 0, 1)),
    ];
    var ambient = Point3D(.2, .2, .1);
    var scene =
        Scene(figures: figures, lightSources: lightSources, ambient: ambient);
    await SceneFileService().saveSceneFile(scene: scene);
  }
}
