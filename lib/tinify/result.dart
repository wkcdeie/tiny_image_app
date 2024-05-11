import 'dart:typed_data';

/*
* {"input":{"size":1037322,"type":"image/png"},
* "output":{"size":155753,"type":"image/png","width":750,"height":1624,"ratio":0.1501,"url":"https://api.tinify.com/output/8kc5f5fzya5855azv1nacawc4hxkkc7p"}
* }
* */
class ImageUploadResult {
  final String type;
  final int size;
  final String url;
  final int width;
  final int height;
  final double ratio;

  ImageUploadResult(
      {required this.type,
      this.size = 0,
      required this.url,
      this.width = 0,
      this.height = 0,
      this.ratio = 0.0});

  ImageUploadResult copyWith({String? url}) {
    return ImageUploadResult(
      type: type,
      size: size,
      url: url ?? this.url,
      width: width,
      height: height,
      ratio: ratio,
    );
  }
}

class ImageResizeResult {
  final int width;
  final int height;
  final Uint8List data;

  ImageResizeResult(this.width, this.height, this.data);
}

class ImageConvertResult extends ImageResizeResult {
  final String type;

  ImageConvertResult(int width, int height, Uint8List data, this.type)
      : super(width, height, data);
}
