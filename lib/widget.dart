import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart' as mime;

void showToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    behavior: SnackBarBehavior.floating,
  ));
}

class ImagePreviewItem extends StatelessWidget {
  final String url;
  final Size? size;
  final int? length;
  final String? type;
  final double? ratio;
  final VoidCallback? onTapDownload;

  const ImagePreviewItem(
      {Key? key,
      required this.url,
      this.size,
      this.length,
      this.type,
      this.ratio,
      this.onTapDownload})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              Expanded(
                child: url.isEmpty
                    ? const Icon(Icons.image_not_supported_outlined)
                    : (url.startsWith('http')
                        ? Image.network(
                            url,
                            loadingBuilder: (_, child, event) {
                              if (event == null ||
                                  event.expectedTotalBytes == null) {
                                return child;
                              }
                              final p = event.cumulativeBytesLoaded /
                                  event.expectedTotalBytes!;
                              return Center(
                                  child: CircularProgressIndicator(value: p));
                            },
                          )
                        : Image.file(File(url))),
              ),
              const SizedBox(height: 10),
              if (url.isNotEmpty)
                Wrap(
                  spacing: 5,
                  children: [
                    if (ratio != null)
                      Chip(
                        avatar: const Icon(Icons.trending_down, size: 16),
                        label:
                            Text('${((1 - ratio!) * 100).toStringAsFixed(0)}%'),
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.only(right: 10),
                        shape: shape,
                      ),
                    Chip(
                      label: Text(
                          _formatSize(length ?? FileStat.statSync(url).size)),
                      padding: EdgeInsets.zero,
                      shape: shape,
                    ),
                    if (size != null)
                      Chip(
                        label: Text(
                            '${size!.width.toStringAsFixed(0)}x${size!.height.toStringAsFixed(0)}'),
                        padding: EdgeInsets.zero,
                        shape: shape,
                      ),
                    Chip(
                      label: Text(type ?? mime.lookupMimeType(url) ?? ''),
                      padding: EdgeInsets.zero,
                      shape: shape,
                    ),
                  ],
                ),
            ],
          ),
          if (onTapDownload != null)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.download),
                onPressed: onTapDownload,
              ),
            ),
        ],
      ),
    );
  }

  String _formatSize(int length) {
    final kb = length / 1000;
    if (kb < 1000) {
      return '${kb.round()}Kb';
    }
    final mb = kb / 1000;
    return '${mb.round()}M';
  }
}

class SectionItem extends StatelessWidget {
  final String section;
  final Widget child;

  const SectionItem({Key? key, required this.section, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.fromLTRB(12, 15, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: child,
        ),
        Positioned(
          left: 15,
          top: 0,
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Text(
              section,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ],
    );
  }
}
