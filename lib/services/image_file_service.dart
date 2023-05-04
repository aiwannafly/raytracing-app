import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../algorithms/bmp.dart';
import '../algorithms/types.dart';
import 'service_io.dart';

class ImageFileService {
  static Future<Uint8List?> readFileByte(String filePath) async {
    Uri myUri = Uri.parse(filePath);
    File imageFile = File.fromUri(myUri);
    Uint8List? bytes;
    await imageFile.readAsBytes().then((value) {
      bytes = Uint8List.fromList(value);
    }).catchError((onError) {
      return null;
    });
    return bytes;
  }

  static Future<BMPImage?> openImage(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bmp'],
    );
    if (result == null) return null;
    String path = result.files.first.path!;
    File file = File.fromUri(Uri(path: path));
    Uint8List bytes = file.readAsBytesSync();
    var params = BMP.getParams(bytes);
    if (params == null) return null;
    return BMPImage.memory(bytes, params);
  }

  static void saveImageBMP(BuildContext context, BMPImage image) async {
    String? result = await FilePicker.platform
        .saveFile(type: FileType.custom, allowedExtensions: ['bmp']);
    if (result == null) return;
    String path = "$result.bmp";
    File file = await File(path).create();
    file.writeAsBytesSync(image.bytes);
    Future.microtask(() => ServiceIO.showMessage("Saved file $path", context));
  }

  static void saveCanvasScene(BuildContext context,
      {required List<Section> sections,
      required double width,
      required double height}) async {
    String? result = await FilePicker.platform
        .saveFile(type: FileType.custom, allowedExtensions: ['png']);
    if (result == null) return;
    String path = "$result.png";
    File file = await File(path).create();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0.0, 0.0, width, height));
    canvas.drawColor(Colors.white, BlendMode.color);
    var linePaint = Paint()
      ..color = Colors.black87
      ..isAntiAlias=true
      ..strokeWidth = 1;
    for (Section s in sections) {
      canvas.drawLine(
          Offset(s.start.x, s.start.y), Offset(s.end.x, s.end.y), linePaint);
    }
    var pic = recorder.endRecording();
    var img = await pic.toImage(width.round(), height.round());
    ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    file.writeAsBytesSync(byteData.buffer.asUint8List());
    Future.microtask(() => ServiceIO.showMessage("Saved file $path", context));
  }
}
