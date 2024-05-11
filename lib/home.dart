import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaru_widgets/widgets.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'dialog.dart';
import 'widget.dart';
import 'tinify/api.dart';
import 'tinify/result.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _outputTypes = ['WebP', 'Jpeg', 'Png'];
  final _resizeMethods = ['scale', 'fit', 'cover', 'thumb'];
  final _selectFileController = TextEditingController();
  final _imageWidthController = TextEditingController();
  final _imageHeightController = TextEditingController();
  final _lockSize = ValueNotifier(true);
  final _selectResizeMethod = ValueNotifier<String?>(null);
  final _selectOutputType = ValueNotifier<String?>(null);
  final _backgroundColor = ValueNotifier<Color?>(null);
  final _uploadResult = ValueNotifier<ImageUploadResult?>(null);
  img.Image? _originImage;

  @override
  void dispose() {
    _selectFileController.dispose();
    _imageWidthController.dispose();
    _imageHeightController.dispose();
    _lockSize.dispose();
    _selectResizeMethod.dispose();
    _selectOutputType.dispose();
    _backgroundColor.dispose();
    _uploadResult.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: YaruWindowTitleBar(
        title: const Text('TinyImage'),
        actions: [
          YaruIconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const SettingDialog(),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'File:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: TextField(
                    controller: _selectFileController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Select image',
                    ),
                    onTap: _pickImage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionItem(
              section: 'Resize Option',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Size:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 30),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _imageWidthController,
                          decoration: const InputDecoration(
                            labelText: 'Width',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => _updateImageSize(width: value),
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: _lockSize,
                        builder: (_, isLock, __) => AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: IconButton(
                            icon: Icon(isLock ? Icons.lock : Icons.lock_open),
                            onPressed: () {
                              _lockSize.value = !_lockSize.value;
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _imageHeightController,
                          decoration: const InputDecoration(
                            labelText: 'Height',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => _updateImageSize(height: value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ValueListenableBuilder(
                    valueListenable: _selectResizeMethod,
                    builder: (_, resizeMethod, __) {
                      return Row(
                        children: [
                          Text(
                            'Method:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 5),
                          ..._resizeMethods.expand((element) => [
                                YaruRadioButton(
                                  title: Text(element),
                                  value: element,
                                  groupValue: resizeMethod,
                                  toggleable: true,
                                  onChanged: (value) {
                                    _selectResizeMethod.value = value;
                                  },
                                ),
                                const SizedBox(width: 5),
                              ]),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionItem(
              section: 'Convert Option',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder(
                    valueListenable: _selectOutputType,
                    builder: (_, outputType, __) {
                      return Row(
                        children: [
                          Text(
                            'Output:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 5),
                          ..._outputTypes.expand((element) => [
                                YaruRadioButton(
                                  title: Text(element),
                                  value: element,
                                  groupValue: outputType,
                                  toggleable: true,
                                  onChanged: (value) {
                                    _selectOutputType.value = value;
                                  },
                                ),
                                const SizedBox(width: 5),
                              ]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Text(
                        'Background:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 5),
                      ValueListenableBuilder(
                        valueListenable: _backgroundColor,
                        builder: (_, color, __) => YaruPopupMenuButton(
                          initialValue: color,
                          child: Container(width: 60, height: 24, color: color),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: Colors.white, child: Text('White')),
                            const PopupMenuItem(
                                value: Colors.black, child: Text('Black')),
                            const PopupMenuItem(
                                value: Colors.transparent,
                                child: Text('Custom')),
                          ],
                          onSelected: (value) {
                            if (value == Colors.transparent) {
                              _showColorPicker();
                            } else {
                              _backgroundColor.value = value;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            ButtonBar(
              alignment: MainAxisAlignment.start,
              children: [
                ValueListenableBuilder(
                  valueListenable: _selectFileController,
                  builder: (_, value, __) => OutlinedButton(
                    onPressed: value.text.isEmpty ? null : _compressImage,
                    child: const Text('Compress'),
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: _uploadResult,
                  builder: (_, result, __) => OutlinedButton(
                    onPressed: result?.url == null ? null : _resizeImage,
                    child: const Text('Resize'),
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: _uploadResult,
                  builder: (_, result, __) => OutlinedButton(
                    onPressed: result?.url == null ? null : _convertImage,
                    child: const Text('Convert'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: _selectFileController,
                      builder: (_, value, __) =>
                          ImagePreviewItem(url: value.text),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: _uploadResult,
                      builder: (_, result, __) => ImagePreviewItem(
                        url: result?.url ?? '',
                        size: Size((_originImage?.width ?? 0).toDouble(),
                            (_originImage?.height ?? 0).toDouble()),
                        length: result?.size,
                        type: result?.type,
                        ratio: result?.ratio,
                        onTapDownload: result == null ? null : _downloadImage,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _pickImage() async {
    final result = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'images',
          extensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
        )
      ],
    );
    if (result == null) {
      return;
    }
    _selectFileController.text = result.path;
    _uploadResult.value = null;
    _originImage = await img.decodeImageFile(result.path);
    if (_originImage == null) {
      return;
    }
    _imageWidthController.text = _originImage!.width.toString();
    _imageHeightController.text = _originImage!.height.toString();
  }

  void _showColorPicker() async {
    final color = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ColorDialog(
        color: _backgroundColor.value,
      ),
    );
    _backgroundColor.value = color;
  }

  void _updateImageSize({String? width, String? height}) {
    if (!_lockSize.value || _originImage == null) {
      return;
    }
    final originWidth = _originImage!.width;
    final originHeight = _originImage!.height;
    final ratio = originWidth / originHeight;
    if (width != null) {
      final w = int.tryParse(width) ?? 0;
      final h = w / ratio;
      _imageHeightController.text = h.ceil().toString();
    } else if (height != null) {
      final h = int.tryParse(height) ?? 0;
      final w = h * ratio;
      _imageWidthController.text = w.ceil().toString();
    }
  }

  void _compressImage() async {
    if (_selectFileController.text.isEmpty) {
      return;
    } else if (_uploadResult.value != null) {
      return;
    }
    if (!mounted) {
      return;
    }
    try {
      showLoading(context);
      _uploadResult.value =
          await TinifyClient.upload(_selectFileController.text);
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      showToast(context, e.toString());
    } finally {
      hideLoading();
    }
  }

  void _resizeImage() async {
    final imageUrl = _uploadResult.value?.url;
    if (imageUrl == null ||
        imageUrl.isEmpty ||
        _selectResizeMethod.value == null) {
      showToast(context, 'resize method cannot empty');
      return;
    }
    final width = int.tryParse(_imageWidthController.text);
    final height = int.tryParse(_imageHeightController.text);
    if (width == null || height == null) {
      showToast(context, 'width or height cannot empty');
      return;
    }
    final savedFile = await _saveImage(tag: '${_selectResizeMethod.value}_');
    if (savedFile == null || !mounted) {
      return;
    }
    try {
      showLoading(context);
      final result = await TinifyClient.resize(
          imageUrl, _selectResizeMethod.value!, width, height);
      if (result.data.isNotEmpty) {
        await savedFile.writeAsBytes(result.data);
        _uploadResult.value = _uploadResult.value?.copyWith(
          url: savedFile.path,
        );
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      showToast(context, e.toString());
    } finally {
      hideLoading();
    }
  }

  void _convertImage() async {
    final imageUrl = _uploadResult.value?.url;
    if (imageUrl == null ||
        imageUrl.isEmpty ||
        _selectOutputType.value == null) {
      showToast(context, 'output type cannot empty');
      return;
    }
    final savedFile =
        await _saveImage(tag: '${_selectOutputType.value!.toLowerCase()}_');
    if (savedFile == null || !mounted) {
      return;
    }
    String? backgroundColor;
    if (_backgroundColor.value != null) {
      backgroundColor = colorToHex(_backgroundColor.value!,
          includeHashSign: true, enableAlpha: false);
    }
    try {
      showLoading(context);
      final result = await TinifyClient.convert(
          imageUrl, _selectOutputType.value!.toLowerCase(),
          background: backgroundColor);
      if (result.data.isNotEmpty) {
        await savedFile.writeAsBytes(result.data);
        _uploadResult.value = _uploadResult.value?.copyWith(
          url: savedFile.path,
        );
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      showToast(context, e.toString());
    } finally {
      hideLoading();
    }
  }

  void _downloadImage() async {
    final imageUrl = _uploadResult.value?.url;
    if (imageUrl == null) {
      return;
    }
    final savedFile = await _saveImage(tag: 'compress_');
    if (savedFile == null || !mounted) {
      return null;
    }
    try {
      showLoading(context);
      final convertResult = await TinifyClient.download(imageUrl);
      if (convertResult.data.isNotEmpty) {
        await savedFile.writeAsBytes(convertResult.data);
      } else if (mounted) {
        showToast(context, 'image download failed');
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      showToast(context, e.toString());
    } finally {
      hideLoading();
    }
  }

  Future<File?> _saveImage({String? tag}) async {
    final fileName = path.basename(_selectFileController.text);
    final rootDir = path.dirname(_selectFileController.text);
    final location = await getSaveLocation(
      initialDirectory: rootDir,
      suggestedName: '${tag ?? ''}$fileName',
    );
    if (location == null) {
      return null;
    }
    final savedFile = File(location.path);
    if (await savedFile.exists()) {
      await savedFile.delete();
    }
    return savedFile;
  }
}
