import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'rgb.dart';

class BMPImageParams {
  final int fileSize;
  final int pixelOffset;
  final int headerOffset;
  final int height;
  final int width;
  final int bitsPerPixel;
  final int compressionType;
  final int bytesPerPixel;

  BMPImageParams(
      {required this.fileSize,
      required this.pixelOffset,
      required this.headerOffset,
      required this.height,
      required this.width,
      required this.bitsPerPixel,
      required this.compressionType,
      required this.bytesPerPixel});
}

class BMPImage {
  late final BMPImageParams params;
  late final Uint8List bytes;
  static const headerOffset = 14;

  BMPImage.memory(this.bytes, this.params);

  BMPImage({required int width, required int height}) {
    assert(width > 0);
    assert(height > 0);
    int fileSize = BMP._defaultBytes.length + (width * height) * 3;
    bytes = Uint8List(fileSize);
    for (int i = 0; i < BMP._defaultBytes.length; i++) {
      bytes[i] = BMP._defaultBytes[i];
    }
    Endian endianness = Endian.little;
    bytes.buffer.asByteData().setInt32(2, fileSize, endianness);
    bytes.buffer
        .asByteData()
        .setInt32(headerOffset + 4, width, endianness);
    bytes.buffer
        .asByteData()
        .setInt32(headerOffset + 8, height, endianness);
    params = BMP.getParams(bytes)!;
  }

  int? getPixel({required int x, required int y}) {
    if (x < 0 || y < 0 || x >= params.width || y >= params.height) {
      return null;
    }
    int pixelByteOffset = _getPixelOffset(x: x, y: y);
    if (pixelByteOffset + 2 >= bytes.length) return null;
    if (pixelByteOffset < 0) return null;
    return BMP._fromBytesToInt32(bytes[pixelByteOffset++],
        bytes[pixelByteOffset++], bytes[pixelByteOffset], 0);
  }

  RGB? getRGB({required int x, required int y}) {
    if (x < 0 || y < 0 || x >= params.width || y >= params.height) {
      return null;
    }
    int pixelByteOffset = _getPixelOffset(x: x, y: y);
    if (pixelByteOffset + 2 >= bytes.length) return null;
    if (pixelByteOffset < 0) return null;
    int blue = bytes[pixelByteOffset++];
    int green = bytes[pixelByteOffset++];
    int red = bytes[pixelByteOffset];
    return RGB(red, green, blue);
  }

  int _getPixelOffset({required int x, required int y}) {
    y = params.height - y - 1;
    return params.pixelOffset + params.bytesPerPixel * (x + y * (params.width));
  }

  void setPixel({required int x, required int y, required Color color}) {
    setRGB(x: x, y: y, color: RGB(color.red, color.green, color.blue));
  }

  void setRGB({required int x, required int y, required RGB color}) {
    if (x < 0 || y < 0 || x >= params.width || y >= params.height) {
      return;
    }
    int pixelByteOffset = _getPixelOffset(x: x, y: y);
    if (pixelByteOffset + 2 >= bytes.length) return;
    if (pixelByteOffset < 0) return;
    bytes[pixelByteOffset++] = color.blue;
    bytes[pixelByteOffset++] = color.green;
    bytes[pixelByteOffset++] = color.red;
  }

  BMPImage _resizeImage(int newWidth, int newHeight) {
    // bytes changing according to BMP format...
    int oldWidth = params.width;
    int oldHeight = params.height;
    int oldPixelsCount = oldWidth * oldHeight;
    int newPixelsCount = newWidth * newHeight;
    int newSize = params.fileSize + (newPixelsCount - oldPixelsCount) * 3;
    Uint8List newBytes = Uint8List(newSize);
    for (int i = 0; i < params.pixelOffset; i++) {
      newBytes[i] = bytes[i];
    }
    Endian endianness = Endian.little;
    newBytes.buffer.asByteData().setInt32(2, newSize, endianness);
    newBytes.buffer
        .asByteData()
        .setInt32(headerOffset + 4, newWidth, endianness);
    newBytes.buffer
        .asByteData()
        .setInt32(headerOffset + 8, newHeight, endianness);
    var newParams = BMP.getParams(newBytes)!;
    return BMPImage.memory(newBytes, newParams);
  }

