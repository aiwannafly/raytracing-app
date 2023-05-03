import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:icg_raytracing/algorithms/types.dart';
import 'package:icg_raytracing/model/scene/figures/box.dart';
import 'package:icg_raytracing/model/scene/figures/quadrangle.dart';
import 'package:icg_raytracing/model/scene/figures/sphere.dart';
import 'package:icg_raytracing/model/scene/figures/triangle.dart';
import 'package:icg_raytracing/model/scene/light_source.dart';
import 'package:icg_raytracing/model/scene/scene.dart';

import '../model/scene/figures/figure.dart';

class SceneFileService {
  SceneFileService._internal();

  factory SceneFileService() {
    return SceneFileService._internal();
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
        figures.add(Sphere(
            center: center,
            radius: radius,
            optics: optics));
      } else if (line.startsWith('BOX')) {
        var minPos = point;
        var maxPos = _pointFromLine(lines[curr++]);
        var optics = _opticsFromLine(lines[curr++]);
        figures.add(Box(
            minPos: minPos,
            maxPos: maxPos,
            optics: optics));
      } else if (line.startsWith('TRIANGLE')) {
        var first = point;
        var second = _pointFromLine(lines[curr++]);
        var third = _pointFromLine(lines[curr++]);
        var optics = _opticsFromLine(lines[curr++]);
        figures.add(Triangle(
            first: first,
            second: second,
            third: third,
            optics: optics));
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
        figures: figures,
        lightSources: lightSources,
        ambientColor: ambientColor);
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
