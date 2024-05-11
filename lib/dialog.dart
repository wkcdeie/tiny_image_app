import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:yaru_widgets/widgets.dart';
import 'tinify/config.dart';

class ColorDialog extends StatefulWidget {
  final Color? color;

  const ColorDialog({Key? key, this.color}) : super(key: key);

  @override
  State<ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<ColorDialog> {
  final _hexController = TextEditingController();
  late Color _color;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _color = widget.color ?? Theme.of(context).primaryColor;
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorPicker(
              pickerColor: _color,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: true,
              paletteType: PaletteType.hsvWithHue,
              labelTypes: const [],
              portraitOnly: true,
              pickerAreaBorderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              hexInputController: _hexController,
              onColorChanged: (color) {
                _color = color;
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _hexController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.tag),
                ),
                autofocus: true,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(9),
                  FilteringTextInputFormatter.allow(RegExp(kValidHexPattern)),
                ],
                onSubmitted: (_) {
                  Navigator.of(context).pop(_color);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingDialog extends StatefulWidget {
  const SettingDialog({Key? key}) : super(key: key);

  @override
  State<SettingDialog> createState() => SettingDialogState();
}

class SettingDialogState extends State<SettingDialog> {
  final _apiUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Configuration.getBaseUrl().then((value) {
      _apiUrlController.text = value;
    });
    Configuration.getApiKey().then((value) {
      _apiKeyController.text = value;
    });
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const YaruDialogTitleBar(
        leading: Icon(Icons.settings),
        title: Text('Setting'),
      ),
      titlePadding: EdgeInsets.zero,
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('API URL:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(controller: _apiUrlController),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('API Key:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(controller: _apiKeyController),
                ),
              ],
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        FilledButton(
          onPressed: () {
            _apiUrlController.clear();
            _apiKeyController.clear();
          },
          child: const Text('Rest'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_apiUrlController.text.isNotEmpty) {
              Configuration.setBaseUrl(_apiUrlController.text);
            }
            if (_apiKeyController.text.isNotEmpty) {
              Configuration.setApiKey(_apiKeyController.text);
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

BuildContext? _loadingCtx;

void showLoading(BuildContext context) {
  _loadingCtx = null;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      _loadingCtx = ctx;
      return const Center(child: YaruCircularProgressIndicator());
    },
  );
}

void hideLoading() {
  if (_loadingCtx != null && _loadingCtx!.mounted) {
    Navigator.of(_loadingCtx!).pop();
  }
}
