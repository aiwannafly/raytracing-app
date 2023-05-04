import 'dart:io';
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
    lines.add('${settings.backgroundColor}');
    lines.add('${settings.gamma}');
    lines.add('${settings.depth}');
    lines.add(settings.quality.name);
    lines.add(settings.eye.toString());
    lines.add(settings.view.toString());
    lines.add(settings.up.toString());
    lines.add('${settings.zNear} ${settings.zFar}');
    lines.add('${settings.planeWidth} ${settings.planeHeight}');
    String text =
        lines.fold("", (prev, curr) => "$prev$curr\n");
    await file.writeAsString(text);
  }

  Future<RenderSettings?> openSettingsFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['render']);
    if (result == null) return null;
    String path = result.files.first.path!;
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
        backgroundColor: backgroundColor,
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

  Future<Scene?> openSceneFile() async {
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
    return Scene(
        figures: figures, lightSources: lightSources, ambient: ambientColor);
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
}