  // returns new image with the params
  // old image is not resized, just placed in center
  BMPImage? expandAndAlignCenter(int newWidth, int newHeight) {
    int oldWidth = params.width;
    int oldHeight = params.height;
    if (newWidth <= oldWidth || newHeight <= oldHeight) {
      return this;
    }
    while (newWidth % 4 != 0) {
      newWidth++;
    }
    var newImage = _resizeImage(newWidth, newHeight);
    int shiftX = (newWidth - oldWidth) ~/ 2;
    int shiftY = (newHeight - oldHeight) ~/ 2;
    for (int y = 0; y < newHeight; y++) {
      for (int x = 0; x < newWidth; x++) {
        newImage.setRGB(x: x, y: y, color: RGB(255, 255, 255));
      }
    }
    for (int y = 0; y < oldHeight; y++) {
      for (int x = 0; x < oldWidth; x++) {
        newImage.setRGB(
            x: x + shiftX, y: y + shiftY, color: getRGB(x: x, y: y)!);
      }
    }
    return newImage;
  }

  // returns new image with params
  // width = oldWidth * resizer
  // height = oldHeight * resizer
  BMPImage? trivialInterpolation(double resizer) {
    if (resizer <= 0) {
      return null;
    }
    int oldWidth = params.width;
    int oldHeight = params.height;
    int newWidth = (oldWidth * resizer).round();
    int newHeight = (oldHeight * resizer).round();
    while (newWidth % 4 != 0) {
      newWidth++;
    }
    var newImage = _resizeImage(newWidth, newHeight);
    for (int y = 0; y < newHeight; y++) {
      for (int x = 0; x < newWidth; x++) {
        int nx = normalizeCoord((x * (1 / resizer)).round(), oldWidth);
        int ny = normalizeCoord((y * (1 / resizer)).round(), oldHeight);
        newImage.setRGB(x: x, y: y, color: getRGB(x: nx, y: ny)!);
      }
    }
    return newImage;
  }

  // returns new image with params
  // width = oldWidth * resizer
  // height = oldHeight * resizer
  BMPImage? bilinearInterpolation(double resizer) {
    if (resizer <= 0) {
      return null;
    }
    int oldWidth = params.width;
    int oldHeight = params.height;
    int newWidth = (oldWidth * resizer).round();
    int newHeight = (oldHeight * resizer).round();
    while (newWidth % 4 != 0) {
      newWidth++;
    }
    var newImage = _resizeImage(newWidth, newHeight);
    if (resizer <= 1) {
      for (int y = 0; y < newHeight; y++) {
        for (int x = 0; x < newWidth; x++) {
          int nx = normalizeCoord((x * (1 / resizer)).round(), oldWidth);
          int ny = normalizeCoord((y * (1 / resizer)).round(), oldHeight);
          newImage.setRGB(x: x, y: y, color: getRGB(x: nx, y: ny)!);
        }
      }
      return newImage;
    }
    List<RGB?> pixels = List.filled(newHeight * newWidth, null);
    for (int y = 0; y < oldHeight; y++) {
      for (int x = 0; x < oldWidth; x++) {
        RGB pixel = getRGB(x: x, y: y)!;
        int nx = (x * resizer).round();
        int ny = (y * resizer).round();
        pixels[nx + ny * newWidth] = pixel;
        newImage.setRGB(x: nx, y: ny, color: pixel);
      }
    }
    // actually bilinear interpolation
    for (int y = 0; y < newHeight - 1; y++) {
      int nextY = y + 1;
      while (nextY < newHeight && pixels[nextY * newWidth] == null) {
        nextY++;
      }
      if (nextY == newHeight) break;
      for (int x = 0; x < newWidth - 1; x++) {
        int nextX = x + 1;
        while (nextX < newWidth && pixels[nextX + y * newWidth] == null) {
          nextX++;
        }
        if (nextX == newWidth) break;
        int x1 = x, x2 = nextX, y1 = y, y2 = nextY;
        RGBDouble f11 = newImage.getRGB(x: x1, y: y1)!.toRGBDouble();
        RGBDouble f12 = newImage.getRGB(x: x1, y: y2)!.toRGBDouble();
        RGBDouble f21 = newImage.getRGB(x: x2, y: y1)!.toRGBDouble();
        RGBDouble f22 = newImage.getRGB(x: x2, y: y2)!.toRGBDouble();
        for (int i = y1; i <= y2; i++) {
          for (int j = x1; j <= x2; j++) {
            if ((i == y1 && j == x1) ||
                (i == y1 && j == x2) ||
                (i == y2 && j == x1) ||
                (i == y2 && j == x2)) {
              continue;
            }
            num alphaX = (j - x1) / (x2 - x1);
            num alphaY = (i - y1) / (y2 - y1);
            var color1 = RGBDouble.sumTwo(
                f11.mulScalar(1 - alphaX), f21.mulScalar(alphaX));
            var color2 = RGBDouble.sumTwo(
                f12.mulScalar(1 - alphaX), f22.mulScalar(alphaX));
            var res = RGBDouble.sumTwo(
                color1.mulScalar(1 - alphaY), color2.mulScalar(alphaY));
            newImage.setRGB(x: j, y: i, color: res.toRGB());
          }
        }
        x = nextX - 1;
      }
      y = nextY - 1;
    }
    return newImage;
  }

  static int normalizeCoord(int coord, int bound) {
    return min(max(0, coord), bound - 1);
  }
}

class BMP {
  static BMPImageParams? getParams(Uint8List bytes) {
    if (!(bytes[0] == 66 && bytes[1] == 77)) return null; // BM chars
    if (bytes.length < 14 + 40) return null;
    int fileSize = _extractInt32(bytes, 2);
    int pixelOffset = _extractInt32(bytes, 10);
    int headerOffset = 14;
    int height = _extractInt32(bytes, headerOffset + 8);
    int width = _extractInt32(bytes, headerOffset + 4);
    int bitsPerPixel = _extractInt16(bytes, headerOffset + 14);
    int compressionType = _extractInt32(bytes, headerOffset + 16);
    int bytesPerPixel = bitsPerPixel ~/ 8;
    return BMPImageParams(
        fileSize: fileSize,
        pixelOffset: pixelOffset,
        headerOffset: headerOffset,
        height: height,
        width: width,
        bitsPerPixel: bitsPerPixel,
        compressionType: compressionType,
        bytesPerPixel: bytesPerPixel);
  }

  static int _fromBytesToInt32(int b3, int b2, int b1, int b0) {
    final int8List = Int8List(4)
      ..[3] = b3
      ..[2] = b2
      ..[1] = b1
      ..[0] = b0;
    return int8List.buffer.asByteData().getInt32(0);
  }

  static int _fromBytesToInt16(int b1, int b0) {
    final int8List = Int8List(4)
      ..[1] = b1
      ..[0] = b0;
    return int8List.buffer.asByteData().getInt16(0);
  }

  static int _extractInt32(Uint8List bytes, int pos) {
    return _fromBytesToInt32(
        bytes[pos++], bytes[pos++], bytes[pos++], bytes[pos]);
  }

  static int _extractInt16(Uint8List bytes, int pos) {
    return _fromBytesToInt16(bytes[pos++], bytes[pos++]);
  }

  static const _defaultBytes = [
    66,
    77,
    42,
    2,
    16,
    0,
    0,
    0,
    0,
    0,
    54,
    0,
    0,
    0,
    40,
    0,
    0,
    0,
    212,
    2,
    0,
    0,
    227,
    1,
    0,
    0,
    1,
    0,
    24,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    19,
    11,
    0,
    0,
    19,
    11,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0
  ];
}
